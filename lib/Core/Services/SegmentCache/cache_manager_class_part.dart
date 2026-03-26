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
  static SegmentCacheManager? maybeFind() => maybeFindSegmentCacheManager();

  static SegmentCacheManager ensure() => ensureSegmentCacheManager();

  final _state = _SegmentCacheManagerState();

  @override
  Future<void> onClose() async {
    await _handleSegmentCacheManagerOnClose();
    super.onClose();
  }
}
