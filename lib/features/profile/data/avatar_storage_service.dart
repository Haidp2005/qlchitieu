import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class AvatarStorageService {
  static const String _defaultBucket = 'avatars';

  static bool get isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!isConfigured) {
      throw Exception(
        'Supabase chưa được cấu hình. Hãy chạy app với --dart-define SUPABASE_URL và SUPABASE_ANON_KEY',
      );
    }

    final client = Supabase.instance.client;

    const bucket = String.fromEnvironment(
      'SUPABASE_AVATAR_BUCKET',
      defaultValue: _defaultBucket,
    );

    final ext = _extractExtension(fileName);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: _contentTypeFromExtension(ext),
      ),
    );

    return client.storage.from(bucket).getPublicUrl(path);
  }

  static String _extractExtension(String fileName) {
    final index = fileName.lastIndexOf('.');
    if (index == -1 || index == fileName.length - 1) {
      return 'jpg';
    }
    return fileName.substring(index + 1).toLowerCase();
  }

  static String _contentTypeFromExtension(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'jpeg':
      case 'jpg':
      default:
        return 'image/jpeg';
    }
  }
}
