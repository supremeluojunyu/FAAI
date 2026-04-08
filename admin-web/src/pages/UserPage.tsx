import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchUsers } from "../api/client";

export default function UserPage() {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => {
    fetchUsers().then(setRows);
  }, []);
  return (
    <Card title="用户管理">
      <Table
        rowKey="id"
        dataSource={rows}
        columns={[
          { title: "手机号", dataIndex: "phone" },
          { title: "昵称", dataIndex: "nickname" },
          { title: "角色", dataIndex: "role" },
          { title: "状态", dataIndex: "status" }
        ]}
      />
    </Card>
  );
}
