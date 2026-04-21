import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/CacheFirst/scoped_snapshot_store.dart';
import 'package:turqappv2/Core/Services/CacheFirst/shared_prefs_scoped_snapshot_store.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ProfileManifestRepository extends GetxService {
  ProfileManifestRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  static const int _maxManifestBytes = 4 * 1024 * 1024;
  static const Duration _authReadyTimeout = Duration(milliseconds: 1600);
  static const String _headerSurfaceKey = 'profile_manifest_header';
  static const String _headerScopeId = 'active';
  static const int _headerSnapshotSchemaVersion = 1;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  final Map<String, _ProfileManifestCacheEntry> _cache =
      <String, _ProfileManifestCacheEntry>{};
  final Map<String, _ProfileManifestHeaderCacheEntry> _headerCache =
      <String, _ProfileManifestHeaderCacheEntry>{};
  late final SharedPrefsScopedSnapshotStore<Map<String, dynamic>>
      _headerSnapshotStore =
      SharedPrefsScopedSnapshotStore<Map<String, dynamic>>(
    prefsPrefix: 'profile_manifest_header_v1',
    encode: (data) => Map<String, dynamic>.from(data),
    decode: (data) => Map<String, dynamic>.from(data),
  );

  static ProfileManifestRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileManifestRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfileManifestRepository>();
  }

  static ProfileManifestRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileManifestRepository(), permanent: true);
  }

  Future<ProfileBuckets?> loadBuckets({
    required String userId,
    required int limit,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;
    await _ensureManifestAccessReady();
    final userDoc =
        await _firestore.collection('users').doc(normalizedUserId).get(
              const GetOptions(source: Source.serverAndCache),
            );
    final data = userDoc.data();
    if (data == null) return null;
    final manifest = data['profileManifest'];
    if (manifest is! Map) return null;
    final manifestMap = Map<String, dynamic>.from(manifest);
    final storagePath = (manifestMap['storagePath'] ?? '').toString().trim();
    if (storagePath.isEmpty) return null;

    final cached = _cache[normalizedUserId];
    if (cached != null && cached.storagePath == storagePath) {
      return _trimBuckets(cached.buckets, limit: limit);
    }

    try {
      final bytes = await _storage.ref(storagePath).getData(_maxManifestBytes);
      if (bytes == null || bytes.isEmpty) return null;
      final payload = parseManifestPayload(utf8.decode(bytes));
      if (payload == null) return null;
      _cache[normalizedUserId] = _ProfileManifestCacheEntry(
        storagePath: storagePath,
        header: payload.header,
        buckets: payload.buckets,
      );
      await _writeHeaderSnapshot(
        userId: normalizedUserId,
        storagePath: storagePath,
        header: payload.header,
      );
      return _trimBuckets(payload.buckets, limit: limit);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> loadHeader({
    required String userId,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;
    await _ensureManifestAccessReady();
    final userDoc =
        await _firestore.collection('users').doc(normalizedUserId).get(
              const GetOptions(source: Source.serverAndCache),
            );
    final data = userDoc.data();
    if (data == null) return null;
    final manifest = data['profileManifest'];
    if (manifest is! Map) return null;
    final manifestMap = Map<String, dynamic>.from(manifest);
    final storagePath = (manifestMap['storagePath'] ?? '').toString().trim();
    if (storagePath.isEmpty) return null;

    final cached = _cache[normalizedUserId];
    if (cached != null && cached.storagePath == storagePath) {
      return cached.header.isEmpty ? null : cached.header;
    }

    final headerCached = _headerCache[normalizedUserId];
    if (headerCached != null && headerCached.storagePath == storagePath) {
      return headerCached.header.isEmpty ? null : headerCached.header;
    }

    final diskHeader = await _readHeaderSnapshot(
      userId: normalizedUserId,
      storagePath: storagePath,
    );
    if (diskHeader != null) {
      _headerCache[normalizedUserId] = _ProfileManifestHeaderCacheEntry(
        storagePath: storagePath,
        header: diskHeader,
      );
      return diskHeader.isEmpty ? null : diskHeader;
    }

    try {
      final bytes = await _storage.ref(storagePath).getData(_maxManifestBytes);
      if (bytes == null || bytes.isEmpty) return null;
      final payload = parseManifestPayload(utf8.decode(bytes));
      if (payload == null) return null;
      _cache[normalizedUserId] = _ProfileManifestCacheEntry(
        storagePath: storagePath,
        header: payload.header,
        buckets: payload.buckets,
      );
      await _writeHeaderSnapshot(
        userId: normalizedUserId,
        storagePath: storagePath,
        header: payload.header,
      );
      return payload.header.isEmpty ? null : payload.header;
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureManifestAccessReady() async {
    await CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: false,
      timeout: _authReadyTimeout,
      recordTimeoutFailure: false,
    );
  }

  ProfileBuckets _trimBuckets(
    ProfileBuckets buckets, {
    required int limit,
  }) {
    final normalizedLimit = limit <= 0 ? 1 : limit;
    return ProfileBuckets(
      all: buckets.all.take(normalizedLimit).toList(growable: false),
      photos: buckets.photos.take(normalizedLimit).toList(growable: false),
      videos: buckets.videos.take(normalizedLimit).toList(growable: false),
      reshares: buckets.reshares.take(normalizedLimit).toList(growable: false),
      scheduled:
          buckets.scheduled.take(normalizedLimit).toList(growable: false),
    );
  }

  Future<Map<String, dynamic>?> _readHeaderSnapshot({
    required String userId,
    required String storagePath,
  }) async {
    final record = await _headerSnapshotStore.read(
      _headerSnapshotKey(userId),
      allowStale: true,
    );
    final data = record?.data;
    if (data == null) return null;
    final decoded =
        decodeHeaderSnapshot(data, expectedStoragePath: storagePath);
    if (decoded == null) return null;
    final header = decoded['header'];
    return header is Map ? Map<String, dynamic>.from(header) : null;
  }

  Future<void> _writeHeaderSnapshot({
    required String userId,
    required String storagePath,
    required Map<String, dynamic> header,
  }) async {
    final normalizedHeader = Map<String, dynamic>.from(header);
    _headerCache[userId] = _ProfileManifestHeaderCacheEntry(
      storagePath: storagePath,
      header: normalizedHeader,
    );
    await _headerSnapshotStore.write(
      _headerSnapshotKey(userId),
      ScopedSnapshotRecord<Map<String, dynamic>>(
        data: encodeHeaderSnapshot(
          storagePath: storagePath,
          header: normalizedHeader,
        ),
        snapshotAt: DateTime.now(),
        schemaVersion: _headerSnapshotSchemaVersion,
        generationId: 'manifest:$storagePath',
        source: CachedResourceSource.scopedDisk,
      ),
    );
  }

  ScopedSnapshotKey _headerSnapshotKey(String userId) => ScopedSnapshotKey(
        surfaceKey: _headerSurfaceKey,
        userId: userId,
        scopeId: _headerScopeId,
      );

  static _ProfileManifestPayload? parseManifestPayload(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map) return null;
    final json = Map<String, dynamic>.from(decoded);
    List<PostsModel> decodePosts(dynamic rawBucket) {
      if (rawBucket is! Map) return const <PostsModel>[];
      final map = Map<String, dynamic>.from(rawBucket);
      final items = map['items'];
      if (items is! List) return const <PostsModel>[];
      return items
          .whereType<Map>()
          .map((raw) {
            final entry = Map<String, dynamic>.from(raw);
            final docId =
                (entry['docID'] ?? entry['docId'] ?? '').toString().trim();
            final data = entry['data'];
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
          .where((post) => !post.shouldHideWhileUploading)
          .toList(growable: false);
    }

    final header = json['header'] is Map
        ? Map<String, dynamic>.from(json['header'] as Map)
        : const <String, dynamic>{};
    return _ProfileManifestPayload(
      header: header,
      buckets: ProfileBuckets(
        all: decodePosts(json['all']),
        photos: decodePosts(json['photos']),
        videos: decodePosts(json['videos']),
        reshares: decodePosts(json['reshares']),
        scheduled: decodePosts(json['scheduled']),
      ),
    );
  }

  static ProfileBuckets? parseManifestJson(String rawJson) =>
      parseManifestPayload(rawJson)?.buckets;

  static Map<String, dynamic> encodeHeaderSnapshot({
    required String storagePath,
    required Map<String, dynamic> header,
  }) {
    return <String, dynamic>{
      'storagePath': storagePath.trim(),
      'header': Map<String, dynamic>.from(header),
    };
  }

  static Map<String, dynamic>? decodeHeaderSnapshot(
    Map<String, dynamic> raw, {
    String? expectedStoragePath,
  }) {
    final storagePath = (raw['storagePath'] ?? '').toString().trim();
    if (storagePath.isEmpty) return null;
    final normalizedExpected = (expectedStoragePath ?? '').trim();
    if (normalizedExpected.isNotEmpty && storagePath != normalizedExpected) {
      return null;
    }
    final header = raw['header'];
    if (header is! Map) return null;
    return <String, dynamic>{
      'storagePath': storagePath,
      'header': Map<String, dynamic>.from(header),
    };
  }

  static Map<String, dynamic> headerAsUserCard(Map<String, dynamic> header) {
    String asTrimmedString(dynamic value) => (value ?? '').toString().trim();
    return <String, dynamic>{
      'nickname': asTrimmedString(header['nickname']),
      'displayName': asTrimmedString(header['displayName']),
      'avatarUrl': asTrimmedString(header['avatarUrl']),
      'rozet': asTrimmedString(header['rozet']),
      'bio': asTrimmedString(header['bio']),
      'adres': asTrimmedString(header['adres']),
      'meslekKategori': asTrimmedString(header['meslekKategori']),
      'counterOfFollowers': header['followerCount'] ?? 0,
      'counterOfFollowings': header['followingCount'] ?? 0,
    };
  }
}

class _ProfileManifestCacheEntry {
  const _ProfileManifestCacheEntry({
    required this.storagePath,
    required this.header,
    required this.buckets,
  });

  final String storagePath;
  final Map<String, dynamic> header;
  final ProfileBuckets buckets;
}

class _ProfileManifestPayload {
  const _ProfileManifestPayload({
    required this.header,
    required this.buckets,
  });

  final Map<String, dynamic> header;
  final ProfileBuckets buckets;
}

class _ProfileManifestHeaderCacheEntry {
  const _ProfileManifestHeaderCacheEntry({
    required this.storagePath,
    required this.header,
  });

  final String storagePath;
  final Map<String, dynamic> header;
}
