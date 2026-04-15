import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Models/posts_model.dart';

class TurqImageCacheManager {
  static const key = 'turqImageCache';
  static const startupPosterHintsKey = 'posterHints';

  static CacheManager? _instance;
  static final Map<String, String> _resolvedFilePathByUrl = <String, String>{};
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
          stalePeriod: const Duration(days: 30),
          maxNrOfCacheObjects: 2000,
        ),
      ));

  static CacheManager get instance => ensure();

  static void rememberResolvedFile(String url, String filePath) {
    final normalizedUrl = _normalizeRememberedUrlKey(url);
    final normalizedPath = filePath.trim();
    if (normalizedUrl.isEmpty || normalizedPath.isEmpty) return;
    if (!File(normalizedPath).existsSync()) return;
    _resolvedFilePathByUrl[normalizedUrl] = normalizedPath;
  }

  static String rememberedResolvedFilePathForUrl(String url) {
    final normalized = _normalizeRememberedUrlKey(url);
    if (normalized.isEmpty) return '';
    var remembered = _resolvedFilePathByUrl[normalized] ?? '';
    if (remembered.isEmpty) {
      final legacyKey = url.trim();
      remembered = _resolvedFilePathByUrl[legacyKey] ?? '';
      if (remembered.isNotEmpty) {
        _resolvedFilePathByUrl[normalized] = remembered;
        _resolvedFilePathByUrl.remove(legacyKey);
      }
    }
    if (remembered.isEmpty) return '';
    if (!File(remembered).existsSync()) {
      _resolvedFilePathByUrl.remove(normalized);
      return '';
    }
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

  static Future<void> removeUrl(String url) async {
    final normalized = _normalizeRememberedUrlKey(url);
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

  static List<Map<String, String>> buildPosterHintsForPosts(
    Iterable<PostsModel> posts, {
    int maxEntries = 32,
    int maxEntriesPerPost = 2,
  }) {
    if (maxEntries <= 0 || maxEntriesPerPost <= 0) {
      return const <Map<String, String>>[];
    }
    final hints = <Map<String, String>>[];
    final seenUrls = <String>{};

    for (final post in posts) {
      var addedForPost = 0;
      for (final url in post.preferredVideoPosterUrls) {
        final normalizedUrl = url.trim();
        if (normalizedUrl.isEmpty || !seenUrls.add(normalizedUrl)) {
          continue;
        }
        final path = rememberedResolvedFilePathForUrl(normalizedUrl);
        if (path.isEmpty) continue;
        hints.add(<String, String>{
          'u': normalizedUrl,
          'p': path,
        });
        addedForPost++;
        if (addedForPost >= maxEntriesPerPost || hints.length >= maxEntries) {
          break;
        }
      }
      if (hints.length >= maxEntries) {
        break;
      }
    }

    return hints;
  }

  static void hydratePosterHints(dynamic raw) {
    if (raw is! List) return;
    for (final entry in raw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
      final url = (map['u'] ?? map['url'] ?? '').toString().trim();
      final path = (map['p'] ?? map['path'] ?? '').toString().trim();
      if (url.isEmpty || path.isEmpty) continue;
      rememberResolvedFile(url, path);
    }
  }

  static void hydratePosterHintsFromPayload(Map<String, dynamic> payload) {
    hydratePosterHints(payload[startupPosterHintsKey]);
  }
}
