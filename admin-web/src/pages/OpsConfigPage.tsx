import { Button, Card, Form, Input, InputNumber, Space, Switch, Table, Tabs, message } from "antd";
import { useEffect, useState } from "react";
import {
  fetchAppVersionPolicy,
  fetchCustomerService,
  fetchRechargePackages,
  fetchWalletConfig,
  publishConfigs,
  saveAppVersionPolicy,
  saveCustomerService,
  saveRechargePackages,
  saveWalletConfig
} from "../api/client";

type RechargePkg = { id: string; amount: number; bonus: number; label: string };
type RechargeConfig = {
  enabled: boolean;
  notice: string;
  packages: RechargePkg[];
};

export default function OpsConfigPage() {
  const [rechargeForm] = Form.useForm<RechargeConfig>();
  const [walletForm] = Form.useForm<Record<string, unknown>>();
  const [serviceForm] = Form.useForm<Record<string, unknown>>();
  const [versionForm] = Form.useForm<Record<string, unknown>>();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  const load = async () => {
    setLoading(true);
    try {
      rechargeForm.setFieldsValue(await fetchRechargePackages());
      walletForm.setFieldsValue(await fetchWalletConfig());
      serviceForm.setFieldsValue(await fetchCustomerService());
      versionForm.setFieldsValue(await fetchAppVersionPolicy());
    } catch (e) {
      message.error(e instanceof Error ? e.message : "加载失败");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const saveAll = async () => {
    const recharge = await rechargeForm.validateFields();
    const wallet = await walletForm.validateFields();
    const service = await serviceForm.validateFields();
    const version = await versionForm.validateFields();
    setSaving(true);
    try {
      await saveRechargePackages(recharge);
      await saveWalletConfig(wallet);
      await saveCustomerService(service);
      await saveAppVersionPolicy(version);
      message.success("运营配置已保存");
    } catch (e) {
      message.error(e instanceof Error ? e.message : "保存失败");
    } finally {
      setSaving(false);
    }
  };

  const publish = async () => {
    setSaving(true);
    try {
      const recharge = await rechargeForm.validateFields();
      const wallet = await walletForm.validateFields();
      const service = await serviceForm.validateFields();
      const version = await versionForm.validateFields();
      await saveRechargePackages(recharge);
      await saveWalletConfig(wallet);
      await saveCustomerService(service);
      await saveAppVersionPolicy(version);
      await publishConfigs();
      message.success("已发布到 App（app-config.json）");
    } catch (e) {
      message.error(e instanceof Error ? e.message : "发布失败");
    } finally {
      setSaving(false);
    }
  };

  const packages = Form.useWatch("packages", rechargeForm) ?? [];

  return (
    <Card
      title="运营配置（充值 / 钱包 / 客服）"
      loading={loading}
      extra={
        <Space>
          <Button onClick={load}>刷新</Button>
          <Button loading={saving} onClick={saveAll}>
            保存
          </Button>
          <Button type="primary" loading={saving} onClick={publish}>
            保存并发布
          </Button>
        </Space>
      }
    >
      <Tabs
        items={[
          {
            key: "recharge",
            label: "充值档位",
            children: (
              <Form form={rechargeForm} layout="vertical">
                <Form.Item name="enabled" label="启用充值" valuePropName="checked">
                  <Switch />
                </Form.Item>
                <Form.Item name="notice" label="充值说明">
                  <Input.TextArea rows={2} />
                </Form.Item>
                <Form.List name="packages">
                  {(fields, { add, remove }) => (
                    <>
                      <Table
                        size="small"
                        pagination={false}
                        rowKey="key"
                        dataSource={fields.map((f) => ({ key: f.key, name: f.name }))}
                        columns={[
                          {
                            title: "档位 ID",
                            render: (_, row) => (
                              <Form.Item name={[row.name, "id"]} rules={[{ required: true }]} style={{ margin: 0 }}>
                                <Input placeholder="p30" />
                              </Form.Item>
                            )
                          },
                          {
                            title: "展示名",
                            render: (_, row) => (
                              <Form.Item name={[row.name, "label"]} rules={[{ required: true }]} style={{ margin: 0 }}>
                                <Input />
                              </Form.Item>
                            )
                          },
                          {
                            title: "金额(元)",
                            render: (_, row) => (
                              <Form.Item name={[row.name, "amount"]} rules={[{ required: true }]} style={{ margin: 0 }}>
                                <InputNumber min={1} style={{ width: "100%" }} />
                              </Form.Item>
                            )
                          },
                          {
                            title: "赠送(元)",
                            render: (_, row) => (
                              <Form.Item name={[row.name, "bonus"]} style={{ margin: 0 }}>
                                <InputNumber min={0} style={{ width: "100%" }} />
                              </Form.Item>
                            )
                          },
                          {
                            title: "",
                            render: (_, row) => (
                              <Button type="link" danger onClick={() => remove(row.name)}>
                                删除
                              </Button>
                            )
                          }
                        ]}
                      />
                      <Button type="dashed" onClick={() => add({ id: `p${packages.length + 1}`, amount: 10, bonus: 0, label: "10元" })} style={{ marginTop: 8 }}>
                        添加档位
                      </Button>
                    </>
                  )}
                </Form.List>
              </Form>
            )
          },
          {
            key: "wallet",
            label: "钱包",
            children: (
              <Form form={walletForm} layout="vertical">
                <Form.Item name="rechargeEnabled" label="显示充值入口" valuePropName="checked">
                  <Switch />
                </Form.Item>
                <Form.Item name="withdrawEnabled" label="显示提现入口" valuePropName="checked">
                  <Switch />
                </Form.Item>
                <Form.Item name="withdrawMin" label="最低提现(元)">
                  <InputNumber min={1} style={{ width: 200 }} />
                </Form.Item>
                <Form.Item name="balanceTip" label="余额说明">
                  <Input.TextArea rows={2} />
                </Form.Item>
                <Form.Item name="withdrawTip" label="提现说明">
                  <Input.TextArea rows={2} />
                </Form.Item>
              </Form>
            )
          },
          {
            key: "version",
            label: "版本控制",
            children: (
              <Form form={versionForm} layout="vertical">
                <Form.Item name="enabled" label="启用版本校验" valuePropName="checked">
                  <Switch />
                </Form.Item>
                <Form.Item name="forceUpdate" label="过低时强制更新（不可跳过）" valuePropName="checked">
                  <Switch />
                </Form.Item>
                <Form.Item
                  name="minVersion"
                  label="最低可用版本号"
                  rules={[{ required: true }]}
                  extra="低于此版本的 App 将无法登录和使用，例如 0.0.7"
                >
                  <Input placeholder="0.0.7" />
                </Form.Item>
                <Form.Item name="minBuildNumber" label="最低构建号（可选，与 pubspec +8 对应）">
                  <InputNumber min={0} style={{ width: 200 }} />
                </Form.Item>
                <Form.Item name="latestVersion" label="最新版本号（展示用）">
                  <Input placeholder="0.0.8" />
                </Form.Item>
                <Form.Item name="latestBuildNumber" label="最新构建号">
                  <InputNumber min={0} style={{ width: 200 }} />
                </Form.Item>
                <Form.Item
                  name="blockedVersions"
                  label="禁止使用的版本（每行一个）"
                  getValueFromEvent={(e) =>
                    (e?.target?.value ?? "")
                      .split("\n")
                      .map((s: string) => s.trim())
                      .filter(Boolean)
                  }
                  getValueProps={(v) => ({
                    value: Array.isArray(v) ? v.join("\n") : v ?? ""
                  })}
                >
                  <Input.TextArea rows={3} placeholder={"0.0.5\n0.0.6"} />
                </Form.Item>
                <Form.Item name="title" label="弹窗标题">
                  <Input />
                </Form.Item>
                <Form.Item name="message" label="弹窗说明">
                  <Input.TextArea rows={2} />
                </Form.Item>
                <Form.Item
                  name="downloadPageUrl"
                  label="下载页地址（留空则用已发布 APK 下载页）"
                  extra="例如 http://124.220.4.69:8081/download/"
                >
                  <Input />
                </Form.Item>
                <Form.Item name="downloadApkUrl" label="APK 直链（留空则用同步的 app-release.apk）">
                  <Input />
                </Form.Item>
              </Form>
            )
          },
          {
            key: "service",
            label: "客服",
            children: (
              <Form form={serviceForm} layout="vertical">
                <Form.Item name="phone" label="客服电话">
                  <Input />
                </Form.Item>
                <Form.Item name="wechat" label="客服微信">
                  <Input />
                </Form.Item>
                <Form.Item name="workHours" label="服务时间">
                  <Input />
                </Form.Item>
                <Form.Item name="helpUrl" label="帮助链接（可选）">
                  <Input placeholder="https://..." />
                </Form.Item>
              </Form>
            )
          }
        ]}
      />
    </Card>
  );
}
