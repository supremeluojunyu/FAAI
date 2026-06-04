import 'package:flutter/material.dart';
import '../../services/user_hub_service.dart';

class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  List<Map<String, dynamic>> _jobs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await UserHubService(widget.apiBaseUrl).fetchWorkbenchJobs();
      final drafts = list.where((j) {
        final s = (j['status'] ?? '').toString().toUpperCase();
        return s == 'PENDING' || s == 'FAILED' || s == 'DRAFT';
      }).toList();
      if (!mounted) return;
      setState(() {
        _jobs = drafts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('草稿箱')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _jobs.isEmpty
                  ? const Center(child: Text('暂无草稿任务\n可在工作台创建模型后在此查看'))
                  : ListView.builder(
                      itemCount: _jobs.length,
                      itemBuilder: (_, i) {
                        final j = _jobs[i];
                        return ListTile(
                          leading: const Icon(Icons.drafts_outlined),
                          title: Text((j['type'] ?? '任务').toString()),
                          subtitle: Text('状态：${j['status'] ?? '-'}'),
                        );
                      },
                    ),
    );
  }
}
