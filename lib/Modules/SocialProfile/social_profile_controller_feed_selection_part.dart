part of 'social_profile_controller.dart';

extension SocialProfileControllerFeedSelectionPart on SocialProfileController {
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
}
