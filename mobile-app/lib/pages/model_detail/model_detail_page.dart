import 'package:flutter/material.dart';

class ModelDetailPage extends StatelessWidget {
  const ModelDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模型详情')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            style: FilledButton.styleFrom(shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () {},
            child: const Text('立即购买'),
          ),
        ),
      ),
      body: ListView(
        children: [
          Container(height: 300, color: const Color(0xFF334155)),
          Card(
            margin: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('机甲高达模型', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('¥29.9', style: TextStyle(color: Color(0xFFF97316), fontSize: 18, fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text('格式 OBJ | 大小 15.2MB | 三角面 245k'),
              ]),
            ),
          )
        ],
      ),
    );
  }
}
