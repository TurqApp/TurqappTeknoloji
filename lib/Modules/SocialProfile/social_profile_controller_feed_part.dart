part of 'social_profile_controller.dart';

extension SocialProfileControllerFeedPart on SocialProfileController {
  int _performResolveResumeCenteredIndex() {
    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    if (activeLength == 0) return -1;
    final pendingIdentity = _pendingCenteredIdentity;
    if (pendingIdentity != null && pendingIdentity.isNotEmpty) {
      final pendingIndex = postSelection.value == 0
          ? combinedFeedEntries.indexWhere((entry) {
              final entryDocId = ((entry['docID'] as String?) ?? '').trim();
              final entryIsReshare = entry['isReshare'] == true;
              return combinedEntryIdentity(
                    docId: entryDocId,
                    isReshare: entryIsReshare,
                  ) ==
                  pendingIdentity;
            })
          : allPosts
              .indexWhere((post) => 'post_${post.docID}' == pendingIdentity);
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < activeLength) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < activeLength) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _performResumeCenteredPost() {
    final activeCombinedEntries = postSelection.value == 0
        ? combinedFeedEntries
        : const <Map<String, dynamic>>[];
    final activeLength = postSelection.value == 0
        ? activeCombinedEntries.length
        : allPosts.length;
    final expectedDocId = (lastCenteredIndex != null &&
            lastCenteredIndex! >= 0 &&
            lastCenteredIndex! < activeLength)
        ? postSelection.value == 0
            ? ((activeCombinedEntries[lastCenteredIndex!]['docID']
                    as String?) ??
                '')
            : allPosts[lastCenteredIndex!].docID
        : null;
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= activeLength) return;
    lastCenteredIndex = target;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    capturePendingCenteredEntry(preferredIndex: target);
    _invariantGuard.assertCenteredSelection(
      surface: 'social_profile',
      invariantKey: 'resume_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: postSelection.value == 0
          ? activeCombinedEntries
              .map((entry) => ((entry['docID'] as String?) ?? ''))
              .toList(growable: false)
          : allPosts.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );
  }

  void _performCapturePendingCenteredEntry({
    int? preferredIndex,
    PostsModel? model,
    bool isReshare = false,
  }) {
    if (model != null) {
      final docId = model.docID.trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = postSelection.value == 0
          ? combinedEntryIdentity(docId: docId, isReshare: isReshare)
          : 'post_$docId';
      return;
    }

    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= activeLength) {
      _pendingCenteredIdentity = null;
      return;
    }

    if (postSelection.value == 0) {
      final entry = combinedFeedEntries[candidateIndex];
      final docId = ((entry['docID'] as String?) ?? '').trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = combinedEntryIdentity(
        docId: docId,
        isReshare: entry['isReshare'] == true,
      );
      return;
    }

    final docId = allPosts[candidateIndex].docID.trim();
    _pendingCenteredIdentity = docId.isEmpty ? null : 'post_$docId';
  }

  Future<void> _performGetPosts({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial);
  }

  Future<void> _performGetPhotos({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial);
  }

  Future<void> _performSetPostSelection(int index) async {
    postSelection.value = index;
    UserAnalyticsService.instance
        .trackFeatureUsage('social_profile_tab_$index');
    if (index == 5) {
      if (scheduledPosts.isEmpty || lastScheduledDoc == null) {
        await fetchScheduledPosts(initial: true);
      }
    }
  }

  String _performCombinedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) {
    return '${isReshare ? 'reshare' : 'post'}_$docId';
  }

  List<Map<String, dynamic>> _performCombinedFeedEntries() {
    final combinedPosts = <Map<String, dynamic>>[];

    for (final post in allPosts) {
      combinedPosts.add(<String, dynamic>{
        'docID': post.docID,
        'post': post,
        'isReshare': false,
        'timestamp': post.timeStamp,
      });
    }

    for (final reshare in reshares) {
      combinedPosts.add(<String, dynamic>{
        'docID': reshare.docID,
        'post': reshare,
        'isReshare': true,
        'timestamp': reshare.timeStamp,
      });
    }

    combinedPosts.sort(
      (a, b) => (b['timestamp'] as num).compareTo(a['timestamp'] as num),
    );
    return combinedPosts;
  }

  int _performIndexOfCombinedEntry({
    required String docId,
    required bool isReshare,
  }) {
    final identity = combinedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return combinedFeedEntries.indexWhere((entry) {
      final entryDocId = ((entry['docID'] as String?) ?? '').trim();
      final entryIsReshare = entry['isReshare'] == true;
      return combinedEntryIdentity(
            docId: entryDocId,
            isReshare: entryIsReshare,
          ) ==
          identity;
    });
  }

  String _performAgendaInstanceTag({
    required String docId,
    required bool isReshare,
  }) {
    return 'social_${isReshare ? 'reshare' : 'post'}_$docId';
  }

  Future<void> _performFetchScheduledPosts({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial);
  }

  Future<void> _performRefreshAll() async {
    try {
      await getCounters();
      await getUserData();
      await getSocialMediaLinks();

      _lastPrimaryDoc = null;
      _hasMorePrimary = true;

      await Future.wait([
        _fetchPrimaryBuckets(initial: true, force: true),
        getReshares(),
      ]);
    } catch (e) {
      print('SocialProfile.refreshAll error: $e');
    }
  }

  Future<void> _performDisposeAgendaContentController(String docID) async {
    final tags = <String>{
      agendaInstanceTag(docId: docID, isReshare: false),
      agendaInstanceTag(docId: docID, isReshare: true),
    };
    for (final tag in tags) {
      if (AgendaContentController.maybeFind(tag: tag) != null) {
        Get.delete<AgendaContentController>(tag: tag, force: true);
      }
    }
  }

  Future<void> _performRestoreCachedBuckets() async {
    final buckets = await _profileRepository.readCachedBuckets(userID);
    if (buckets == null) return;
    if (buckets.all.isNotEmpty) {
      allPosts.assignAll(buckets.all);
    }
    if (buckets.photos.isNotEmpty) {
      photos.assignAll(buckets.photos);
    }
    if (buckets.scheduled.isNotEmpty) {
      scheduledPosts.assignAll(buckets.scheduled);
    }
  }

  Future<void> _performFetchPrimaryBuckets({
    required bool initial,
    bool force = false,
  }) async {
    if (_isLoadingPrimary && !force) return;
    if (!initial && !_hasMorePrimary) return;

    _isLoadingPrimary = true;
    isLoadingPosts.value = true;
    isLoadingPhoto.value = true;
    isLoadingScheduled.value = true;
    try {
      if (initial) {
        _lastPrimaryDoc = null;
        _hasMorePrimary = true;
      }

      final page = await PerformanceService.traceFeedLoad(
        () => _profileRepository.fetchPrimaryPage(
          uid: userID,
          startAfter: initial ? null : _lastPrimaryDoc,
          limit: pageSize,
        ),
        postCount: allPosts.length,
        feedMode: 'profile_primary',
      );

      if (initial) {
        allPosts.assignAll(page.all);
        photos.assignAll(page.photos);
        scheduledPosts.assignAll(page.scheduled);
      } else {
        allPosts.addAll(_dedupePosts(allPosts, page.all));
        photos.addAll(_dedupePosts(photos, page.photos));
        scheduledPosts.addAll(_dedupePosts(scheduledPosts, page.scheduled));
      }

      _lastPrimaryDoc = page.lastDoc;
      _hasMorePrimary = page.hasMore;
      lastPostDoc = _lastPrimaryDoc;
      lastPostDocPhoto = _lastPrimaryDoc;
      lastScheduledDoc = _lastPrimaryDoc;
      hasMorePosts.value = _hasMorePrimary;
      hasMorePhoto.value = _hasMorePrimary;
      hasMoreScheduled.value = _hasMorePrimary;

      await _profileRepository.writeBuckets(
        userID,
        ProfileBuckets(
          all: allPosts,
          photos: photos,
          videos: allPosts.where((post) => post.hasPlayableVideo).toList(),
          scheduled: scheduledPosts,
        ),
      );
    } catch (e) {
      print('_fetchPrimaryBuckets(SocialProfile) error: $e');
    } finally {
      _isLoadingPrimary = false;
      isLoadingPosts.value = false;
      isLoadingPhoto.value = false;
      isLoadingScheduled.value = false;
    }
  }

  List<PostsModel> _performDedupePosts(
    List<PostsModel> existing,
    List<PostsModel> incoming,
  ) {
    final known = existing.map((e) => e.docID).toSet();
    return incoming.where((post) => known.add(post.docID)).toList();
  }
}
