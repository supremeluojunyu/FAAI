import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Card, Col, Row, Statistic } from "antd";
import { useEffect, useState } from "react";
import { fetchDashboard } from "../api/client";
export default function DashboardPage() {
    const [data, setData] = useState({ total_users: 0, total_models: 0, total_orders: 0, revenue: 0 });
    useEffect(() => {
        fetchDashboard().then(setData);
    }, []);
    return (_jsxs(Row, { gutter: 16, children: [_jsx(Col, { span: 6, children: _jsx(Card, { children: _jsx(Statistic, { title: "\u603B\u7528\u6237", value: data.total_users }) }) }), _jsx(Col, { span: 6, children: _jsx(Card, { children: _jsx(Statistic, { title: "\u603B\u6A21\u578B", value: data.total_models }) }) }), _jsx(Col, { span: 6, children: _jsx(Card, { children: _jsx(Statistic, { title: "\u603B\u8BA2\u5355", value: data.total_orders }) }) }), _jsx(Col, { span: 6, children: _jsx(Card, { children: _jsx(Statistic, { title: "\u8425\u6536", value: data.revenue, prefix: "\u00A5" }) }) })] }));
}
