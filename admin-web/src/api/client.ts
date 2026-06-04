import axios from "axios";
import { clearToken, getToken, setToken } from "../auth";

export const api = axios.create({
  baseURL: "/api/v1",
  timeout: 15000
});

api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

api.interceptors.response.use(
  (resp) => {
    const body = resp.data;
    if (body && typeof body.code === "number" && body.code !== 0) {
      return Promise.reject(new Error(body.message || "请求失败"));
    }
    return resp;
  },
  (error) => {
    const msg = error.response?.data?.message || error.message || "网络错误";
    if (error.response?.status === 401 || error.response?.data?.code === 1002) {
      clearToken();
    }
    return Promise.reject(new Error(msg));
  }
);

export async function sendLoginCode(phone: string) {
  const { data } = await api.post("/auth/send-code", { phone });
  return data.data as { expire_sec?: number; debug_code?: string };
}

export async function loginAdmin(phone: string, code: string) {
  const { data } = await api.post("/auth/login", { phone, code });
  const payload = data.data as { token: string; user: { role: string; nickname?: string; phone: string } };
  if (payload.user.role !== "ADMIN") {
    throw new Error("该账号不是管理员，无法登录后台");
  }
  setToken(payload.token);
  return payload.user;
}

export async function fetchConfigs() {
  const { data } = await api.get("/admin/configs");
  return data.data.list;
}

export async function saveConfig(key: string, value: unknown, description?: string) {
  const { data } = await api.put(`/admin/configs/${key}`, { value, description });
  return data.data;
}

export async function publishConfigs() {
  const { data } = await api.post("/admin/configs/publish");
  return data.data;
}

export async function fetchSplashAds() {
  const list = await fetchConfigs();
  const row = list.find((x: { key: string }) => x.key === "splash_ads");
  return (
    row?.value ?? {
      enabled: true,
      skipAfterSec: 2,
      durationSec: 5,
      items: []
    }
  );
}

export async function saveSplashAds(value: unknown) {
  return saveConfig("splash_ads", value, "App 启动广告页配置");
}

function pickConfig<T>(list: { key: string; value: T }[], key: string, fallback: T): T {
  const row = list.find((x) => x.key === key);
  return (row?.value as T) ?? fallback;
}

export async function fetchRechargePackages() {
  const list = await fetchConfigs();
  return pickConfig(list, "recharge_packages", {
    enabled: true,
    notice: "",
    packages: []
  });
}

export async function saveRechargePackages(value: unknown) {
  return saveConfig("recharge_packages", value, "App 充值档位配置");
}

export async function fetchWalletConfig() {
  const list = await fetchConfigs();
  return pickConfig(list, "wallet_config", {
    rechargeEnabled: true,
    withdrawEnabled: false,
    withdrawMin: 10,
    withdrawTip: "",
    balanceTip: ""
  });
}

export async function saveWalletConfig(value: unknown) {
  return saveConfig("wallet_config", value, "App 钱包页文案与开关");
}

export async function fetchCustomerService() {
  const list = await fetchConfigs();
  return pickConfig(list, "customer_service", {
    phone: "",
    wechat: "",
    workHours: "",
    helpUrl: ""
  });
}

export async function saveCustomerService(value: unknown) {
  return saveConfig("customer_service", value, "客服与帮助配置");
}

export async function fetchAppVersionPolicy() {
  const list = await fetchConfigs();
  return pickConfig(list, "app_version_policy", {
    enabled: false,
    minVersion: "0.0.0",
    minBuildNumber: 0,
    latestVersion: "",
    latestBuildNumber: 0,
    blockedVersions: [] as string[],
    forceUpdate: true,
    title: "需要更新 App",
    message: "当前版本过低，请下载最新版本后继续使用。",
    downloadPageUrl: "",
    downloadApkUrl: ""
  });
}

export async function saveAppVersionPolicy(value: unknown) {
  return saveConfig("app_version_policy", value, "App 最低可用版本与强制更新");
}

export async function fetchUsers(params?: Record<string, string>) {
  const { data } = await api.get("/admin/users", { params });
  return data.data.list;
}

export async function fetchModels() {
  const { data } = await api.get("/admin/models");
  return data.data.list;
}

export async function fetchDemands() {
  const { data } = await api.get("/admin/demands");
  return data.data.list;
}

export async function fetchPosts() {
  const { data } = await api.get("/admin/posts");
  return data.data.list;
}

export async function fetchDashboard() {
  const { data } = await api.get("/admin/statistics/dashboard");
  return data.data;
}

export async function fetchActivityLogs(params?: Record<string, string>) {
  const { data } = await api.get("/admin/activity-logs", { params });
  return data.data as {
    list: unknown[];
    total: number;
    page: number;
    action_stats: { action: string; count: number }[];
  };
}
