import fs from "node:fs";
import path from "node:path";
import { prisma } from "../models/prisma";

const DEFAULT_SPLASH_ADS = {
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
};

function configFilePath() {
  return (
    process.env.APP_CONFIG_PATH ||
    path.resolve(__dirname, "../../../config-server/public/app-config.json")
  );
}

export async function publishAppConfig() {
  const filePath = configFilePath();
  const existing = fs.existsSync(filePath)
    ? (JSON.parse(fs.readFileSync(filePath, "utf8")) as Record<string, unknown>)
    : {};

  const configs = await prisma.systemConfig.findMany();
  const map = Object.fromEntries(configs.map((c: { key: string; value: unknown }) => [c.key, c.value]));

  const splashAds = (map.splash_ads as Record<string, unknown> | undefined) ?? existing.splashAds ?? DEFAULT_SPLASH_ADS;
  const maintenance = (map.maintenance_mode as boolean | undefined) ?? existing.maintenance ?? false;
  const features = {
    ...((existing.features as Record<string, unknown> | undefined) ?? {}),
    enableAI: (map.enable_ai as boolean | undefined) ?? (existing.features as Record<string, unknown> | undefined)?.enableAI ?? true,
    maxUploadSizeMB:
      (map.max_upload_mb as number | undefined) ??
      (existing.features as Record<string, unknown> | undefined)?.maxUploadSizeMB ??
      200
  };

  const next = {
    ...existing,
    splashAds,
    maintenance,
    features,
    version: new Date().toISOString()
  };

  fs.mkdirSync(path.dirname(filePath), { recursive: true });
  fs.writeFileSync(filePath, JSON.stringify(next, null, 2) + "\n");
  return { filePath, config: next };
}
