import { Layout, Menu } from "antd";
import { useMemo, useState } from "react";
import ConfigPage from "./pages/ConfigPage";
import DashboardPage from "./pages/DashboardPage";
import DemandPage from "./pages/DemandPage";
import ModelPage from "./pages/ModelPage";
import PostPage from "./pages/PostPage";
import UserPage from "./pages/UserPage";

const { Header, Content } = Layout;

export default function App() {
  const [active, setActive] = useState("dashboard");
  const page = useMemo(() => {
    if (active === "configs") return <ConfigPage />;
    if (active === "users") return <UserPage />;
    if (active === "models") return <ModelPage />;
    if (active === "demands") return <DemandPage />;
    if (active === "posts") return <PostPage />;
    return <DashboardPage />;
  }, [active]);

  return (
    <Layout style={{ minHeight: "100vh" }}>
      <Header>
        <Menu
          theme="dark"
          mode="horizontal"
          selectedKeys={[active]}
          onClick={(e) => setActive(e.key)}
          items={[
            { key: "dashboard", label: "数据看板" },
            { key: "configs", label: "系统配置" },
            { key: "users", label: "用户管理" },
            { key: "models", label: "模型管理" },
            { key: "demands", label: "需求管理" },
            { key: "posts", label: "社区管理" }
          ]}
        />
      </Header>
      <Content style={{ padding: 24 }}>
        {page}
      </Content>
    </Layout>
  );
}
