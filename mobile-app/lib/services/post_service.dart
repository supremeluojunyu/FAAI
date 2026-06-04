import 'package:dio/dio.dart';
import 'api_dio.dart';
import 'auth_service.dart';

class CommunityPost {
  final String id;
  final String content;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final String authorName;
  final bool isLiked;

  CommunityPost({
    required this.id,
    required this.content,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
    required this.authorName,
    this.isLiked = false,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    final author = (json['author'] as Map?)?.cast<String, dynamic>() ?? (json['user'] as Map?)?.cast<String, dynamic>() ?? {};
    return CommunityPost(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
      authorName: (author['nickname'] ?? '用户').toString(),
      isLiked: json['is_liked'] == true,
    );
  }
}

class PostService {
  PostService(this.baseUrl);
  final String baseUrl;

  Dio _dio(String? token) {
    final dio = createApiDio(baseUrl);
    if (token != null && token.isNotEmpty) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return dio;
  }

  Map<String, dynamic> _unwrap(dynamic raw) {
    final body = (raw as Map).cast<String, dynamic>();
    if ((body['code'] as num? ?? 0) != 0) {
      throw Exception((body['message'] ?? '请求失败').toString());
    }
    return (body['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }

  Future<List<CommunityPost>> listPosts() async {
    final token = await AuthService(baseUrl).getLocalToken();
    final resp = await _dio(token).get('/posts');
    final data = _unwrap(resp.data);
    return (data['list'] as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((e) => CommunityPost.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<({bool liked, int count})> toggleLike(String postId) async {
    final token = await AuthService(baseUrl).getLocalToken();
    if (token == null || token.isEmpty) throw Exception('请先登录');
    final resp = await _dio(token).post('/posts/$postId/like');
    final data = _unwrap(resp.data);
    return (
      liked: data['is_liked'] == true,
      count: (data['like_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> sharePost(String postId) async {
    final token = await AuthService(baseUrl).getLocalToken();
    if (token == null || token.isEmpty) throw Exception('请先登录');
    await _dio(token).post('/posts/$postId/share', data: {'channel': 'app'});
  }
}
