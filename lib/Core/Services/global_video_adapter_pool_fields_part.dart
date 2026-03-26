part of 'global_video_adapter_pool.dart';

class _GlobalVideoAdapterPoolState {
  final Map<String, _WarmAdapterEntry> warmAdapters =
      <String, _WarmAdapterEntry>{};
  final List<String> warmOrder = <String>[];
  final Map<HLSVideoAdapter, String> leasedKeys = <HLSVideoAdapter, String>{};
  final Map<String, int> leaseCounts = <String, int>{};
}

extension _GlobalVideoAdapterPoolFieldsPart on GlobalVideoAdapterPool {
  Map<String, _WarmAdapterEntry> get _warmAdapters => _state.warmAdapters;
  List<String> get _warmOrder => _state.warmOrder;
  Map<HLSVideoAdapter, String> get _leasedKeys => _state.leasedKeys;
  Map<String, int> get _leaseCounts => _state.leaseCounts;
}

class _WarmAdapterEntry {
  const _WarmAdapterEntry({
    required this.adapter,
    required this.url,
    required this.coordinateAudioFocus,
  });

  final HLSVideoAdapter adapter;
  final String url;
  final bool coordinateAudioFocus;
}
