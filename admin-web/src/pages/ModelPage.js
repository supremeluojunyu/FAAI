import { jsx as _jsx } from "react/jsx-runtime";
import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchModels } from "../api/client";
export default function ModelPage() {
    const [rows, setRows] = useState([]);
    useEffect(() => {
        fetchModels().then(setRows);
    }, []);
    return (_jsx(Card, { title: "\u6A21\u578B\u7BA1\u7406", children: _jsx(Table, { rowKey: "id", dataSource: rows, columns: [
                { title: "标题", dataIndex: "title" },
                { title: "分类", dataIndex: "category" },
                { title: "价格", dataIndex: "price" },
                { title: "状态", dataIndex: "status" }
            ] }) }));
}
