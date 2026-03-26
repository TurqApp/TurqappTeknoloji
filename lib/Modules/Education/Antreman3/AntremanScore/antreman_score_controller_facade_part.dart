part of 'antreman_score_controller_library.dart';

AntremanScoreController ensureAntremanScoreController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindAntremanScoreController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    AntremanScoreController(),
    tag: tag,
    permanent: permanent,
  );
}

AntremanScoreController? maybeFindAntremanScoreController({String? tag}) {
  final isRegistered = Get.isRegistered<AntremanScoreController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<AntremanScoreController>(tag: tag);
}
