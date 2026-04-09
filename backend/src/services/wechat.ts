import { env } from "../config/env";

type WechatLoginResult = {
  openid: string;
  unionid?: string;
};

export async function getWechatOpenIdByCode(code: string): Promise<WechatLoginResult> {
  if (!env.wechatAppId || !env.wechatAppSecret) {
    throw new Error("WECHAT_APPID / WECHAT_APPSECRET 未配置");
  }

  const url = new URL("https://api.weixin.qq.com/sns/oauth2/access_token");
  url.searchParams.set("appid", env.wechatAppId);
  url.searchParams.set("secret", env.wechatAppSecret);
  url.searchParams.set("code", code);
  url.searchParams.set("grant_type", "authorization_code");

  const resp = await fetch(url, { method: "GET" });
  const data = (await resp.json()) as Record<string, unknown>;

  if (!resp.ok || typeof data.errcode === "number") {
    throw new Error(`微信换取 openid 失败: ${JSON.stringify(data)}`);
  }

  return {
    openid: String(data.openid || ""),
    unionid: data.unionid ? String(data.unionid) : undefined
  };
}
