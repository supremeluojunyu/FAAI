import type { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";
import type { JwtPayload } from "./auth";
import { logUserActivity } from "../services/activity-log";

/** 不记录（避免刷屏或重复） */
const SKIP_PATHS = new Set([
  "/admin/activity-logs",
  "/user/activity",
  "/health"
]);

/** 已在业务里单独记登录详情，中间件跳过避免重复 */
const SKIP_AUTH_PATHS = new Set([
  "/auth/send-code",
  "/auth/login",
  "/auth/carrier-login",
  "/auth/guest",
  "/auth/wechat/login"
]);

function parseAuth(req: Request): JwtPayload | undefined {
  const token = req.headers.authorization?.replace(/^Bearer\s+/i, "");
  if (!token) return undefined;
  try {
    return jwt.verify(token, env.jwtSecret) as JwtPayload;
  } catch {
    return undefined;
  }
}

function pickId(path: string, segment: number) {
  const parts = path.split("/").filter(Boolean);
  return parts[segment] ?? undefined;
}

function resolveAction(method: string, path: string): {
  action: string;
  targetType?: string;
  targetId?: string;
  summary?: string;
} | null {
  if (SKIP_PATHS.has(path)) return null;
  if (SKIP_AUTH_PATHS.has(path)) return null;

  const m = method.toUpperCase();
  const p = path.split("?")[0];

  if (p.startsWith("/admin/")) {
    return { action: "ADMIN_API", targetType: "admin", targetId: p, summary: `${m} ${p}` };
  }

  if (m === "GET" && p === "/models") return { action: "BROWSE_MODELS", summary: "浏览商城列表" };
  if (m === "GET" && p === "/models/search") return { action: "SEARCH_MODELS", summary: "搜索模型" };
  if (m === "GET" && /^\/models\/[^/]+$/.test(p)) {
    return { action: "VIEW_MODEL", targetType: "model", targetId: pickId(p, 1), summary: "查看模型详情" };
  }
  if (m === "POST" && /^\/models\/[^/]+\/favorite$/.test(p)) {
    return { action: "TOGGLE_FAVORITE", targetType: "model", targetId: pickId(p, 1), summary: "收藏/取消收藏" };
  }
  if (m === "POST" && /^\/models\/[^/]+\/like$/.test(p)) {
    return { action: "TOGGLE_LIKE_MODEL", targetType: "model", targetId: pickId(p, 1), summary: "点赞/取消点赞" };
  }
  if (m === "POST" && /^\/models\/[^/]+\/share$/.test(p)) {
    return { action: "SHARE_MODEL", targetType: "model", targetId: pickId(p, 1), summary: "分享模型" };
  }

  if (m === "GET" && p === "/posts") return { action: "BROWSE_POSTS", summary: "浏览社区列表" };
  if (m === "GET" && /^\/posts\/[^/]+$/.test(p)) {
    return { action: "VIEW_POST", targetType: "post", targetId: pickId(p, 1), summary: "查看动态" };
  }
  if (m === "POST" && /^\/posts\/[^/]+\/like$/.test(p)) {
    return { action: "TOGGLE_LIKE_POST", targetType: "post", targetId: pickId(p, 1), summary: "点赞动态" };
  }
  if (m === "POST" && /^\/posts\/[^/]+\/share$/.test(p)) {
    return { action: "SHARE_POST", targetType: "post", targetId: pickId(p, 1), summary: "分享动态" };
  }
  if (m === "POST" && p === "/posts") return { action: "CREATE_POST", summary: "发布动态" };
  if (m === "POST" && p === "/comments") return { action: "CREATE_COMMENT", summary: "发表评论" };

  if (m === "GET" && p === "/user/favorites") return { action: "VIEW_FAVORITES", summary: "查看我的收藏" };
  if (m === "GET" && p === "/user/profile") return { action: "VIEW_PROFILE", summary: "查看个人资料" };
  if (m === "PUT" && p === "/user/profile") return { action: "UPDATE_PROFILE", summary: "更新资料" };
  if (m === "GET" && p === "/wallet/balance") return { action: "VIEW_WALLET", summary: "查看钱包" };
  if (m === "POST" && p === "/wallet/recharge") return { action: "WALLET_RECHARGE", summary: "发起充值" };
  if (m === "POST" && p === "/wallet/withdraw") return { action: "WALLET_WITHDRAW", summary: "申请提现" };

  if (m === "GET" && p === "/orders") return { action: "VIEW_ORDERS", summary: "查看订单" };
  if (m === "POST" && p === "/orders/buy") return { action: "ORDER_BUY", summary: "购买模型" };
  if (m === "GET" && p.startsWith("/workbench/")) return { action: "WORKBENCH", targetId: p, summary: `${m} ${p}` };
  if (m === "GET" && p.startsWith("/demands")) return { action: "DEMAND", targetId: p, summary: `${m} ${p}` };
  if (m === "POST" && p.startsWith("/demands")) return { action: "DEMAND", targetId: p, summary: `${m} ${p}` };

  if (m === "GET" && p.startsWith("/designer/")) return { action: "DESIGNER", targetId: p, summary: `${m} ${p}` };

  return { action: "API_CALL", targetType: "api", targetId: p, summary: `${m} ${p}` };
}

function safeBody(req: Request): Record<string, unknown> | undefined {
  const body = req.body as Record<string, unknown> | undefined;
  if (!body || typeof body !== "object") return undefined;
  const copy: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(body)) {
    if (/password|code|token|secret/i.test(k)) {
      copy[k] = "***";
    } else if (typeof v === "string" && v.length > 200) {
      copy[k] = `${v.slice(0, 80)}...`;
    } else {
      copy[k] = v;
    }
  }
  return Object.keys(copy).length ? copy : undefined;
}

/**
 * 自动记录所有 /api/v1 请求：哪个账户、调用了什么接口、是否成功。
 */
export function activityAudit(req: Request, res: Response, next: NextFunction) {
  const auth = parseAuth(req);
  if (auth) req.auth = auth;

  const started = Date.now();
  res.on("finish", () => {
    if (res.statusCode >= 500) return;

    const path = req.path || "";
    const resolved = resolveAction(req.method, path);
    if (!resolved) return;

    const query =
      req.query && Object.keys(req.query).length
        ? Object.fromEntries(Object.entries(req.query).map(([k, v]) => [k, String(v)]))
        : undefined;

    void logUserActivity({
      userId: auth?.userId,
      action: resolved.action,
      targetType: resolved.targetType,
      targetId: resolved.targetId,
      detail: {
        summary: resolved.summary,
        method: req.method,
        path,
        status: res.statusCode,
        duration_ms: Date.now() - started,
        role: auth?.role,
        query,
        body: safeBody(req)
      },
      req
    });
  });

  next();
}
