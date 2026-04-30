import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/app_firebase_storage.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

class ProfileManifestSyncService extends GetxService {
  static const int _manifestPostLimit = 80;
  static const int _manifestReshareLimit =
      ReadBudgetRegistry.reshareUserPreviewInitialLimit;
  static const Duration _defaultDebounce = Duration(milliseconds: 600);

  ProfileManifestSyncService({
    FirebaseStorage? storage,
    FirebaseFirestore? firestore,
  })  : _storage = storage ?? AppFirebaseStorage.instance,
        _firestore = firestore ?? AppFirestore.instance;

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;

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
    final reshareRefs = await _loadReshareRefs(uid);
    final reshareTimeByPostId = <String, int>{
      for (final ref in reshareRefs)
        if (ref.postId.trim().isNotEmpty)
          ref.postId.trim(): ref.timeStamp.toInt(),
    };
    final manifestReshares = await _loadManifestReshares(
      uid,
      refs: reshareRefs,
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

    Map<String, dynamic> encodePost(
      PostsModel post, {
      bool refreshAuthorSnapshot = false,
      int? reshareTimestamp,
    }) {
      final data = post.toMap();
      final statsMap = post.stats.toMap();
      if (refreshAuthorSnapshot) {
        if (nickname.isNotEmpty) data['authorNickname'] = nickname;
        if (displayName.isNotEmpty) data['authorDisplayName'] = displayName;
        if (avatarUrl.isNotEmpty) data['authorAvatarUrl'] = avatarUrl;
        if (rozet.isNotEmpty) data['rozet'] = rozet;
        data['userID'] = uid;
      }
      data['docID'] = post.docID;
      data['userID'] = post.userID;
      data['authorNickname'] = data['authorNickname'] ?? post.authorNickname;
      data['authorDisplayName'] =
          data['authorDisplayName'] ?? post.authorDisplayName;
      data['authorAvatarUrl'] = data['authorAvatarUrl'] ?? post.authorAvatarUrl;
      data['rozet'] = data['rozet'] ?? post.rozet;
      data['metin'] = post.metin;
      data['thumbnail'] = post.thumbnail;
      data['img'] = List<String>.from(post.img, growable: false);
      data['video'] = post.video;
      data['videoLook'] = Map<String, dynamic>.from(post.videoLook);
      data['hlsMasterUrl'] = post.hlsMasterUrl;
      data['hlsStatus'] = post.hlsStatus;
      data['hlsUpdatedAt'] = post.hlsUpdatedAt;
      data['hasHls'] = post.hasHls;
      data['isHlsReady'] = post.isHlsReady;
      data['hasPlayableVideo'] = post.hasPlayableVideo;
      data['hasVideoSignal'] = post.hasVideoSignal;
      data['hasRenderableVideoCard'] = post.hasRenderableVideoCard;
      data['aspectRatio'] = post.aspectRatio;
      data['timeStamp'] = post.timeStamp;
      data['scheduledAt'] = post.scheduledAt;
      data['editTime'] = post.editTime;
      data['shortId'] = post.shortId;
      data['shortUrl'] = post.shortUrl;
      data['shareShortUrl'] = post.shortUrl;
      data['tags'] = List<String>.from(post.tags, growable: false);
      data['konum'] = post.konum;
      data['locationCity'] = post.locationCity;
      data['originalPostID'] = post.originalPostID;
      data['originalUserID'] = post.originalUserID;
      data['quotedPost'] = post.quotedPost;
      data['quotedOriginalText'] = post.quotedOriginalText;
      data['quotedSourceUserID'] = post.quotedSourceUserID;
      data['quotedSourceDisplayName'] = post.quotedSourceDisplayName;
      data['quotedSourceUsername'] = post.quotedSourceUsername;
      data['quotedSourceAvatarUrl'] = post.quotedSourceAvatarUrl;
      data['ad'] = post.ad;
      data['isAd'] = post.isAd;
      data['arsiv'] = post.arsiv;
      data['deletedPost'] = post.deletedPost;
      data['deletedPostTime'] = post.deletedPostTime;
      data['gizlendi'] = post.gizlendi;
      data['isUploading'] = post.isUploading;
      data['flood'] = post.flood;
      data['floodCount'] = post.floodCount;
      data['mainFlood'] = post.mainFlood;
      data['sikayetEdildi'] = post.sikayetEdildi;
      data['stabilized'] = post.stabilized;
      data['debugMode'] = post.debugMode;
      data['izBirakYayinTarihi'] = post.izBirakYayinTarihi;
      data['paylasGizliligi'] = post.paylasGizliligi;
      data['paylasimVisibility'] = post.paylasimVisibility;
      data['yorum'] = post.yorum;
      data['yorumMap'] = Map<String, dynamic>.from(post.yorumMap);
      data['yorumVisibility'] = post.yorumVisibility;
      data['reshareMap'] = Map<String, dynamic>.from(post.reshareMap);
      data['poll'] = Map<String, dynamic>.from(post.poll);
      data['stats'] = statsMap;
      data['commentCount'] = statsMap['commentCount'] ?? 0;
      data['likeCount'] = statsMap['likeCount'] ?? 0;
      data['savedCount'] = statsMap['savedCount'] ?? 0;
      data['statsCount'] = statsMap['statsCount'] ?? 0;
      data['reportedCount'] = statsMap['reportedCount'] ?? 0;
      data['retryCount'] = statsMap['retryCount'] ?? 0;
      if (reshareTimestamp != null) {
        final rawReshareMap = data['reshareMap'];
        final reshareMap = rawReshareMap is Map
            ? Map<String, dynamic>.from(rawReshareMap)
            : <String, dynamic>{};
        reshareMap['manifestReshareTimeStamp'] = reshareTimestamp;
        data['reshareMap'] = reshareMap;
      }
      return <String, dynamic>{
        'docID': post.docID,
        'data': data,
      };
    }

    Map<String, dynamic> encodeBucket(
      List<PostsModel> posts, {
      bool refreshAuthorSnapshot = false,
      Map<String, int> reshareTimeByPostId = const <String, int>{},
    }) {
      return <String, dynamic>{
        'items': posts
            .map(
              (post) => encodePost(
                post,
                refreshAuthorSnapshot: refreshAuthorSnapshot,
                reshareTimestamp: reshareTimeByPostId[post.docID],
              ),
            )
            .toList(growable: false),
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
      'all': encodeBucket(
        profilePage.all,
        refreshAuthorSnapshot: true,
      ),
      'photos': encodeBucket(
        profilePage.photos,
        refreshAuthorSnapshot: true,
      ),
      'videos': encodeBucket(
        profilePage.videos,
        refreshAuthorSnapshot: true,
      ),
      'reshares': encodeBucket(
        manifestReshares,
        reshareTimeByPostId: reshareTimeByPostId,
      ),
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
            'reshares': manifestReshares.length,
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

  Future<List<UserPostReference>> _loadReshareRefs(String uid) async {
    final visibleNowThresholdMs = DateTime.now().millisecondsSinceEpoch;
    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('reshared_posts')
        .where('timeStamp', isLessThanOrEqualTo: visibleNowThresholdMs)
        .orderBy('timeStamp', descending: true)
        .limit(_manifestReshareLimit)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map(UserPostReference.fromDoc)
        .where((ref) => ref.postId.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<PostsModel>> _loadManifestReshares(
    String uid, {
    required List<UserPostReference> refs,
  }) async {
    if (refs.isEmpty) return const <PostsModel>[];
    final visibleNowThresholdMs = DateTime.now().millisecondsSinceEpoch;
    final posts = await UserPostLinkService.ensure().fetchResharedPosts(
      uid,
      refs,
      preferCache: true,
      cacheOnly: false,
    );
    return posts
        .where((post) => post.docID.trim().isNotEmpty)
        .where((post) => !post.deletedPost)
        .where((post) => !post.arsiv)
        .where((post) => !post.shouldHideWhileUploading)
        .where((post) => post.timeStamp <= visibleNowThresholdMs)
        .toList(growable: false);
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
