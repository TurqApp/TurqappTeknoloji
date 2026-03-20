import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/music_model.dart';

class StoryMusicLibraryService {
  StoryMusicLibraryService._();

  static final StoryMusicLibraryService instance =
      StoryMusicLibraryService._();

  static const String _cacheKey = 'storyMusic.library.v1';
  static const String _cacheTimeKey = 'storyMusic.library.updatedAt.v1';
  static const Duration _cacheTtl = Duration(days: 7);
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseFirestore.instance.collection('storyMusic');

  Future<List<MusicModel>> fetchTracks({
    int limit = 20,
    bool forceRemote = false,
  }) async {
    if (!forceRemote) {
      final cached = await _loadCache();
      if (cached.isNotEmpty) {
        unawaited(_warmTopCache(limit: 100));
        return _sortAndLimit(cached, limit);
      }
    }

    final remote = await _fetchRemote();
    if (remote.isNotEmpty) {
      await _persistCache(remote);
      unawaited(_warmTopCache(limit: 100));
      return _sortAndLimit(remote, limit);
    }

    final cached = await _loadCache(ignoreTtl: true);
    if (cached.isNotEmpty) {
      unawaited(_warmTopCache(limit: 100));
      return _sortAndLimit(cached, limit);
    }

    return const <MusicModel>[];
  }

  Future<List<MusicModel>> fetchAdminTracks({
    bool preferCache = true,
    bool forceRemote = false,
  }) async {
    if (preferCache && !forceRemote) {
      final cached = await _loadCache(ignoreTtl: true);
      if (cached.isNotEmpty) {
        return cached.toList(growable: true)
          ..sort((a, b) {
            final byOrder = a.order.compareTo(b.order);
            if (byOrder != 0) return byOrder;
            return compareNormalizedText(a.title, b.title);
          });
      }
    }

    try {
      final snap = await _collection.orderBy('order').get();
      final items = snap.docs
          .map((doc) => MusicModel.fromMap(doc.data(), doc.id))
          .toList(growable: true);
      if (items.isNotEmpty) {
        await _persistCache(items);
      }
      return items;
    } catch (_) {
      final cached = await _loadCache(ignoreTtl: true);
      return cached.toList(growable: true)
        ..sort((a, b) {
          final byOrder = a.order.compareTo(b.order);
          if (byOrder != 0) return byOrder;
          return compareNormalizedText(a.title, b.title);
        });
    }
  }

  Future<int> fetchNextOrder() async {
    try {
      final tracks = await fetchAdminTracks(preferCache: true);
      if (tracks.isEmpty) return 1;
      return tracks
              .map((e) => e.order)
              .fold<int>(0, (max, value) => value > max ? value : max) +
          1;
    } catch (_) {
      return 1;
    }
  }

  Future<void> incrementUseCount(MusicModel track) async {
    if (track.docID.trim().isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection.doc(track.docID).set({
        'title': track.title,
        'artist': track.artist,
        'audioUrl': track.audioUrl,
        'coverUrl': track.coverUrl,
        'durationMs': track.durationMs,
        'category': track.category,
        'order': track.order,
        'isActive': true,
        'useCount': FieldValue.increment(1),
        'shareCount': track.shareCount,
        'storyCount': track.storyCount,
        'lastUsedAt': now,
      }, SetOptions(merge: true));
    } catch (_) {}

    final cached = await _loadCache(ignoreTtl: true);
    if (cached.isEmpty) return;
    final index = cached.indexWhere((e) => e.docID == track.docID);
    if (index == -1) return;
    final current = cached[index];
    cached[index] = MusicModel(
      docID: current.docID,
      title: current.title,
      artist: current.artist,
      audioUrl: current.audioUrl,
      coverUrl: current.coverUrl,
      durationMs: current.durationMs,
      useCount: current.useCount + 1,
      shareCount: current.shareCount,
      storyCount: current.storyCount,
      order: current.order,
      lastUsedAt: now,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      isActive: current.isActive,
      category: current.category,
    );
    await _persistCache(cached);
  }

