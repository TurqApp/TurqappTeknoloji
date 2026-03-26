part of 'complaint.dart';

class ComplaintController extends GetxController {
  static ComplaintController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ComplaintController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static ComplaintController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ComplaintController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ComplaintController>(tag: tag);
  }

  final _state = _ComplaintControllerState();
}
