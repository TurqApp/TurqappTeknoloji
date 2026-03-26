part of 'cache_manager.dart';

/// Segment seviyesinde HLS disk cache yöneticisi.
/// CDN path'ini mirror ederek disk'e yazar, index.json ile takip eder.
///
/// Disk yapısı:
/// ```
/// {appSupport}/hls_cache/
///   index.json
///   Posts/{docID}/hls/master.m3u8
///   Posts/{docID}/hls/720p/playlist.m3u8
///   Posts/{docID}/hls/720p/segment_0.ts
/// ```
class SegmentCacheManager extends GetxController {
  static SegmentCacheManager? maybeFind() {
    final isRegistered = Get.isRegistered<SegmentCacheManager>();
    if (!isRegistered) return null;
    return Get.find<SegmentCacheManager>();
  }

  static SegmentCacheManager ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(SegmentCacheManager(), permanent: true);
  }

  final _state = _SegmentCacheManagerState();

  @override
  Future<void> onClose() async {
    await _handleSegmentCacheManagerOnClose();
    super.onClose();
  }
}
