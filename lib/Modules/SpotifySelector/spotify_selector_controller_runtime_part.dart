part of 'spotify_selector_controller_library.dart';

class SpotifySelectorControllerRuntimePart {
  const SpotifySelectorControllerRuntimePart(this.controller);

  final SpotifySelectorController controller;

  void onInit() {
    AudioFocusCoordinator.instance.registerAudioPlayer(controller._audioPlayer);
    controller._audioPlayer.onPlayerComplete.listen((_) {
      controller.currentPlayingUrl.value = '';
    });
    controller.searchController.addListener(() {
      controller.query.value = controller.searchController.text.trim();
      controller._resetVisibleCount();
    });
    controller.scrollController.addListener(controller._handleScroll);
    controller._loadTracks();
  }

  Future<void> loadTracks() async {
    controller.isLoading.value = true;
    try {
      final tracks = await StoryMusicLibraryService.instance.fetchTracks(
        limit: 100,
        forceRemote: true,
      );
      final saved =
          await StoryMusicLibraryService.instance.fetchSavedMusicIds();
      controller.library.assignAll(tracks);
      controller.savedTrackIds
        ..clear()
        ..addAll(saved);
    } finally {
      controller.isLoading.value = false;
    }
  }

  Future<void> playMusic(MusicModel track) async {
    final url = track.audioUrl.trim();
    if (url.isEmpty) return;
    if (controller.currentPlayingUrl.value == url) {
      await controller._audioPlayer.pause();
      controller.currentPlayingUrl.value = '';
      return;
    }

    await controller._audioPlayer.stop();
    await AudioFocusCoordinator.instance
        .requestAudioPlayerPlay(controller._audioPlayer);
    final playablePath =
        await StoryMusicLibraryService.instance.resolvePlayablePath(url);
    if (playablePath.isNotEmpty) {
      await controller._audioPlayer.play(DeviceFileSource(playablePath));
    } else {
      await controller._audioPlayer.play(UrlSource(url));
    }
    controller.currentPlayingUrl.value = url;
    StoryMusicLibraryService.instance.warmTrack(track);
  }

  Future<void> toggleSaved(MusicModel track) async {
    final saved =
        await StoryMusicLibraryService.instance.toggleSavedMusic(track);
    if (saved) {
      controller.savedTrackIds.add(track.docID);
    } else {
      controller.savedTrackIds.remove(track.docID);
    }
    controller.savedTrackIds.refresh();
  }

  void onClose() {
    controller.scrollController.dispose();
    controller.searchController.dispose();
    AudioFocusCoordinator.instance
        .unregisterAudioPlayer(controller._audioPlayer);
    controller._audioPlayer.dispose();
  }
}

SpotifySelectorController ensureSpotifySelectorController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindSpotifySelectorController(tag: tag);
  if (existing != null) return existing;
  return Get.put(SpotifySelectorController(), tag: tag, permanent: permanent);
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
