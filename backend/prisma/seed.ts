import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const MODELS = [
  {
    title: "糖艺牡丹模具",
    category: "糖艺",
    style: "花卉",
    coverUrl: "https://picsum.photos/seed/moyu-sugar-peony/800/800",
    price: 29.9,
    description: "高精度糖艺牡丹翻糖模具，适合婚礼蛋糕装饰。"
  },
  {
    title: "机甲高达 GK 件",
    category: "机甲",
    style: "科幻",
    coverUrl: "https://picsum.photos/seed/moyu-mecha-gundam/800/800",
    price: 49.9,
    description: "1/100 比例机甲拼装参考模型，含分件结构。"
  },
  {
    title: "欧式建筑构件包",
    category: "建筑",
    style: "古典",
    coverUrl: "https://picsum.photos/seed/moyu-building-euro/800/800",
    price: 39.0,
    description: "柱式、拱门、檐口等欧式建筑装饰构件合集。"
  },
  {
    title: "卡通猫咪盲盒",
    category: "潮玩",
    style: "卡通",
    coverUrl: "https://picsum.photos/seed/moyu-cat-blindbox/800/800",
    price: 19.9,
    description: "Q 版猫咪系列潮玩模型，支持 3D 打印。"
  },
  {
    title: "食品翻糖蝴蝶结",
    category: "糖艺",
    style: "甜品",
    coverUrl: "https://picsum.photos/seed/moyu-sugar-bow/800/800",
    price: 15.9,
    description: "食品级翻糖蝴蝶结模具，烘焙店常用款。"
  },
  {
    title: "工业机械臂零件",
    category: "工业",
    style: "机械",
    coverUrl: "https://picsum.photos/seed/moyu-industrial-arm/800/800",
    price: 59.0,
    description: "六轴机械臂外观参考模型，适合教学展示。"
  },
  {
    title: "古风宫殿屋檐",
    category: "建筑",
    style: "国风",
    coverUrl: "https://picsum.photos/seed/moyu-palace-roof/800/800",
    price: 45.0,
    description: "中式宫殿屋檐组件，游戏场景与沙盘适用。"
  },
  {
    title: "赛车轮毂改装款",
    category: "载具",
    style: "现代",
    coverUrl: "https://picsum.photos/seed/moyu-racing-wheel/800/800",
    price: 32.0,
    description: "高性能赛车轮毂 3D 模型，多尺寸规格。"
  }
];

