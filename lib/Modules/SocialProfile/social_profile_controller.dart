import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/formatters.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Core/Services/runtime_invariant_guard.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Repositories/profile_repository.dart';
import 'package:turqappv2/Core/Repositories/social_media_links_repository.dart';
import 'package:turqappv2/Core/Repositories/story_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Models/social_media_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import '../../Models/posts_model.dart';
import '../../Models/user_post_reference.dart';
import '../../Services/user_post_link_service.dart';
import '../../Services/user_analytics_service.dart';
import 'package:turqappv2/Core/notification_service.dart';
import '../Agenda/AgendaContent/agenda_content_controller.dart';
import '../Profile/SocialMediaLinks/social_media_links_controller.dart';
import '../Story/StoryRow/story_user_model.dart';

class SocialProfileController extends GetxController {
  static SocialProfileController ensure({
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SocialProfileController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static SocialProfileController? maybeFind({String? tag}) {
    if (!Get.isRegistered<SocialProfileController>(tag: tag)) return null;
    return Get.find<SocialProfileController>(tag: tag);
  }

  var totalMarket = 0.obs;
  var totalPosts = 0.obs;
  var totalLikes = 0.obs;
  var totalFollower = 0.obs;
  var totalFollowing = 0.obs;
  var postSelection = 0.obs;

  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? _pendingCenteredIdentity;

  final ScrollController scrollController = ScrollController();
  final RxList<SocialMediaModel> socialMediaList = <SocialMediaModel>[].obs;
  final RxList<PostsModel> reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? _resharesSub;
  final UserRepository _userRepository = UserRepository.ensure();
  final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final SocialMediaLinksRepository _socialLinksRepository =
      SocialMediaLinksRepository.ensure();
  final StoryRepository _storyRepository = StoryRepository.ensure();
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();
  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  final Map<String, GlobalKey> _postKeys = {};
  var showPfImage = false.obs;

  String userID;
  SocialProfileController({required this.userID});
  var nickname = "".obs;
  var displayName = "".obs;
  var avatarUrl = "".obs;
  var firstName = "".obs;
  var lastName = "".obs;
  var token = "".obs;
  var email = "".obs;
  var rozet = "".obs;
  var bio = "".obs;

  var adres = "".obs;
  var phoneNumber = "".obs;
  var mailIzin = false.obs;
  var aramaIzin = false.obs;
  var ban = false.obs;
  var gizliHesap = false.obs;
  var hesapOnayi = false.obs;
  var meslek = "".obs;
  var blockedUsers = <String>[].obs;
  var complatedCheck = false.obs;
  var takipEdiyorum = false.obs;
  var followLoading = false.obs;
  static const Duration _followCheckCacheTtl = Duration(seconds: 20);
  static const Duration _counterCacheTtl = Duration(seconds: 30);
  static const Duration _cacheStaleRetention = Duration(minutes: 3);
  static const int _maxCacheEntries = 500;
  static final Map<String, _SocialFollowCheckCacheEntry> _followCheckCache =
      <String, _SocialFollowCheckCacheEntry>{};
  static final Map<String, _SocialCounterCacheEntry> _counterCache =
      <String, _SocialCounterCacheEntry>{};

  final RxList<PostsModel> allPosts = <PostsModel>[].obs;

  final RxList<PostsModel> photos = <PostsModel>[].obs;
  final RxList<PostsModel> scheduledPosts = <PostsModel>[].obs;

  bool isPrivateContentBlockedFor(String? viewerUserId) {
    return gizliHesap.value &&
        takipEdiyorum.value == false &&
        viewerUserId != userID;
  }

  bool isBlockedByCurrentViewer(String? otherUserId) {
    final other = (otherUserId ?? '').trim();
    if (other.isEmpty) return false;
    final currentBlocked = CurrentUserService.instance.blockedUserIds;
    return currentBlocked.contains(other);
  }

  String displayCounterValue({
    required String? viewerUserId,
    required num value,
  }) {
    if (isBlockedByCurrentViewer(viewerUserId)) {
      return "0";
    }
    return NumberFormatter.format(value.toInt());
  }

  final RxBool isLoadingPosts = false.obs;
  final RxBool hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;
  final int pageSize = 12;
  final ProfileRepository _profileRepository = ProfileRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  DocumentSnapshot<Map<String, dynamic>>? _lastPrimaryDoc;
  bool _hasMorePrimary = true;
  bool _isLoadingPrimary = false;

  final RxBool isLoadingPhoto = false.obs;
  final RxBool hasMorePhoto = true.obs;
  DocumentSnapshot? lastPostDocPhoto;
  final int pageSizePhoto = 12;

  // Scheduled (İz Bırak)
  final RxBool isLoadingScheduled = false.obs;
  final RxBool hasMoreScheduled = true.obs;
  DocumentSnapshot? lastScheduledDoc;
  final int pageSizeScheduled = 12;
  StoryUserModel? storyUserModel;
  // Yukarı butonu
  final RxBool showScrollToTop = false.obs;
  StreamSubscription<Map<String, dynamic>?>? _userDocSub;

  String _resolveNickname(
    Map<String, dynamic> raw,
    Map<String, dynamic> profile,
  ) {
    final nickname =
        (raw["nickname"] ?? profile["nickname"] ?? "").toString().trim();
    final username =
        (raw["username"] ?? profile["username"] ?? "").toString().trim();
    final displayName =
        (raw["displayName"] ?? profile["displayName"] ?? "").toString().trim();
    if (nickname.isNotEmpty) return nickname;
    if (username.isNotEmpty) return username;
    return displayName;
  }

  int resolveResumeCenteredIndex() {
    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    if (activeLength == 0) return -1;
    final pendingIdentity = _pendingCenteredIdentity;
    if (pendingIdentity != null && pendingIdentity.isNotEmpty) {
      final pendingIndex = postSelection.value == 0
          ? combinedFeedEntries.indexWhere((entry) {
              final entryDocId = ((entry['docID'] as String?) ?? '').trim();
              final entryIsReshare = entry['isReshare'] == true;
              return combinedEntryIdentity(
                    docId: entryDocId,
                    isReshare: entryIsReshare,
                  ) ==
                  pendingIdentity;
            })
          : allPosts
              .indexWhere((post) => 'post_${post.docID}' == pendingIdentity);
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < activeLength) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < activeLength) {
      return centeredIndex.value;
    }
    return 0;
  }

  void resumeCenteredPost() {
    final activeCombinedEntries = postSelection.value == 0
        ? combinedFeedEntries
        : const <Map<String, dynamic>>[];
    final activeLength = postSelection.value == 0
        ? activeCombinedEntries.length
        : allPosts.length;
    final expectedDocId = (lastCenteredIndex != null &&
            lastCenteredIndex! >= 0 &&
            lastCenteredIndex! < activeLength)
        ? postSelection.value == 0
            ? ((activeCombinedEntries[lastCenteredIndex!]['docID']
                    as String?) ??
                '')
            : allPosts[lastCenteredIndex!].docID
        : null;
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= activeLength) return;
    lastCenteredIndex = target;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    capturePendingCenteredEntry(preferredIndex: target);
    _invariantGuard.assertCenteredSelection(
      surface: 'social_profile',
      invariantKey: 'resume_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: postSelection.value == 0
          ? activeCombinedEntries
              .map((entry) => ((entry['docID'] as String?) ?? ''))
              .toList(growable: false)
          : allPosts.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );
  }

