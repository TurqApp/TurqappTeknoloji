part of 'network_awareness_service.dart';

class NetworkAwarenessService extends GetxController {
  static NetworkAwarenessService? maybeFind() =>
      _maybeFindNetworkAwarenessService();

  static NetworkAwarenessService ensure() => _ensureNetworkAwarenessService();

  final _state = _NetworkAwarenessServiceState();

  NetworkType get currentNetwork =>
      _debugOverrideNetwork ?? _currentNetwork.value;
  NetworkSettings get settings => _settings.value;
  DataUsageStats get dataUsage => _dataUsage.value;

  bool get isConnected => currentNetwork != NetworkType.none;
  bool get isOnWiFi => currentNetwork == NetworkType.wifi;
  bool get isOnCellular => currentNetwork == NetworkType.cellular;

  static const String _settingsKey = 'network_settings';
  static const String _dataUsageKey = 'data_usage_stats';

  @override
  void onInit() {
    super.onInit();
    _handleNetworkAwarenessInit(this);
  }

  @override
  void onClose() {
    _handleNetworkAwarenessClose(this);
    super.onClose();
  }
}