async function main() {
  const admin = await prisma.user.upsert({
    where: { phone: "13800000000" },
    update: { role: "ADMIN", nickname: "超级管理员" },
    create: {
      phone: "13800000000",
      nickname: "超级管理员",
      role: "ADMIN",
      status: "ACTIVE"
    }
  });

  const designer = await prisma.user.upsert({
    where: { phone: "13900001111" },
    update: { role: "DESIGNER", nickname: "糖艺设计师" },
    create: {
      phone: "13900001111",
      nickname: "糖艺设计师",
      role: "DESIGNER",
      status: "ACTIVE",
      avatar: "https://picsum.photos/seed/moyu-designer-avatar/200/200"
    }
  });

  const buyer = await prisma.user.upsert({
    where: { phone: "13700002222" },
    update: {},
    create: {
      phone: "13700002222",
      nickname: "测试买家",
      role: "BUYER",
      status: "ACTIVE"
    }
  });

  for (const m of MODELS) {
    const exists = await prisma.model.findFirst({ where: { title: m.title, designerId: designer.id } });
    if (exists) {
      await prisma.model.update({
        where: { id: exists.id },
        data: {
          coverUrl: m.coverUrl,
          description: m.description,
          status: "ON_SALE",
          price: m.price
        }
      });
      continue;
    }
    await prisma.model.create({
      data: {
        designerId: designer.id,
        title: m.title,
        description: m.description,
        category: m.category,
        style: m.style,
        format: "STL",
        fileSize: 12_500_000,
        price: m.price,
        coverUrl: m.coverUrl,
        downloadUrl: "https://example.com/models/demo.stl",
        status: "ON_SALE",
        viewCount: Math.floor(Math.random() * 500) + 50,
        likeCount: Math.floor(Math.random() * 80) + 5,
        favoriteCount: Math.floor(Math.random() * 40) + 2
      }
    });
  }

  const posts = [
    { content: "新上架糖艺牡丹模具，欢迎试打反馈！", tags: ["糖艺", "上新"] },
    { content: "机甲高达 GK 件渲染效果分享", tags: ["机甲", "渲染"] },
    { content: "翻糖蝴蝶结模具实拍，细节拉满", tags: ["糖艺", "实拍"] }
  ];
  for (const p of posts) {
    const exists = await prisma.post.findFirst({ where: { content: p.content, userId: designer.id } });
    if (exists) continue;
    await prisma.post.create({
      data: {
        userId: designer.id,
        content: p.content,
        type: "TEXT",
        topicTags: p.tags,
        likeCount: Math.floor(Math.random() * 30) + 1,
        commentCount: Math.floor(Math.random() * 10),
        status: "PUBLISHED"
      }
    });
  }

  const defaultConfigs = [
    { key: "api_base_url", value: "https://api.yourdomain.com/v1", description: "API 基础地址" },
    { key: "maintenance_mode", value: false, description: "维护模式" },
    { key: "enable_ai", value: true, description: "启用 AI 功能" },
    { key: "max_upload_mb", value: 200, description: "上传大小限制" },
    {
      key: "splash_ads",
      value: {
        enabled: true,
        skipAfterSec: 2,
        durationSec: 5,
        items: [
          {
            id: "demo-1",
            title: "模宇宙(糖艺大模王)",
            imageUrl: "https://picsum.photos/seed/moyu-ad1/1080/1920",
            linkUrl: "https://example.com/ad1",
            network: "custom"
          }
        ]
      },
      description: "App 启动广告页配置"
    },
    {
      key: "recharge_packages",
      value: {
        enabled: true,
        notice: "充值金额实时到账，可用于购买模型与增值服务。",
        packages: [
          { id: "p6", amount: 6, bonus: 0, label: "6元" },
          { id: "p30", amount: 30, bonus: 3, label: "30元送3元" },
          { id: "p68", amount: 68, bonus: 8, label: "68元送8元" },
          { id: "p128", amount: 128, bonus: 20, label: "128元送20元" }
        ]
      },
      description: "App 充值档位配置"
    },
    {
      key: "wallet_config",
      value: {
        rechargeEnabled: true,
        withdrawEnabled: false,
        withdrawMin: 10,
        withdrawTip: "提现需完成实名认证，审核后 1-3 个工作日到账。",
        balanceTip: "余额可用于购买模型、打赏设计师等。"
      },
      description: "App 钱包页文案与开关"
    },
    {
      key: "customer_service",
      value: {
        phone: "400-000-0000",
        wechat: "moyu_support",
        workHours: "9:00-18:00（工作日）",
        helpUrl: ""
      },
      description: "客服与帮助配置"
    },
    {
      key: "app_version_policy",
      value: {
        enabled: true,
        minVersion: "0.0.7",
        minBuildNumber: 8,
        latestVersion: "0.0.8",
        latestBuildNumber: 9,
        blockedVersions: ["0.0.5", "0.0.6"],
        forceUpdate: true,
        title: "需要更新 App",
        message: "当前版本过低或已停用，请下载安装最新版本后继续使用。",
        downloadPageUrl: "",
        downloadApkUrl: ""
      },
      description: "App 最低可用版本与强制更新"
    }
  ];

  for (const cfg of defaultConfigs) {
    await prisma.systemConfig.upsert({
      where: { key: cfg.key },
      update: { value: cfg.value, description: cfg.description },
      create: cfg
    });
  }

  console.log("Seed completed", { admin: admin.phone, designer: designer.phone, buyer: buyer.phone, models: MODELS.length });
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
