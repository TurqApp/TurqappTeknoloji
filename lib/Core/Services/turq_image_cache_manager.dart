import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class TurqImageCacheManager {
  static const key = 'turqImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 2000,
    ),
  );
}
