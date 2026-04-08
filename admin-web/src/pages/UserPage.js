import { jsx as _jsx } from "react/jsx-runtime";
import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchUsers } from "../api/client";
export default function UserPage() {
    const [rows, setRows] = useState([]);
    useEffect(() => {
        fetchUsers().then(setRows);
    }, []);
    return (_jsx(Card, { title: "\u7528\u6237\u7BA1\u7406", children: _jsx(Table, { rowKey: "id", dataSource: rows, columns: [
                { title: "手机号", dataIndex: "phone" },
                { title: "昵称", dataIndex: "nickname" },
                { title: "角色", dataIndex: "role" },
                { title: "状态", dataIndex: "status" }
            ] }) }));
}
