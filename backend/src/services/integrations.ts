import crypto from "crypto";
import { GetObjectCommand, PutObjectCommand, S3Client } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import jpush from "jpush-sdk";
import { env } from "../config/env";

const s3 = new S3Client({
  endpoint: env.s3Endpoint,
  credentials: { accessKeyId: env.s3AccessKey, secretAccessKey: env.s3SecretKey }
});

export function verifyWechatSign(body: string, sign: string, key: string): boolean {
  const computed = crypto.createHash("md5").update(body + "&key=" + key).digest("hex").toUpperCase();
  return computed === sign;
}

export async function generateDownloadUrl(key: string) {
  const command = new GetObjectCommand({ Bucket: env.s3BucketModels, Key: key });
  return getSignedUrl(s3, command, { expiresIn: 300 });
}

export async function uploadConfigJson(bucket: string, objectKey: string, body: object) {
  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: objectKey,
      Body: JSON.stringify(body),
      ContentType: "application/json"
    })
  );
}

const jpushClient = jpush.buildClient({
  appKey: process.env.JPUSH_APPKEY || "",
  masterSecret: process.env.JPUSH_MASTER_SECRET || ""
});

export async function pushToUser(registrationId: string, title: string, content: string, extras: object) {
  await jpushClient.send({
    platform: "all",
    audience: { registration_id: [registrationId] },
    notification: { alert: content, android: { title, extras }, ios: { alert: content, extras } }
  });
}
