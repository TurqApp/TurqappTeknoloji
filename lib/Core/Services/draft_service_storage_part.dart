part of 'draft_service_library.dart';

extension DraftServiceStoragePart on DraftService {
  Future<List<String>> _saveMediaFiles(
    List<File> files,
    String draftId,
    String type,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final draftDir = Directory(p.join(appDir.path, 'drafts', draftId, type));

    if (!await draftDir.exists()) {
      await draftDir.create(recursive: true);
    }

    final savedPaths = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final extension = p.extension(file.path);
      final targetPath = p.join(draftDir.path, '$i$extension');
      await file.copy(targetPath);
      savedPaths.add(targetPath);
    }

    return savedPaths;
  }

  Future<String> _saveMediaFile(File file, String draftId, String type) async {
    final appDir = await getApplicationDocumentsDirectory();
    final draftDir = Directory(p.join(appDir.path, 'drafts', draftId, type));

    if (!await draftDir.exists()) {
      await draftDir.create(recursive: true);
    }

    final extension = p.extension(file.path);
    final targetPath = p.join(draftDir.path, 'media$extension');
    await file.copy(targetPath);
    return targetPath;
  }

  Future<void> _cleanupDraftMedia(PostDraft draft) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final draftDir = Directory(p.join(appDir.path, 'drafts', draft.id));
      if (await draftDir.exists()) {
        await draftDir.delete(recursive: true);
      }
    } catch (_) {}
  }

  Future<void> _saveDraftsToStorage() async {
    final preferences = ensureLocalPreferenceRepository();
    final draftsJson = _drafts.map((draft) => draft.toJson()).toList();
    await preferences.setString(_activeDraftsKey, jsonEncode(draftsJson));
  }

  Future<void> _loadDraftsFromStorage() async {
    final preferences = ensureLocalPreferenceRepository();
    final draftsString = await preferences.getString(_activeDraftsKey);

    _drafts.clear();
    if (draftsString != null) {
      try {
        final decoded = jsonDecode(draftsString);
        if (decoded is! List) {
          await preferences.remove(_activeDraftsKey);
          return;
        }
        var shouldPrune = false;
        final restored = <PostDraft>[];
        for (final item in decoded) {
          if (item is! Map) {
            shouldPrune = true;
            continue;
          }
          try {
            restored.add(
              PostDraft.fromJson(
                Map<String, dynamic>.from(item.cast<dynamic, dynamic>()),
              ),
            );
          } catch (_) {
            shouldPrune = true;
          }
        }
        _drafts.assignAll(restored);
        if (shouldPrune) {
          await _saveDraftsToStorage();
        }
      } catch (_) {
        await preferences.remove(_activeDraftsKey);
      }
    }
  }

  Future<void> _loadSettings() async {
    final preferences = ensureLocalPreferenceRepository();
    _autoSaveEnabled.value =
        await preferences.getBool(DraftService._autoSaveKey) ?? true;
    _autoSaveInterval.value =
        await preferences.getInt('auto_save_interval') ?? 30;
  }
}
