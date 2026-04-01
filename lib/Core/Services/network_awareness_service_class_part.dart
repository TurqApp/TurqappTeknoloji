part of 'network_awareness_service.dart';

class NetworkAwarenessService extends _NetworkAwarenessServiceBase {
  static NetworkAwarenessService? maybeFind() =>
      _maybeFindNetworkAwarenessService();

  static NetworkAwarenessService ensure() => _ensureNetworkAwarenessService();
}
