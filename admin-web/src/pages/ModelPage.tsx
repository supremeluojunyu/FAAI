import { Card, Table } from "antd";
import { useEffect, useState } from "react";
import { fetchModels } from "../api/client";

export default function ModelPage() {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => {
    fetchModels().then(setRows);
  }, []);
  return (
    <Card title="模型管理">
      <Table
        rowKey="id"
        dataSource={rows}
        columns={[
          { title: "标题", dataIndex: "title" },
          { title: "分类", dataIndex: "category" },
          { title: "价格", dataIndex: "price" },
          { title: "状态", dataIndex: "status" }
        ]}
      />
    </Card>
  );
}