  Future<MusicModel?> fetchTrackById(
    String musicId, {
    bool preferCache = true,
  }) async {
    final cleanId = musicId.trim();
    if (cleanId.isEmpty) return null;

    if (preferCache) {
      final cached = await _loadCache(ignoreTtl: true);
      for (final track in cached) {
        if (track.docID == cleanId) {
          return track;
        }
      }
    }

    try {
      final doc = await _collection.doc(cleanId).get();
      if (!doc.exists) return null;
      return MusicModel.fromMap(doc.data() ?? const <String, dynamic>{}, doc.id);
    } catch (_) {
      return null;
    }
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> fetchStoryLinks(
    String musicId, {
    int limit = 50,
  }) async {
    final cleanId = musicId.trim();
    if (cleanId.isEmpty) return const [];
    try {
      final snap = await _collection
          .doc(cleanId)
          .collection('stories')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs;
    } catch (_) {
      return const [];
    }
  }

  Future<Set<String>> fetchSavedMusicIds() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return <String>{};
    try {
      final entries = await _userSubcollectionRepository.getEntries(
        uid,
        subcollection: 'savedMusic',
        orderByField: 'savedAt',
        descending: true,
        preferCache: true,
      );
      return entries.map((entry) => entry.id).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<bool> toggleSavedMusic(MusicModel track) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final cleanId = track.docID.trim();
    if (uid == null || uid.isEmpty || cleanId.isEmpty) return false;
    final existing = await _userSubcollectionRepository.getEntry(
      uid,
      subcollection: 'savedMusic',
      docId: cleanId,
      preferCache: true,
    );
    if (existing != null) {
      await _userSubcollectionRepository.deleteEntry(
        uid,
        subcollection: 'savedMusic',
        docId: cleanId,
      );
      return false;
    }
    await _userSubcollectionRepository.upsertEntry(
      uid,
      subcollection: 'savedMusic',
      docId: cleanId,
      data: {
        'musicId': cleanId,
        'title': track.title,
        'artist': track.artist,
        'audioUrl': track.audioUrl,
        'coverUrl': track.coverUrl,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      },
    );
    return true;
  }

  Future<void> recordStoryUsage({
    required MusicModel track,
    required String storyId,
    required String userId,
    required int createdAt,
  }) async {
    final cleanMusicId = track.docID.trim();
    final cleanStoryId = storyId.trim();
    final cleanUserId = userId.trim();
    if (cleanMusicId.isEmpty || cleanStoryId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection.doc(cleanMusicId).set({
        'title': track.title,
        'artist': track.artist,
        'audioUrl': track.audioUrl,
        'coverUrl': track.coverUrl,
        'durationMs': track.durationMs,
        'category': track.category,
        'order': track.order,
        'isActive': true,
        'useCount': FieldValue.increment(1),
        'storyCount': FieldValue.increment(1),
        'shareCount': track.shareCount,
        'lastUsedAt': now,
        'createdAt': track.createdAt > 0 ? track.createdAt : now,
        'updatedAt': now,
      }, SetOptions(merge: true));

      await _collection.doc(cleanMusicId).collection('stories').doc(cleanStoryId).set({
        'storyId': cleanStoryId,
        'userId': cleanUserId,
        'createdAt': createdAt,
        'musicId': cleanMusicId,
      }, SetOptions(merge: true));
    } catch (_) {}

    await _updateCachedTrack(
      cleanMusicId,
      (current) => MusicModel(
        docID: current.docID,
        title: current.title,
        artist: current.artist,
        audioUrl: current.audioUrl,
        coverUrl: current.coverUrl,
        durationMs: current.durationMs,
        useCount: current.useCount + 1,
        shareCount: current.shareCount,
        storyCount: current.storyCount + 1,
        order: current.order,
        lastUsedAt: now,
        createdAt: current.createdAt,
        updatedAt: now,
        isActive: current.isActive,
        category: current.category,
      ),
    );
  }

  Future<void> removeStoryUsage({
    required String musicId,
    required String storyId,
  }) async {
    final cleanMusicId = musicId.trim();
    final cleanStoryId = storyId.trim();
    if (cleanMusicId.isEmpty || cleanStoryId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection.doc(cleanMusicId).collection('stories').doc(cleanStoryId).delete();
      await _collection.doc(cleanMusicId).set({
        'storyCount': FieldValue.increment(-1),
        'updatedAt': now,
      }, SetOptions(merge: true));
    } catch (_) {}

    await _updateCachedTrack(
      cleanMusicId,
      (current) => MusicModel(
        docID: current.docID,
        title: current.title,
        artist: current.artist,
        audioUrl: current.audioUrl,
        coverUrl: current.coverUrl,
        durationMs: current.durationMs,
        useCount: current.useCount,
        shareCount: current.shareCount,
        storyCount: math.max(0, current.storyCount - 1),
        order: current.order,
        lastUsedAt: current.lastUsedAt,
        createdAt: current.createdAt,
        updatedAt: now,
        isActive: current.isActive,
        category: current.category,
      ),
    );
  }

  Future<void> restoreStoryUsage({
    required String musicId,
    required String storyId,
    required String userId,
    required int createdAt,
    required String title,
    required String artist,
    required String audioUrl,
    required String coverUrl,
  }) async {
    final cleanMusicId = musicId.trim();
    final cleanStoryId = storyId.trim();
    final cleanUserId = userId.trim();
    if (cleanMusicId.isEmpty || cleanStoryId.isEmpty || cleanUserId.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await _collection.doc(cleanMusicId).set({
        'title': title,
        'artist': artist,
        'audioUrl': audioUrl,
        'coverUrl': coverUrl,
        'storyCount': FieldValue.increment(1),
        'lastUsedAt': now,
        'updatedAt': now,
        'isActive': true,
      }, SetOptions(merge: true));
      await _collection.doc(cleanMusicId).collection('stories').doc(cleanStoryId).set({
        'storyId': cleanStoryId,
        'userId': cleanUserId,
        'createdAt': createdAt,
        'musicId': cleanMusicId,
      }, SetOptions(merge: true));
    } catch (_) {}

    await _updateCachedTrack(
      cleanMusicId,
      (current) => MusicModel(
        docID: current.docID,
        title: title.isNotEmpty ? title : current.title,
        artist: artist.isNotEmpty ? artist : current.artist,
        audioUrl: audioUrl.isNotEmpty ? audioUrl : current.audioUrl,
        coverUrl: coverUrl.isNotEmpty ? coverUrl : current.coverUrl,
        durationMs: current.durationMs,
        useCount: current.useCount,
        shareCount: current.shareCount,
        storyCount: current.storyCount + 1,
        order: current.order,
        lastUsedAt: now,
        createdAt: current.createdAt,
        updatedAt: now,
        isActive: true,
        category: current.category,
      ),
    );
  }

  Future<String> resolvePlayablePath(String url) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return '';

    try {
      final cached = await TurqImageCacheManager.instance.getFileFromCache(
        cleanUrl,
      );
      if (cached != null && await cached.file.exists()) {
        return cached.file.path;
      }
    } catch (_) {}

    try {
      final file = await TurqImageCacheManager.instance.getSingleFile(cleanUrl);
      return file.path;
    } catch (_) {
      return '';
    }
  }

