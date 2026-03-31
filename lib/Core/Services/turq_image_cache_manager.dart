import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class TurqImageCacheManager {
  static const key = 'turqImageCache';

  static CacheManager? _instance;
  static final Map<String, String> _resolvedFilePathByUrl = <String, String>{};
  static CacheManager? maybeFind() => _instance;

  static CacheManager ensure() =>
      maybeFind() ??
      (_instance = CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 2000,
        ),
      ));

  static CacheManager get instance => ensure();

  static void rememberResolvedFile(String url, String filePath) {
    final normalizedUrl = url.trim();
    final normalizedPath = filePath.trim();
    if (normalizedUrl.isEmpty || normalizedPath.isEmpty) return;
    _resolvedFilePathByUrl[normalizedUrl] = normalizedPath;
  }

  static String rememberedResolvedFilePathForUrl(String url) {
    final normalized = url.trim();
    if (normalized.isEmpty) return '';
    return _resolvedFilePathByUrl[normalized] ?? '';
  }

  static String rememberedResolvedFilePathForUrls(Iterable<String> urls) {
    for (final rawUrl in urls) {
      final remembered = rememberedResolvedFilePathForUrl(rawUrl);
      if (remembered.isNotEmpty) {
        return remembered;
      }
    }
    return '';
  }

  static Future<File> warmUrl(String url) async {
    final normalized = url.trim();
    final file = await instance.getSingleFile(normalized);
    rememberResolvedFile(normalized, file.path);
    return file;
  }

  static Future<void> removeUrl(String url) async {
    final normalized = url.trim();
    if (normalized.isEmpty) return;
    try {
      _resolvedFilePathByUrl.remove(normalized);
      await instance.removeFile(normalized);
    } catch (_) {}
  }

  static Future<void> removeUrls(Iterable<String> urls) async {
    final normalized = urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (normalized.isEmpty) return;
    await Future.wait(
      normalized.map(removeUrl),
    );
  }
}
