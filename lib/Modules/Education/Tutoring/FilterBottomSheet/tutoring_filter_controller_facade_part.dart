part of 'tutoring_filter_controller_library.dart';

TutoringFilterController? maybeFindTutoringFilterController() {
  final isRegistered = Get.isRegistered<TutoringFilterController>();
  if (!isRegistered) return null;
  return Get.find<TutoringFilterController>();
}

TutoringFilterController ensureTutoringFilterController({
  bool permanent = false,
}) {
  final existing = maybeFindTutoringFilterController();
  if (existing != null) return existing;
  return Get.put(TutoringFilterController(), permanent: permanent);
}
