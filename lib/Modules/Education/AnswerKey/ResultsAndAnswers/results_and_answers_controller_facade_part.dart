part of 'results_and_answers_controller.dart';

ResultsAndAnswersController _ensureResultsAndAnswersController(
  OpticalFormModel model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindResultsAndAnswersController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ResultsAndAnswersController(model),
    tag: tag,
    permanent: permanent,
  );
}

ResultsAndAnswersController? _maybeFindResultsAndAnswersController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<ResultsAndAnswersController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ResultsAndAnswersController>(tag: tag);
}
