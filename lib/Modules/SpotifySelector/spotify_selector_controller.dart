import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/audio_focus_coordinator.dart';
import 'package:turqappv2/Core/Services/story_music_library_service.dart';
import 'package:turqappv2/Models/music_model.dart';

class SpotifySelectorController extends GetxController {
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

  List<MusicModel> get forYouTracks {
    final filtered = _applyQuery(library);
    final saved =
        filtered.where((e) => savedTrackIds.contains(e.docID)).toList();
    final popular = filtered
        .where((e) => !savedTrackIds.contains(e.docID))
        .toList()
      ..sort(_byPopularity);
    return _sliceVisible([...saved, ...popular]);
  }

  List<MusicModel> get popularTracks {
    final filtered = _applyQuery(library).toList(growable: true)
      ..sort(_byPopularity);
    return _sliceVisible(filtered);
  }

  List<MusicModel> get allTracks {
    final filtered = _applyQuery(library).toList(growable: true)
      ..sort(_byPopularity);
    return _sliceVisible(filtered);
  }

  List<MusicModel> get savedTracks {
    final filtered = _applyQuery(library)
        .where((track) => savedTrackIds.contains(track.docID))
        .toList(growable: true)
      ..sort((a, b) {
        final byPopularity = _byPopularity(a, b);
        if (byPopularity != 0) return byPopularity;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
    return _sliceVisible(filtered);
  }

  MusicModel? get currentTrack {
    final currentUrl = currentPlayingUrl.value.trim();
    if (currentUrl.isEmpty) return null;
    for (final track in library) {
      if (track.audioUrl == currentUrl) {
        return track;
      }
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    AudioFocusCoordinator.instance.registerAudioPlayer(_audioPlayer);
    _audioPlayer.onPlayerComplete.listen((_) {
      currentPlayingUrl.value = '';
    });
    searchController.addListener(() {
      query.value = searchController.text.trim();
      _resetVisibleCount();
    });
    scrollController.addListener(_handleScroll);
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    isLoading.value = true;
    try {
      final tracks = await StoryMusicLibraryService.instance.fetchTracks(
        limit: 100,
        forceRemote: true,
      );
      final saved =
          await StoryMusicLibraryService.instance.fetchSavedMusicIds();
      library.assignAll(tracks);
      savedTrackIds
        ..clear()
        ..addAll(saved);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playMusic(MusicModel track) async {
    final url = track.audioUrl.trim();
    if (url.isEmpty) return;
    if (currentPlayingUrl.value == url) {
      await _audioPlayer.pause();
      currentPlayingUrl.value = '';
      return;
    }

    await _audioPlayer.stop();
    await AudioFocusCoordinator.instance.requestAudioPlayerPlay(_audioPlayer);
    final playablePath =
        await StoryMusicLibraryService.instance.resolvePlayablePath(url);
    if (playablePath.isNotEmpty) {
      await _audioPlayer.play(DeviceFileSource(playablePath));
    } else {
      await _audioPlayer.play(UrlSource(url));
    }
    currentPlayingUrl.value = url;
    unawaited(StoryMusicLibraryService.instance.warmTrack(track));
  }

  Future<void> toggleSaved(MusicModel track) async {
    final saved =
        await StoryMusicLibraryService.instance.toggleSavedMusic(track);
    if (saved) {
      savedTrackIds.add(track.docID);
    } else {
      savedTrackIds.remove(track.docID);
    }
    savedTrackIds.refresh();
  }

  List<MusicModel> currentTabTracks() {
    switch (selectedTab.value) {
      case 0:
        return forYouTracks;
      case 1:
        return popularTracks;
      case 2:
        return allTracks;
      case 3:
        return savedTracks;
      default:
        return allTracks;
    }
  }

  void goToPage(int index) {
    selectedTab.value = index;
    _resetVisibleCount();
  }

  bool get hasMoreForCurrentTab {
    final total = _allTracksForCurrentTab().length;
    return visibleCount.value < total;
  }

  void loadMore() {
    if (!hasMoreForCurrentTab) return;
    visibleCount.value += 20;
  }

  List<MusicModel> _applyQuery(List<MusicModel> source) {
    final q = query.value.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((track) {
      final haystack = [
        track.title,
        track.artist,
        track.category,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList(growable: false);
  }

  List<MusicModel> _sliceVisible(List<MusicModel> tracks) {
    final limit = visibleCount.value;
    if (tracks.length <= limit) return tracks;
    return tracks.take(limit).toList(growable: false);
  }

  List<MusicModel> _allTracksForCurrentTab() {
    switch (selectedTab.value) {
      case 0:
        final filtered = _applyQuery(library);
        final saved =
            filtered.where((e) => savedTrackIds.contains(e.docID)).toList();
        final popular = filtered
            .where((e) => !savedTrackIds.contains(e.docID))
            .toList()
          ..sort(_byPopularity);
        return [...saved, ...popular];
      case 1:
        return _applyQuery(library).toList(growable: true)..sort(_byPopularity);
      case 2:
        return _applyQuery(library).toList(growable: true)..sort(_byPopularity);
      case 3:
        return _applyQuery(library)
            .where((track) => savedTrackIds.contains(track.docID))
            .toList(growable: true)
          ..sort((a, b) {
            final byPopularity = _byPopularity(a, b);
            if (byPopularity != 0) return byPopularity;
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });
      default:
        return _applyQuery(library).toList(growable: true)..sort(_byPopularity);
    }
  }

  void _resetVisibleCount() {
    visibleCount.value = 20;
    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
  }

  void _handleScroll() {
    if (!scrollController.hasClients) return;
    if (scrollController.position.extentAfter < 240) {
      loadMore();
    }
  }

  int _byPopularity(MusicModel a, MusicModel b) {
    final aHasCover = a.coverUrl.trim().isNotEmpty;
    final bHasCover = b.coverUrl.trim().isNotEmpty;
    if (aHasCover != bHasCover) {
      return bHasCover ? 1 : -1;
    }
    final byUse = b.useCount.compareTo(a.useCount);
    if (byUse != 0) return byUse;
    final byStory = b.storyCount.compareTo(a.storyCount);
    if (byStory != 0) return byStory;
    final byOrder = a.order.compareTo(b.order);
    if (byOrder != 0) return byOrder;
    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    AudioFocusCoordinator.instance.unregisterAudioPlayer(_audioPlayer);
    _audioPlayer.dispose();
    super.onClose();
  }
}
