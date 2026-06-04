import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Alert, Button, Card, Input, Select, Space, Table, Tag, message } from "antd";
import { useEffect, useState } from "react";
import { fetchActivityLogs } from "../api/client";
const ACTION_LABELS = {
    LOGIN_SMS: "短信登录",
    LOGIN_CARRIER: "运营商登录",
    LOGIN_GUEST: "游客进入",
    LOGIN_WECHAT: "微信登录",
    SEND_SMS_CODE: "发送验证码",
    APP_LOGIN_SUCCESS: "App登录成功",
    OPEN_TAB: "切换底部Tab",
    OPEN_PAGE: "打开页面",
    BROWSE_MODELS: "浏览商城",
    SEARCH_MODELS: "搜索模型",
    VIEW_MODEL: "查看模型",
    TOGGLE_FAVORITE: "收藏操作",
    TOGGLE_LIKE_MODEL: "模型点赞",
    SHARE_MODEL: "分享模型",
    BROWSE_POSTS: "浏览社区",
    VIEW_POST: "查看动态",
    TOGGLE_LIKE_POST: "动态点赞",
    SHARE_POST: "分享动态",
    VIEW_FAVORITES: "我的收藏",
    VIEW_PROFILE: "个人资料",
    UPDATE_PROFILE: "更新资料",
    VIEW_WALLET: "查看钱包",
    WALLET_RECHARGE: "发起充值",
    WALLET_WITHDRAW: "申请提现",
    VIEW_ORDERS: "查看订单",
    ORDER_BUY: "购买模型",
    WORKBENCH: "工作台",
    DEMAND: "需求/接单",
    DESIGNER: "设计师",
    ADMIN_API: "管理端操作",
    API_CALL: "其他API",
    APP_EVENT: "App事件"
};
function actionLabel(action) {
    return ACTION_LABELS[action] ?? action;
}
function summaryOf(detail) {
    if (!detail || typeof detail !== "object")
        return "-";
    const d = detail;
    if (typeof d.summary === "string")
        return d.summary;
    if (typeof d.page === "string")
        return `页面: ${d.page}`;
    if (typeof d.tab === "string")
        return `Tab: ${d.tab}`;
    return JSON.stringify(d).slice(0, 120);
}
export default function UserLogsPage() {
    const [rows, setRows] = useState([]);
    const [stats, setStats] = useState([]);
    const [loading, setLoading] = useState(false);
    const [total, setTotal] = useState(0);
    const [page, setPage] = useState(1);
    const [action, setAction] = useState();
    const [phone, setPhone] = useState("");
    const load = async (p = page) => {
        setLoading(true);
        try {
            const data = await fetchActivityLogs({
                page: String(p),
                size: "50",
                ...(action ? { action } : {}),
                ...(phone ? { phone } : {})
            });
            setRows(data.list);
            setTotal(data.total);
            setStats(data.action_stats ?? []);
            setPage(data.page ?? p);
        }
        catch (e) {
            message.error(e instanceof Error ? e.message : "加载失败");
        }
        finally {
            setLoading(false);
        }
    };
    useEffect(() => {
        load(1);
    }, []);
    return (_jsxs(Space, { direction: "vertical", size: "large", style: { width: "100%" }, children: [_jsx(Alert, { type: "info", showIcon: true, message: "\u81EA\u52A8\u8BB0\u5F55\u8BF4\u660E", description: "\u7528\u6237\u767B\u5F55\u540E\uFF0CApp \u6BCF\u6B21\u8BF7\u6C42\u63A5\u53E3\u3001\u5207\u6362 Tab\u3001\u6253\u5F00\u9875\u9762\u90FD\u4F1A\u81EA\u52A8\u5199\u5165\u65E5\u5FD7\u3002\u8BF7\u7528 App \u767B\u5F55\u5E76\u64CD\u4F5C\u540E\u5237\u65B0\u672C\u9875\uFF1B\u4EC5\u7BA1\u7406\u7AEF\u767B\u5F55\u4E0D\u4F1A\u4EA7\u751F App \u884C\u4E3A\u8BB0\u5F55\u3002" }), _jsx(Card, { title: "\u884C\u4E3A\u7EDF\u8BA1\uFF08\u5168\u5E93\uFF09", size: "small", children: _jsxs(Space, { wrap: true, children: [stats.length === 0 ? _jsx("span", { style: { color: "#999" }, children: "\u6682\u65E0\u7EDF\u8BA1" }) : null, stats.map((s) => (_jsxs(Tag, { style: { cursor: "pointer" }, onClick: () => { setAction(s.action); load(1); }, children: [actionLabel(s.action), "\uFF1A", s.count] }, s.action)))] }) }), _jsx(Card, { title: `用户操作日志（共 ${total} 条）`, extra: _jsxs(Space, { children: [_jsx(Select, { allowClear: true, placeholder: "\u884C\u4E3A\u7C7B\u578B", style: { width: 180 }, value: action, onChange: setAction, options: Object.entries(ACTION_LABELS).map(([value, label]) => ({ value, label })) }), _jsx(Input, { placeholder: "\u624B\u673A\u53F7", value: phone, onChange: (e) => setPhone(e.target.value), style: { width: 140 } }), _jsx(Button, { type: "primary", onClick: () => load(1), children: "\u67E5\u8BE2" }), _jsx(Button, { onClick: () => {
                                setAction(undefined);
                                setPhone("");
                                load(1);
                            }, children: "\u91CD\u7F6E" }), _jsx(Button, { onClick: () => load(page), children: "\u5237\u65B0" })] }), children: _jsx(Table, { rowKey: "id", loading: loading, locale: { emptyText: "暂无日志。请用 App 账号登录并浏览商城/社区后点击「刷新」。" }, dataSource: rows, pagination: {
                        current: page,
                        total,
                        pageSize: 50,
                        showTotal: (t) => `共 ${t} 条`,
                        onChange: (p) => load(p)
                    }, scroll: { x: 1200 }, columns: [
                        {
                            title: "时间",
                            dataIndex: "createdAt",
                            width: 168,
                            render: (v) => new Date(v).toLocaleString("zh-CN", { hour12: false, timeZone: "Asia/Shanghai" })
                        },
                        {
                            title: "账户",
                            width: 200,
                            render: (_, r) => r.user ? (_jsxs("div", { children: [_jsx("div", { children: r.user.nickname ?? "用户" }), _jsxs("div", { style: { fontSize: 12, color: "#666" }, children: [r.user.phone, " \u00B7 ", r.user.role] })] })) : (_jsx(Tag, { children: "\u672A\u767B\u5F55/\u6E38\u5BA2" }))
                        },
                        {
                            title: "操作",
                            dataIndex: "action",
                            width: 130,
                            render: (v) => _jsx(Tag, { color: "processing", children: actionLabel(v) })
                        },
                        {
                            title: "说明",
                            dataIndex: "detail",
                            width: 200,
                            ellipsis: true,
                            render: (v) => summaryOf(v)
                        },
                        {
                            title: "对象",
                            width: 180,
                            render: (_, r) => r.targetType ? `${r.targetType}: ${r.targetId ?? "-"}` : "-"
                        },
                        {
                            title: "状态",
                            width: 70,
                            render: (_, r) => {
                                const s = r?.detail?.status;
                                if (s == null)
                                    return "-";
                                return _jsx(Tag, { color: s < 400 ? "success" : "error", children: String(s) });
                            }
                        },
                        { title: "IP", dataIndex: "ip", width: 120 }
                    ] }) })] }));
}
