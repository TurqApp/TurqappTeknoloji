import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/music_model.dart';

part 'spotify_selector_controller_browse_part.dart';
part 'spotify_selector_controller_runtime_part.dart';

class SpotifySelectorController extends GetxController {
  static SpotifySelectorController ensure({String? tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(SpotifySelectorController(), tag: tag);
  }

  static SpotifySelectorController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SpotifySelectorController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SpotifySelectorController>(tag: tag);
  }

  final RxList<MusicModel> library = <MusicModel>[].obs;
  final RxSet<String> savedTrackIds = <String>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString currentPlayingUrl = ''.obs;
  final RxInt selectedTab = 0.obs;
  final RxString query = ''.obs;
  final RxInt visibleCount = 20.obs;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    SpotifySelectorControllerRuntimePart(this).onInit();
  }

  Future<void> _loadTracks() =>
      SpotifySelectorControllerRuntimePart(this).loadTracks();

  Future<void> playMusic(MusicModel track) =>
      SpotifySelectorControllerRuntimePart(this).playMusic(track);

  Future<void> toggleSaved(MusicModel track) =>
      SpotifySelectorControllerRuntimePart(this).toggleSaved(track);

  @override
  void onClose() {
    SpotifySelectorControllerRuntimePart(this).onClose();
    super.onClose();
  }
}
