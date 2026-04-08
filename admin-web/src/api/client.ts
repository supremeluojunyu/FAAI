import axios from "axios";

export const api = axios.create({
  baseURL: "http://192.168.202.142:3000/api/v1",
  timeout: 10000
});

export async function fetchConfigs() {
  const { data } = await api.get("/admin/configs");
  return data.data.list;
}

export async function publishConfigs() {
  const { data } = await api.post("/admin/configs/publish");
  return data.data;
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
