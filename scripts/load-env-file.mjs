import fs from "node:fs";
import path from "node:path";

/** 加载 KEY=VALUE 环境文件（不覆盖已有环境变量） */
export function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const text = fs.readFileSync(filePath, "utf8");
  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const idx = trimmed.indexOf("=");
    if (idx <= 0) continue;
    const key = trimmed.slice(0, idx).trim();
    const val = trimmed.slice(idx + 1).trim();
    if (process.env[key] === undefined) process.env[key] = val;
  }
}

export function loadProjectEnv(root) {
  loadEnvFile(path.join(root, "config/apk-sync.env"));
}
