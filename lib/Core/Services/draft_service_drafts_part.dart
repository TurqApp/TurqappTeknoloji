part of 'draft_service_library.dart';

extension DraftServiceDraftsPart on DraftService {
  Future<String> saveDraft({
    required String text,
    required List<File> images,
    File? video,
    required String location,
    required String gif,
    required bool commentEnabled,
    required int sharePrivacy,
    DateTime? scheduledDate,
    String? existingDraftId,
  }) async {
    if (text.trim().isEmpty && images.isEmpty && video == null && gif.isEmpty) {
      return '';
    }

    final draftId =
        existingDraftId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final imagePaths = await _saveMediaFiles(images, draftId, 'images');
    final videoPath =
        video != null ? await _saveMediaFile(video, draftId, 'video') : null;

    final draft = PostDraft(
      id: draftId,
      text: text,
      imagePaths: imagePaths,
      videoPath: videoPath,
      location: location,
      gif: gif,
      commentEnabled: commentEnabled,
      sharePrivacy: sharePrivacy,
      lastModified: DateTime.now(),
      scheduledDate: scheduledDate,
    );

    final existingIndex = _drafts.indexWhere((d) => d.id == draftId);
    if (existingIndex != -1) {
      _drafts[existingIndex] = draft;
    } else {
      _drafts.add(draft);
    }

    if (_drafts.length > DraftService._maxDrafts) {
      _drafts.sort((a, b) => b.lastModified.compareTo(a.lastModified));
      final removedDrafts = _drafts.sublist(DraftService._maxDrafts);
      for (final removedDraft in removedDrafts) {
        await _cleanupDraftMedia(removedDraft);
      }
      _drafts.removeRange(DraftService._maxDrafts, _drafts.length);
    }

    await _saveDraftsToStorage();
    return draftId;
  }

  PostDraft? loadDraft(String draftId) {
    return _drafts.firstWhereOrNull((d) => d.id == draftId);
  }

  Future<void> deleteDraft(String draftId) async {
    final draft = _drafts.firstWhereOrNull((d) => d.id == draftId);
    if (draft != null) {
      await _cleanupDraftMedia(draft);
      _drafts.removeWhere((d) => d.id == draftId);
      await _saveDraftsToStorage();
    }
  }

  Future<void> clearAllDrafts() async {
    for (final draft in _drafts) {
      await _cleanupDraftMedia(draft);
    }
    _drafts.clear();
    await _saveDraftsToStorage();
  }

  List<PostDraft> getDraftsSorted() {
    final sortedDrafts = List<PostDraft>.from(_drafts);
    sortedDrafts.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return sortedDrafts;
  }

  Future<void> setAutoSaveEnabled(bool enabled) async {
    _autoSaveEnabled.value = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(DraftService._autoSaveKey, enabled);
  }

  Future<void> setAutoSaveInterval(int seconds) async {
    _autoSaveInterval.value = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_save_interval', seconds);
  }

  Map<String, dynamic> getDraftStats() {
    final now = DateTime.now();
    final today =
        _drafts.where((d) => now.difference(d.lastModified).inDays == 0).length;
    final thisWeek =
        _drafts.where((d) => now.difference(d.lastModified).inDays < 7).length;

    return {
      'total': _drafts.length,
      'today': today,
      'thisWeek': thisWeek,
      'withMedia': _drafts.where((d) => d.hasMedia).length,
      'textOnly': _drafts.where((d) => !d.hasMedia && d.text.isNotEmpty).length,
    };
  }

  Map<String, dynamic> exportDraft(String draftId) {
    final draft = loadDraft(draftId);
    if (draft == null) return {};

    return {
      'text': draft.text,
      'location': draft.location,
      'hasImages': draft.imagePaths.isNotEmpty,
      'hasVideo': draft.videoPath != null,
      'hasGif': draft.gif.isNotEmpty,
      'lastModified': draft.lastModified.toIso8601String(),
    };
  }
}
