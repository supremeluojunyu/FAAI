# FRP 隧道传递真实客户端 IP

日志里若全是 `127.0.0.1`，说明 FRP 以 **TCP 穿透** 连到本机，且未把访客公网 IP 带给 Nginx/后端。

本项目采用 **Proxy Protocol v2**（仅改本机 frpc + Nginx，**不必**改公网 frps）：

## 一键启用（本机）

```bash
bash ~/FAAI/scripts/enable-frp-real-ip.sh
```

## 手动配置

### 1. frpc.toml（本机）

`localPort` 指向 Nginx 的 PP 专用口 `9080`，并开启：

```toml
[[proxies]]
name = "webFAFI"
type = "tcp"
localIP = "127.0.0.1"
localPort = 9080
remotePort = 8081

[proxies.transport]
proxyProtocolVersion = "v2"
```

参考：`deploy/frp/frpc.toml.example`

### 2. Nginx

`deploy/nginx/moyu.conf` 已包含：

- `listen 80` — 局域网直连，无 PP
- `listen 127.0.0.1:9080 proxy_protocol` — 仅 frpc 使用

应用配置：

```bash
bash ~/FAAI/scripts/apply-nginx-config.sh
```

### 3. 重启

```bash
sudo systemctl restart frpc
cd ~/FAAI/backend && npm run build && sudo systemctl restart moyu-backend
```

## 备选：HTTP 类型代理

若不能改 PP，可将 TCP 改为 `type = "http"`，由 frp 写入 `X-Forwarded-For`（公网端口与 `vhostHTTPPort` 相关，见 [frp 文档](https://gofrp.org/en/docs/features/common/realip/)）。

## 验证

公网访问一次 App 或管理端后，在 **用户日志** 中 IP 应为手机/浏览器公网地址，而非 `127.0.0.1`。

本机快速自检（模拟上游已写入公网 IP）：

```bash
curl -s -H "X-Forwarded-For: 203.0.113.9" http://127.0.0.1/api/v1/models | head -c 80
```
