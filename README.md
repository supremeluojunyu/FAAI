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

## 发布 Android APK（GitHub Release）

仓库已配置 Actions：推送 **`v` 开头** 的 Git 标签后，会自动在 GitHub 上创建/更新对应 **Release**，并上传 `app-release.apk`。

```bash
git tag v1.0.0
git push origin v1.0.0
```

在仓库页 **Releases** 中即可下载 APK。首次使用前请确认 **Settings → Actions → General** 中 Workflow 权限为默认（`GITHUB_TOKEN` 可写 contents）。

**首次 CI 构建通常要 15～40 分钟**（安装 Android SDK、下载 Gradle/依赖）。Actions 里步骤长时间「转圈」时，点开该步骤展开日志，一般是在下载而非卡死。`v0.x` 标签会自动标记为 **Pre-release**。

若 Release 页面出现 **Draft** 且没有 `app-release.apk`，多半是旧版 workflow 里 `files` 缩进错误导致未上传附件；更新仓库后请在网页上 **删除该 Draft Release**，再按下面重打标签触发。

若你曾推送过旧版 workflow 导致失败，可修正后推送新 commit，再**移动标签**重新触发：

```bash
git push origin :refs/tags/v0.0.1   # 删除远程标签（可选）
git tag -d v0.0.1
git tag -a v0.0.1 -m "retry"
git push origin v0.0.1
```

## 新 Ubuntu 虚拟机一键部署

```bash
bash scripts/oneclick_setup.sh
bash scripts/oneclick_deploy.sh
```

可选指定本机 IP：`bash scripts/oneclick_deploy.sh 192.168.x.x`
