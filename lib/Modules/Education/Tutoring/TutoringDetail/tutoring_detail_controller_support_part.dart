part of 'tutoring_detail_controller.dart';

extension TutoringDetailControllerSupportPart on TutoringDetailController {
  void _bootstrapFromArguments() {
    final tutoringData = Get.arguments as TutoringModel?;
    if (tutoringData != null) {
      _TutoringDetailControllerRuntimeX(this).bootstrap(tutoringData);
    }
  }
}
