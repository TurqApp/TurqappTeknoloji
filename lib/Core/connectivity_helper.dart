import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityHelper {
  static Future<bool> isWifi() => Connectivity()
      .checkConnectivity()
      .then((results) => results.contains(ConnectivityResult.wifi))
      .catchError((_) => true);
}
