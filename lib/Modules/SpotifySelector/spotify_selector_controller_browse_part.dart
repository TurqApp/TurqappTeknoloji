part of 'spotify_selector_controller.dart';

extension SpotifySelectorControllerBrowsePart on SpotifySelectorController {
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
    final q = normalizeSearchText(query.value);
    if (q.isEmpty) return source;
    return source.where((track) {
      final haystack = normalizeSearchText([
        track.title,
        track.artist,
        track.category,
      ].join(' '));
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
            return compareNormalizedText(a.title, b.title);
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
    return compareNormalizedText(a.title, b.title);
  }
}
