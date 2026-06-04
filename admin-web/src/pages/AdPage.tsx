import {
  Button,
  Card,
  Form,
  Input,
  InputNumber,
  Space,
  Switch,
  Table,
  message
} from "antd";
import { useEffect, useState } from "react";
import { fetchSplashAds, publishConfigs, saveSplashAds } from "../api/client";

type AdItem = {
  id: string;
  title: string;
  imageUrl: string;
  linkUrl: string;
  network: string;
};

type SplashAds = {
  enabled: boolean;
  skipAfterSec: number;
  durationSec: number;
  items: AdItem[];
};

export default function AdPage() {
  const [form] = Form.useForm<SplashAds>();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      const data = await fetchSplashAds();
      form.setFieldsValue(data);
    } catch (e) {
      message.error(e instanceof Error ? e.message : "加载失败");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      await saveSplashAds(values);
      message.success("广告配置已保存");
    } catch (e) {
      if (e instanceof Error) message.error(e.message);
    } finally {
      setSaving(false);
    }
  };

  const handlePublish = async () => {
    try {
      setSaving(true);
      const values = await form.validateFields();
      await saveSplashAds(values);
      await publishConfigs();
      message.success("已发布到 App 配置（app-config.json）");
    } catch (e) {
      message.error(e instanceof Error ? e.message : "发布失败");
    } finally {
      setSaving(false);
    }
  };

  const items = Form.useWatch("items", form) ?? [];

  return (
    <Card
      title="启动广告管理"
      loading={loading}
      extra={
        <Space>
          <Button onClick={load}>刷新</Button>
          <Button onClick={handleSave} loading={saving}>
            保存
          </Button>
          <Button type="primary" onClick={handlePublish} loading={saving}>
            保存并发布到 App
          </Button>
        </Space>
      }
    >
      <Form form={form} layout="vertical" initialValues={{ enabled: true, skipAfterSec: 2, durationSec: 5, items: [] }}>
        <Space size="large" wrap>
          <Form.Item label="启用广告页" name="enabled" valuePropName="checked">
            <Switch />
          </Form.Item>
          <Form.Item label="可跳过倒计时（秒）" name="skipAfterSec">
            <InputNumber min={0} max={30} />
          </Form.Item>
          <Form.Item label="每屏展示时长（秒）" name="durationSec">
            <InputNumber min={1} max={60} />
          </Form.Item>
        </Space>

        <Form.List name="items">
          {(fields, { add, remove }) => (
            <>
              {fields.map(({ key, name, ...rest }) => (
                <Card
                  key={key}
                  size="small"
                  style={{ marginBottom: 12 }}
                  title={`广告 ${name + 1}`}
                  extra={<Button type="link" danger onClick={() => remove(name)}>删除</Button>}
                >
                  <Form.Item {...rest} name={[name, "id"]} label="ID" rules={[{ required: true }]}>
                    <Input placeholder="ad-001" />
                  </Form.Item>
                  <Form.Item {...rest} name={[name, "title"]} label="标题" rules={[{ required: true }]}>
                    <Input placeholder="广告标题" />
                  </Form.Item>
                  <Form.Item {...rest} name={[name, "imageUrl"]} label="图片 URL" rules={[{ required: true }]}>
                    <Input placeholder="https://..." />
                  </Form.Item>
                  <Form.Item {...rest} name={[name, "linkUrl"]} label="跳转链接" rules={[{ required: true }]}>
                    <Input placeholder="https://广告主落地页" />
                  </Form.Item>
                  <Form.Item {...rest} name={[name, "network"]} label="广告来源" initialValue="custom">
                    <Input placeholder="custom / admob / gdt 等" />
                  </Form.Item>
                </Card>
              ))}
              <Button type="dashed" block onClick={() =>
                  add({
                    id: `ad-${Date.now()}`,
                    title: "",
                    imageUrl: "",
                    linkUrl: "",
                    network: "custom"
                  })
                }
              >
                添加广告
              </Button>
            </>
          )}
        </Form.List>
      </Form>

      <Table
        style={{ marginTop: 24 }}
        rowKey="id"
        pagination={false}
        dataSource={items}
        columns={[
          { title: "ID", dataIndex: "id" },
          { title: "标题", dataIndex: "title" },
          { title: "来源", dataIndex: "network" },
          { title: "图片", dataIndex: "imageUrl", ellipsis: true },
          { title: "链接", dataIndex: "linkUrl", ellipsis: true }
        ]}
        locale={{ emptyText: "暂无广告，请点击上方添加" }}
      />
      <p style={{ marginTop: 16, color: "#888" }}>
        当前共 {items.length} 条广告。保存并发布后，App 启动时将按顺序展示（登录页之前）。
      </p>
    </Card>
  );
}
