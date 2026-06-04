import 'package:share_plus/share_plus.dart';

class ShareHelper {
  static Future<void> shareText({
    required String title,
    required String text,
    String? link,
  }) async {
    final body = link == null || link.isEmpty ? text : '$text\n$link';
    await Share.share(body, subject: title);
  }
}
