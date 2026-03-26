part of 'results_and_answers.dart';

SpeedometerController ensureSpeedometerController(
  double targetValue, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSpeedometerController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SpeedometerController(targetValue),
    tag: tag,
    permanent: permanent,
  );
}

SpeedometerController? maybeFindSpeedometerController({String? tag}) {
  final isRegistered = Get.isRegistered<SpeedometerController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SpeedometerController>(tag: tag);
}
