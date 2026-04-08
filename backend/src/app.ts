import cors from "cors";
import express from "express";
import morgan from "morgan";
import { errorHandler, notFoundHandler } from "./middlewares/errorHandler";
import { v1Router } from "./routes/v1";

export const app = express();

app.use(cors());
app.use(express.json({ limit: "10mb" }));
app.use(morgan("dev"));

app.get("/health", (_req, res) => {
  res.json({ ok: true, service: "moyu-backend" });
});

app.use("/api/v1", v1Router);
app.use(notFoundHandler);
app.use(errorHandler);
