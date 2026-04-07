part of 'hls_data_usage_probe.dart';

class _HlsDataUsageProbeState {
  final List<HlsTransferEvent> events = <HlsTransferEvent>[];
  final Map<String, int> segmentDownloads = <String, int>{};
  final Map<String, int> segmentCacheHits = <String, int>{};
  final Map<String, _VariantCatalog> variantCatalogs =
      <String, _VariantCatalog>{};
  final Map<String, _DocAccumulator> docUsage = <String, _DocAccumulator>{};
  final Map<String, _InFlightTransfer> inFlight = <String, _InFlightTransfer>{};
  final math.Random random = math.Random(7);

  DateTime startedAt = DateTime.now();
  String label = 'default';
  String? visibleDocId;
  HlsDebugNetworkProfile networkProfile = HlsDebugNetworkProfile.fast;
  int peakConcurrentDownloads = 0;
  int peakParallelDocDownloads = 0;
  int peakOffscreenParallelDownloads = 0;
  int variantSwitchesObserved = 0;
  String? lastVisibleVariantKey;
  String? mobileBytesKpiSignature;
}

extension _HlsDataUsageProbeFieldsPart on HlsDataUsageProbe {
  List<HlsTransferEvent> get _events => _state.events;
  Map<String, int> get _segmentDownloads => _state.segmentDownloads;
  Map<String, int> get _segmentCacheHits => _state.segmentCacheHits;
  Map<String, _VariantCatalog> get _variantCatalogs => _state.variantCatalogs;
  Map<String, _DocAccumulator> get _docUsage => _state.docUsage;
  Map<String, _InFlightTransfer> get _inFlight => _state.inFlight;
  math.Random get _random => _state.random;

  DateTime get _startedAt => _state.startedAt;
  set _startedAt(DateTime value) => _state.startedAt = value;

  String get _label => _state.label;
  set _label(String value) => _state.label = value;

  String? get _visibleDocId => _state.visibleDocId;
  set _visibleDocId(String? value) => _state.visibleDocId = value;

  HlsDebugNetworkProfile get _networkProfile => _state.networkProfile;
  set _networkProfile(HlsDebugNetworkProfile value) =>
      _state.networkProfile = value;

  int get _peakConcurrentDownloads => _state.peakConcurrentDownloads;
  set _peakConcurrentDownloads(int value) =>
      _state.peakConcurrentDownloads = value;

  int get _peakParallelDocDownloads => _state.peakParallelDocDownloads;
  set _peakParallelDocDownloads(int value) =>
      _state.peakParallelDocDownloads = value;

  int get _peakOffscreenParallelDownloads =>
      _state.peakOffscreenParallelDownloads;
  set _peakOffscreenParallelDownloads(int value) =>
      _state.peakOffscreenParallelDownloads = value;

  int get _variantSwitchesObserved => _state.variantSwitchesObserved;
  set _variantSwitchesObserved(int value) =>
      _state.variantSwitchesObserved = value;

  String? get _lastVisibleVariantKey => _state.lastVisibleVariantKey;
  set _lastVisibleVariantKey(String? value) =>
      _state.lastVisibleVariantKey = value;

  String? get _mobileBytesKpiSignature => _state.mobileBytesKpiSignature;
  set _mobileBytesKpiSignature(String? value) =>
      _state.mobileBytesKpiSignature = value;
}
