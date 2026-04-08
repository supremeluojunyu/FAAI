import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchDemands } from "../api/client";

export default function DemandPage() {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => {
    fetchDemands().then(setRows);
  }, []);
  return (
    <Card title="需求管理">
      <Table
        rowKey="id"
        dataSource={rows}
        columns={[
          { title: "标题", dataIndex: "title" },
          { title: "类型", dataIndex: "type" },
          { title: "预算", dataIndex: "budget" },
          { title: "状态", dataIndex: "status" }
        ]}
      />
    </Card>
  );
}