  Future<void> warmTrack(MusicModel track) async {
    final cleanAudioUrl = track.audioUrl.trim();
    final cleanCoverUrl = track.coverUrl.trim();
    if (cleanAudioUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanAudioUrl);
      } catch (_) {}
    }
    if (cleanCoverUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanCoverUrl);
      } catch (_) {}
    }
  }

  Future<void> warmTrackFromStory({
    required String audioUrl,
    required String coverUrl,
  }) async {
    final cleanAudioUrl = audioUrl.trim();
    final cleanCoverUrl = coverUrl.trim();
    if (cleanAudioUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanAudioUrl);
      } catch (_) {}
    }
    if (cleanCoverUrl.isNotEmpty) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(cleanCoverUrl);
      } catch (_) {}
    }
  }

  Future<List<MusicModel>> _fetchRemote() async {
    try {
      final snap = await _collection.limit(200).get();
      return snap.docs
          .map((doc) => MusicModel.fromMap(doc.data(), doc.id))
          .where((track) => track.isActive && track.audioUrl.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return const <MusicModel>[];
    }
  }

  Future<List<MusicModel>> _loadCache({bool ignoreTtl = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ignoreTtl) {
        final updatedAt = prefs.getInt(_cacheTimeKey) ?? 0;
        if (updatedAt <= 0) return const <MusicModel>[];
        final age = DateTime.now().millisecondsSinceEpoch - updatedAt;
        if (age > _cacheTtl.inMilliseconds) {
          return const <MusicModel>[];
        }
      }

      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return const <MusicModel>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const <MusicModel>[];
      return decoded
          .whereType<Map>()
          .map((e) => MusicModel.fromCacheMap(Map<String, dynamic>.from(e)))
          .where((track) => track.isActive && track.audioUrl.isNotEmpty)
          .toList(growable: true);
    } catch (_) {
      return const <MusicModel>[];
    }
  }

  Future<void> _persistCache(List<MusicModel> tracks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(tracks.map((e) => e.toCacheMap()).toList()),
      );
      await prefs.setInt(
        _cacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (_) {}
  }

  Future<void> _updateCachedTrack(
    String musicId,
    MusicModel Function(MusicModel current) builder,
  ) async {
    final cached = await _loadCache(ignoreTtl: true);
    if (cached.isEmpty) return;
    final index = cached.indexWhere((e) => e.docID == musicId);
    if (index == -1) return;
    cached[index] = builder(cached[index]);
    await _persistCache(cached);
  }

  List<MusicModel> _sortAndLimit(List<MusicModel> tracks, int limit) {
    final sorted = tracks.toList(growable: true)
      ..sort((a, b) {
        final byUse = b.useCount.compareTo(a.useCount);
        if (byUse != 0) return byUse;
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return compareNormalizedText(a.title, b.title);
      });
    if (sorted.length <= limit) return sorted;
    return sorted.take(limit).toList(growable: false);
  }

  Future<void> _warmTopCache({required int limit}) async {
    final tracks = await _loadCache(ignoreTtl: true);
    if (tracks.isEmpty) return;
    final top = _sortAndLimit(tracks, limit);
    for (final track in top) {
      await warmTrack(track);
    }
  }
}
