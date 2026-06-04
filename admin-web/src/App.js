import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
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
        if (active === "ads")
            return _jsx(AdPage, {});
        if (active === "ops")
            return _jsx(OpsConfigPage, {});
        if (active === "logs")
            return _jsx(UserLogsPage, {});
        if (active === "configs")
            return _jsx(ConfigPage, {});
        if (active === "users")
            return _jsx(UserPage, {});
        if (active === "models")
            return _jsx(ModelPage, {});
        if (active === "demands")
            return _jsx(DemandPage, {});
        if (active === "posts")
            return _jsx(PostPage, {});
        return _jsx(DashboardPage, {});
    }, [active]);
    if (!loggedIn) {
        return _jsx(LoginPage, { onSuccess: () => setLoggedIn(true) });
    }
    return (_jsxs(Layout, { style: { minHeight: "100vh" }, children: [_jsxs(Header, { style: { display: "flex", alignItems: "center", gap: 24 }, children: [_jsx("div", { style: { color: "#fff", fontWeight: 600, whiteSpace: "nowrap" }, children: "\u6A21\u5B87\u5B99(\u7CD6\u827A\u5927\u6A21\u738B)" }), _jsx(Menu, { theme: "dark", mode: "horizontal", selectedKeys: [active], onClick: (e) => setActive(e.key), style: { flex: 1, minWidth: 0 }, items: [
                            { key: "dashboard", label: "数据看板" },
                            { key: "ads", label: "广告管理" },
                            { key: "ops", label: "运营配置" },
                            { key: "logs", label: "用户日志" },
                            { key: "configs", label: "系统配置" },
                            { key: "users", label: "用户管理" },
                            { key: "models", label: "模型管理" },
                            { key: "demands", label: "需求管理" },
                            { key: "posts", label: "社区管理" }
                        ] }), _jsx(Button, { type: "link", style: { color: "#fff" }, onClick: () => {
                            clearToken();
                            setLoggedIn(false);
                        }, children: "\u9000\u51FA" })] }), _jsx(Content, { style: { padding: 24 }, children: page })] }));
}
