part of 'tutoring_filter_controller_library.dart';

TutoringFilterController? maybeFindTutoringFilterController() =>
    Get.isRegistered<TutoringFilterController>()
        ? Get.find<TutoringFilterController>()
        : null;

TutoringFilterController ensureTutoringFilterController({
  bool permanent = false,
}) =>
    maybeFindTutoringFilterController() ??
    Get.put(TutoringFilterController(), permanent: permanent);
