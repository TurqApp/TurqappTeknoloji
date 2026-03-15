import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Modules/SpotifySelector/spotify_selector.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:video_player/video_player.dart';

import 'drawing_screen.dart';

part 'story_maker_controller_media_part.dart';
part 'story_maker_controller_elements_part.dart';
part 'story_maker_controller_save_part.dart';

enum StoryElementType {
  video,
  image,
  text,
  sticker,
  gif,
  drawing,
}

class StoryElement {
  final String id;
  StoryElementType type;
  String content;
  double width;
  double height;
  Offset position;
  double rotation;
  int zIndex;
  bool isMuted;
  double fontSize;
  double aspectRatio;
  int textColor;
  int textBgColor;
  bool hasTextBg;
  String textAlign;
  String fontWeight;
  bool italic;
  bool underline;
  double shadowBlur;
  double shadowOpacity;
  String fontFamily;
  bool hasOutline;
  int outlineColor;
  String stickerType;
  String stickerData;
  String mediaLookPreset;
  Offset? initialFocalPoint;
  Offset? initialPosition;
  double? initialWidth;
  double? initialHeight;
  double? initialRotation;
  double? initialFontSize;

  StoryElement({
    String? id,
    required this.type,
    required this.content,
    required this.width,
    required this.height,
    required this.position,
    this.rotation = 0,
    this.zIndex = 0,
    this.isMuted = false,
    this.fontSize = 20,
    this.aspectRatio = 1.0,
    this.textColor = 0xFFFFFFFF,
    this.textBgColor = 0x66000000,
    this.hasTextBg = false,
    this.textAlign = 'center',
    this.fontWeight = 'regular',
    this.italic = false,
    this.underline = false,
    this.shadowBlur = 2.0,
    this.shadowOpacity = 0.6,
    this.fontFamily = 'MontserratMedium',
    this.hasOutline = false,
    this.outlineColor = 0xFF000000,
    this.stickerType = '',
    this.stickerData = '',
    this.mediaLookPreset = 'original',
    this.initialFocalPoint,
    this.initialPosition,
    this.initialWidth,
    this.initialHeight,
    this.initialRotation,
    this.initialFontSize,
  }) : id = id ?? _generateId();

  static String _generateId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart =
        List.generate(5, (_) => random.nextInt(36).toRadixString(36)).join();
    return 'element_$timestamp$randomPart';
  }
}

class StoryMakerController extends GetxController {
  static const List<String> supportedMediaLookPresets = <String>[
    'original',
    'clear',
    'cinema',
    'vibe',
  ];
  static const double _topBarHeight = 60.0;
  static const double _bottomToolsHeight = 80.0;
  static const double _mediaLookToolsHeight = 88.0;

  final Rx<Color> color = Colors.transparent.obs;
  RxList<StoryElement> elements = <StoryElement>[].obs;
  var music = "".obs;
  final Rxn<MusicModel> selectedMusic = Rxn<MusicModel>();

  RxBool isDragging = false.obs;
  StoryElement? draggedElement;
  RxBool isElementOverTrash = false.obs;
  Offset? lastFingerPosition;
  final List<Color> colorOptions = [
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

  int _colorIndex = 0;
  int _zIndexCounter = 0;
  String _sharedPostSeedFingerprint = '';

  final List<List<StoryElement>> _history = [];
  int _historyIndex = -1;
  final int _maxHistorySize = 20;

  RxBool canUndo = false.obs;
  RxBool canRedo = false.obs;

  static RxBool isUploadingStory = false.obs;

  final AudioPlayer _audioPlayer = AudioPlayer();
  var isMusicPlaying = false.obs;

  StoryMakerController() {
    try {
      _audioPlayer.setAudioContext(
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

  @override
  void onInit() {
    super.onInit();
    AudioFocusCoordinator.instance.registerAudioPlayer(_audioPlayer);
    _saveState();
  }

  @override
  void onClose() {
    AudioFocusCoordinator.instance.unregisterAudioPlayer(_audioPlayer);
    try {
      if (_audioPlayer.state != PlayerState.disposed) {
        _audioPlayer.stop().then((_) {
          _audioPlayer.dispose();
        }).catchError((e) {
          print("AudioPlayer dispose error (ignored): $e");
          try {
            _audioPlayer.dispose();
          } catch (disposeError) {
            print("AudioPlayer final dispose error (ignored): $disposeError");
          }
        });
      }
    } catch (e) {
      print("AudioPlayer onClose error (ignored): $e");
    }

    elements.clear();
    music.value = "";
    selectedMusic.value = null;
    color.value = Colors.transparent;
    _colorIndex = 0;
    _zIndexCounter = 0;
    _sharedPostSeedFingerprint = '';
    _history.clear();
    _historyIndex = -1;
    canUndo.value = false;
    canRedo.value = false;
    super.onClose();
  }

  void changeCircleColor() {
    color.value = colorOptions[_colorIndex];
    _colorIndex = (_colorIndex + 1) % colorOptions.length;
  }

  StoryElement? get currentBackgroundMediaElement {
    final media = elements.where((e) =>
        e.type == StoryElementType.image || e.type == StoryElementType.video);
    if (media.isEmpty) return null;
    final sorted = media.toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    return sorted.first;
  }

  void setCurrentMediaLookPreset(String preset) {
    if (!supportedMediaLookPresets.contains(preset)) return;
    final target = currentBackgroundMediaElement;
    if (target == null || target.mediaLookPreset == preset) return;
    _saveState();
    target.mediaLookPreset = preset;
    elements.refresh();
  }

  double _availablePlaygroundHeight({bool includeMediaLookTools = true}) {
    final screenH = Get.height;
    final topSafeArea = Get.mediaQuery.padding.top;
    final reservedMediaLook = includeMediaLookTools ? _mediaLookToolsHeight : 0;
    return screenH -
        topSafeArea -
        _topBarHeight -
        _bottomToolsHeight -
        reservedMediaLook;
  }
}
