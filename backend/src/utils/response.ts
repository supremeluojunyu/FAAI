import { Response } from "express";

export function ok(res: Response, data: unknown = {}, message = "success") {
  return res.json({ code: 0, message, data });
}

export function fail(res: Response, code: number, message: string, data: unknown = {}) {
  return res.status(200).json({ code, message, data });
}
