import 'package:get/get.dart';

String normalizeAdsCenterError(Object error) {
  final text = error.toString();
  if (text.contains('permission-denied')) {
    return 'ads_center.permission_denied'.tr;
  }
  return text;
}
