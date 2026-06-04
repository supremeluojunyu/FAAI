import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import { Button, Card, Form, Input, message } from "antd";
import { useState } from "react";
import { loginAdmin, sendLoginCode } from "../api/client";
export default function LoginPage({ onSuccess }) {
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
        }
        catch (e) {
            message.error(e instanceof Error ? e.message : "发送失败");
        }
        finally {
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
        }
        catch (e) {
            message.error(e instanceof Error ? e.message : "登录失败");
        }
        finally {
            setLoading(false);
        }
    };
    return (_jsx("div", { style: { minHeight: "100vh", display: "grid", placeItems: "center", background: "#f5f7fb" }, children: _jsx(Card, { title: "\u6A21\u5B87\u5B99(\u7CD6\u827A\u5927\u6A21\u738B) \u7BA1\u7406\u540E\u53F0", style: { width: 420 }, children: _jsxs(Form, { form: form, layout: "vertical", initialValues: { phone: "13800000000" }, children: [_jsx(Form.Item, { label: "\u7BA1\u7406\u5458\u624B\u673A\u53F7", name: "phone", rules: [{ required: true, message: "请输入手机号" }], children: _jsx(Input, { placeholder: "13800000000", maxLength: 11 }) }), _jsx(Form.Item, { label: "\u9A8C\u8BC1\u7801", name: "code", rules: [{ required: true, message: "请输入验证码" }], children: _jsx(Input, { placeholder: "\u5F00\u53D1\u73AF\u5883\u9ED8\u8BA4 123456", maxLength: 6 }) }), _jsxs("div", { style: { display: "flex", gap: 8 }, children: [_jsx(Button, { onClick: handleSendCode, loading: loading, children: "\u53D1\u9001\u9A8C\u8BC1\u7801" }), _jsx(Button, { type: "primary", onClick: handleLogin, loading: loading, block: true, children: "\u767B\u5F55" })] }), tip ? _jsx("p", { style: { marginTop: 12, color: "#666" }, children: tip }) : null, _jsxs("p", { style: { marginTop: 16, color: "#999", fontSize: 13 }, children: ["\u4EC5 ADMIN \u89D2\u8272\u8D26\u53F7\u53EF\u767B\u5F55\u3002\u5F00\u53D1\u73AF\u5883\u9A8C\u8BC1\u7801\u56FA\u5B9A\u4E3A ", _jsx("code", { children: "123456" }), "\u3002"] })] }) }) }));
}