  void capturePendingCenteredEntry({
    int? preferredIndex,
    PostsModel? model,
    bool isReshare = false,
  }) {
    if (model != null) {
      final docId = model.docID.trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = postSelection.value == 0
          ? combinedEntryIdentity(docId: docId, isReshare: isReshare)
          : 'post_$docId';
      return;
    }

    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= activeLength) {
      _pendingCenteredIdentity = null;
      return;
    }

    if (postSelection.value == 0) {
      final entry = combinedFeedEntries[candidateIndex];
      final docId = ((entry['docID'] as String?) ?? '').trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = combinedEntryIdentity(
        docId: docId,
        isReshare: entry['isReshare'] == true,
      );
      return;
    }

    final docId = allPosts[candidateIndex].docID.trim();
    _pendingCenteredIdentity = docId.isEmpty ? null : 'post_$docId';
  }

  @override
  void onInit() {
    UserAnalyticsService.instance.trackFeatureUsage('social_profile_open');
    getUserData();
    getCounters();
    getUserStoryUserModelAndPrint(userID);
    getSocialMediaLinks();
    isFollowingCheck();
    _logProfileVisitIfNeeded();
    super.onInit();
    unawaited(_restoreCachedBuckets());
    _fetchPrimaryBuckets(initial: true);
    getReshares();
  }

  Future<void> _logProfileVisitIfNeeded() async {
    try {
      final current = CurrentUserService.instance.userId;
      if (current.isEmpty) return;
      if (current == userID) return; // kendi profili
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await _userSubcollectionRepository.upsertEntry(
        userID,
        subcollection: 'ProfileVisits',
        docId: '${current}_$nowMs',
        data: {
          'visitorId': current,
          'timeStamp': nowMs,
        },
      );
    } catch (e) {
      print('Profile visit log error: $e');
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    _userDocSub?.cancel();
    _resharesSub?.cancel();
    super.onClose();
  }

  Future<void> getCounters() async {
    try {
      _pruneCaches();
      final cached = _counterCache[userID];
      if (cached != null &&
          DateTime.now().difference(cached.cachedAt) <= _counterCacheTtl) {
        totalFollower.value = cached.followers;
        totalFollowing.value = cached.followings;
        return;
      }

      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      final followerCounter = summary?.followerCount ?? 0;
      final followingCounter = summary?.followingCount ?? 0;

      totalFollower.value = followerCounter;
      totalFollowing.value = followingCounter;

      // Counter alanı sıfırlanmış/bozuksa, gerçek ilişki koleksiyonlarından yeniden say.
      if (totalFollower.value == 0 || totalFollowing.value == 0) {
        final followers = await _followRepository.getFollowerIds(
          userID,
          preferCache: true,
          forceRefresh: false,
        );
        final followings = await _visibilityPolicy.loadViewerFollowingIds(
          viewerUserId: userID,
          preferCache: true,
          forceRefresh: false,
        );
        totalFollower.value = followers.length;
        totalFollowing.value = followings.length;
      }
      _counterCache[userID] = _SocialCounterCacheEntry(
        followers: totalFollower.value,
        followings: totalFollowing.value,
        cachedAt: DateTime.now(),
      );
    } catch (e) {
      print("⚠️ SocialProfile getCounters error: $e");
    }
  }

  Future<void> getReshares() async {
    _resharesSub?.cancel();
    _resharesSub = _linkService.listenResharedPosts(userID).listen((refs) {
      _hydrateReshares(refs);
    });
  }

  Future<void> _hydrateReshares(List<UserPostReference> refs) async {
    try {
      final posts = await _linkService.fetchResharedPosts(userID, refs);
      reshares.value = posts;
    } catch (e) {
      print('SocialProfileController hydrate reshares error: $e');
    }
  }

  Future<void> getPosts({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial);
  }

  Future<void> getPhotos({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial);
  }

  Future<void> isFollowingCheck() async {
    final currentUid = CurrentUserService.instance.userId;
    if (currentUid.isEmpty) return;
    _pruneCaches();
    final cacheKey = '$currentUid:$userID';
    final cached = _followCheckCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _followCheckCacheTtl) {
      takipEdiyorum.value = cached.isFollowing;
      complatedCheck.value = true;
      return;
    }
    final isFollowing = await FollowRepository.ensure().isFollowing(
      userID,
      currentUid: currentUid,
      preferCache: true,
    );
    takipEdiyorum.value = isFollowing;
    complatedCheck.value = true;
    _followCheckCache[cacheKey] = _SocialFollowCheckCacheEntry(
      isFollowing: isFollowing,
      cachedAt: DateTime.now(),
    );
  }

  Future<void> setPostSelection(int index) async {
    postSelection.value = index;
    UserAnalyticsService.instance
        .trackFeatureUsage('social_profile_tab_$index');
    if (index == 5) {
      if (scheduledPosts.isEmpty || lastScheduledDoc == null) {
        await fetchScheduledPosts(initial: true);
      }
    }
  }

  GlobalKey getPostKey({
    required String docId,
    required bool isReshare,
  }) {
    final identity = combinedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return _postKeys.putIfAbsent(
      identity,
      () => GlobalObjectKey('social_$identity'),
    );
  }

  String combinedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) {
    return '${isReshare ? 'reshare' : 'post'}_$docId';
  }

  List<Map<String, dynamic>> get combinedFeedEntries {
    final combinedPosts = <Map<String, dynamic>>[];

    for (final post in allPosts) {
      combinedPosts.add(<String, dynamic>{
        'docID': post.docID,
        'post': post,
        'isReshare': false,
        'timestamp': post.timeStamp,
      });
    }

    for (final reshare in reshares) {
      combinedPosts.add(<String, dynamic>{
        'docID': reshare.docID,
        'post': reshare,
        'isReshare': true,
        'timestamp': reshare.timeStamp,
      });
    }

    combinedPosts.sort(
      (a, b) => (b['timestamp'] as num).compareTo(a['timestamp'] as num),
    );
    return combinedPosts;
  }

  int indexOfCombinedEntry({
    required String docId,
    required bool isReshare,
  }) {
    final identity = combinedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return combinedFeedEntries.indexWhere((entry) {
      final entryDocId = ((entry['docID'] as String?) ?? '').trim();
      final entryIsReshare = entry['isReshare'] == true;
      return combinedEntryIdentity(
            docId: entryDocId,
            isReshare: entryIsReshare,
          ) ==
          identity;
    });
  }

  String agendaInstanceTag({
    required String docId,
    required bool isReshare,
  }) {
    return 'social_${isReshare ? 'reshare' : 'post'}_$docId';
  }

  Future<void> fetchScheduledPosts({bool initial = false}) async {
    await _fetchPrimaryBuckets(initial: initial);
  }

  Future<void> refreshAll() async {
    try {
      // Temel kullanıcı verileri ve sayfalar
      await getCounters();
      await getUserData();
      await getSocialMediaLinks();

      _lastPrimaryDoc = null;
      _hasMorePrimary = true;

      await Future.wait([
        _fetchPrimaryBuckets(initial: true, force: true),
        getReshares(),
      ]);
    } catch (e) {
      print('SocialProfile.refreshAll error: $e');
    }
  }

  Future<void> disposeAgendaContentController(String docID) async {
    final tags = <String>{
      agendaInstanceTag(docId: docID, isReshare: false),
      agendaInstanceTag(docId: docID, isReshare: true),
    };
    for (final tag in tags) {
      if (AgendaContentController.maybeFind(tag: tag) != null) {
        Get.delete<AgendaContentController>(tag: tag, force: true);
      }
    }
  }

  Future<void> getSocialMediaLinks() async {
    final list = await _socialLinksRepository.getLinks(
      userID,
      preferCache: true,
      forceRefresh: false,
    );
    socialMediaList.value = list;
  }

  Future<void> showSocialMediaLinkDelete(String docID) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'social_links.remove_title'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: "MontserratBold",
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'social_links.remove_message'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Get.back();
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'common.cancel'.tr,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      Get.back();
                      await _socialLinksRepository.deleteLink(userID, docID);

                      unawaited(
                        SocialMediaController.maybeFind()?.getData(
                              silent: true,
                              forceRefresh: true,
                            ) ??
                            Future.value(),
                      );
                    },
                    child: Container(
                      height: 50,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Text(
                        'common.remove'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> getUserData() async {
    _userDocSub?.cancel();
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        final cachedRaw = await _userRepository.getUserRaw(
          userID,
          preferCache: true,
          cacheOnly: true,
        );
        final bootstrapData = (cachedRaw != null && cachedRaw.isNotEmpty)
            ? cachedRaw
            : summary.toMap();
        _applyUserData(bootstrapData);
        if (_needsHeaderSupplementalData(bootstrapData)) {
          final raw = await _userRepository.getUserRaw(
            userID,
            preferCache: false,
            forceServer: true,
          );
          if (raw != null && raw.isNotEmpty) {
            await _userRepository.putUserRaw(userID, raw);
            _applyUserData(raw);
          }
        } else if (cachedRaw != null && cachedRaw.isNotEmpty) {
          _applySupplementalUserData(cachedRaw);
        }
        return;
      }
    } catch (e) {
      print('SocialProfile.getUserData resolver error: $e');
    }

    try {
      final raw = await _userRepository.getUserRaw(userID, preferCache: true);
      _applyUserData(raw ?? const <String, dynamic>{});
    } catch (e) {
      print("SocialProfile.getUserData fallback error: $e");
    }
  }

  bool _needsHeaderSupplementalData(Map<String, dynamic> raw) {
    final profile = (raw["profile"] is Map)
        ? Map<String, dynamic>.from(raw["profile"] as Map)
        : const <String, dynamic>{};
    final bioText = (raw["bio"] ?? profile["bio"] ?? "").toString().trim();
    final addressText =
        (raw["adres"] ?? profile["adres"] ?? "").toString().trim();
    final meslekText =
        (raw["meslekKategori"] ?? profile["meslekKategori"] ?? "")
            .toString()
            .trim();
    return bioText.isEmpty || addressText.isEmpty || meslekText.isEmpty;
  }

  void _applyUserData(Map<String, dynamic> raw) {
    final profile = (raw["profile"] is Map)
        ? Map<String, dynamic>.from(raw["profile"] as Map)
        : const <String, dynamic>{};
    final stats = (raw["stats"] is Map)
        ? Map<String, dynamic>.from(raw["stats"] as Map)
        : const <String, dynamic>{};

    nickname.value = _resolveNickname(raw, profile);
    displayName.value =
        (raw["displayName"] ?? profile["displayName"] ?? "").toString().trim();
    avatarUrl.value = resolveAvatarUrl(raw, profile: profile);
    final nextDisplay = displayName.value;
    if (nextDisplay.isNotEmpty) {
      firstName.value = nextDisplay;
      lastName.value = "";
    } else {
      firstName.value =
          (raw["firstName"] ?? profile["firstName"] ?? "").toString();
      lastName.value =
          (raw["lastName"] ?? profile["lastName"] ?? "").toString();
    }
    email.value = (raw["email"] ?? profile["email"] ?? "").toString();
    rozet.value = (raw["rozet"] ?? profile["rozet"] ?? "").toString();
    bio.value = (raw["bio"] ?? profile["bio"] ?? "").toString();
    adres.value = (raw["adres"] ?? profile["adres"] ?? "").toString();
    meslek.value =
        (raw["meslekKategori"] ?? profile["meslekKategori"] ?? "").toString();

    totalMarket.value = 0;
    final postsCount = raw["counterOfPosts"] ?? stats["counterOfPosts"] ?? 0;
    final likesCount = raw["counterOfLikes"] ?? stats["counterOfLikes"] ?? 0;
    totalPosts.value = (postsCount is num) ? postsCount.toInt() : 0;
    totalLikes.value = (likesCount is num) ? likesCount.toInt() : 0;
    _applySupplementalUserData(raw);
  }

  void _applySupplementalUserData(Map<String, dynamic> raw) {
    final profile = (raw["profile"] is Map)
        ? Map<String, dynamic>.from(raw["profile"] as Map)
        : const <String, dynamic>{};
    final preferences = (raw["preferences"] is Map)
        ? Map<String, dynamic>.from(raw["preferences"] as Map)
        : const <String, dynamic>{};
    final stats = (raw["stats"] is Map)
        ? Map<String, dynamic>.from(raw["stats"] as Map)
        : const <String, dynamic>{};

    email.value = (raw["email"] ?? profile["email"] ?? "").toString();
    token.value = (raw["token"] ?? "").toString();
    phoneNumber.value =
        (raw["phoneNumber"] ?? profile["phoneNumber"] ?? "").toString();
    mailIzin.value =
        (raw["mailIzin"] ?? preferences["mailIzin"] ?? false) == true;
    aramaIzin.value =
        (raw["aramaIzin"] ?? preferences["aramaIzin"] ?? false) == true;
    ban.value = (raw["isBanned"] ?? raw["ban"] ?? false) == true;
    gizliHesap.value = (raw["isPrivate"] ?? raw["gizliHesap"] ?? false) == true;
    hesapOnayi.value =
        (raw["isApproved"] ?? raw["hesapOnayi"] ?? false) == true;
    final blocked = raw["blockedUsers"];
    if (blocked is List) {
      blockedUsers.value = blocked.map((e) => e.toString()).toList();
    } else {
      blockedUsers.clear();
    }
    final postsCount = raw["counterOfPosts"] ?? stats["counterOfPosts"] ?? 0;
    final likesCount = raw["counterOfLikes"] ?? stats["counterOfLikes"] ?? 0;
    totalPosts.value =
        (postsCount is num) ? postsCount.toInt() : totalPosts.value;
    totalLikes.value =
        (likesCount is num) ? likesCount.toInt() : totalLikes.value;
  }

  Future<void> toggleFollowStatus() async {
    if (followLoading.value) return;
    final bool wasFollowing = takipEdiyorum.value;
    // Optimistic UI update
    takipEdiyorum.value = !wasFollowing;
    followLoading.value = true;
    try {
      final outcome = await FollowService.toggleFollow(userID);
      // Reconcile with server outcome
      takipEdiyorum.value = outcome.nowFollowing;
      final currentUid = CurrentUserService.instance.userId;
      if (currentUid.isNotEmpty) {
        _followCheckCache['$currentUid:$userID'] = _SocialFollowCheckCacheEntry(
          isFollowing: outcome.nowFollowing,
          cachedAt: DateTime.now(),
        );
      }

      // ⚠️ CRITICAL FIX: Update follower count after follow/unfollow
      if (outcome.nowFollowing && !wasFollowing) {
        // Followed - increase follower count
        totalFollower.value++;
        NotificationService.instance.sendNotification(
          token: token.value,
          title: CurrentUserService.instance.nickname,
          body: "seni takip etmeye başladı",
          docID: userID,
          type: "User",
        );
      } else if (!outcome.nowFollowing && wasFollowing) {
        // Unfollowed - decrease follower count
        totalFollower.value--;
      }

      if (outcome.limitReached) {
        AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
      }
    } catch (e) {
      // Revert on error
      takipEdiyorum.value = wasFollowing;
      print("Bir hata oluştu: $e");
    } finally {
      followLoading.value = false;
    }
  }

  Future<void> block() async {
    await noYesAlert(
      title: 'common.block'.tr,
      message: 'social_profile.block_confirm_body'
          .trParams({'nickname': nickname.value}),
      cancelText: 'common.cancel'.tr,
      yesText: 'common.block'.tr,
      onYesPressed: () async {
        final currentUid = CurrentUserService.instance.userId;

        // 1) Engellenenler listesine ekle (canonical subcollection + legacy array)
        await _userSubcollectionRepository.upsertEntry(
          currentUid,
          subcollection: 'blockedUsers',
          docId: userID,
          data: {
            "userID": userID,
            "updatedDate": DateTime.now().millisecondsSinceEpoch,
          },
        );

        // 2) Takip ilişkilerini temizle
        await _followRepository.deleteRelationPair(
          currentUid: currentUid,
          otherUid: userID,
        );
        await _followRepository.deleteRelationPair(
          currentUid: userID,
          otherUid: currentUid,
        );

        // 3) Veri yenileme
        CurrentUserService.instance.forceRefresh();
        getUserData();
        isFollowingCheck();
      },
    );
  }

  Future<void> unblock() async {
    await noYesAlert(
      title: 'blocked_users.unblock_confirm_title'.tr,
      message: 'blocked_users.unblock_confirm_body'
          .trParams({'nickname': nickname.value}),
      cancelText: 'common.cancel'.tr,
      yesText: 'blocked_users.unblock'.tr,
      onYesPressed: () async {
        // 1) Engellenenler listesinden kaldır
        final currentUid = CurrentUserService.instance.userId;
        await _userSubcollectionRepository.deleteEntry(
          currentUid,
          subcollection: 'blockedUsers',
          docId: userID,
        );
        // 2) Verileri yenile
        CurrentUserService.instance.forceRefresh();
        getUserData();
        isFollowingCheck();
      },
    );
  }

  Future<void> getUserStoryUserModelAndPrint(String userId) async {
    final stories = await _storyRepository.getStoriesForUser(
      userId,
      preferCache: true,
    );

    if (stories.isEmpty) {
      print("Kullanıcıya ait hiç hikaye yok.");
      return;
    }

    // Kullanıcı bilgisini çek
    final summary = await _userSummaryResolver.resolve(
      userId,
      preferCache: true,
    );
    if (summary == null) {
      print("Kullanıcı bulunamadı.");
      return;
    }
    final raw = await _userRepository.getUserRaw(
      userId,
      preferCache: true,
      cacheOnly: true,
    );
    final fullNameSource = raw ?? const <String, dynamic>{};
    final userModel = StoryUserModel(
      nickname: summary.nickname,
      avatarUrl: summary.avatarUrl,
      fullName:
          "${fullNameSource['firstName'] ?? ""} ${fullNameSource['lastName'] ?? ""}"
              .trim(),
      userID: userId,
      stories: stories,
    );

    print("Kullanıcı StoryUserModel: $userModel");
    storyUserModel = userModel;
    print(
        "Nickname: ${userModel.nickname}, Story Sayısı: ${userModel.stories.length}");
  }

  void _pruneCaches() {
    final now = DateTime.now();
    bool isStale(DateTime t) => now.difference(t) > _cacheStaleRetention;
    _followCheckCache.removeWhere((_, v) => isStale(v.cachedAt));
    _counterCache.removeWhere((_, v) => isStale(v.cachedAt));
    _trimMap(_followCheckCache, (v) => v.cachedAt);
    _trimMap(_counterCache, (v) => v.cachedAt);
  }

  void _trimMap<T>(Map<String, T> map, DateTime Function(T value) cachedAt) {
    if (map.length <= _maxCacheEntries) return;
    final entries = map.entries.toList()
      ..sort((a, b) => cachedAt(a.value).compareTo(cachedAt(b.value)));
    final removeCount = map.length - _maxCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      map.remove(entries[i].key);
    }
  }

  Future<void> _restoreCachedBuckets() async {
    final buckets = await _profileRepository.readCachedBuckets(userID);
    if (buckets == null) return;
    if (buckets.all.isNotEmpty) {
      allPosts.assignAll(buckets.all);
    }
    if (buckets.photos.isNotEmpty) {
      photos.assignAll(buckets.photos);
    }
    if (buckets.scheduled.isNotEmpty) {
      scheduledPosts.assignAll(buckets.scheduled);
    }
  }

  Future<void> _fetchPrimaryBuckets({
    required bool initial,
    bool force = false,
  }) async {
    if (_isLoadingPrimary && !force) return;
    if (!initial && !_hasMorePrimary) return;

    _isLoadingPrimary = true;
    isLoadingPosts.value = true;
    isLoadingPhoto.value = true;
    isLoadingScheduled.value = true;
    try {
      if (initial) {
        _lastPrimaryDoc = null;
        _hasMorePrimary = true;
      }

      final page = await PerformanceService.traceFeedLoad(
        () => _profileRepository.fetchPrimaryPage(
          uid: userID,
          startAfter: initial ? null : _lastPrimaryDoc,
          limit: pageSize,
        ),
        postCount: allPosts.length,
        feedMode: 'profile_primary',
      );

      if (initial) {
        allPosts.assignAll(page.all);
        photos.assignAll(page.photos);
        scheduledPosts.assignAll(page.scheduled);
      } else {
        allPosts.addAll(_dedupePosts(allPosts, page.all));
        photos.addAll(_dedupePosts(photos, page.photos));
        scheduledPosts.addAll(_dedupePosts(scheduledPosts, page.scheduled));
      }

      _lastPrimaryDoc = page.lastDoc;
      _hasMorePrimary = page.hasMore;
      lastPostDoc = _lastPrimaryDoc;
      lastPostDocPhoto = _lastPrimaryDoc;
      lastScheduledDoc = _lastPrimaryDoc;
      hasMorePosts.value = _hasMorePrimary;
      hasMorePhoto.value = _hasMorePrimary;
      hasMoreScheduled.value = _hasMorePrimary;

      await _profileRepository.writeBuckets(
        userID,
        ProfileBuckets(
          all: allPosts,
          photos: photos,
          videos: allPosts.where((post) => post.hasPlayableVideo).toList(),
          scheduled: scheduledPosts,
        ),
      );
    } catch (e) {
      print('_fetchPrimaryBuckets(SocialProfile) error: $e');
    } finally {
      _isLoadingPrimary = false;
      isLoadingPosts.value = false;
      isLoadingPhoto.value = false;
      isLoadingScheduled.value = false;
    }
  }

  List<PostsModel> _dedupePosts(
    List<PostsModel> existing,
    List<PostsModel> incoming,
  ) {
    final known = existing.map((e) => e.docID).toSet();
    return incoming.where((post) => known.add(post.docID)).toList();
  }
}

class _SocialFollowCheckCacheEntry {
  final bool isFollowing;
  final DateTime cachedAt;

  const _SocialFollowCheckCacheEntry({
    required this.isFollowing,
    required this.cachedAt,
  });
}

class _SocialCounterCacheEntry {
  final int followers;
  final int followings;
  final DateTime cachedAt;

  const _SocialCounterCacheEntry({
    required this.followers,
    required this.followings,
    required this.cachedAt,
  });
}

final VisibilityPolicyService _visibilityPolicy =
    VisibilityPolicyService.ensure();
