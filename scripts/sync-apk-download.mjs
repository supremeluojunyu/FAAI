import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createWriteStream } from "node:fs";
import { pipeline } from "node:stream/promises";
import { Readable } from "node:stream";
import QRCode from "qrcode";
import { loadProjectEnv } from "./load-env-file.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
loadProjectEnv(ROOT);

const REPO = process.env.GITHUB_REPO || "supremeluojunyu/FAAI";
const DOWNLOAD_DIR = path.join(ROOT, "config-server/public/download");
const APK_PATH = path.join(DOWNLOAD_DIR, "app-release.apk");
const VERSION_PATH = path.join(DOWNLOAD_DIR, "version.json");

const API_MIRROR_PREFIX =
  process.env.GITHUB_API_MIRROR || "https://gh-proxy.com/https://api.github.com";
const DOWNLOAD_MIRROR_PREFIX =
  process.env.GITHUB_DOWNLOAD_MIRROR || "https://gh-proxy.com/https://github.com";

function mirrorApiUrl(pathname) {
  const p = pathname.startsWith("/") ? pathname : `/${pathname}`;
  const prefix = API_MIRROR_PREFIX.replace(/\/$/, "");
  if (prefix === "https://api.github.com" || prefix === "direct") {
    return `https://api.github.com${p}`;
  }
  return `${prefix}${p}`;
}

function mirrorDownloadUrl(url) {
  if (!url || !url.startsWith("https://github.com/")) return url;
  if (process.env.GITHUB_DOWNLOAD_MIRROR === "direct") return url;
  return `${DOWNLOAD_MIRROR_PREFIX.replace(/\/$/, "")}/${url.replace(/^https:\/\//, "")}`;
}

function readPublicBaseUrl() {
  const cfgPath = path.join(ROOT, "config/public-endpoint.json");
  if (fs.existsSync(cfgPath)) {
    return JSON.parse(fs.readFileSync(cfgPath, "utf8")).publicBaseUrl?.replace(/\/$/, "");
  }
  const appCfg = path.join(ROOT, "config-server/public/app-config.json");
  if (fs.existsSync(appCfg)) {
    return JSON.parse(fs.readFileSync(appCfg, "utf8")).publicBaseUrl?.replace(/\/$/, "");
  }
  return "";
}

