import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/workbench_service.dart';

class WorkbenchJobDetailPage extends StatefulWidget {
  const WorkbenchJobDetailPage({super.key, required this.service, required this.jobId});
  final WorkbenchService service;
  final String jobId;

  @override
  State<WorkbenchJobDetailPage> createState() => _WorkbenchJobDetailPageState();
}

class _WorkbenchJobDetailPageState extends State<WorkbenchJobDetailPage> {
  WorkbenchJob? _job;
  String? _error;
  bool _publishing = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final job = await widget.service.fetchJob(widget.jobId);
      if (!mounted) return;
      setState(() {
        _job = job;
        _error = null;
      });
      if (job.isDone) _timer?.cancel();
    } catch (e) {
      if (!mounted || silent) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _publish() async {
    final job = _job;
    if (job == null || job.status != "SUCCESS") return;
    setState(() => _publishing = true);
    try {
      final modelId = await widget.service.publishJob(job.id, price: 29.9, title: job.result?.title);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("发布成功，模型ID: $modelId")));
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("发布失败: $e")));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    return Scaffold(
      appBar: AppBar(title: const Text("任务详情")),
      body: job == null
          ? Center(child: Text(_error ?? "加载中..."))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    title: Text(job.type),
                    subtitle: Text("状态: ${job.status}"),
                    trailing: job.durationSec == null ? null : Text("${job.durationSec}s"),
                  ),
                ),
                const SizedBox(height: 12),
                if (job.result != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      job.result!.coverUrl,
                      height: 220,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 220,
                        color: const Color(0xFF334155),
                        child: const Center(child: Text("3D预览占位图", style: TextStyle(color: Colors.white))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(job.result!.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(job.result!.description),
                  const SizedBox(height: 8),
                  Text("格式: ${job.result!.format}"),
                  Text("大小: ${(job.result!.fileSize / 1024 / 1024).toStringAsFixed(2)} MB"),
                  Text("下载: ${job.result!.downloadUrl}", maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: (job != null && job.status == "SUCCESS" && !_publishing) ? _publish : null,
            child: Text(job?.publishModelId != null ? "已发布（${job!.publishModelId}）" : (_publishing ? "发布中..." : "发布为模型草稿")),
          ),
        ),
      ),
    );
  }
}
