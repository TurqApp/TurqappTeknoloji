import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class TurqImageCacheManager {
  static const key = 'turqImageCache';

  static CacheManager? _instance;
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

  static Future<void> removeUrl(String url) async {
    final normalized = url.trim();
    if (normalized.isEmpty) return;
    try {
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
