import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('客服帮助')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('常见问题', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _faq('如何一键登录？', '授权电话权限后，App 将通过运营商/SIM 自动识别本机号码，无需手动输入。'),
          _faq('游客浏览和登录有什么区别？', '游客可浏览商城与社区；登录后可收藏、购买、使用工作台等完整功能。'),
          _faq('模型无法加载图片？', '请检查网络，或在设置中重置服务器地址后重试。'),
          const SizedBox(height: 24),
          const Text('联系我们', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('邮箱'),
            subtitle: const Text('support@moyu.example.com'),
            onTap: () => launchUrl(Uri.parse('mailto:support@moyu.example.com')),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('服务时间'),
            subtitle: const Text('工作日 9:00 - 18:00'),
          ),
        ],
      ),
    );
  }

  Widget _faq(String q, String a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600)), children: [Padding(padding: const EdgeInsets.all(16), child: Text(a))]),
    );
  }
}
