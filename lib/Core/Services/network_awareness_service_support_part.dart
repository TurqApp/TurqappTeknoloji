part of 'network_awareness_service.dart';

const String _networkAwarenessSettingsKey = 'network_settings';
const String _networkAwarenessDataUsageKey = 'data_usage_stats';

extension NetworkAwarenessServiceSupportPart on NetworkAwarenessService {
  Rx<NetworkType> get currentNetworkRx => _currentNetwork;

  NetworkType get currentNetwork =>
      _debugOverrideNetwork ?? _currentNetwork.value;

  NetworkSettings get settings => _settings.value;

  DataUsageStats get dataUsage => _dataUsage.value;

  bool get isConnected => currentNetwork != NetworkType.none;

  bool get isOnWiFi => currentNetwork == NetworkType.wifi;

  bool get isOnCellular => currentNetwork == NetworkType.cellular;
}
