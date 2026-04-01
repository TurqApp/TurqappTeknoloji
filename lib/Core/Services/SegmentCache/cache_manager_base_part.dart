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
abstract class _SegmentCacheManagerBase extends GetxController {
  final _state = _SegmentCacheManagerState();
}

class SegmentCacheManager extends _SegmentCacheManagerBase {
  static SegmentCacheManager? maybeFind() => maybeFindSegmentCacheManager();
  static SegmentCacheManager ensure() => ensureSegmentCacheManager();

  @override
  Future<void> onClose() async {
    await _handleSegmentCacheManagerOnClose();
    super.onClose();
  }
}
