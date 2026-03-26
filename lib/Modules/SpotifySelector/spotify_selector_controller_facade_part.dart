part of 'spotify_selector_controller_library.dart';

SpotifySelectorController ensureSpotifySelectorController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSpotifySelectorController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SpotifySelectorController(),
    tag: tag,
    permanent: permanent,
  );
}

SpotifySelectorController? maybeFindSpotifySelectorController({String? tag}) {
  final isRegistered = Get.isRegistered<SpotifySelectorController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SpotifySelectorController>(tag: tag);
}

extension SpotifySelectorControllerFacadePart on SpotifySelectorController {
  Future<void> _loadTracks() =>
      SpotifySelectorControllerRuntimePart(this).loadTracks();

  Future<void> playMusic(MusicModel track) =>
      SpotifySelectorControllerRuntimePart(this).playMusic(track);

  Future<void> toggleSaved(MusicModel track) =>
      SpotifySelectorControllerRuntimePart(this).toggleSaved(track);
}
