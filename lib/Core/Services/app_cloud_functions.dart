import 'package:cloud_functions/cloud_functions.dart';

class AppCloudFunctions {
  const AppCloudFunctions._();

  static FirebaseFunctions get instance => FirebaseFunctions.instance;

  static FirebaseFunctions instanceFor({required String region}) =>
      FirebaseFunctions.instanceFor(region: region);
}
