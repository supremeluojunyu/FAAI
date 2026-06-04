import 'package:dio/dio.dart';
import 'auth_service.dart';

class ModelItem {
  final String id;
  final String title;
  final String coverUrl;
  final String category;
  final String price;
  final int likeCount;

  ModelItem({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.category,
    required this.price,
    required this.likeCount,
  });

  factory ModelItem.fromJson(Map<String, dynamic> json) {
    return ModelItem(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      coverUrl: (json['coverUrl'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ModelDetail {
  final ModelItem item;
  final String description;
  final String format;
  final int fileSize;
  final Map<String, dynamic>? designer;

  ModelDetail({
    required this.item,
    required this.description,
    required this.format,
    required this.fileSize,
    this.designer,
  });
}

class ModelService {
  ModelService(this.baseUrl);
  final String baseUrl;

  Dio _dio(String? token) => Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        headers: token == null ? {} : {'Authorization': 'Bearer $token'},
      ));

  Future<List<ModelItem>> listModels({int page = 1, int size = 40}) async {
    final token = await AuthService(baseUrl).getLocalToken();
    final resp = await _dio(token).get('/models', queryParameters: {'page': page, 'size': size});
    final data = _unwrap(resp.data);
    final list = (data['list'] as List<dynamic>? ?? []).whereType<Map>().map((e) => ModelItem.fromJson(e.cast<String, dynamic>())).toList();
    return list;
  }

  Future<ModelDetail> getModel(String id) async {
    final token = await AuthService(baseUrl).getLocalToken();
    final resp = await _dio(token).get('/models/$id');
    final data = _unwrap(resp.data);
    final model = (data['model'] as Map?)?.cast<String, dynamic>() ?? {};
    return ModelDetail(
      item: ModelItem.fromJson(model),
      description: (model['description'] ?? '').toString(),
      format: (model['format'] ?? '').toString(),
      fileSize: (model['fileSize'] as num?)?.toInt() ?? 0,
      designer: (data['designer_info'] as Map?)?.cast<String, dynamic>(),
    );
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final body = (raw as Map).cast<String, dynamic>();
    if ((body['code'] as num? ?? 0) != 0) {
      throw Exception((body['message'] ?? '请求失败').toString());
    }
    return (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }
}
