import 'package:flutter/material.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('社区')),
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: const Padding(
            padding: EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('设计师A · 2小时前'),
              SizedBox(height: 8),
              Text('这是一个社区动态内容示例，最多显示 5 行，超出可折叠。'),
              SizedBox(height: 8),
              Row(children: [Icon(Icons.favorite_border), SizedBox(width: 12), Icon(Icons.comment_outlined), SizedBox(width: 12), Icon(Icons.share_outlined)])
            ]),
          ),
        ),
      ),
    );
  }
}
