part of 'create_tutoring_controller.dart';

class CreateTutoringController extends GetxController {
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
