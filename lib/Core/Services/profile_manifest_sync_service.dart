import 'dart:async';
import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ProfileManifestSyncService extends GetxService {
  static const int _manifestPostLimit = 80;
  static const Duration _defaultDebounce = Duration(milliseconds: 600);

  ProfileManifestSyncService({
    FirebaseStorage? storage,
  }) : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Timer? _debounce;
  Future<void>? _inFlight;

  static ProfileManifestSyncService? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileManifestSyncService>();
    if (!isRegistered) return null;
    return Get.find<ProfileManifestSyncService>();
  }

  static ProfileManifestSyncService ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileManifestSyncService(), permanent: true);
  }

  void scheduleCurrentUserSync({
    String reason = 'client_update',
    Duration delay = _defaultDebounce,
  }) {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    if (uid.isEmpty) return;
    _debounce?.cancel();
    _debounce = Timer(delay, () {
      unawaited(syncCurrentUserNow(reason: reason));
    });
  }

  Future<void> syncCurrentUserNow({
    String reason = 'manual',
  }) async {
    final uid = CurrentUserService.instance.effectiveUserId.trim();
    if (uid.isEmpty) return;
    final existing = _inFlight;
    if (existing != null) {
      await existing;
      return;
    }
    final future = _performSync(uid, reason: reason);
    _inFlight = future;
    await future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
  }

  Future<void> _performSync(
    String uid, {
    required String reason,
  }) async {
    final profileRepository = ensureProfileRepository();
    final userRepository = UserRepository.ensure();
    final currentUser = CurrentUserService.instance.currentUser;
    final rawUser = await userRepository.getUserRaw(
      uid,
      preferCache: true,
      cacheOnly: false,
    );

    final generatedAt = DateTime.now().millisecondsSinceEpoch;
    final profilePage = await profileRepository.fetchPrimaryPage(
      uid: uid,
      limit: _manifestPostLimit,
    );

    String firstNonEmpty(Iterable<String> values) {
      for (final value in values) {
        final normalized = value.trim();
        if (normalized.isNotEmpty) return normalized;
      }
      return '';
    }

    final nickname = firstNonEmpty(<String>[
      currentUser?.nickname ?? '',
      (rawUser?['nickname'] ?? '').toString(),
    ]);
    final displayName = firstNonEmpty(<String>[
      currentUser?.fullName ?? '',
      [
        currentUser?.firstName ?? '',
        currentUser?.lastName ?? '',
      ].where((part) => part.trim().isNotEmpty).join(' '),
      (rawUser?['displayName'] ?? '').toString(),
      (rawUser?['fullName'] ?? '').toString(),
    ]);
    final avatarUrl = firstNonEmpty(<String>[
      currentUser?.avatarUrl ?? '',
      (rawUser?['avatarUrl'] ?? '').toString(),
    ]);
    final rozet = firstNonEmpty(<String>[
      currentUser?.rozet ?? '',
      (rawUser?['rozet'] ?? '').toString(),
    ]);
    final bio = firstNonEmpty(<String>[
      currentUser?.bio ?? '',
      (rawUser?['bio'] ?? '').toString(),
    ]);
    final adres = firstNonEmpty(<String>[
      currentUser?.adres ?? '',
      (rawUser?['adres'] ?? '').toString(),
    ]);
    final meslekKategori = firstNonEmpty(<String>[
      currentUser?.meslekKategori ?? '',
      (rawUser?['meslekKategori'] ?? '').toString(),
    ]);
    final followerCount = currentUser?.counterOfFollowers ??
        ((rawUser?['counterOfFollowers'] as num?)?.toInt() ??
            (rawUser?['followersCount'] as num?)?.toInt() ??
            0);
    final followingCount = currentUser?.counterOfFollowings ??
        ((rawUser?['counterOfFollowings'] as num?)?.toInt() ??
            (rawUser?['followingCount'] as num?)?.toInt() ??
            0);

    Map<String, dynamic> encodePost(PostsModel post) {
      final data = post.toMap();
      if (nickname.isNotEmpty) data['authorNickname'] = nickname;
      if (displayName.isNotEmpty) data['authorDisplayName'] = displayName;
      if (avatarUrl.isNotEmpty) data['authorAvatarUrl'] = avatarUrl;
      if (rozet.isNotEmpty) data['rozet'] = rozet;
      data['userID'] = uid;
      return <String, dynamic>{
        'docID': post.docID,
        'data': data,
      };
    }

    Map<String, dynamic> encodeBucket(List<PostsModel> posts) {
      return <String, dynamic>{
        'items': posts.map(encodePost).toList(growable: false),
      };
    }

    final payload = <String, dynamic>{
      'schemaVersion': 1,
      'userId': uid,
      'manifestId': 'profile_${uid}_v$generatedAt',
      'generatedAt': generatedAt,
      'header': <String, dynamic>{
        'nickname': nickname,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'rozet': rozet,
        'bio': bio,
        'adres': adres,
        'meslekKategori': meslekKategori,
        'followerCount': followerCount,
        'followingCount': followingCount,
      },
      'all': encodeBucket(profilePage.all),
      'photos': encodeBucket(profilePage.photos),
      'videos': encodeBucket(profilePage.videos),
      'reshares': const <String, dynamic>{'items': <Map<String, dynamic>>[]},
      'scheduled': const <String, dynamic>{'items': <Map<String, dynamic>>[]},
    };

    final storagePath =
        'users/$uid/profile_manifest/manifest_v$generatedAt.json';
    final ref = _storage.ref().child(storagePath);
    await ref.putString(
      jsonEncode(payload),
      format: PutStringFormat.raw,
      metadata: SettableMetadata(
        contentType: 'application/json; charset=utf-8',
        cacheControl: 'private, max-age=300',
      ),
    );

    await userRepository.upsertUserFields(
      uid,
      <String, dynamic>{
        'profileManifest': <String, dynamic>{
          'schemaVersion': 1,
          'manifestId': payload['manifestId'],
          'activeVersion': 'v$generatedAt',
          'storagePath': storagePath,
          'itemCount': profilePage.all.length,
          'bucketCounts': <String, dynamic>{
            'all': profilePage.all.length,
            'photos': profilePage.photos.length,
            'videos': profilePage.videos.length,
          },
          'updatedAt': generatedAt,
          'lastRebuildAt': generatedAt,
          'lastEventAt': generatedAt,
          'dirty': false,
          'rebuildReason': reason,
          'ttlUntil': generatedAt + const Duration(days: 7).inMilliseconds,
          'visibility': 'public_safe_client',
        },
      },
    );

    unawaited(_cleanupPreviousManifests(uid, keepPath: storagePath));
  }

  Future<void> _cleanupPreviousManifests(
    String uid, {
    required String keepPath,
  }) async {
    try {
      final folderRef = _storage.ref().child('users/$uid/profile_manifest');
      final listing = await folderRef.listAll();
      final deletions = <Future<void>>[];
      for (final item in listing.items) {
        if (item.fullPath == keepPath) continue;
        deletions.add(item.delete());
      }
      if (deletions.isNotEmpty) {
        await Future.wait(deletions);
      }
    } catch (_) {}
  }
}

ProfileManifestSyncService ensureProfileManifestSyncService() =>
    ProfileManifestSyncService.ensure();
