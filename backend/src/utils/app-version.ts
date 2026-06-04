export type AppVersionPolicy = {
  enabled?: boolean;
  minVersion?: string;
  minBuildNumber?: number;
  latestVersion?: string;
  latestBuildNumber?: number;
  blockedVersions?: string[];
  forceUpdate?: boolean;
  title?: string;
  message?: string;
  downloadPageUrl?: string;
  downloadApkUrl?: string;
};

export function parseVersionParts(version: string): number[] {
  return version
    .replace(/^v/i, "")
    .split(/[.+]/)
    .map((x) => parseInt(x.replace(/\D/g, ""), 10) || 0);
}

/** 比较语义化版本：-1 低于，0 相等，1 高于 */
export function compareVersion(a: string, b: string): number {
  const pa = parseVersionParts(a);
  const pb = parseVersionParts(b);
  const len = Math.max(pa.length, pb.length);
  for (let i = 0; i < len; i++) {
    const da = pa[i] ?? 0;
    const db = pb[i] ?? 0;
    if (da < db) return -1;
    if (da > db) return 1;
  }
  return 0;
}

export function checkAppVersion(
  version: string,
  buildNumber: number,
  policy: AppVersionPolicy | null | undefined
): { allowed: boolean; reason?: string } {
  if (!policy?.enabled) return { allowed: true };

  const ver = (version || "0.0.0").trim();
  const build = Number.isFinite(buildNumber) ? buildNumber : 0;

  const blocked = policy.blockedVersions ?? [];
  if (blocked.some((b) => compareVersion(ver, b) === 0)) {
    return { allowed: false, reason: "当前版本已被禁止使用" };
  }

  const minVer = (policy.minVersion ?? "").trim();
  if (minVer && compareVersion(ver, minVer) < 0) {
    return { allowed: false, reason: `版本过低（当前 ${ver}，最低要求 ${minVer}）` };
  }

  const minBuild = policy.minBuildNumber ?? 0;
  if (minBuild > 0 && build > 0 && build < minBuild) {
    return { allowed: false, reason: `构建号过低（当前 ${build}，最低要求 ${minBuild}）` };
  }

  return { allowed: true };
}
