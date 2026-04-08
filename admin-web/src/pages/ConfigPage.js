import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Button, Card, Table, message } from "antd";
import { useEffect, useState } from "react";
import { fetchConfigs, publishConfigs } from "../api/client";
export default function ConfigPage() {
    const [rows, setRows] = useState([]);
    const [loading, setLoading] = useState(false);
    const load = async () => {
        setLoading(true);
        try {
            setRows(await fetchConfigs());
        }
        finally {
            setLoading(false);
        }
    };
    useEffect(() => {
        load();
    }, []);
    return (_jsxs(Card, { title: "\u7CFB\u7EDF\u914D\u7F6E", children: [_jsx(Button, { type: "primary", onClick: async () => {
                    await publishConfigs();
                    message.success("配置已发布");
                }, children: "\u53D1\u5E03\u5230 CDN" }), _jsx(Table, { rowKey: "id", loading: loading, dataSource: rows, columns: [
                    { title: "Key", dataIndex: "key" },
                    { title: "Value", dataIndex: "value", render: (v) => JSON.stringify(v) },
                    { title: "描述", dataIndex: "description" }
                ] })] }));
}
