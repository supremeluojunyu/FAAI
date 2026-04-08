import { Router } from "express";
import jwt from "jsonwebtoken";
import { z } from "zod";
import { env } from "../config/env";
import { authRequired, adminRequired } from "../middlewares/auth";
import { prisma } from "../models/prisma";
import { fail, ok } from "../utils/response";

export const v1Router = Router();

v1Router.post("/auth/send-code", async (req, res) => {
  const parsed = z.object({ phone: z.string().min(11) }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  return ok(res, { expire_sec: 60 });
});

v1Router.post("/auth/login", async (req, res) => {
  const parsed = z.object({ phone: z.string(), code: z.string() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const user = await prisma.user.upsert({
    where: { phone: parsed.data.phone },
    update: {},
    create: { phone: parsed.data.phone, role: "BUYER", status: "ACTIVE" }
  });
  const token = jwt.sign({ userId: user.id, role: user.role }, env.jwtSecret, { expiresIn: env.jwtExpiresIn } as jwt.SignOptions);
  return ok(res, { token, user });
});

v1Router.get("/user/profile", authRequired, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.auth!.userId } });
  return ok(res, { user });
});

v1Router.put("/user/profile", authRequired, async (req, res) => {
  const parsed = z.object({
    nickname: z.string().optional(),
    avatar: z.string().optional(),
    bio: z.string().optional()
  }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const user = await prisma.user.update({ where: { id: req.auth!.userId }, data: parsed.data });
  return ok(res, { user });
});

v1Router.post("/user/apply-designer", authRequired, async (req, res) => {
  const parsed = z.object({ reason: z.string().min(2), portfolio_images: z.array(z.string()).min(1) }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const app = await prisma.designerApplication.upsert({
    where: { userId: req.auth!.userId },
    update: { reason: parsed.data.reason, portfolio: parsed.data.portfolio_images, status: "PENDING" },
    create: { userId: req.auth!.userId, reason: parsed.data.reason, portfolio: parsed.data.portfolio_images }
  });
  return ok(res, { application_id: app.id });
});

v1Router.get("/models", async (req, res) => {
  const page = Number(req.query.page || 1);
  const size = Number(req.query.size || 20);
  const list = await prisma.model.findMany({
    skip: (page - 1) * size,
    take: size,
    orderBy: { createdAt: "desc" }
  });
  const total = await prisma.model.count();
  return ok(res, { list, total });
});

v1Router.get("/models/:id", async (req, res) => {
  const model = await prisma.model.findUnique({ where: { id: req.params.id }, include: { designer: true } });
  if (!model) return fail(res, 1001, "模型不存在");
  return ok(res, {
    model,
    images: [],
    designer_info: model.designer,
    is_favorited: false,
    is_liked: false
  });
});

v1Router.post("/models/:id/favorite", authRequired, async (req, res) => {
  const where = { userId_modelId: { userId: req.auth!.userId, modelId: req.params.id } };
  const found = await prisma.modelFavorite.findUnique({ where });
  if (found) {
    await prisma.modelFavorite.delete({ where });
    await prisma.model.update({ where: { id: req.params.id }, data: { favoriteCount: { decrement: 1 } } });
    return ok(res, { is_favorited: false });
  }
  await prisma.modelFavorite.create({ data: { userId: req.auth!.userId, modelId: req.params.id } });
  await prisma.model.update({ where: { id: req.params.id }, data: { favoriteCount: { increment: 1 } } });
  return ok(res, { is_favorited: true });
});

v1Router.post("/models/:id/like", authRequired, async (req, res) => {
  const where = { userId_modelId: { userId: req.auth!.userId, modelId: req.params.id } };
  const found = await prisma.modelLike.findUnique({ where });
  if (found) {
    await prisma.modelLike.delete({ where });
    const model = await prisma.model.update({ where: { id: req.params.id }, data: { likeCount: { decrement: 1 } } });
    return ok(res, { is_liked: false, like_count: model.likeCount });
  }
  await prisma.modelLike.create({ data: { userId: req.auth!.userId, modelId: req.params.id } });
  const model = await prisma.model.update({ where: { id: req.params.id }, data: { likeCount: { increment: 1 } } });
  return ok(res, { is_liked: true, like_count: model.likeCount });
});

v1Router.get("/models/search", async (req, res) => {
  const keyword = String(req.query.keyword || "");
  const list = await prisma.model.findMany({
    where: {
      status: "ON_SALE",
      OR: keyword ? [{ title: { contains: keyword, mode: "insensitive" } }, { description: { contains: keyword, mode: "insensitive" } }] : undefined
    },
    orderBy: { createdAt: "desc" }
  });
  return ok(res, { list, total: list.length });
});

v1Router.post("/orders/buy", authRequired, async (req, res) => {
  const parsed = z.object({ model_id: z.string() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const model = await prisma.model.findUnique({ where: { id: parsed.data.model_id } });
  if (!model || model.status !== "ON_SALE") return fail(res, 3002, "模型已下架");
  const order = await prisma.order.create({
    data: {
      buyerId: req.auth!.userId,
      modelId: model.id,
      amount: model.price,
      tradeNo: `TRADE_${Date.now()}`
    }
  });
  return ok(res, { order_id: order.id, trade_no: order.tradeNo, pay_params: { channel: "mock" } });
});

v1Router.get("/orders/:id/download", authRequired, async (req, res) => {
  const order = await prisma.order.findUnique({ where: { id: req.params.id }, include: { model: true } });
  if (!order || order.buyerId !== req.auth!.userId) return fail(res, 1001, "订单不存在");
  if (order.payStatus !== "PAID") return fail(res, 1003, "订单未支付");
  return ok(res, { download_url: order.model.downloadUrl, expire_at: order.downloadExpireAt });
});

v1Router.get("/orders", authRequired, async (req, res) => {
  const status = String(req.query.status || "");
  const list = await prisma.order.findMany({
    where: { buyerId: req.auth!.userId, ...(status ? { payStatus: status as never } : {}) },
    orderBy: { createdAt: "desc" }
  });
  return ok(res, { list });
});

v1Router.post("/ai/photo-to-3d", authRequired, async (_req, res) => ok(res, { task_id: `ai_${Date.now()}`, preview_url: "" }));
v1Router.post("/ai/text-to-3d", authRequired, async (_req, res) => ok(res, { task_id: `ai_${Date.now()}`, preview_url: "" }));
v1Router.get("/ai/task/:task_id", authRequired, async (_req, res) => ok(res, { status: "PROCESSING", result_url: "" }));

v1Router.post("/demands", authRequired, async (req, res) => {
  const parsed = z.object({
    title: z.string().min(1),
    description: z.string().min(1),
    type: z.enum(["MODELING", "PRINT", "MODIFY"]),
    reference_images: z.array(z.string()).default([]),
    budget: z.coerce.number().positive(),
    deadline: z.string()
  }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const demand = await prisma.demand.create({
    data: {
      buyerId: req.auth!.userId,
      title: parsed.data.title,
      description: parsed.data.description,
      type: parsed.data.type,
      referenceImages: parsed.data.reference_images,
      budget: parsed.data.budget,
      deadline: new Date(parsed.data.deadline),
      platformEscrowAmount: parsed.data.budget
    }
  });
  return ok(res, { demand_id: demand.id, payment_url: `mock://pay/${demand.id}` });
});

v1Router.get("/demands", authRequired, async (req, res) => {
  const list = await prisma.demand.findMany({
    where: { status: { not: "CANCELLED" }, ...(req.query.type ? { type: String(req.query.type) as never } : {}) },
    orderBy: { createdAt: "desc" }
  });
  return ok(res, { list });
});

v1Router.post("/demands/:id/accept", authRequired, async (req, res) => {
  const demand = await prisma.demand.findUnique({ where: { id: req.params.id } });
  if (!demand) return fail(res, 1001, "需求不存在");
  if (demand.status !== "WAITING_FOR_DESIGNER" && demand.status !== "PENDING_PAY") return fail(res, 3003, "需求状态不允许");
  const assignment = await prisma.demandAssignment.create({ data: { demandId: demand.id, designerId: req.auth!.userId, status: "ACCEPTED" } });
  await prisma.demand.update({ where: { id: demand.id }, data: { status: "IN_PROGRESS" } });
  return ok(res, { assignment_id: assignment.id });
});

v1Router.get("/demands/my-published", authRequired, async (req, res) => {
  const list = await prisma.demand.findMany({
    where: { buyerId: req.auth!.userId, ...(req.query.status ? { status: String(req.query.status) as never } : {}) },
    orderBy: { createdAt: "desc" }
  });
  return ok(res, { list });
});

v1Router.get("/demands/my-accepted", authRequired, async (req, res) => {
  const rows = await prisma.demandAssignment.findMany({
    where: { designerId: req.auth!.userId },
    include: { demand: true },
    orderBy: { acceptedAt: "desc" }
  });
  const list = req.query.status ? rows.filter((x) => x.demand.status === String(req.query.status)) : rows;
  return ok(res, { list });
});

v1Router.post("/deliveries", authRequired, async (req, res) => {
  const parsed = z.object({ demand_id: z.string(), file_url: z.string(), comment: z.string().optional() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const delivery = await prisma.delivery.create({
    data: { demandId: parsed.data.demand_id, designerId: req.auth!.userId, fileUrl: parsed.data.file_url, comment: parsed.data.comment }
  });
  await prisma.demand.update({ where: { id: parsed.data.demand_id }, data: { status: "REVIEW" } });
  return ok(res, { delivery_id: delivery.id });
});

v1Router.post("/demands/:id/accept-delivery", authRequired, async (req, res) => {
  const demand = await prisma.demand.findUnique({ where: { id: req.params.id } });
  if (!demand || demand.buyerId !== req.auth!.userId) return fail(res, 1003, "无权限");
  await prisma.demand.update({ where: { id: demand.id }, data: { status: "COMPLETED" } });
  return ok(res, { success: true });
});

v1Router.post("/demands/:id/reject-delivery", authRequired, async (req, res) => {
  const parsed = z.object({ reason: z.string().min(1) }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const demand = await prisma.demand.findUnique({ where: { id: req.params.id } });
  if (!demand || demand.buyerId !== req.auth!.userId) return fail(res, 1003, "无权限");
  await prisma.demand.update({ where: { id: demand.id }, data: { status: "IN_PROGRESS" } });
  return ok(res, { success: true });
});

v1Router.get("/designer/models", authRequired, async (req, res) => {
  const status = String(req.query.status || "all");
  const list = await prisma.model.findMany({
    where: { designerId: req.auth!.userId, ...(status !== "all" ? { status: status as never } : {}) },
    orderBy: { createdAt: "desc" }
  });
  return ok(res, { list });
});

v1Router.post("/designer/models", authRequired, async (req, res) => {
  const parsed = z.object({
    title: z.string().min(1),
    description: z.string().optional(),
    category: z.string().default("其他"),
    style: z.string().default("默认"),
    format: z.string().default("OBJ"),
    fileSize: z.coerce.number().default(0),
    price: z.coerce.number().default(0),
    coverUrl: z.string().default(""),
    downloadUrl: z.string().default("")
  }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const model = await prisma.model.create({
    data: { ...parsed.data, designerId: req.auth!.userId, status: "DRAFT" }
  });
  return ok(res, { model_id: model.id });
});

v1Router.put("/designer/models/:id", authRequired, async (req, res) => {
  const parsed = z.object({ title: z.string().optional(), price: z.coerce.number().optional(), status: z.enum(["DRAFT", "ON_SALE", "OFF_SALE"]).optional() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const model = await prisma.model.findUnique({ where: { id: req.params.id } });
  if (!model || model.designerId !== req.auth!.userId) return fail(res, 1003, "无权限");
  await prisma.model.update({ where: { id: req.params.id }, data: parsed.data as never });
  return ok(res, { success: true });
});

v1Router.post("/designer/models/:id/convert", authRequired, async (_req, res) => ok(res, { task_id: `convert_${Date.now()}` }));

v1Router.get("/designer/statistics", authRequired, async (req, res) => {
  const models = await prisma.model.findMany({ where: { designerId: req.auth!.userId } });
  const modelIds = models.map((m) => m.id);
  const sales = await prisma.order.count({ where: { modelId: { in: modelIds }, payStatus: "PAID" } });
  const revenueRows = await prisma.order.findMany({ where: { modelId: { in: modelIds }, payStatus: "PAID" }, select: { amount: true } });
  const revenue = revenueRows.reduce((sum, x) => sum + Number(x.amount), 0);
  const views = models.reduce((sum, m) => sum + m.viewCount, 0);
  const favorites = models.reduce((sum, m) => sum + m.favoriteCount, 0);
  return ok(res, { views, favorites, sales, revenue, days: Number(req.query.days || 30) });
});

v1Router.get("/posts", async (_req, res) => {
  const list = await prisma.post.findMany({ orderBy: { createdAt: "desc" }, take: 20 });
  return ok(res, { list });
});

v1Router.post("/posts", authRequired, async (req, res) => {
  const parsed = z.object({
    content: z.string().min(1),
    type: z.enum(["TEXT", "IMAGE", "VIDEO", "MODEL_PREVIEW"]).default("TEXT"),
    topic_tags: z.array(z.string()).default([])
  }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const post = await prisma.post.create({
    data: {
      userId: req.auth!.userId,
      content: parsed.data.content,
      type: parsed.data.type,
      topicTags: parsed.data.topic_tags
    }
  });
  return ok(res, { post_id: post.id });
});

v1Router.get("/posts/:id", async (req, res) => {
  const post = await prisma.post.findUnique({ where: { id: req.params.id } });
  if (!post) return fail(res, 1001, "动态不存在");
  const comments = await prisma.comment.findMany({ where: { postId: req.params.id }, orderBy: { createdAt: "asc" } });
  return ok(res, { post, comments, is_liked: false });
});

v1Router.post("/posts/:id/like", authRequired, async (req, res) => {
  const where = { postId_userId: { postId: req.params.id, userId: req.auth!.userId } };
  const found = await prisma.postLike.findUnique({ where });
  let post;
  if (found) {
    await prisma.postLike.delete({ where });
    post = await prisma.post.update({ where: { id: req.params.id }, data: { likeCount: { decrement: 1 } } });
  } else {
    await prisma.postLike.create({ data: { postId: req.params.id, userId: req.auth!.userId } });
    post = await prisma.post.update({ where: { id: req.params.id }, data: { likeCount: { increment: 1 } } });
  }
  return ok(res, { like_count: post.likeCount });
});

v1Router.post("/comments", authRequired, async (req, res) => {
  const parsed = z.object({ post_id: z.string(), parent_id: z.string().optional(), content: z.string().min(1) }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const comment = await prisma.comment.create({
    data: { postId: parsed.data.post_id, parentId: parsed.data.parent_id, content: parsed.data.content, userId: req.auth!.userId }
  });
  await prisma.post.update({ where: { id: parsed.data.post_id }, data: { commentCount: { increment: 1 } } });
  return ok(res, { comment_id: comment.id });
});

v1Router.post("/follow/:user_id", authRequired, async (_req, res) => ok(res, { is_following: true }));
v1Router.get("/user/:user_id/homepage", async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.params.user_id } });
  const posts = await prisma.post.findMany({ where: { userId: req.params.user_id }, take: 20 });
  const models = await prisma.model.findMany({ where: { designerId: req.params.user_id }, take: 20 });
  return ok(res, { user, posts, models });
});
v1Router.get("/ranking/designers", async (_req, res) => {
  const list = await prisma.user.findMany({ where: { role: "DESIGNER" }, take: 50, orderBy: { createdAt: "desc" } });
  return ok(res, { list });
});

v1Router.get("/wallet/balance", authRequired, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.auth!.userId } });
  return ok(res, { balance: user?.balance || 0 });
});
v1Router.post("/wallet/recharge", authRequired, async (req, res) => {
  const parsed = z.object({ amount: z.coerce.number().positive(), channel: z.string() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const tx = await prisma.transaction.create({ data: { userId: req.auth!.userId, amount: parsed.data.amount, type: "RECHARGE", status: "PENDING" } });
  return ok(res, { pay_params: { trade_no: tx.id, channel: parsed.data.channel } });
});
v1Router.post("/wallet/withdraw", authRequired, async (req, res) => {
  const parsed = z.object({ amount: z.coerce.number().positive(), bank_card_id: z.string() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const tx = await prisma.transaction.create({ data: { userId: req.auth!.userId, amount: -parsed.data.amount, type: "WITHDRAW", status: "PENDING", remark: parsed.data.bank_card_id } });
  return ok(res, { apply_id: tx.id });
});

v1Router.get("/admin/configs", authRequired, adminRequired, async (_req, res) => {
  const list = await prisma.systemConfig.findMany({ orderBy: { key: "asc" } });
  return ok(res, { list });
});

v1Router.put("/admin/configs/:key", authRequired, adminRequired, async (req, res) => {
  const parsed = z.object({ value: z.any(), description: z.string().optional() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  await prisma.systemConfig.upsert({
    where: { key: req.params.key },
    update: { value: parsed.data.value, description: parsed.data.description, updatedBy: req.auth!.userId },
    create: { key: req.params.key, value: parsed.data.value, description: parsed.data.description, updatedBy: req.auth!.userId }
  });
  return ok(res, { success: true });
});

v1Router.post("/admin/configs/publish", authRequired, adminRequired, async (_req, res) => {
  // 实际项目中请写入 S3/CDN，并记录审计日志。
  const configs = await prisma.systemConfig.findMany();
  return ok(res, {
    task_id: `publish_${Date.now()}`,
    config_preview: configs
  });
});

v1Router.get("/admin/users", authRequired, adminRequired, async (req, res) => {
  const list = await prisma.user.findMany({
    where: {
      ...(req.query.role ? { role: String(req.query.role) as never } : {}),
      ...(req.query.status ? { status: String(req.query.status) as never } : {})
    },
    orderBy: { createdAt: "desc" }
  });
  return ok(res, { list });
});
v1Router.put("/admin/users/:id/role", authRequired, adminRequired, async (req, res) => {
  const parsed = z.object({ role: z.enum(["BUYER", "DESIGNER", "ADMIN"]) }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  await prisma.user.update({ where: { id: req.params.id }, data: { role: parsed.data.role } });
  return ok(res, { success: true });
});
v1Router.get("/admin/designer-applications", authRequired, adminRequired, async (_req, res) => ok(res, { list: await prisma.designerApplication.findMany({ orderBy: { createdAt: "desc" } }) }));
v1Router.post("/admin/designer-applications/:id/review", authRequired, adminRequired, async (req, res) => {
  const parsed = z.object({ approved: z.boolean(), review_msg: z.string().optional() }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  const app = await prisma.designerApplication.update({
    where: { id: req.params.id },
    data: { status: parsed.data.approved ? "APPROVED" : "REJECTED", reviewedAt: new Date(), reviewMsg: parsed.data.review_msg }
  });
  if (parsed.data.approved) await prisma.user.update({ where: { id: app.userId }, data: { role: "DESIGNER" } });
  return ok(res, { success: true });
});
v1Router.get("/admin/models", authRequired, adminRequired, async (_req, res) => ok(res, { list: await prisma.model.findMany({ orderBy: { createdAt: "desc" } }) }));
v1Router.put("/admin/models/:id/status", authRequired, adminRequired, async (req, res) => {
  const parsed = z.object({ status: z.enum(["DRAFT", "ON_SALE", "OFF_SALE"]) }).safeParse(req.body);
  if (!parsed.success) return fail(res, 1001, "参数错误");
  await prisma.model.update({ where: { id: req.params.id }, data: { status: parsed.data.status } });
  return ok(res, { success: true });
});
v1Router.get("/admin/demands", authRequired, adminRequired, async (_req, res) => ok(res, { list: await prisma.demand.findMany({ orderBy: { createdAt: "desc" } }) }));
v1Router.post("/admin/demands/:id/refund", authRequired, adminRequired, async (req, res) => {
  await prisma.demand.update({ where: { id: req.params.id }, data: { status: "CANCELLED" } });
  return ok(res, { success: true });
});
v1Router.get("/admin/posts", authRequired, adminRequired, async (_req, res) => ok(res, { list: await prisma.post.findMany({ orderBy: { createdAt: "desc" } }) }));
v1Router.delete("/admin/posts/:id", authRequired, adminRequired, async (req, res) => {
  await prisma.post.update({ where: { id: req.params.id }, data: { status: "DELETED" } });
  return ok(res, { success: true });
});
v1Router.post("/admin/topics", authRequired, adminRequired, async (_req, res) => ok(res, { topic_id: `topic_${Date.now()}` }));
v1Router.get("/admin/statistics/dashboard", authRequired, adminRequired, async (_req, res) => {
  const [total_users, total_models, total_orders] = await Promise.all([prisma.user.count(), prisma.model.count(), prisma.order.count()]);
  const paidOrders = await prisma.order.findMany({ where: { payStatus: "PAID" }, select: { amount: true } });
  const revenue = paidOrders.reduce((sum, x) => sum + Number(x.amount), 0);
  return ok(res, { total_users, total_models, total_orders, revenue });
});
