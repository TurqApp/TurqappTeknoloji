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
    final prefs = await SharedPreferences.getInstance();
    final draftsJson = _drafts.map((draft) => draft.toJson()).toList();
    await prefs.setString(_activeDraftsKey, jsonEncode(draftsJson));
  }

  Future<void> _loadDraftsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final draftsString = prefs.getString(_activeDraftsKey);

    _drafts.clear();
    if (draftsString != null) {
      try {
        final draftsJson = jsonDecode(draftsString);
        if (draftsJson is! List) {
          await prefs.remove(_activeDraftsKey);
          return;
        }
        _drafts.assignAll(
          draftsJson.map((item) => PostDraft.fromJson(item)).toList(),
        );
      } catch (_) {
        await prefs.remove(_activeDraftsKey);
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _autoSaveEnabled.value = prefs.getBool(DraftService._autoSaveKey) ?? true;
    _autoSaveInterval.value = prefs.getInt('auto_save_interval') ?? 30;
  }
}
