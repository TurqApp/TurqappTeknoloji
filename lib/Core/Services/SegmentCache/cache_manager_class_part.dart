part of 'cache_manager.dart';

class SegmentCacheManager extends _SegmentCacheManagerBase {
  static SegmentCacheManager? maybeFind() => maybeFindSegmentCacheManager();

  static SegmentCacheManager ensure() => ensureSegmentCacheManager();

  @override
  Future<void> onClose() async {
    await _handleSegmentCacheManagerOnClose();
    super.onClose();
  }
}
