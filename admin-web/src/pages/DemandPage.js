import { jsx as _jsx } from "react/jsx-runtime";
import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchDemands } from "../api/client";
export default function DemandPage() {
    const [rows, setRows] = useState([]);
    useEffect(() => {
        fetchDemands().then(setRows);
    }, []);
    return (_jsx(Card, { title: "\u9700\u6C42\u7BA1\u7406", children: _jsx(Table, { rowKey: "id", dataSource: rows, columns: [
                { title: "标题", dataIndex: "title" },
                { title: "类型", dataIndex: "type" },
                { title: "预算", dataIndex: "budget" },
                { title: "状态", dataIndex: "status" }
            ] }) }));
}
