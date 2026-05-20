import 'package:turqappv2/Core/Services/network_awareness_service.dart';

class ConnectivityHelper {
  static Future<bool> isWifi() async {
    final network = NetworkAwarenessService.maybeFind();
    if (network == null) return true;
    return network.isOnWiFi || (network.allowLiveRead && !network.isOnCellular);
  }
}
