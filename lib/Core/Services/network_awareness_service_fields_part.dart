part of 'network_awareness_service.dart';

class _NetworkAwarenessServiceState {
  final Rx<NetworkType> currentNetwork = NetworkType.none.obs;
  final Rx<NetworkSettings> settings = NetworkSettings().obs;
  final Rx<DataUsageStats> dataUsage = DataUsageStats(
    uploadedMB: 0,
    downloadedMB: 0,
    lastReset: DateTime.now(),
  ).obs;

  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;
  Timer? connectivityPollTimer;
  NetworkType? debugOverrideNetwork;
}

extension _NetworkAwarenessServiceFieldsPart on NetworkAwarenessService {
  Rx<NetworkType> get _currentNetwork => _state.currentNetwork;
  Rx<NetworkSettings> get _settings => _state.settings;
  Rx<DataUsageStats> get _dataUsage => _state.dataUsage;
  StreamSubscription<List<ConnectivityResult>>? get _connectivitySubscription =>
      _state.connectivitySubscription;
  set _connectivitySubscription(
    StreamSubscription<List<ConnectivityResult>>? value,
  ) =>
      _state.connectivitySubscription = value;
  Timer? get _connectivityPollTimer => _state.connectivityPollTimer;
  set _connectivityPollTimer(Timer? value) =>
      _state.connectivityPollTimer = value;
  NetworkType? get _debugOverrideNetwork => _state.debugOverrideNetwork;
  set _debugOverrideNetwork(NetworkType? value) =>
      _state.debugOverrideNetwork = value;
}
