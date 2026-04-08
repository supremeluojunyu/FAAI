import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchPosts } from "../api/client";

export default function PostPage() {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => {
    fetchPosts().then(setRows);
  }, []);
  return (
    <Card title="社区管理">
      <Table
        rowKey="id"
        dataSource={rows}
        columns={[
          { title: "用户ID", dataIndex: "userId" },
          { title: "内容", dataIndex: "content", ellipsis: true },
          { title: "状态", dataIndex: "status" },
          { title: "发布时间", dataIndex: "createdAt" }
        ]}
      />
    </Card>
  );
}