function authHeaders(extra = {}) {
  const headers = {
    Accept: "application/vnd.github+json",
    "User-Agent": "moyu-apk-sync",
    ...extra
  };
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

async function fetchJson(url, headers) {
  let lastErr;
  const urls = [url];
  if (url.includes("api.github.com") && !url.includes("gh-proxy")) {
    urls.push(mirrorApiUrl(url.replace(/^https:\/\/api\.github\.com/, "")));
  }
  for (const u of urls) {
    try {
      const resp = await fetch(u, { headers, signal: AbortSignal.timeout(60000) });
      if (!resp.ok) {
        const text = await resp.text();
        throw new Error(`HTTP ${resp.status}: ${text.slice(0, 200)}`);
      }
      return resp.json();
    } catch (e) {
      lastErr = e;
    }
  }
  const detail = lastErr?.cause?.code || lastErr?.message || "unknown";
  throw new Error(`GitHub 请求失败 (${detail})，URL: ${url}`);
}

async function fetchLatestRelease() {
  const apiUrl = mirrorApiUrl(`/repos/${REPO}/releases?per_page=20`);
  const releases = await fetchJson(apiUrl, authHeaders());
  if (!Array.isArray(releases)) {
    throw new Error(typeof releases?.message === "string" ? releases.message : "GitHub API 返回异常");
  }
  const candidates = releases.filter(
    (r) => !r.draft && r.assets?.some((a) => a.name === "app-release.apk")
  );
  if (!candidates.length) throw new Error("未找到含 app-release.apk 的 Release");
  candidates.sort((a, b) => new Date(b.published_at) - new Date(a.published_at));
  return candidates[0];
}

function assetApiUrl(assetId) {
  return mirrorApiUrl(`/repos/${REPO}/releases/assets/${assetId}`);
}

async function downloadFile(url, dest, headers = {}, assetId) {
  const candidates = [];
  if (assetId) candidates.push(assetApiUrl(assetId));
  if (url) candidates.push(mirrorDownloadUrl(url), url);

  let lastErr;
  for (const u of candidates) {
    try {
      const resp = await fetch(u, { headers, redirect: "follow", signal: AbortSignal.timeout(600000) });
      if (!resp.ok) throw new Error(`下载失败 ${resp.status}`);
      const buf = Buffer.from(await resp.arrayBuffer());
      fs.writeFileSync(dest, buf);
      return;
    } catch (e) {
      lastErr = e;
    }
  }
  const detail = lastErr?.cause?.code || lastErr?.message || "unknown";
  throw new Error(`APK 下载失败 (${detail})`);
}

function renderIndex(meta) {
  const apkUrl = meta.download_url;
  return `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>模宇宙(糖艺大模王) App 下载 ${meta.tag_name}</title>
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
  <meta http-equiv="Pragma" content="no-cache" />
  <style>
    * { box-sizing: border-box; }
    body { font-family: system-ui, -apple-system, sans-serif; max-width: 520px; margin: 32px auto; padding: 0 16px 48px; color: #1f1f1f; background: #f7f8fa; }
    h1 { font-size: 1.5rem; margin: 0 0 8px; }
    .card { background: #fff; border: 1px solid #e8e8e8; border-radius: 16px; padding: 28px 24px; box-shadow: 0 4px 16px rgba(0,0,0,.05); text-align: center; }
    .sub { color: #666; font-size: 15px; margin-bottom: 20px; line-height: 1.6; }
    .qr-wrap { display: inline-block; padding: 12px; background: #fff; border: 1px solid #eee; border-radius: 12px; margin: 8px 0 16px; }
    .qr-wrap img { display: block; width: 240px; height: 240px; }
    .qr-tip { color: #888; font-size: 13px; margin-bottom: 16px; }
    .btn { display: inline-block; padding: 14px 28px; background: #1677ff; color: #fff; text-decoration: none; border-radius: 10px; font-weight: 600; font-size: 16px; }
    .meta { text-align: left; color: #666; font-size: 14px; line-height: 1.9; margin-top: 24px; padding-top: 20px; border-top: 1px solid #f0f0f0; }
    code { background: #f5f5f5; padding: 2px 6px; border-radius: 4px; word-break: break-all; font-size: 13px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>模宇宙(糖艺大模王) Android App</h1>
    <p style="color:#1677ff;font-weight:700;font-size:18px;margin:0 0 12px">当前版本 ${meta.tag_name}</p>
    <p class="sub">扫码或点击下方按钮，下载最新 APK 安装包</p>
    <div class="qr-wrap"><img src="qr.png?v=${Date.now()}" alt="扫码下载 APK" width="240" height="240" /></div>
    <p class="qr-tip">手机扫码直接下载</p>
    <a class="btn" href="${apkUrl}?v=${meta.tag_name}">下载 APK（${meta.tag_name}）</a>
    <div class="meta">
      <div>版本：<code>${meta.tag_name}</code></div>
      <div>大小：${meta.size_mb} MB</div>
      <div>更新时间：${meta.updated_at_local}</div>
      <div>下载地址：<code>${apkUrl}</code></div>
    </div>
  </div>
</body>
</html>`;
}

async function writeQrImage(url, dest) {
  await QRCode.toFile(dest, url, { width: 240, margin: 2, errorCorrectionLevel: "M" });
}

/** 供 Nginx include：下载时显示与 Release 一致的文件名（仅 ASCII，避免引号破坏 nginx 配置） */
function writeApkHeadersConf(tag) {
  const safeTag = String(tag).replace(/[^a-zA-Z0-9._-]/g, "");
  const fileName = `moyu-${safeTag}.apk`;
  const conf = `add_header Content-Disposition 'attachment; filename="${fileName}"';\n`;
  fs.writeFileSync(path.join(DOWNLOAD_DIR, "apk-headers.conf"), conf);
}

async function main() {
  fs.mkdirSync(DOWNLOAD_DIR, { recursive: true });
  console.log("GitHub API:", API_MIRROR_PREFIX.includes("gh-proxy") ? "镜像模式" : "直连");

  const release = await fetchLatestRelease();
  const asset = release.assets?.find((a) => a.name === "app-release.apk");
  if (!asset) throw new Error(`Release ${release.tag_name} 未找到 app-release.apk`);

  let needDownload = true;
  if (fs.existsSync(VERSION_PATH)) {
    const prev = JSON.parse(fs.readFileSync(VERSION_PATH, "utf8"));
    if (prev.tag_name === release.tag_name && prev.asset_id === asset.id && fs.existsSync(APK_PATH)) {
      needDownload = false;
      console.log(`已是最新: ${release.tag_name}`);
    }
  }

  const dlHeaders = authHeaders({ Accept: "application/octet-stream" });

  if (needDownload) {
    console.log(`下载 ${release.tag_name} ...`);
    const tmp = `${APK_PATH}.tmp`;
    await downloadFile(asset.browser_download_url, tmp, dlHeaders, asset.id);
    fs.renameSync(tmp, APK_PATH);
    console.log(`已保存: ${APK_PATH}`);
  }

  const stat = fs.statSync(APK_PATH);
  const publicBase = readPublicBaseUrl() || "";
  const meta = {
    tag_name: release.tag_name,
    asset_id: asset.id,
    size_bytes: stat.size,
    size_mb: (stat.size / 1024 / 1024).toFixed(1),
    published_at: release.published_at,
    updated_at: new Date().toISOString(),
    updated_at_local: new Date().toLocaleString("zh-CN", {
      hour12: false,
      timeZone: "Asia/Shanghai",
    }),
    download_url: publicBase ? `${publicBase}/download/app-release.apk` : "/download/app-release.apk",
    page_url: publicBase ? `${publicBase}/download/` : "/download/",
  };

  fs.writeFileSync(VERSION_PATH, JSON.stringify(meta, null, 2) + "\n");
  writeApkHeadersConf(meta.tag_name);
  const qrPath = path.join(DOWNLOAD_DIR, "qr.png");
  await writeQrImage(meta.download_url, qrPath);
  fs.writeFileSync(path.join(DOWNLOAD_DIR, "index.html"), renderIndex(meta));

  const appCfgPath = path.join(ROOT, "config-server/public/app-config.json");
  if (fs.existsSync(appCfgPath)) {
    const appCfg = JSON.parse(fs.readFileSync(appCfgPath, "utf8"));
    appCfg.apkDownloadUrl = meta.download_url;
    appCfg.apkPageUrl = meta.page_url;
    appCfg.apkVersion = meta.tag_name;
    fs.writeFileSync(appCfgPath, JSON.stringify(appCfg, null, 2) + "\n");
  }

  console.log("下载页:", meta.page_url);
  console.log("APK直链:", meta.download_url);
  console.log("下载文件名:", `模宇宙(糖艺大模王)-${meta.tag_name}.apk`);
  try {
    const { execSync } = await import("node:child_process");
    execSync("bash scripts/apply-nginx-config.sh", { cwd: ROOT, stdio: "pipe" });
    console.log("Nginx 已重载（APK 下载文件名已更新）");
  } catch {
    console.log("提示: 请执行 bash scripts/apply-nginx-config.sh 使下载文件名生效");
  }
}

main().catch((err) => {
  console.error(err.message || err);
  console.error("\n提示: 若直连 GitHub 失败，请在 config/apk-sync.env 配置 GITHUB_TOKEN，默认已走 gh-proxy 镜像。");
  console.error("推送代码请用 SSH: bash scripts/git-push-github.sh");
  process.exit(1);
});
