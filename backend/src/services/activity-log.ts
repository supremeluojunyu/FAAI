import type { Request } from "express";
import type { Prisma } from "@prisma/client";
import { prisma } from "../models/prisma";
import { getClientIp, getClientIpDebug } from "../utils/client-ip";

export type ActivityAction =
  | "LOGIN_SMS"
  | "LOGIN_CARRIER"
  | "LOGIN_GUEST"
  | "LOGIN_WECHAT"
  | "SEND_SMS_CODE"
  | "VIEW_MODEL"
  | "FAVORITE_MODEL"
  | "UNFAVORITE_MODEL"
  | "LIKE_MODEL"
  | "UNLIKE_MODEL"
  | "SHARE_MODEL"
  | "VIEW_POST"
  | "LIKE_POST"
  | "UNLIKE_POST"
  | "SHARE_POST"
  | "WALLET_RECHARGE"
  | "APP_EVENT";

export async function logUserActivity(input: {
  userId?: string | null;
  action: ActivityAction | string;
  targetType?: string;
  targetId?: string;
  detail?: Record<string, unknown>;
  req?: Request;
}) {
  try {
    const ipDebug = getClientIpDebug(input.req);
    const mergedDetail = {
      ...(input.detail ?? {}),
      ...(ipDebug.ip
        ? { client_ip_source: ipDebug.source, client_ip_chain: ipDebug.chain }
        : {})
    };
    await prisma.userActivityLog.create({
      data: {
        userId: input.userId ?? null,
        action: input.action,
        targetType: input.targetType,
        targetId: input.targetId,
        detail: (Object.keys(mergedDetail).length ? mergedDetail : undefined) as Prisma.InputJsonValue | undefined,
        ip: getClientIp(input.req),
        userAgent: input.req?.headers["user-agent"]?.slice(0, 500)
      }
    });
  } catch (e) {
    console.error("[activity-log]", e);
  }
}
