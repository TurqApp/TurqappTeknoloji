part of 'story_repository.dart';

extension StoryRepositoryFoundationPart on StoryRepository {
  String createStoryDocumentId() {
    return AppFirestore.instance.collection('stories').doc().id;
  }

  Future<void> saveStoryData({
    required String storyId,
    required Map<String, dynamic> storyData,
  }) async {
    final normalizedStoryId = storyId.trim();
    if (normalizedStoryId.isEmpty || storyData.isEmpty) return;
    await AppFirestore.instance
        .collection('stories')
        .doc(normalizedStoryId)
        .set(storyData);
  }

  UserProfileCacheService _resolveUserCache() {
    return ensureUserProfileCacheService();
  }

  int _performAsEpochMillis(dynamic value, {required int fallback}) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is num) return value.toInt();
    if (value is String) {
      final numeric = int.tryParse(value);
      if (numeric != null) return numeric;
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    return fallback;
  }

  List<Map<String, dynamic>> _performNormalizeStoryElements(dynamic raw) {
    if (raw is! List) return const <Map<String, dynamic>>[];
    return raw.map<Map<String, dynamic>>((item) {
      if (item is Map) {
        final map = Map<String, dynamic>.from(item.cast<dynamic, dynamic>());
        final positionRaw = map['position'];
        if (positionRaw is Map) {
          map['position'] = Map<String, dynamic>.from(
            positionRaw.cast<dynamic, dynamic>(),
          );
        }
        return map;
      }
      return const <String, dynamic>{};
    }).toList(growable: false);
  }

  Future<void> _performEnsureInitialized() async {
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    if (_storyRowCacheDirectoryPath != null) return;
    final dir = await getApplicationSupportDirectory();
    final storyDir = Directory('${dir.path}/story_mini_cache');
    if (!await storyDir.exists()) {
      await storyDir.create(recursive: true);
    }
    _storyRowCacheDirectoryPath = storyDir.path;
  }

  String? _performStoryRowCachePathForOwner(String ownerUid) {
    final dir = _storyRowCacheDirectoryPath;
    final normalizedUid = ownerUid.trim();
    if (dir == null || normalizedUid.isEmpty) return null;
    return '$dir/story_row_v2_$normalizedUid.json';
  }
}

DateTime _storyRepositoryResolveStoryExpiryCutoff() {
  return DateTime.now().subtract(const Duration(hours: 24));
}
