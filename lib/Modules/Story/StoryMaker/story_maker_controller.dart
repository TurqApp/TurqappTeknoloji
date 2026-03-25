import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Services/upload_validation_service.dart';
import 'package:turqappv2/Core/Services/user_moderation_guard.dart';
import 'package:turqappv2/Core/Services/webp_upload_service.dart';
import 'package:turqappv2/Core/Utils/cdn_url_builder.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/music_model.dart';
import 'package:turqappv2/Modules/SpotifySelector/spotify_selector.dart';
import 'package:turqappv2/Modules/Story/StoryRow/story_row_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:video_player/video_player.dart';

import 'drawing_screen.dart';

part 'story_maker_controller_media_part.dart';
part 'story_maker_controller_elements_part.dart';
part 'story_maker_controller_models_part.dart';
part 'story_maker_controller_save_part.dart';
part 'story_maker_controller_runtime_part.dart';

class StoryMakerController extends GetxController {
  static StoryMakerController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      StoryMakerController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static StoryMakerController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<StoryMakerController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<StoryMakerController>(tag: tag);
  }

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
    _configureStoryMakerAudioPlayer(_audioPlayer);
  }

  @override
  void onInit() {
    super.onInit();
    _handleStoryMakerOnInit(this);
  }

  @override
  void onClose() {
    _handleStoryMakerOnClose(this);
    super.onClose();
  }

  double _availablePlaygroundHeight({bool includeMediaLookTools = true}) {
    return _storyMakerAvailablePlaygroundHeight(
      this,
      includeMediaLookTools: includeMediaLookTools,
    );
  }
}
