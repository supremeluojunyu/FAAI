import { Button, Card, Table, message } from "antd";
import { useEffect, useState } from "react";
import { fetchConfigs, publishConfigs } from "../api/client";

export default function ConfigPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      setRows(await fetchConfigs());
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  return (
    <Card title="系统配置">
      <Button
        type="primary"
        onClick={async () => {
          await publishConfigs();
          message.success("配置已发布");
        }}
      >
        发布到 CDN
      </Button>
      <Table
        rowKey="id"
        loading={loading}
        dataSource={rows}
        columns={[
          { title: "Key", dataIndex: "key" },
          { title: "Value", dataIndex: "value", render: (v) => JSON.stringify(v) },
          { title: "描述", dataIndex: "description" }
        ]}
      />
    </Card>
  );
}
