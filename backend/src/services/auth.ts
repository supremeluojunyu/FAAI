import crypto from "node:crypto";
import { env } from "../config/env";

type SmsCodeRecord = {
  code: string;
  expireAt: number;
};

const smsCodeStore = new Map<string, SmsCodeRecord>();

function genCode() {
  if (env.nodeEnv !== "production") return "123456";
  return String(crypto.randomInt(100000, 1000000));
}

export async function sendSmsCode(phone: string) {
  const code = genCode();
  const expireAt = Date.now() + env.smsCodeTtlSec * 1000;
  smsCodeStore.set(phone, { code, expireAt });

  // TODO: 切换真实短信服务商时，在这里接入阿里云/腾讯云 SDK。
  // 目前使用 mock 模式，便于内网调试。
  if (env.smsProvider === "mock") {
    return {
      expireSec: env.smsCodeTtlSec,
      debugCode: env.nodeEnv === "production" ? undefined : code
    };
  }

  return { expireSec: env.smsCodeTtlSec };
}

export function verifySmsCode(phone: string, code: string) {
  const record = smsCodeStore.get(phone);
  if (!record) return false;
  if (record.expireAt < Date.now()) {
    smsCodeStore.delete(phone);
    return false;
  }
  const ok = record.code === code;
  if (ok) smsCodeStore.delete(phone);
  return ok;
}
