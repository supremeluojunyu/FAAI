import 'package:flutter/material.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = ['我的收藏', '浏览足迹', '草稿箱', '钱包', '设置', '客服帮助'];
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('未命名用户'),
              subtitle: Text('这个人很懒，什么都没写'),
              trailing: Icon(Icons.edit),
            ),
          ),
          const SizedBox(height: 8),
          ...items.map((e) => Card(child: ListTile(title: Text(e), trailing: const Icon(Icons.chevron_right)))),
        ],
      ),
    );
  }
}
