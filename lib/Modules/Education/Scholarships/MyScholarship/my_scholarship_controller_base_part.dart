part of 'my_scholarship_controller_library.dart';

abstract class _MyScholarshipControllerBase extends GetxController {
  final _MyScholarshipControllerState _state = _MyScholarshipControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited((this as MyScholarshipController).bootstrapMyScholarships());
  }
}
