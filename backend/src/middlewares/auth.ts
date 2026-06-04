import { NextFunction, Request, Response } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";
import { fail } from "../utils/response";

export interface JwtPayload {
  userId: string;
  role: "BUYER" | "DESIGNER" | "ADMIN";
}

declare global {
  namespace Express {
    interface Request {
      auth?: JwtPayload;
    }
  }
}

function parseToken(req: Request): JwtPayload | null {
  const token = req.headers.authorization?.replace("Bearer ", "");
  if (!token) return null;
  try {
    return jwt.verify(token, env.jwtSecret) as JwtPayload;
  } catch {
    return null;
  }
}

/** 有 token 则解析用户，无 token 也放行 */
export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  req.auth = parseToken(req) ?? undefined;
  next();
}

export function authRequired(req: Request, res: Response, next: NextFunction) {
  const payload = parseToken(req);
  if (!payload) return fail(res, 1002, "未登录或登录已过期");
  req.auth = payload;
  next();
}

export function adminRequired(req: Request, res: Response, next: NextFunction) {
  if (!req.auth || req.auth.role !== "ADMIN") return fail(res, 1003, "无权限");
  next();
}
