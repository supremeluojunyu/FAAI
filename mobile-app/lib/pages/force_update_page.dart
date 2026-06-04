import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/version_policy.dart';
import '../utils/app_version_info.dart';

class ForceUpdatePage extends StatelessWidget {
  const ForceUpdatePage({
    super.key,
    required this.policy,
    this.reason,
    this.downloadUrl,
  });

  final VersionPolicy policy;
  final String? reason;
  final String? downloadUrl;

  Future<void> _openDownload() async {
    final url = downloadUrl ?? policy.resolveDownloadUrl();
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('无法打开下载链接');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !policy.forceUpdate,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FutureBuilder<AppVersionInfo>(
              future: AppVersionInfo.get(),
              builder: (context, snap) {
                final info = snap.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.system_update, size: 72, color: Color(0xFF1677FF)),
                    const SizedBox(height: 24),
                    Text(
                      policy.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reason ?? policy.message,
                      style: const TextStyle(color: Colors.black87, height: 1.5),
                    ),
                    if (info != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '当前版本：${info.version} (${info.buildNumber})\n'
                        '要求最低：${policy.minVersion}'
                        '${policy.minBuildNumber > 0 ? ' (构建号 ≥ ${policy.minBuildNumber})' : ''}\n'
                        '最新版本：${policy.latestVersion.isNotEmpty ? policy.latestVersion : '请见下载页'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.6),
                      ),
                    ],
                    const Spacer(),
                    FilledButton(
                      onPressed: _openDownload,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      child: const Text('立即下载最新版'),
                    ),
                    if (!policy.forceUpdate) ...[
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('稍后再说'),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
