import { jsx as _jsx, Fragment as _Fragment, jsxs as _jsxs } from "react/jsx-runtime";
import { Button, Card, Form, Input, InputNumber, Space, Switch, Table, Tabs, message } from "antd";
import { useEffect, useState } from "react";
import { fetchAppVersionPolicy, fetchCustomerService, fetchRechargePackages, fetchWalletConfig, publishConfigs, saveAppVersionPolicy, saveCustomerService, saveRechargePackages, saveWalletConfig } from "../api/client";
export default function OpsConfigPage() {
    const [rechargeForm] = Form.useForm();
    const [walletForm] = Form.useForm();
    const [serviceForm] = Form.useForm();
    const [versionForm] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const load = async () => {
        setLoading(true);
        try {
            rechargeForm.setFieldsValue(await fetchRechargePackages());
            walletForm.setFieldsValue(await fetchWalletConfig());
            serviceForm.setFieldsValue(await fetchCustomerService());
            versionForm.setFieldsValue(await fetchAppVersionPolicy());
        }
        catch (e) {
            message.error(e instanceof Error ? e.message : "加载失败");
        }
        finally {
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
        }
        catch (e) {
            message.error(e instanceof Error ? e.message : "保存失败");
        }
        finally {
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
        }
        catch (e) {
            message.error(e instanceof Error ? e.message : "发布失败");
        }
        finally {
            setSaving(false);
        }
    };
    const packages = Form.useWatch("packages", rechargeForm) ?? [];
    return (_jsx(Card, { title: "\u8FD0\u8425\u914D\u7F6E\uFF08\u5145\u503C / \u94B1\u5305 / \u5BA2\u670D\uFF09", loading: loading, extra: _jsxs(Space, { children: [_jsx(Button, { onClick: load, children: "\u5237\u65B0" }), _jsx(Button, { loading: saving, onClick: saveAll, children: "\u4FDD\u5B58" }), _jsx(Button, { type: "primary", loading: saving, onClick: publish, children: "\u4FDD\u5B58\u5E76\u53D1\u5E03" })] }), children: _jsx(Tabs, { items: [
                {
                    key: "recharge",
                    label: "充值档位",
                    children: (_jsxs(Form, { form: rechargeForm, layout: "vertical", children: [_jsx(Form.Item, { name: "enabled", label: "\u542F\u7528\u5145\u503C", valuePropName: "checked", children: _jsx(Switch, {}) }), _jsx(Form.Item, { name: "notice", label: "\u5145\u503C\u8BF4\u660E", children: _jsx(Input.TextArea, { rows: 2 }) }), _jsx(Form.List, { name: "packages", children: (fields, { add, remove }) => (_jsxs(_Fragment, { children: [_jsx(Table, { size: "small", pagination: false, rowKey: "key", dataSource: fields.map((f) => ({ key: f.key, name: f.name })), columns: [
                                                {
                                                    title: "档位 ID",
                                                    render: (_, row) => (_jsx(Form.Item, { name: [row.name, "id"], rules: [{ required: true }], style: { margin: 0 }, children: _jsx(Input, { placeholder: "p30" }) }))
                                                },
                                                {
                                                    title: "展示名",
                                                    render: (_, row) => (_jsx(Form.Item, { name: [row.name, "label"], rules: [{ required: true }], style: { margin: 0 }, children: _jsx(Input, {}) }))
                                                },
                                                {
                                                    title: "金额(元)",
                                                    render: (_, row) => (_jsx(Form.Item, { name: [row.name, "amount"], rules: [{ required: true }], style: { margin: 0 }, children: _jsx(InputNumber, { min: 1, style: { width: "100%" } }) }))
                                                },
                                                {
                                                    title: "赠送(元)",
                                                    render: (_, row) => (_jsx(Form.Item, { name: [row.name, "bonus"], style: { margin: 0 }, children: _jsx(InputNumber, { min: 0, style: { width: "100%" } }) }))
                                                },
                                                {
                                                    title: "",
                                                    render: (_, row) => (_jsx(Button, { type: "link", danger: true, onClick: () => remove(row.name), children: "\u5220\u9664" }))
                                                }
                                            ] }), _jsx(Button, { type: "dashed", onClick: () => add({ id: `p${packages.length + 1}`, amount: 10, bonus: 0, label: "10元" }), style: { marginTop: 8 }, children: "\u6DFB\u52A0\u6863\u4F4D" })] })) })] }))
                },
                {
                    key: "wallet",
                    label: "钱包",
                    children: (_jsxs(Form, { form: walletForm, layout: "vertical", children: [_jsx(Form.Item, { name: "rechargeEnabled", label: "\u663E\u793A\u5145\u503C\u5165\u53E3", valuePropName: "checked", children: _jsx(Switch, {}) }), _jsx(Form.Item, { name: "withdrawEnabled", label: "\u663E\u793A\u63D0\u73B0\u5165\u53E3", valuePropName: "checked", children: _jsx(Switch, {}) }), _jsx(Form.Item, { name: "withdrawMin", label: "\u6700\u4F4E\u63D0\u73B0(\u5143)", children: _jsx(InputNumber, { min: 1, style: { width: 200 } }) }), _jsx(Form.Item, { name: "balanceTip", label: "\u4F59\u989D\u8BF4\u660E", children: _jsx(Input.TextArea, { rows: 2 }) }), _jsx(Form.Item, { name: "withdrawTip", label: "\u63D0\u73B0\u8BF4\u660E", children: _jsx(Input.TextArea, { rows: 2 }) })] }))
                },
                {
                    key: "version",
                    label: "版本控制",
                    children: (_jsxs(Form, { form: versionForm, layout: "vertical", children: [_jsx(Form.Item, { name: "enabled", label: "\u542F\u7528\u7248\u672C\u6821\u9A8C", valuePropName: "checked", children: _jsx(Switch, {}) }), _jsx(Form.Item, { name: "forceUpdate", label: "\u8FC7\u4F4E\u65F6\u5F3A\u5236\u66F4\u65B0\uFF08\u4E0D\u53EF\u8DF3\u8FC7\uFF09", valuePropName: "checked", children: _jsx(Switch, {}) }), _jsx(Form.Item, { name: "minVersion", label: "\u6700\u4F4E\u53EF\u7528\u7248\u672C\u53F7", rules: [{ required: true }], extra: "\u4F4E\u4E8E\u6B64\u7248\u672C\u7684 App \u5C06\u65E0\u6CD5\u767B\u5F55\u548C\u4F7F\u7528\uFF0C\u4F8B\u5982 0.0.7", children: _jsx(Input, { placeholder: "0.0.7" }) }), _jsx(Form.Item, { name: "minBuildNumber", label: "\u6700\u4F4E\u6784\u5EFA\u53F7\uFF08\u53EF\u9009\uFF0C\u4E0E pubspec +8 \u5BF9\u5E94\uFF09", children: _jsx(InputNumber, { min: 0, style: { width: 200 } }) }), _jsx(Form.Item, { name: "latestVersion", label: "\u6700\u65B0\u7248\u672C\u53F7\uFF08\u5C55\u793A\u7528\uFF09", children: _jsx(Input, { placeholder: "0.0.8" }) }), _jsx(Form.Item, { name: "latestBuildNumber", label: "\u6700\u65B0\u6784\u5EFA\u53F7", children: _jsx(InputNumber, { min: 0, style: { width: 200 } }) }), _jsx(Form.Item, { name: "blockedVersions", label: "\u7981\u6B62\u4F7F\u7528\u7684\u7248\u672C\uFF08\u6BCF\u884C\u4E00\u4E2A\uFF09", getValueFromEvent: (e) => (e?.target?.value ?? "")
                                    .split("\n")
                                    .map((s) => s.trim())
                                    .filter(Boolean), getValueProps: (v) => ({
                                    value: Array.isArray(v) ? v.join("\n") : v ?? ""
                                }), children: _jsx(Input.TextArea, { rows: 3, placeholder: "0.0.5\n0.0.6" }) }), _jsx(Form.Item, { name: "title", label: "\u5F39\u7A97\u6807\u9898", children: _jsx(Input, {}) }), _jsx(Form.Item, { name: "message", label: "\u5F39\u7A97\u8BF4\u660E", children: _jsx(Input.TextArea, { rows: 2 }) }), _jsx(Form.Item, { name: "downloadPageUrl", label: "\u4E0B\u8F7D\u9875\u5730\u5740\uFF08\u7559\u7A7A\u5219\u7528\u5DF2\u53D1\u5E03 APK \u4E0B\u8F7D\u9875\uFF09", extra: "\u4F8B\u5982 http://124.220.4.69:8081/download/", children: _jsx(Input, {}) }), _jsx(Form.Item, { name: "downloadApkUrl", label: "APK \u76F4\u94FE\uFF08\u7559\u7A7A\u5219\u7528\u540C\u6B65\u7684 app-release.apk\uFF09", children: _jsx(Input, {}) })] }))
                },
                {
                    key: "service",
                    label: "客服",
                    children: (_jsxs(Form, { form: serviceForm, layout: "vertical", children: [_jsx(Form.Item, { name: "phone", label: "\u5BA2\u670D\u7535\u8BDD", children: _jsx(Input, {}) }), _jsx(Form.Item, { name: "wechat", label: "\u5BA2\u670D\u5FAE\u4FE1", children: _jsx(Input, {}) }), _jsx(Form.Item, { name: "workHours", label: "\u670D\u52A1\u65F6\u95F4", children: _jsx(Input, {}) }), _jsx(Form.Item, { name: "helpUrl", label: "\u5E2E\u52A9\u94FE\u63A5\uFF08\u53EF\u9009\uFF09", children: _jsx(Input, { placeholder: "https://..." }) })] }))
                }
            ] }) }));
}
