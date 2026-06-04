import type { NextFunction, Request, Response } from "express";
import fs from "node:fs";
import path from "node:path";
import { checkAppVersion, type AppVersionPolicy } from "../utils/app-version";
import { fail } from "../utils/response";

const CONFIG_PATH =
  process.env.APP_CONFIG_PATH ||
  path.resolve(__dirname, "../../../config-server/public/app-config.json");

let cachedPolicy: AppVersionPolicy | null = null;
let cachedAt = 0;

function loadPolicy(): AppVersionPolicy | null {
  const now = Date.now();
  if (cachedPolicy && now - cachedAt < 15_000) return cachedPolicy;
  try {
    if (!fs.existsSync(CONFIG_PATH)) return null;
    const json = JSON.parse(fs.readFileSync(CONFIG_PATH, "utf8")) as Record<string, unknown>;
    cachedPolicy = (json.versionPolicy as AppVersionPolicy) ?? null;
    cachedAt = now;
    return cachedPolicy;
  } catch {
    return null;
  }
}

/** 供发布配置后刷新 */
export function invalidateVersionPolicyCache() {
  cachedPolicy = null;
  cachedAt = 0;
}

/**
 * 校验来自 Android App 的请求（带 X-App-Client: moyu-app）。
 * 版本过低返回 code=1009，禁止登录与使用接口。
 */
export function appVersionGuard(req: Request, res: Response, next: NextFunction) {
  if (req.headers["x-app-client"] !== "moyu-app") return next();

  const policy = loadPolicy();
  if (!policy?.enabled) return next();

  const version = String(req.headers["x-app-version"] ?? "0.0.0");
  const build = Number(req.headers["x-app-build"] ?? 0);
  const result = checkAppVersion(version, build, policy);
  if (result.allowed) return next();

  const pageUrl = policy.downloadPageUrl || "";
  const apkUrl = policy.downloadApkUrl || "";
  return fail(res, 1009, policy.message || result.reason || "请更新到最新版本", {
    force_update: policy.forceUpdate !== false,
    title: policy.title || "需要更新",
    reason: result.reason,
    current_version: version,
    current_build: build,
    min_version: policy.minVersion,
    min_build_number: policy.minBuildNumber,
    latest_version: policy.latestVersion,
    download_page_url: pageUrl,
    download_apk_url: apkUrl
  });
}
