import { jsx as _jsx, jsxs as _jsxs, Fragment as _Fragment } from "react/jsx-runtime";
import { Button, Card, Form, Input, InputNumber, Space, Switch, Table, message } from "antd";
import { useEffect, useState } from "react";
import { fetchSplashAds, publishConfigs, saveSplashAds } from "../api/client";
export default function AdPage() {
    const [form] = Form.useForm();
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const load = async () => {
        setLoading(true);
        try {
            const data = await fetchSplashAds();
            form.setFieldsValue(data);
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
    const handleSave = async () => {
        try {
            const values = await form.validateFields();
            setSaving(true);
            await saveSplashAds(values);
            message.success("广告配置已保存");
        }
        catch (e) {
            if (e instanceof Error)
                message.error(e.message);
        }
        finally {
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
        }
        catch (e) {
            message.error(e instanceof Error ? e.message : "发布失败");
        }
        finally {
            setSaving(false);
        }
    };
    const items = Form.useWatch("items", form) ?? [];
    return (_jsxs(Card, { title: "\u542F\u52A8\u5E7F\u544A\u7BA1\u7406", loading: loading, extra: _jsxs(Space, { children: [_jsx(Button, { onClick: load, children: "\u5237\u65B0" }), _jsx(Button, { onClick: handleSave, loading: saving, children: "\u4FDD\u5B58" }), _jsx(Button, { type: "primary", onClick: handlePublish, loading: saving, children: "\u4FDD\u5B58\u5E76\u53D1\u5E03\u5230 App" })] }), children: [_jsxs(Form, { form: form, layout: "vertical", initialValues: { enabled: true, skipAfterSec: 2, durationSec: 5, items: [] }, children: [_jsxs(Space, { size: "large", wrap: true, children: [_jsx(Form.Item, { label: "\u542F\u7528\u5E7F\u544A\u9875", name: "enabled", valuePropName: "checked", children: _jsx(Switch, {}) }), _jsx(Form.Item, { label: "\u53EF\u8DF3\u8FC7\u5012\u8BA1\u65F6\uFF08\u79D2\uFF09", name: "skipAfterSec", children: _jsx(InputNumber, { min: 0, max: 30 }) }), _jsx(Form.Item, { label: "\u6BCF\u5C4F\u5C55\u793A\u65F6\u957F\uFF08\u79D2\uFF09", name: "durationSec", children: _jsx(InputNumber, { min: 1, max: 60 }) })] }), _jsx(Form.List, { name: "items", children: (fields, { add, remove }) => (_jsxs(_Fragment, { children: [fields.map(({ key, name, ...rest }) => (_jsxs(Card, { size: "small", style: { marginBottom: 12 }, title: `广告 ${name + 1}`, extra: _jsx(Button, { type: "link", danger: true, onClick: () => remove(name), children: "\u5220\u9664" }), children: [_jsx(Form.Item, { ...rest, name: [name, "id"], label: "ID", rules: [{ required: true }], children: _jsx(Input, { placeholder: "ad-001" }) }), _jsx(Form.Item, { ...rest, name: [name, "title"], label: "\u6807\u9898", rules: [{ required: true }], children: _jsx(Input, { placeholder: "\u5E7F\u544A\u6807\u9898" }) }), _jsx(Form.Item, { ...rest, name: [name, "imageUrl"], label: "\u56FE\u7247 URL", rules: [{ required: true }], children: _jsx(Input, { placeholder: "https://..." }) }), _jsx(Form.Item, { ...rest, name: [name, "linkUrl"], label: "\u8DF3\u8F6C\u94FE\u63A5", rules: [{ required: true }], children: _jsx(Input, { placeholder: "https://\u5E7F\u544A\u4E3B\u843D\u5730\u9875" }) }), _jsx(Form.Item, { ...rest, name: [name, "network"], label: "\u5E7F\u544A\u6765\u6E90", initialValue: "custom", children: _jsx(Input, { placeholder: "custom / admob / gdt \u7B49" }) })] }, key))), _jsx(Button, { type: "dashed", block: true, onClick: () => add({
                                        id: `ad-${Date.now()}`,
                                        title: "",
                                        imageUrl: "",
                                        linkUrl: "",
                                        network: "custom"
                                    }), children: "\u6DFB\u52A0\u5E7F\u544A" })] })) })] }), _jsx(Table, { style: { marginTop: 24 }, rowKey: "id", pagination: false, dataSource: items, columns: [
                    { title: "ID", dataIndex: "id" },
                    { title: "标题", dataIndex: "title" },
                    { title: "来源", dataIndex: "network" },
                    { title: "图片", dataIndex: "imageUrl", ellipsis: true },
                    { title: "链接", dataIndex: "linkUrl", ellipsis: true }
                ], locale: { emptyText: "暂无广告，请点击上方添加" } }), _jsxs("p", { style: { marginTop: 16, color: "#888" }, children: ["\u5F53\u524D\u5171 ", items.length, " \u6761\u5E7F\u544A\u3002\u4FDD\u5B58\u5E76\u53D1\u5E03\u540E\uFF0CApp \u542F\u52A8\u65F6\u5C06\u6309\u987A\u5E8F\u5C55\u793A\uFF08\u767B\u5F55\u9875\u4E4B\u524D\uFF09\u3002"] })] }));
}
