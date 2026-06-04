import 'package:flutter/material.dart';
import '../../services/user_hub_service.dart';
import '../model_detail/model_detail_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await UserHubService(widget.apiBaseUrl).loadBrowseHistory();
    if (!mounted) return;
    setState(() {
      _list = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览足迹'),
        actions: [
          if (_list.isNotEmpty)
            TextButton(
              onPressed: () async {
                await UserHubService(widget.apiBaseUrl).clearBrowseHistory();
                _load();
              },
              child: const Text('清空'),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty
              ? const Center(child: Text('暂无浏览记录'))
              : ListView.builder(
                  itemCount: _list.length,
                  itemBuilder: (_, i) {
                    final m = _list[i];
                    return ListTile(
                      leading: m['coverUrl'] != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(m['coverUrl'].toString(), width: 56, height: 56, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.history),
                      title: Text(m['title']?.toString() ?? ''),
                      subtitle: Text(m['viewedAt']?.toString().split('T').first ?? ''),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ModelDetailPage(modelId: m['id'].toString())),
                      ),
                    );
                  },
                ),
    );
  }
}
