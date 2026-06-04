import type { Request } from "express";

function normalizeIp(raw: string): string {
  let ip = raw.trim();
  if (ip.startsWith("::ffff:")) ip = ip.slice(7);
  if (ip.includes("%")) ip = ip.split("%")[0]!;
  return ip;
}

function isPrivateOrLoopback(ip: string): boolean {
  if (!ip || ip === "::1") return true;
  if (ip.startsWith("fc") || ip.startsWith("fd") || ip.startsWith("fe80:")) return true;
  if (/^127\./.test(ip)) return true;
  if (/^10\./.test(ip)) return true;
  if (/^192\.168\./.test(ip)) return true;
  const m = /^172\.(\d+)\./.exec(ip);
  if (m) {
    const n = Number(m[1]);
    if (n >= 16 && n <= 31) return true;
  }
  return false;
}

function headerValue(req: Request, name: string): string | undefined {
  const v = req.headers[name.toLowerCase()];
  if (typeof v === "string" && v.trim()) return v.trim();
  if (Array.isArray(v) && v[0]) return String(v[0]).trim();
  return undefined;
}

function collectCandidates(req: Request): { ip: string; source: string }[] {
  const out: { ip: string; source: string }[] = [];
  const push = (source: string, raw?: string) => {
    if (!raw) return;
    for (const part of raw.split(",")) {
      const ip = normalizeIp(part);
      if (ip) out.push({ ip, source });
    }
  };

  push("cf-connecting-ip", headerValue(req, "cf-connecting-ip"));
  push("true-client-ip", headerValue(req, "true-client-ip"));
  push("x-real-ip", headerValue(req, "x-real-ip"));
  push("x-forwarded-for", headerValue(req, "x-forwarded-for"));
  push("x-original-forwarded-for", headerValue(req, "x-original-forwarded-for"));
  push("x-client-ip", headerValue(req, "x-client-ip"));

  if (req.ip) push("express-req.ip", req.ip);
  if (req.socket?.remoteAddress) push("socket", req.socket.remoteAddress);

  return out;
}

/** 解析真实客户端公网 IP（适配 Nginx / FRP 隧道） */
export function getClientIp(req?: Request): string | null {
  if (!req) return null;

  const candidates = collectCandidates(req);
  const firstPublic = candidates.find((c) => !isPrivateOrLoopback(c.ip));
  if (firstPublic) return firstPublic.ip;

  return candidates[0]?.ip ?? null;
}

export function getClientIpDebug(req?: Request) {
  const candidates = req ? collectCandidates(req) : [];
  const chosen = req ? getClientIp(req) : null;
  const source = candidates.find((c) => c.ip === chosen)?.source ?? null;
  return {
    ip: chosen,
    source,
    chain: candidates.map((c) => c.ip).join(", "),
    x_forwarded_for: req ? headerValue(req, "x-forwarded-for") : undefined,
    x_real_ip: req ? headerValue(req, "x-real-ip") : undefined,
    remote: req?.socket?.remoteAddress
  };
}
