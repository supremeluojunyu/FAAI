import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(__dirname, "..");
const HOME = process.env.HOME || "/home/golden";

function findFrpcToml() {
  const candidates = [
    process.env.FRPC_TOML,
    path.join(ROOT, "../frp_0.52.3_linux_amd64/frpc.toml"),
    path.join(HOME, "frp_0.52.3_linux_amd64/frpc.toml"),
  ].filter(Boolean);

  for (const p of candidates) {
    if (fs.existsSync(p)) return p;
  }

  const parent = path.join(ROOT, "..");
  if (fs.existsSync(parent)) {
    for (const name of fs.readdirSync(parent)) {
      if (!name.startsWith("frp")) continue;
      const p = path.join(parent, name, "frpc.toml");
      if (fs.existsSync(p)) return p;
    }
  }
  return null;
}

function parseToml(content) {
  const serverAddr = content.match(/serverAddr\s*=\s*"([^"]+)"/)?.[1] ?? "";
  const proxies = [];
  const blocks = content.split(/\[\[proxies\]\]/).slice(1);
  for (const block of blocks) {
    const name = block.match(/name\s*=\s*"([^"]+)"/)?.[1] ?? "";
    const type = block.match(/type\s*=\s*"([^"]+)"/)?.[1] ?? "tcp";
    const localPort = Number(block.match(/localPort\s*=\s*(\d+)/)?.[1] ?? 0);
    const remotePort = Number(block.match(/remotePort\s*=\s*(\d+)/)?.[1] ?? 0);
    proxies.push({ name, type, localPort, remotePort });
  }
  return { serverAddr, proxies };
}

function pickWebProxy(proxies) {
  return (
    proxies.find((p) => p.name === "webFAFI" || p.name === "webFAAI") ??
    proxies.find((p) => p.localPort === 80) ??
    proxies.find((p) => p.type === "tcp" && p.remotePort > 0)
  );
}

export function resolveFrpPublicUrl() {
  const frpcPath = findFrpcToml();
  if (!frpcPath) {
    throw new Error("未找到 frpc.toml，请确认 FRP 目录与 FAAI 同级");
  }

  const { serverAddr, proxies } = parseToml(fs.readFileSync(frpcPath, "utf8"));
  const web = pickWebProxy(proxies);
  if (!serverAddr || !web?.remotePort) {
    throw new Error(`frpc.toml 解析失败: ${frpcPath}`);
  }

  return {
    frpcPath,
    publicBaseUrl: `http://${serverAddr}:${web.remotePort}`,
    serverAddr,
    remotePort: web.remotePort,
    proxyName: web.name,
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  console.log(JSON.stringify(resolveFrpPublicUrl(), null, 2));
}
