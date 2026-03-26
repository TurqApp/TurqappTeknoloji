part of 'create_tutoring_controller.dart';

class CreateTutoringController extends GetxController {
  static CreateTutoringController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      CreateTutoringController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static CreateTutoringController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<CreateTutoringController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<CreateTutoringController>(tag: tag);
  }

  final _state = _CreateTutoringControllerState();

  static List<String> get weekDays => _createTutoringWeekDays;
  static List<String> get timeSlots => _createTutoringTimeSlots;

  @override
  void onInit() {
    super.onInit();
    _handleRuntimeInit();
  }

  @override
  void onClose() {
    _handleRuntimeClose();
    super.onClose();
  }
}
