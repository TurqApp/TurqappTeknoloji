part of 'network_awareness_service.dart';

const String _networkAwarenessSettingsKey = 'network_settings';
const String _networkAwarenessDataUsageKey = 'data_usage_stats';

extension NetworkAwarenessServiceSupportPart on NetworkAwarenessService {
  Rx<NetworkType> get currentNetworkRx => _currentNetwork;
  Rx<NetworkReachabilityState> get reachabilityStateRx => _reachabilityState;

  NetworkType get currentNetwork =>
      _debugOverrideNetwork ?? _currentNetwork.value;

  NetworkReachabilityState get reachabilityState =>
      _debugOverrideNetwork != null
          ? (_debugOverrideNetwork == NetworkType.none
              ? NetworkReachabilityState.offlineConfirmed
              : NetworkReachabilityState.online)
          : _reachabilityState.value;

  NetworkSettings get settings => _settings.value;

  DataUsageStats get dataUsage => _dataUsage.value;

  bool get isOfflineConfirmed =>
      reachabilityState == NetworkReachabilityState.offlineConfirmed;

  bool get isNetworkUnstable =>
      reachabilityState == NetworkReachabilityState.unstable;

  bool get isConnected => !isOfflineConfirmed;

  bool get isOnWiFi => currentNetwork == NetworkType.wifi;

  bool get isOnCellular => currentNetwork == NetworkType.cellular;

  bool get allowLiveRead => !isOfflineConfirmed;

  bool get allowBackgroundRefresh => !isOfflineConfirmed;

  bool get allowMediaFetch => !isOfflineConfirmed;

  bool get allowWriteAttempt => !isOfflineConfirmed;

  bool get allowQueueWrites => isOfflineConfirmed;

  bool get allowUploadAttempt =>
      !isNetworkUnstable &&
      !isOfflineConfirmed &&
      currentNetwork != NetworkType.none;
}
