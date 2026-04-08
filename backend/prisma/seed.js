"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
async function main() {
    await prisma.user.upsert({
        where: { phone: "13800000000" },
        update: {},
        create: {
            phone: "13800000000",
            nickname: "超级管理员",
            role: "ADMIN",
            status: "ACTIVE"
        }
    });
    const defaultConfigs = [
        { key: "api_base_url", value: "https://api.yourdomain.com/v1", description: "API 基础地址" },
        { key: "maintenance_mode", value: false, description: "维护模式" },
        { key: "enable_ai", value: true, description: "启用 AI 功能" },
        { key: "max_upload_mb", value: 200, description: "上传大小限制" }
    ];
    for (const cfg of defaultConfigs) {
        await prisma.systemConfig.upsert({
            where: { key: cfg.key },
            update: { value: cfg.value, description: cfg.description },
            create: cfg
        });
    }
    console.log("Seed completed");
}
main()
    .catch((e) => {
    console.error(e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
