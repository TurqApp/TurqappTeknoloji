import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
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

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  final Map<String, _ProfileManifestCacheEntry> _cache =
      <String, _ProfileManifestCacheEntry>{};

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
      final buckets = parseManifestJson(utf8.decode(bytes));
      if (buckets == null) return null;
      _cache[normalizedUserId] = _ProfileManifestCacheEntry(
        storagePath: storagePath,
        buckets: buckets,
      );
      return _trimBuckets(buckets, limit: limit);
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

  static ProfileBuckets? parseManifestJson(String rawJson) {
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

    return ProfileBuckets(
      all: decodePosts(json['all']),
      photos: decodePosts(json['photos']),
      videos: decodePosts(json['videos']),
      reshares: decodePosts(json['reshares']),
      scheduled: decodePosts(json['scheduled']),
    );
  }
}

class _ProfileManifestCacheEntry {
  const _ProfileManifestCacheEntry({
    required this.storagePath,
    required this.buckets,
  });

  final String storagePath;
  final ProfileBuckets buckets;
}
