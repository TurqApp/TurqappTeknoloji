part of 'story_maker_controller.dart';

const List<String> _storyMakerSupportedMediaLookPresets = <String>[
  'original',
  'clear',
  'cinema',
  'vibe',
];
const double _storyMakerTopBarHeight = 60.0;
const double _storyMakerBottomToolsHeight = 80.0;
const double _storyMakerMediaLookToolsHeight = 88.0;
final RxBool _storyMakerIsUploadingStory = false.obs;
final List<Color> _storyMakerColorOptions = <Color>[
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.orange,
  Colors.purple,
  Colors.teal,
  Colors.amber,
  Colors.white,
  Colors.grey.withAlpha(50),
  Colors.black,
];

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
  double _availablePlaygroundHeight({bool includeMediaLookTools = true}) {
    return _storyMakerAvailablePlaygroundHeight(
      this,
      includeMediaLookTools: includeMediaLookTools,
    );
  }

  void changeCircleColor() {
    color.value = _storyMakerColorOptions[_colorIndex];
    _colorIndex = (_colorIndex + 1) % _storyMakerColorOptions.length;
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
    if (!_storyMakerSupportedMediaLookPresets.contains(preset)) {
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
      includeMediaLookTools ? _storyMakerMediaLookToolsHeight : 0;
  return screenH -
      topSafeArea -
      _storyMakerTopBarHeight -
      _storyMakerBottomToolsHeight -
      reservedMediaLook;
}
