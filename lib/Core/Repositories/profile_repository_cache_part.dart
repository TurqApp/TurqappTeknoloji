part of 'profile_repository_library.dart';

extension ProfileRepositoryCachePart on ProfileRepository {
  static const String _archiveKeyPrefix = 'profile_archive_cache_v1';

  Duration get _archiveTtl =>
      MetadataCachePolicy.ttlFor(MetadataCacheBucket.profilePostsBucket);

  int _archiveAsInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final trimmed = value.trim();
      final parsed = int.tryParse(trimmed);
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(trimmed);
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  String _archiveAsTrimmedString(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  String _archiveKey(String uid) => '$_archiveKeyPrefix::$uid';

  Future<SharedPreferences> _archivePrefsInstance() async {
    return SharedPreferences.getInstance();
  }

  List<PostsModel> _decodeArchiveItems(dynamic rawItems) {
    if (rawItems is! List) return const <PostsModel>[];
    return rawItems
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item.cast<dynamic, dynamic>());
          final docId = _archiveAsTrimmedString(map['docID']);
          final data = map['data'];
          if (docId.isEmpty || data is! Map) return null;
          try {
            return PostsModel.fromMap(
              Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
              docId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PostsModel>()
        .toList(growable: false);
  }

  Future<List<PostsModel>> _readArchiveFromPrefs(String uid) async {
    if (uid.isEmpty) return const <PostsModel>[];
    final key = _archiveKey(uid);
    try {
      final prefs = await _archivePrefsInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return const <PostsModel>[];

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(key);
        return const <PostsModel>[];
      }

      final fetchedAtMs = _archiveAsInt(decoded['fetchedAt']);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (fetchedAtMs <= 0 ||
          (nowMs - fetchedAtMs) > _archiveTtl.inMilliseconds) {
        await prefs.remove(key);
        return const <PostsModel>[];
      }

      final out = _decodeArchiveItems(decoded['items']);
      if (out.isEmpty) {
        await prefs.remove(key);
      }
      return out;
    } catch (_) {
      try {
        final prefs = await _archivePrefsInstance();
        await prefs.remove(key);
      } catch (_) {}
      return const <PostsModel>[];
    }
  }

  Future<void> _writeArchiveToPrefs(String uid, List<PostsModel> posts) async {
    if (uid.isEmpty) return;
    try {
      final prefs = await _archivePrefsInstance();
      final payload = <String, dynamic>{
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        'items': posts
            .map(
              (post) => <String, dynamic>{
                'docID': _archiveAsTrimmedString(post.docID),
                'data': post.toMap(),
              },
            )
            .toList(growable: false),
      };
      await prefs.setString(_archiveKey(uid), jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> _removePostFromArchivePrefs({
    required String uid,
    required String docId,
  }) async {
    if (uid.isEmpty || docId.isEmpty) return;
    final key = _archiveKey(uid);
    try {
      final prefs = await _archivePrefsInstance();
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await prefs.remove(key);
        return;
      }
      final items = decoded['items'];
      if (items is! List) {
        await prefs.remove(key);
        return;
      }
      final filtered = items.where((item) {
        if (item is! Map) return false;
        return _archiveAsTrimmedString(item['docID']) != docId;
      }).toList(growable: false);
      if (filtered.isEmpty) {
        await prefs.remove(key);
        return;
      }
      decoded['items'] = filtered;
      await prefs.setString(key, jsonEncode(decoded));
    } catch (_) {}
  }

  Future<ProfileBuckets?> _readCachedBucketsImpl(String uid) async {
    if (uid.isEmpty) return null;
    final readDecision = MetadataReadPolicy.profilePosts();
    final fromMemory = _memory[uid];
    if (fromMemory != null) return fromMemory;
    if (!readDecision.readOrder.contains(MetadataReadSource.sharedPrefs)) {
      return null;
    }
    final buckets =
        await ProfilePostsSnapshotRepository.ensure().readLocalBuckets(
      userId: uid,
    );
    if (buckets == null) return null;
    _memory[uid] = buckets;
    return buckets;
  }

  Future<void> _writeBucketsImpl(String uid, ProfileBuckets buckets) async {
    if (uid.isEmpty) return;
    _memory[uid] = ProfileBuckets(
      all: List<PostsModel>.from(buckets.all),
      photos: List<PostsModel>.from(buckets.photos),
      videos: List<PostsModel>.from(buckets.videos),
      scheduled: List<PostsModel>.from(buckets.scheduled),
    );
    await ProfilePostsSnapshotRepository.ensure().writeLocalBuckets(
      userId: uid,
      buckets: buckets,
      source: CachedResourceSource.scopedDisk,
    );
  }

  Future<void> _removePostFromCachesImpl({
    required String uid,
    required String docId,
  }) async {
    if (uid.isEmpty || docId.isEmpty) return;

    final buckets = _memory[uid];
    if (buckets != null) {
      _memory[uid] = ProfileBuckets(
        all: buckets.all.where((post) => post.docID != docId).toList(),
        photos: buckets.photos.where((post) => post.docID != docId).toList(),
        videos: buckets.videos.where((post) => post.docID != docId).toList(),
        scheduled:
            buckets.scheduled.where((post) => post.docID != docId).toList(),
      );
    }

    final archive = _archiveMemory[uid];
    if (archive != null) {
      _archiveMemory[uid] =
          archive.where((post) => post.docID != docId).toList();
    }

    if (_latestPostMemory[uid]?.docID == docId) {
      _latestPostMemory.remove(uid);
    }
    if (_latestResharePostMemory[uid]?.docID == docId) {
      _latestResharePostMemory.remove(uid);
    }

    await Future.wait(<Future<void>>[
      ProfilePostsSnapshotRepository.ensure().removePostLocally(
        userId: uid,
        docId: docId,
      ),
      _removePostFromArchivePrefs(uid: uid, docId: docId),
    ]);
  }

  Future<List<PostsModel>> _readCachedArchiveImpl(String uid) async {
    if (uid.isEmpty) return const <PostsModel>[];
    final fromMemory = _archiveMemory[uid];
    if (fromMemory != null) return List<PostsModel>.from(fromMemory);
    final archive = await _readArchiveFromPrefs(uid);
    if (archive.isEmpty) return const <PostsModel>[];
    _archiveMemory[uid] = List<PostsModel>.from(archive);
    return archive;
  }

  Future<void> _writeArchiveImpl(String uid, List<PostsModel> posts) async {
    if (uid.isEmpty) return;
    _archiveMemory[uid] = List<PostsModel>.from(posts);
    await _writeArchiveToPrefs(uid, posts);
  }

  Future<void> _clearUserImpl(String uid) async {
    _memory.remove(uid);
    _archiveMemory.remove(uid);
    _latestPostMemory.remove(uid);
    _latestResharePostMemory.remove(uid);
    await Future.wait(<Future<void>>[
      ProfilePostsSnapshotRepository.ensure().clearLocalUser(userId: uid),
      (() async {
        final prefs = await _archivePrefsInstance();
        await prefs.remove(_archiveKey(uid));
      })(),
    ]);
  }
}
