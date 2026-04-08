# 模宇宙全栈项目骨架

## 目录
- `backend`：Node.js + Express + TypeScript + Prisma
- `mobile-app`：Flutter + Riverpod + Dio
- `admin-web`：React + Ant Design
- `config-server`：Nginx 静态配置服务

## 快速启动
1. 后端：
   - 复制 `backend/.env.example` 为 `.env`
   - 执行 `prisma migrate dev`、`prisma db seed`
   - 执行 `npm run dev`
2. 移动端：
   - 进入 `mobile-app` 执行 `flutter pub get`
   - 执行 `flutter run`
3. 管理后台：
   - 进入 `admin-web` 执行 `npm install && npm run dev`
4. 配置服务：
   - 使用 `config-server/nginx.conf` 部署
   - `config-server/public/app-config.json` 可直接被 App 拉取

## 开发地址
- 虚拟机地址：`192.168.202.142`
