import 'package:flutter/material.dart';

class WorkbenchPage extends StatelessWidget {
  const WorkbenchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的模型库'),
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.upload))],
          bottom: const TabBar(tabs: [Tab(text: '全部'), Tab(text: '已上架'), Tab(text: '草稿')]),
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
        body: GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: 12,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemBuilder: (_, __) => Card(
            child: Column(children: [
              Expanded(child: Container(color: const Color(0xFF334155))),
              const Padding(
                padding: EdgeInsets.all(8),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('草稿'), Text('¥19.9')]),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
