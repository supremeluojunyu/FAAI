import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/workbench_service.dart';
import 'food_mold_page.dart';
import 'photo_to_3d_page.dart';
import 'upload_model_page.dart';
import 'workbench_job_detail_page.dart';

class WorkbenchPage extends StatefulWidget {
  const WorkbenchPage({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<WorkbenchPage> createState() => _WorkbenchPageState();
}

class _WorkbenchPageState extends State<WorkbenchPage> {
  late final WorkbenchService _service = WorkbenchService(ApiClient(widget.apiBaseUrl));
  Future<List<WorkbenchJob>>? _jobsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _jobsFuture = _service.fetchJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工作台'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ActionCard(
                title: "拍照生成模型",
                icon: Icons.photo_camera_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PhotoTo3DPage(service: _service)),
                ).then((_) => _reload()),
              ),
              _ActionCard(
                title: "上传模型",
                icon: Icons.upload_file_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => UploadModelPage(service: _service)),
                ).then((_) => _reload()),
              ),
              _ActionCard(
                title: "食品模具制作",
                icon: Icons.cookie_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FoodMoldPage(service: _service)),
                ).then((_) => _reload()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("最近任务", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          FutureBuilder<List<WorkbenchJob>>(
            future: _jobsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text("加载失败: ${snapshot.error}"),
                );
              }
              final list = snapshot.data ?? [];
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text("暂无任务，先创建一个吧。"),
                );
              }
              return Column(
                children: list.take(15).map((job) {
                  return Card(
                    child: ListTile(
                      title: Text("${job.type} · ${job.status}"),
                      subtitle: Text(job.result?.title ?? "任务ID: ${job.id}"),
                      trailing: job.durationSec == null ? null : Text("${job.durationSec}s"),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkbenchJobDetailPage(service: _service, jobId: job.id),
                        ),
                      ).then((_) => _reload()),
                    ),
                  );
                }).toList(),
              );
            },
          )
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 36) / 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
