import { NextFunction, Request, Response } from "express";
import { fail } from "../utils/response";

export function notFoundHandler(_req: Request, res: Response) {
  return fail(res, 1001, "接口不存在");
}

export function errorHandler(err: unknown, _req: Request, res: Response, _next: NextFunction) {
  console.error(err);
  return fail(res, 5000, "服务器错误");
}
