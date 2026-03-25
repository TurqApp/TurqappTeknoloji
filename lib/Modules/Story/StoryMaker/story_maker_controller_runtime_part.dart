part of 'story_maker_controller.dart';

void _configureStoryMakerAudioPlayer(AudioPlayer player) {
  try {
    player.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
      ),
    );
  } catch (_) {}
}

void _handleStoryMakerOnInit(StoryMakerController controller) {
  AudioFocusCoordinator.instance.registerAudioPlayer(controller._audioPlayer);
  controller._saveState();
}

void _handleStoryMakerOnClose(StoryMakerController controller) {
  AudioFocusCoordinator.instance.unregisterAudioPlayer(controller._audioPlayer);
  try {
    if (controller._audioPlayer.state != PlayerState.disposed) {
      controller._audioPlayer.stop().then((_) {
        controller._audioPlayer.dispose();
      }).catchError((e) {
        print("AudioPlayer dispose error (ignored): $e");
        try {
          controller._audioPlayer.dispose();
        } catch (disposeError) {
          print("AudioPlayer final dispose error (ignored): $disposeError");
        }
      });
    }
  } catch (e) {
    print("AudioPlayer onClose error (ignored): $e");
  }

  controller.elements.clear();
  controller.music.value = "";
  controller.selectedMusic.value = null;
  controller.color.value = Colors.transparent;
  controller._colorIndex = 0;
  controller._zIndexCounter = 0;
  controller._sharedPostSeedFingerprint = '';
  controller._history.clear();
  controller._historyIndex = -1;
  controller.canUndo.value = false;
  controller.canRedo.value = false;
}

extension StoryMakerControllerRuntimePart on StoryMakerController {
  void changeCircleColor() {
    color.value = colorOptions[_colorIndex];
    _colorIndex = (_colorIndex + 1) % colorOptions.length;
  }

  StoryElement? get currentBackgroundMediaElement {
    final media = elements.where(
      (e) =>
          e.type == StoryElementType.image || e.type == StoryElementType.video,
    );
    if (media.isEmpty) return null;
    final sorted = media.toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    return sorted.first;
  }

  void setCurrentMediaLookPreset(String preset) {
    if (!StoryMakerController.supportedMediaLookPresets.contains(preset)) {
      return;
    }
    final target = currentBackgroundMediaElement;
    if (target == null || target.mediaLookPreset == preset) return;
    _saveState();
    target.mediaLookPreset = preset;
    elements.refresh();
  }
}

double _storyMakerAvailablePlaygroundHeight(
  StoryMakerController controller, {
  bool includeMediaLookTools = true,
}) {
  final screenH = Get.height;
  final topSafeArea = Get.mediaQuery.padding.top;
  final reservedMediaLook =
      includeMediaLookTools ? StoryMakerController._mediaLookToolsHeight : 0;
  return screenH -
      topSafeArea -
      StoryMakerController._topBarHeight -
      StoryMakerController._bottomToolsHeight -
      reservedMediaLook;
}
