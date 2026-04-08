import { jsx as _jsx } from "react/jsx-runtime";
import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchPosts } from "../api/client";
export default function PostPage() {
    const [rows, setRows] = useState([]);
    useEffect(() => {
        fetchPosts().then(setRows);
    }, []);
    return (_jsx(Card, { title: "\u793E\u533A\u7BA1\u7406", children: _jsx(Table, { rowKey: "id", dataSource: rows, columns: [
                { title: "用户ID", dataIndex: "userId" },
                { title: "内容", dataIndex: "content", ellipsis: true },
                { title: "状态", dataIndex: "status" },
                { title: "发布时间", dataIndex: "createdAt" }
            ] }) }));
}
