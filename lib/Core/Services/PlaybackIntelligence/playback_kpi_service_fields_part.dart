part of 'playback_kpi_service.dart';

class _PlaybackKpiServiceState {
  final recent = <PlaybackKpiEvent>[].obs;
}

extension PlaybackKpiServiceFieldsPart on PlaybackKpiService {
  RxList<PlaybackKpiEvent> get _recent => _state.recent;
}
