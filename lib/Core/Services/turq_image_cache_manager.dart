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
}
