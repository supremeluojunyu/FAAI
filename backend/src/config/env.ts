import dotenv from "dotenv";

dotenv.config();

export const env = {
  nodeEnv: process.env.NODE_ENV || "development",
  port: Number(process.env.PORT || 3000),
  jwtSecret: process.env.JWT_SECRET || "change-me",
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || "7d",
  smsProvider: process.env.SMS_PROVIDER || "mock",
  smsCodeTtlSec: Number(process.env.SMS_CODE_TTL_SEC || 300),
  wechatAppId: process.env.WECHAT_APPID || "",
  wechatAppSecret: process.env.WECHAT_APPSECRET || "",
  s3Endpoint: process.env.S3_ENDPOINT || "",
  s3AccessKey: process.env.S3_ACCESS_KEY || "",
  s3SecretKey: process.env.S3_SECRET_KEY || "",
  s3BucketModels: process.env.S3_BUCKET_MODELS || "model-files"
};
