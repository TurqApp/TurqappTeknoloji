part of 'cache_manager.dart';

class _SegmentCacheManagerState {
  String? cacheDir;
  bool ready = false;
  CacheIndex index = CacheIndex();
  final metrics = CacheMetrics();
  int playlistMetadataBytes = 0;
  int indexMetadataBytes = 0;
  int? userHardLimitBytes;
  int? userSoftLimitBytes;
  Timer? persistTimer;
  Timer? reconcileTimer;
  bool persistDirty = false;
  final writeInFlight = <String, Future<File>>{};
  Future<void>? evictionInFlight;
  final recentlyPlayed = <String>[];
  final lastPersistedProgress = <String, double>{};
  final lastPersistedProgressAt = <String, DateTime>{};
}

extension SegmentCacheManagerFieldsPart on SegmentCacheManager {
  String get _cacheDir => _state.cacheDir!;
  set _cacheDir(String value) => _state.cacheDir = value;
  bool get _isReady => _state.ready;
  set _isReady(bool value) => _state.ready = value;
  CacheIndex get _index => _state.index;
  set _index(CacheIndex value) => _state.index = value;
  CacheMetrics get metrics => _state.metrics;
  int get _playlistMetadataBytes => _state.playlistMetadataBytes;
  set _playlistMetadataBytes(int value) => _state.playlistMetadataBytes = value;
  int get _indexMetadataBytes => _state.indexMetadataBytes;
  set _indexMetadataBytes(int value) => _state.indexMetadataBytes = value;
  int? get _userHardLimitBytes => _state.userHardLimitBytes;
  set _userHardLimitBytes(int? value) => _state.userHardLimitBytes = value;
  int? get _userSoftLimitBytes => _state.userSoftLimitBytes;
  set _userSoftLimitBytes(int? value) => _state.userSoftLimitBytes = value;
  Timer? get _persistTimer => _state.persistTimer;
  set _persistTimer(Timer? value) => _state.persistTimer = value;
  Timer? get _reconcileTimer => _state.reconcileTimer;
  set _reconcileTimer(Timer? value) => _state.reconcileTimer = value;
  bool get _persistDirty => _state.persistDirty;
  set _persistDirty(bool value) => _state.persistDirty = value;
  Map<String, Future<File>> get _writeInFlight => _state.writeInFlight;
  Future<void>? get _evictionInFlight => _state.evictionInFlight;
  set _evictionInFlight(Future<void>? value) => _state.evictionInFlight = value;
  List<String> get _recentlyPlayed => _state.recentlyPlayed;
  Map<String, double> get _lastPersistedProgress =>
      _state.lastPersistedProgress;
  Map<String, DateTime> get _lastPersistedProgressAt =>
      _state.lastPersistedProgressAt;
}
