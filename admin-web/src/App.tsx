import { Button, Layout, Menu } from "antd";
import { useMemo, useState } from "react";
import { clearToken, isLoggedIn } from "./auth";
import AdPage from "./pages/AdPage";
import ConfigPage from "./pages/ConfigPage";
import OpsConfigPage from "./pages/OpsConfigPage";
import UserLogsPage from "./pages/UserLogsPage";
import DashboardPage from "./pages/DashboardPage";
import DemandPage from "./pages/DemandPage";
import LoginPage from "./pages/LoginPage";
import ModelPage from "./pages/ModelPage";
import PostPage from "./pages/PostPage";
import UserPage from "./pages/UserPage";

const { Header, Content } = Layout;

export default function App() {
  const [loggedIn, setLoggedIn] = useState(isLoggedIn());
  const [active, setActive] = useState("dashboard");

  const page = useMemo(() => {
    if (active === "ads") return <AdPage />;
    if (active === "ops") return <OpsConfigPage />;
    if (active === "logs") return <UserLogsPage />;
    if (active === "configs") return <ConfigPage />;
    if (active === "users") return <UserPage />;
    if (active === "models") return <ModelPage />;
    if (active === "demands") return <DemandPage />;
    if (active === "posts") return <PostPage />;
    return <DashboardPage />;
  }, [active]);

  if (!loggedIn) {
    return <LoginPage onSuccess={() => setLoggedIn(true)} />;
  }

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Header style={{ display: "flex", alignItems: "center", gap: 24 }}>
        <div style={{ color: "#fff", fontWeight: 600, whiteSpace: "nowrap" }}>模宇宙(糖艺大模王)</div>
        <Menu
          theme="dark"
          mode="horizontal"
          selectedKeys={[active]}
          onClick={(e) => setActive(e.key)}
          style={{ flex: 1, minWidth: 0 }}
          items={[
            { key: "dashboard", label: "数据看板" },
            { key: "ads", label: "广告管理" },
            { key: "ops", label: "运营配置" },
            { key: "logs", label: "用户日志" },
            { key: "configs", label: "系统配置" },
            { key: "users", label: "用户管理" },
            { key: "models", label: "模型管理" },
            { key: "demands", label: "需求管理" },
            { key: "posts", label: "社区管理" }
          ]}
        />
        <Button
          type="link"
          style={{ color: "#fff" }}
          onClick={() => {
            clearToken();
            setLoggedIn(false);
          }}
        >
          退出
        </Button>
      </Header>
      <Content style={{ padding: 24 }}>{page}</Content>
    </Layout>
  );
}
