part of 'prefetch_scheduler.dart';

/// Wi-Fi prefetch kuyruğu.
///
/// Breadth-first strateji:
/// 1. Sonraki videolarda ilk 2 segment hazır
/// 2. Aktif videoda ilk 2 segment hazır
/// 3. İzleme sırasında yalnızca 1 sonraki segment hazırlanır
class PrefetchScheduler extends GetxController {
  final _state = _PrefetchSchedulerState();

  @override
  void onClose() {
    _handlePrefetchSchedulerClose();
    super.onClose();
  }
}
