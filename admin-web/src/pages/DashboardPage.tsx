import { Card, Col, Row, Statistic } from "antd";
import { useEffect, useState } from "react";
import { fetchDashboard } from "../api/client";

export default function DashboardPage() {
  const [data, setData] = useState({ total_users: 0, total_models: 0, total_orders: 0, revenue: 0 });
  useEffect(() => {
    fetchDashboard().then(setData);
  }, []);
  return (
    <Row gutter={16}>
      <Col span={6}><Card><Statistic title="总用户" value={data.total_users} /></Card></Col>
      <Col span={6}><Card><Statistic title="总模型" value={data.total_models} /></Card></Col>
      <Col span={6}><Card><Statistic title="总订单" value={data.total_orders} /></Card></Col>
      <Col span={6}><Card><Statistic title="营收" value={data.revenue} prefix="¥" /></Card></Col>
    </Row>
  );
}
