import 'api_client.dart';

class WorkbenchJob {
  WorkbenchJob({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    this.durationSec,
    this.publishModelId,
    this.result,
  });

  final String id;
  final String type;
  final String status;
  final DateTime createdAt;
  final int? durationSec;
  final String? publishModelId;
  final WorkbenchResult? result;

  bool get isDone => status == "SUCCESS" || status == "FAILED";

  factory WorkbenchJob.fromJson(Map<String, dynamic> json) {
    final resultRaw = json["result"] as Map<String, dynamic>?;
    return WorkbenchJob(
      id: json["id"].toString(),
      type: json["type"].toString(),
      status: json["status"].toString(),
      createdAt: DateTime.tryParse(json["createdAt"]?.toString() ?? "") ?? DateTime.now(),
      durationSec: (json["durationSec"] as num?)?.toInt(),
      publishModelId: json["publishModelId"]?.toString(),
      result: resultRaw == null ? null : WorkbenchResult.fromJson(resultRaw),
    );
  }
}

class WorkbenchResult {
  WorkbenchResult({
    required this.title,
    required this.description,
    required this.format,
    required this.fileSize,
    required this.coverUrl,
    required this.downloadUrl,
  });

  final String title;
  final String description;
  final String format;
  final int fileSize;
  final String coverUrl;
  final String downloadUrl;

  factory WorkbenchResult.fromJson(Map<String, dynamic> json) {
    return WorkbenchResult(
      title: json["title"]?.toString() ?? "",
      description: json["description"]?.toString() ?? "",
      format: json["format"]?.toString() ?? "GLB",
      fileSize: (json["fileSize"] as num?)?.toInt() ?? 0,
      coverUrl: json["coverUrl"]?.toString() ?? "",
      downloadUrl: json["downloadUrl"]?.toString() ?? "",
    );
  }
}

class PhotoQuota {
  PhotoQuota({required this.limit, required this.used, required this.remaining, required this.period});
  final int limit;
  final int used;
  final int remaining;
  final String period;

  factory PhotoQuota.fromJson(Map<String, dynamic> json) {
    return PhotoQuota(
      limit: (json["limit"] as num?)?.toInt() ?? 0,
      used: (json["used"] as num?)?.toInt() ?? 0,
      remaining: (json["remaining"] as num?)?.toInt() ?? 0,
      period: json["period"]?.toString() ?? "",
    );
  }
}

class WorkbenchService {
  WorkbenchService(this._api);
  final ApiClient _api;

  Future<PhotoQuota> fetchPhotoQuota() async {
    final data = await _api.get("/workbench/photo-to-3d/quota");
    return PhotoQuota.fromJson(data);
  }

  Future<String> createPhotoTo3DJob({required List<String> imageUrls, String? title}) async {
    final data = await _api.post("/workbench/photo-to-3d/jobs", data: {
      "image_urls": imageUrls,
      if (title != null && title.isNotEmpty) "title": title,
    });
    return data["job_id"].toString();
  }

  Future<String> createUploadJob({
    required String fileName,
    required String format,
    required int fileSize,
    required String downloadUrl,
    String? coverUrl,
    String? title,
  }) async {
    final data = await _api.post("/workbench/upload-model/jobs", data: {
      "file_name": fileName,
      "format": format,
      "file_size": fileSize,
      "download_url": downloadUrl,
      if (coverUrl != null && coverUrl.isNotEmpty) "cover_url": coverUrl,
      if (title != null && title.isNotEmpty) "title": title,
    });
    return data["job_id"].toString();
  }

  Future<String> createFoodMoldJob({
    required String sourceModelUrl,
    required int blockCount,
    required double depthMm,
    String? title,
  }) async {
    final data = await _api.post("/workbench/food-mold/jobs", data: {
      "source_model_url": sourceModelUrl,
      "block_count": blockCount,
      "depth_mm": depthMm,
      if (title != null && title.isNotEmpty) "title": title,
    });
    return data["job_id"].toString();
  }

  Future<List<WorkbenchJob>> fetchJobs() async {
    final data = await _api.get("/workbench/jobs");
    final list = (data["list"] as List?) ?? [];
    return list.map((e) => WorkbenchJob.fromJson((e as Map).cast<String, dynamic>())).toList();
  }

  Future<WorkbenchJob> fetchJob(String id) async {
    final data = await _api.get("/workbench/jobs/$id");
    return WorkbenchJob.fromJson((data["job"] as Map).cast<String, dynamic>());
  }

  Future<String> publishJob(String id, {double price = 0, String? title}) async {
    final data = await _api.post("/workbench/jobs/$id/publish", data: {
      "price": price,
      if (title != null && title.isNotEmpty) "title": title,
    });
    return data["model_id"].toString();
  }
}
