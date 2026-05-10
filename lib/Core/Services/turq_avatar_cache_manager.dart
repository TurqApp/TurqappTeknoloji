import 'dart:collection';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';

class TurqAvatarCacheManager {
  static const key = 'turqAvatarCache';
  static const int _maxRememberedResolvedFiles = 2048;
  static const Duration _diskStalePeriod = Duration(days: 30);
  static const int _maxDiskCacheObjects = 10000;

  static CacheManager? _instance;
  static final LinkedHashMap<String, String> _resolvedFilePathByUrl =
      LinkedHashMap<String, String>();

  static CacheManager? maybeFind() => _instance;

  static String _normalizeRememberedUrlKey(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || isDefaultAvatarUrl(trimmed)) return '';
    return CdnUrlBuilder.toCdnUrl(trimmed);
  }

  static CacheManager ensure() =>
      maybeFind() ??
      (_instance = CacheManager(
        Config(
          key,
          stalePeriod: _diskStalePeriod,
          maxNrOfCacheObjects: _maxDiskCacheObjects,
        ),
      ));

  static CacheManager get instance => ensure();

  static void _rememberResolvedFileInMemory(String url, String filePath) {
    _resolvedFilePathByUrl.remove(url);
    _resolvedFilePathByUrl[url] = filePath;
    while (_resolvedFilePathByUrl.length > _maxRememberedResolvedFiles) {
      _resolvedFilePathByUrl.remove(_resolvedFilePathByUrl.keys.first);
    }
  }

  static void rememberResolvedFile(String url, String filePath) {
    final normalizedUrl = _normalizeRememberedUrlKey(url);
    final normalizedPath = filePath.trim();
    if (normalizedUrl.isEmpty || normalizedPath.isEmpty) return;
    if (!File(normalizedPath).existsSync()) return;
    _rememberResolvedFileInMemory(normalizedUrl, normalizedPath);
  }

  static String rememberedResolvedFilePathForUrl(String url) {
    final normalized = _normalizeRememberedUrlKey(url);
    if (normalized.isEmpty) return '';
    var remembered = _resolvedFilePathByUrl[normalized] ?? '';
    if (remembered.isEmpty) {
      final legacyKey = url.trim();
      remembered = _resolvedFilePathByUrl[legacyKey] ?? '';
      if (remembered.isNotEmpty) {
        _rememberResolvedFileInMemory(normalized, remembered);
        _resolvedFilePathByUrl.remove(legacyKey);
      }
    }
    if (remembered.isEmpty) return '';
    if (!File(remembered).existsSync()) {
      _resolvedFilePathByUrl.remove(normalized);
      return '';
    }
    _rememberResolvedFileInMemory(normalized, remembered);
    return remembered;
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
    final normalized = _normalizeRememberedUrlKey(url);
    final file = await instance.getSingleFile(normalized);
    rememberResolvedFile(normalized, file.path);
    return file;
  }
}
