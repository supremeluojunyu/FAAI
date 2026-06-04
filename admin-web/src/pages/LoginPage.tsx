import { Button, Card, Form, Input, message } from "antd";
import { useState } from "react";
import { loginAdmin, sendLoginCode } from "../api/client";

type Props = {
  onSuccess: () => void;
};

export default function LoginPage({ onSuccess }: Props) {
  const [loading, setLoading] = useState(false);
  const [tip, setTip] = useState("");
  const [form] = Form.useForm();

  const handleSendCode = async () => {
    try {
      const phone = String(form.getFieldValue("phone") || "").trim();
      if (!/^1\d{10}$/.test(phone)) {
        message.warning("请输入11位有效手机号");
        return;
      }
      setLoading(true);
      const r = await sendLoginCode(phone);
      const debug = r.debug_code ? `（开发验证码：${r.debug_code}）` : "";
      setTip(`验证码已发送${debug}`);
    } catch (e) {
      message.error(e instanceof Error ? e.message : "发送失败");
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = async () => {
    try {
      const values = await form.validateFields();
      setLoading(true);
      await loginAdmin(values.phone.trim(), values.code.trim());
      message.success("登录成功");
      onSuccess();
    } catch (e) {
      message.error(e instanceof Error ? e.message : "登录失败");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: "100vh", display: "grid", placeItems: "center", background: "#f5f7fb" }}>
      <Card title="模宇宙(糖艺大模王) 管理后台" style={{ width: 420 }}>
        <Form form={form} layout="vertical" initialValues={{ phone: "13800000000" }}>
          <Form.Item label="管理员手机号" name="phone" rules={[{ required: true, message: "请输入手机号" }]}>
            <Input placeholder="13800000000" maxLength={11} />
          </Form.Item>
          <Form.Item label="验证码" name="code" rules={[{ required: true, message: "请输入验证码" }]}>
            <Input placeholder="开发环境默认 123456" maxLength={6} />
          </Form.Item>
          <div style={{ display: "flex", gap: 8 }}>
            <Button onClick={handleSendCode} loading={loading}>
              发送验证码
            </Button>
            <Button type="primary" onClick={handleLogin} loading={loading} block>
              登录
            </Button>
          </div>
          {tip ? <p style={{ marginTop: 12, color: "#666" }}>{tip}</p> : null}
          <p style={{ marginTop: 16, color: "#999", fontSize: 13 }}>
            仅 ADMIN 角色账号可登录。开发环境验证码固定为 <code>123456</code>。
          </p>
        </Form>
      </Card>
    </div>
  );
}
