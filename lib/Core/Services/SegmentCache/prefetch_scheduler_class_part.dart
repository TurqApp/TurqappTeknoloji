part of 'prefetch_scheduler.dart';

/// Wi-Fi prefetch kuyruğu.
///
/// Breadth-first strateji:
/// 1. Sonraki videolarda ilk 2 segment hazır
/// 2. Aktif videoda ilk 2 segment hazır
/// 3. İzleme sırasında yalnızca 1 sonraki segment hazırlanır
class PrefetchScheduler extends GetxController {
  static const String _cdnOrigin = 'https://cdn.turqapp.com';
  static const Map<String, String> _cdnHeaders = {
    'X-Turq-App': 'turqapp-mobile',
    'Referer': '$_cdnOrigin/',
  };
  static const int _targetReadySegments = 2;
  // +5/-5 kuralı: önündeki 5 videonun min 2 segmenti hazır olmalı
  static const int _fallbackBreadthCount = 5;
  static const int _fallbackDepthCount = 3;
  static const int _fallbackMaxConcurrent = 2;
  static const int _fallbackFeedFullWindow = 15;
  static const int _fallbackFeedPrepWindow = 8;
  static const int _wifiMinBreadthCount = 12;
  static const int _wifiMinDepthCount = 7;
  static const int _wifiMinMaxConcurrent = 4;
  static const int _wifiMinFeedFullWindow = 15;
  static const int _wifiMinFeedPrepWindow = 20;

  final _state = _PrefetchSchedulerState();

  @override
  void onClose() {
    _handlePrefetchSchedulerClose();
    super.onClose();
  }
}
