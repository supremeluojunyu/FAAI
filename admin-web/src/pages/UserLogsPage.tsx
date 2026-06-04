import { Alert, Button, Card, Input, Select, Space, Table, Tag, message } from "antd";
import { useEffect, useState } from "react";
import { fetchActivityLogs } from "../api/client";

const ACTION_LABELS: Record<string, string> = {
  LOGIN_SMS: "短信登录",
  LOGIN_CARRIER: "运营商登录",
  LOGIN_GUEST: "游客进入",
  LOGIN_WECHAT: "微信登录",
  SEND_SMS_CODE: "发送验证码",
  APP_LOGIN_SUCCESS: "App登录成功",
  OPEN_TAB: "切换底部Tab",
  OPEN_PAGE: "打开页面",
  BROWSE_MODELS: "浏览商城",
  SEARCH_MODELS: "搜索模型",
  VIEW_MODEL: "查看模型",
  TOGGLE_FAVORITE: "收藏操作",
  TOGGLE_LIKE_MODEL: "模型点赞",
  SHARE_MODEL: "分享模型",
  BROWSE_POSTS: "浏览社区",
  VIEW_POST: "查看动态",
  TOGGLE_LIKE_POST: "动态点赞",
  SHARE_POST: "分享动态",
  VIEW_FAVORITES: "我的收藏",
  VIEW_PROFILE: "个人资料",
  UPDATE_PROFILE: "更新资料",
  VIEW_WALLET: "查看钱包",
  WALLET_RECHARGE: "发起充值",
  WALLET_WITHDRAW: "申请提现",
  VIEW_ORDERS: "查看订单",
  ORDER_BUY: "购买模型",
  WORKBENCH: "工作台",
  DEMAND: "需求/接单",
  DESIGNER: "设计师",
  ADMIN_API: "管理端操作",
  API_CALL: "其他API",
  APP_EVENT: "App事件"
};

function actionLabel(action: string) {
  return ACTION_LABELS[action] ?? action;
}

function summaryOf(detail: unknown) {
  if (!detail || typeof detail !== "object") return "-";
  const d = detail as Record<string, unknown>;
  if (typeof d.summary === "string") return d.summary;
  if (typeof d.page === "string") return `页面: ${d.page}`;
  if (typeof d.tab === "string") return `Tab: ${d.tab}`;
  return JSON.stringify(d).slice(0, 120);
}

export default function UserLogsPage() {
  const [rows, setRows] = useState<any[]>([]);
  const [stats, setStats] = useState<{ action: string; count: number }[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [action, setAction] = useState<string | undefined>();
  const [phone, setPhone] = useState("");

  const load = async (p = page) => {
    setLoading(true);
    try {
      const data = await fetchActivityLogs({
        page: String(p),
        size: "50",
        ...(action ? { action } : {}),
        ...(phone ? { phone } : {})
      });
      setRows(data.list);
      setTotal(data.total);
      setStats(data.action_stats ?? []);
      setPage(data.page ?? p);
    } catch (e) {
      message.error(e instanceof Error ? e.message : "加载失败");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load(1);
  }, []);

  return (
    <Space direction="vertical" size="large" style={{ width: "100%" }}>
      <Alert
        type="info"
        showIcon
        message="自动记录说明"
        description="用户登录后，App 每次请求接口、切换 Tab、打开页面都会自动写入日志。请用 App 登录并操作后刷新本页；仅管理端登录不会产生 App 行为记录。"
      />

      <Card title="行为统计（全库）" size="small">
        <Space wrap>
          {stats.length === 0 ? <span style={{ color: "#999" }}>暂无统计</span> : null}
          {stats.map((s) => (
            <Tag key={s.action} style={{ cursor: "pointer" }} onClick={() => { setAction(s.action); load(1); }}>
              {actionLabel(s.action)}：{s.count}
            </Tag>
          ))}
        </Space>
      </Card>

      <Card
        title={`用户操作日志（共 ${total} 条）`}
        extra={
          <Space>
            <Select
              allowClear
              placeholder="行为类型"
              style={{ width: 180 }}
              value={action}
              onChange={setAction}
              options={Object.entries(ACTION_LABELS).map(([value, label]) => ({ value, label }))}
            />
            <Input placeholder="手机号" value={phone} onChange={(e) => setPhone(e.target.value)} style={{ width: 140 }} />
            <Button type="primary" onClick={() => load(1)}>
              查询
            </Button>
            <Button
              onClick={() => {
                setAction(undefined);
                setPhone("");
                load(1);
              }}
            >
              重置
            </Button>
            <Button onClick={() => load(page)}>刷新</Button>
          </Space>
        }
      >
        <Table
          rowKey="id"
          loading={loading}
          locale={{ emptyText: "暂无日志。请用 App 账号登录并浏览商城/社区后点击「刷新」。" }}
          dataSource={rows}
          pagination={{
            current: page,
            total,
            pageSize: 50,
            showTotal: (t) => `共 ${t} 条`,
            onChange: (p) => load(p)
          }}
          scroll={{ x: 1200 }}
          columns={[
            {
              title: "时间",
              dataIndex: "createdAt",
              width: 168,
              render: (v: string) => new Date(v).toLocaleString("zh-CN", { hour12: false, timeZone: "Asia/Shanghai" })
            },
            {
              title: "账户",
              width: 200,
              render: (_: unknown, r: any) =>
                r.user ? (
                  <div>
                    <div>{r.user.nickname ?? "用户"}</div>
                    <div style={{ fontSize: 12, color: "#666" }}>
                      {r.user.phone} · {r.user.role}
                    </div>
                  </div>
                ) : (
                  <Tag>未登录/游客</Tag>
                )
            },
            {
              title: "操作",
              dataIndex: "action",
              width: 130,
              render: (v: string) => <Tag color="processing">{actionLabel(v)}</Tag>
            },
            {
              title: "说明",
              dataIndex: "detail",
              width: 200,
              ellipsis: true,
              render: (v: unknown) => summaryOf(v)
            },
            {
              title: "对象",
              width: 180,
              render: (_: unknown, r: any) =>
                r.targetType ? `${r.targetType}: ${r.targetId ?? "-"}` : "-"
            },
            {
              title: "状态",
              width: 70,
              render: (_: unknown, r: any) => {
                const s = r?.detail?.status;
                if (s == null) return "-";
                return <Tag color={s < 400 ? "success" : "error"}>{String(s)}</Tag>;
              }
            },
            { title: "IP", dataIndex: "ip", width: 120 }
          ]}
        />
      </Card>
    </Space>
  );
}
