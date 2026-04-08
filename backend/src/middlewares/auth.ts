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

export function authRequired(req: Request, res: Response, next: NextFunction) {
  const token = req.headers.authorization?.replace("Bearer ", "");
  if (!token) return fail(res, 1002, "未登录");
  try {
    req.auth = jwt.verify(token, env.jwtSecret) as JwtPayload;
    next();
  } catch {
    return fail(res, 1002, "登录已过期");
  }
}

export function adminRequired(req: Request, res: Response, next: NextFunction) {
  if (!req.auth || req.auth.role !== "ADMIN") return fail(res, 1003, "无权限");
  next();
}
