part of 'tutoring_detail_controller.dart';

class TutoringDetailController extends GetxController {
  static TutoringDetailController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TutoringDetailController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TutoringDetailController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TutoringDetailController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TutoringDetailController>(tag: tag);
  }

  final _state = _TutoringDetailControllerState();

  @override
  void onInit() {
    super.onInit();
    _bootstrapFromArguments();
  }
}
