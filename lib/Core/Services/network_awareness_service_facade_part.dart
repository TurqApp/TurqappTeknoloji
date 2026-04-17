part of 'network_awareness_service.dart';

NetworkAwarenessService? _maybeFindNetworkAwarenessService() =>
    Get.isRegistered<NetworkAwarenessService>()
        ? Get.find<NetworkAwarenessService>()
        : null;

NetworkAwarenessService _ensureNetworkAwarenessService() =>
    _maybeFindNetworkAwarenessService() ??
    Get.put(NetworkAwarenessService(), permanent: true);

void _handleNetworkAwarenessInit(NetworkAwarenessService service) {
  service._loadSettings();
  service._loadDataUsage();
  service._startNetworkMonitoring();
}

void _handleNetworkAwarenessClose(NetworkAwarenessService service) {
  service._connectivitySubscription?.cancel();
  service._connectivityPollTimer?.cancel();
}
