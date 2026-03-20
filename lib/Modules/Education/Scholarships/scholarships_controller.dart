import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_snapshot_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cached_resource.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
// Corporate ScholarshipsModel no longer used; only IndividualScholarshipsModel remains
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart';

class ScholarshipsController extends GetxController {
  final FollowRepository _followRepository = FollowRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
  final ScholarshipSnapshotRepository _scholarshipSnapshotRepository =
      ScholarshipSnapshotRepository.ensure();
  final ScrollController scrollController = ScrollController();
  final RxList<Map<String, dynamic>> allScholarships =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> visibleScholarships =
      <Map<String, dynamic>>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool isSearching = false.obs;
  final RxMap<String, bool> likedScholarships = <String, bool>{}.obs;
  final RxMap<String, bool> bookmarkedScholarships = <String, bool>{}.obs;
  final List<RxBool> isExpandedList = [];
  final RxMap<String, bool> followedUsers = <String, bool>{}.obs;
  final RxMap<String, bool> followLoading = <String, bool>{}.obs;
  final Set<String> _likedByCurrentUser = <String>{};
  final Set<String> _bookmarkedByCurrentUser = <String>{};
  final Map<String, String> _shortLinkCache = <String, String>{};
  final Set<String> _shortLinkInFlight = <String>{};
  static const int _shortLinkPrefetchLimit = 6;
  static const String _defaultOgImage =
      'https://cdn.turqapp.com/og/default.jpg';
  DateTime? lastRefresh;
  final RxMap<int, RxInt> pageIndices = <int, RxInt>{}.obs;
  final RxDouble scrollOffset = 0.0.obs;
  final int initialBatchSize = 30;
  final int batchSize = 30;
  final RxBool hasMoreData = true.obs;
  final RxInt totalCount = 0.obs;
  Timer? _searchDebounce;
  final int minSearchLength = 2; // minimum search query length
  int _searchRequestToken = 0;
  int _typesensePage = 0;
  StreamSubscription<CachedResource<ScholarshipListingSnapshot>>?
      _homeSnapshotSub;

  bool get hasActiveSearch => searchQuery.value.length >= minSearchLength;

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    unawaited(_bootstrapScholarships());
  }

  Future<void> _bootstrapScholarships() async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _scholarshipSnapshotRepository
        .openHome(
          userId: userId,
          limit: initialBatchSize,
        )
        .listen(_applyHomeSnapshotResource);
  }

  @override
  void onClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> refreshTotalCount() async {
    if (allScholarships.isNotEmpty) {
      totalCount.value = totalCount.value < allScholarships.length
          ? allScholarships.length
          : totalCount.value;
      return;
    }
    try {
      final result = await _scholarshipSnapshotRepository.loadHome(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 1,
      );
      totalCount.value = result.data?.found ?? 0;
    } catch (_) {}
  }

  void setSearchQuery(String q) {
    searchQuery.value = q.trim();
    _searchDebounce?.cancel();
    if (!hasActiveSearch) {
      isSearching.value = false;
      _setVisibleScholarships(allScholarships);
      return;
    }

    final requestToken = ++_searchRequestToken;
    isSearching.value = true;
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      await _searchFromTypesense(searchQuery.value, requestToken);
    });
  }

  void resetSearch() {
    _searchDebounce?.cancel();
    _searchRequestToken++;
    searchQuery.value = '';
    isSearching.value = false;
    _setVisibleScholarships(allScholarships);
  }

  void _applyScholarshipStateFromCombined(List<Map<String, dynamic>> combined) {
    allScholarships.clear();
    allScholarships.addAll(combined);
    _setVisibleScholarships(hasActiveSearch ? visibleScholarships : combined);
  }

  void _setVisibleScholarships(List<Map<String, dynamic>> items) {
    visibleScholarships.assignAll(items);
    isExpandedList
      ..clear()
      ..addAll(List<RxBool>.generate(items.length, (_) => false.obs));
    pageIndices
      ..clear()
      ..addAll(
        Map.fromIterables(
          List.generate(items.length, (i) => i),
          List.generate(items.length, (_) => 0.obs),
        ),
      );
  }

  Future<void> _searchFromTypesense(String query, int requestToken) async {
    final normalized = query.trim();
    if (normalized.length < minSearchLength) {
      if (requestToken == _searchRequestToken) {
        isSearching.value = false;
        _setVisibleScholarships(allScholarships);
      }
      return;
    }

    try {
      final result = await _scholarshipSnapshotRepository.search(
        query: normalized,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: 40,
        forceSync: true,
      );
      if (requestToken != _searchRequestToken ||
          searchQuery.value.trim() != normalized) {
        return;
      }

      final items = result.data?.items ?? const <Map<String, dynamic>>[];
      await _primeLocalStateForCombined(items);
      if (requestToken != _searchRequestToken ||
          searchQuery.value.trim() != normalized) {
        return;
      }
      _setVisibleScholarships(items);
    } catch (_) {
      if (requestToken == _searchRequestToken) {
        _setVisibleScholarships(const []);
      }
    } finally {
      if (requestToken == _searchRequestToken) {
        isSearching.value = false;
      }
    }
  }

  Future<void> _primeLocalStateForCombined(
    List<Map<String, dynamic>> items,
  ) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final followTasks = <Future<void>>[];

    for (final item in items) {
      final docId = (item['docId'] ?? '').toString().trim();
      final model = item['model'] as IndividualScholarshipsModel?;
      final userData = Map<String, dynamic>.from(
        item['userData'] as Map? ?? const <String, dynamic>{},
      );
      final userID = (userData['userID'] ?? model?.userID ?? '')
          .toString()
          .trim();
      likedScholarships.putIfAbsent(
        docId,
        () => _likedByCurrentUser.contains(docId) ||
            (currentUserId.isNotEmpty &&
                (model?.begeniler.contains(currentUserId) ?? false)),
      );
      bookmarkedScholarships.putIfAbsent(
        docId,
        () => _bookmarkedByCurrentUser.contains(docId) ||
            (currentUserId.isNotEmpty &&
                (model?.kaydedenler.contains(currentUserId) ?? false)),
      );
      if (currentUserId.isNotEmpty &&
          userID.isNotEmpty &&
          !followedUsers.containsKey(userID)) {
        followTasks.add(() async {
          followedUsers[userID] =
              await _checkFollowStatus(userID, currentUserId);
        }());
      }
    }
    if (followTasks.isNotEmpty) {
      await Future.wait(followTasks);
    }
  }

  Future<bool> _checkFollowStatus(String followedId, String followerId) async {
    return _followRepository.isFollowing(
      followedId,
      currentUid: followerId,
      preferCache: true,
    );
  }

  Future<void> toggleFollow(String followedId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    followLoading[followedId] = true;
    try {
      final outcome = await FollowService.toggleFollow(followedId);
      if (outcome.limitReached) {
        AppSnackbar(
          'common.warning'.tr,
          'follow.daily_limit_reached'.tr,
        );
        return;
      }
      followedUsers[followedId] = outcome.nowFollowing;
    } finally {
      followLoading[followedId] = false;
    }
  }

  Future<void> fetchScholarships({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        lastRefresh != null &&
        DateTime.now().difference(lastRefresh!).inSeconds < 2) {
      return;
    }
    lastRefresh = DateTime.now();

    try {
      if (!silent) {
        isLoading.value = true;
      }
      final result = await _scholarshipSnapshotRepository.loadHome(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: initialBatchSize,
        forceSync: forceRefresh,
      );
      _typesensePage = 1;
      final snapshot = result.data;
      totalCount.value = snapshot?.found ?? 0;
      final combined = snapshot?.items ?? const <Map<String, dynamic>>[];
      await _primeLocalStateForCombined(combined);

      _applyScholarshipStateFromCombined(combined);
      if (hasActiveSearch) {
        unawaited(
            _searchFromTypesense(searchQuery.value, ++_searchRequestToken));
      }
      _prefetchShortLinksForList(allScholarships);
      SilentRefreshGate.markRefreshed('scholarships:home');
      hasMoreData.value = combined.length >= initialBatchSize &&
          allScholarships.length < totalCount.value;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreScholarships() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      return;
    }

    try {
      isLoadingMore.value = true;
      final result = await _scholarshipSnapshotRepository.loadHome(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        limit: batchSize,
        page: _typesensePage + 1,
        forceSync: true,
      );
      _typesensePage += 1;
      final snapshot = result.data;
      totalCount.value = snapshot?.found ?? totalCount.value;
      final combined = snapshot?.items ?? const <Map<String, dynamic>>[];
      await _primeLocalStateForCombined(combined);

      isExpandedList.addAll(
        List<RxBool>.generate(combined.length, (_) => false.obs),
      );
      final newPageIndices = Map.fromIterables(
        List.generate(combined.length, (i) => allScholarships.length + i),
        List.generate(combined.length, (_) => 0.obs),
      );
      pageIndices.addAll(newPageIndices);

      allScholarships.addAll(combined);
      if (hasActiveSearch) {
        unawaited(
            _searchFromTypesense(searchQuery.value, ++_searchRequestToken));
      } else {
        _setVisibleScholarships(allScholarships);
      }
      _prefetchShortLinksForList(allScholarships);
      hasMoreData.value = combined.length >= batchSize &&
          allScholarships.length < totalCount.value;
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.load_more_failed'.tr);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void updatePageIndex(int scholarshipIndex, int pageIndex) {
    pageIndices[scholarshipIndex]?.value = pageIndex;
  }

  Future<void> toggleLike(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      return;
    }
    final userId = user.uid;
    final wasLiked = likedScholarships[docId] ?? false;

    try {
      likedScholarships[docId] = !wasLiked;
      if (wasLiked) {
        _likedByCurrentUser.remove(docId);
      } else {
        _likedByCurrentUser.add(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['likesCount'] ?? 0) as int;
        final next = (current + (wasLiked ? -1 : 1)).clamp(0, 1 << 30);
        allScholarships[index]['likesCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['likesCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['likesCount'] =
            (current + (wasLiked ? -1 : 1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }

      await _scholarshipRepository.toggleLike(docId, userId: userId);
    } catch (_) {
      likedScholarships[docId] = wasLiked;
      if (wasLiked) {
        _likedByCurrentUser.add(docId);
      } else {
        _likedByCurrentUser.remove(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['likesCount'] ?? 0) as int;
        final next = (current + (wasLiked ? 1 : -1)).clamp(0, 1 << 30);
        allScholarships[index]['likesCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['likesCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['likesCount'] =
            (current + (wasLiked ? 1 : -1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }
      AppSnackbar('common.error'.tr, 'scholarship.like_failed'.tr);
    }
  }

  Future<void> toggleBookmark(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('common.error'.tr, 'scholarship.session_missing'.tr);
      return;
    }
    final userId = user.uid;
    final wasBookmarked = bookmarkedScholarships[docId] ?? false;

    try {
      bookmarkedScholarships[docId] = !wasBookmarked;
      if (wasBookmarked) {
        _bookmarkedByCurrentUser.remove(docId);
      } else {
        _bookmarkedByCurrentUser.add(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['bookmarksCount'] ?? 0) as int;
        final next = (current + (wasBookmarked ? -1 : 1)).clamp(0, 1 << 30);
        allScholarships[index]['bookmarksCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['bookmarksCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['bookmarksCount'] =
            (current + (wasBookmarked ? -1 : 1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }

      await _scholarshipRepository.toggleBookmark(docId, userId: userId);
    } catch (_) {
      bookmarkedScholarships[docId] = wasBookmarked;
      if (wasBookmarked) {
        _bookmarkedByCurrentUser.add(docId);
      } else {
        _bookmarkedByCurrentUser.remove(docId);
      }
      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        final current = (allScholarships[index]['bookmarksCount'] ?? 0) as int;
        final next = (current + (wasBookmarked ? 1 : -1)).clamp(0, 1 << 30);
        allScholarships[index]['bookmarksCount'] = next;
        allScholarships.refresh();
      }
      final visibleIndex =
          visibleScholarships.indexWhere((s) => s['docId'] == docId);
      if (visibleIndex != -1) {
        final current =
            (visibleScholarships[visibleIndex]['bookmarksCount'] ?? 0) as int;
        visibleScholarships[visibleIndex]['bookmarksCount'] =
            (current + (wasBookmarked ? 1 : -1)).clamp(0, 1 << 30);
        visibleScholarships.refresh();
      }
      AppSnackbar('common.error'.tr, 'scholarship.bookmark_failed'.tr);
    }
  }

  Future<void> shareScholarship(
    Map<String, dynamic> scholarshipData,
    BuildContext context,
  ) async {
    final burs = scholarshipData['model'];
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final ownerUid =
        (burs?.userID ?? scholarshipData['userID'] ?? '').toString();
    final canShare = AdminAccessService.isKnownAdminSync() ||
        (ownerUid.isNotEmpty && ownerUid == currentUid);
    if (!canShare) {
      AppSnackbar('common.error'.tr, 'scholarship.share_owner_only'.tr);
      return;
    }
    await _shareScholarshipPublicLink(scholarshipData, burs);
  }

  Future<void> shareScholarshipExternally(
    Map<String, dynamic> scholarshipData,
  ) async {
    final burs = scholarshipData['model'];
    await _shareScholarshipPublicLink(scholarshipData, burs);
  }

  Future<void> _shareScholarshipPublicLink(
    Map<String, dynamic> scholarshipData,
    dynamic burs,
  ) async {
    final String docId =
        (scholarshipData['docId'] ?? scholarshipData['scholarshipId'] ?? '')
            .toString();
    if (docId.isEmpty) {
      AppSnackbar('common.error'.tr, 'scholarship.share_missing_id'.tr);
      return;
    }
    final String shareId = 'scholarship:$docId';
    final String shortTail = docId.length >= 8 ? docId.substring(0, 8) : docId;
    final String fallbackId = 'scholarship-$shortTail';
    final String fallbackUrl = 'https://turqapp.com/e/$fallbackId';
    final String title = _pickScholarshipTitle(scholarshipData, burs);
    final String normalizedTitle = normalizeSearchText(title);
    final String shortDesc = burs.shortDescription.trim();
    final String providerDesc = burs.bursVeren.trim();
    final String desc = shortDesc.isNotEmpty &&
            normalizeSearchText(shortDesc) != normalizedTitle
        ? shortDesc
        : (providerDesc.isNotEmpty &&
                normalizeSearchText(providerDesc) != normalizedTitle
            ? providerDesc
            : 'scholarship.share_fallback_desc'.tr);
    final String existingShortUrl = _readTextField(scholarshipData, 'shortUrl');
    final String? shareImageUrl =
        _pickScholarshipImageFromData(scholarshipData, burs);
    try {
      await ShareActionGuard.run(() async {
        String shortUrl = '';
        try {
          shortUrl = await ShortLinkService().getEducationPublicUrl(
            shareId: shareId,
            title: title,
            desc: desc,
            imageUrl: shareImageUrl,
          );
          if (shortUrl.trim().isNotEmpty &&
              shortUrl.trim() != 'https://turqapp.com') {
            _shortLinkCache[shareId] = shortUrl;
          }
        } catch (_) {
          shortUrl = fallbackUrl;
        }

        if (shortUrl.trim().isEmpty ||
            shortUrl.trim() == 'https://turqapp.com') {
          shortUrl =
              existingShortUrl.isNotEmpty ? existingShortUrl : fallbackUrl;
        }

        await ShareLinkService.shareUrl(
          url: shortUrl,
          title: title,
          subject: title,
        );
      });
    } catch (_) {
      AppSnackbar('common.error'.tr, 'scholarship.share_failed'.tr);
    }
  }

  void _prefetchShortLinksForList(List<Map<String, dynamic>> list) {
    final items = list.take(_shortLinkPrefetchLimit).toList();
    for (final item in items) {
      final docId = (item['docId'] ?? '').toString();
      if (docId.isEmpty) continue;
      final shareId = 'scholarship:$docId';
      if (_shortLinkCache.containsKey(shareId) ||
          _shortLinkInFlight.contains(shareId)) {
        continue;
      }
      _shortLinkInFlight.add(shareId);
      final model = item['model'] as IndividualScholarshipsModel?;
      final title = model != null
          ? _pickScholarshipTitle(item, model)
          : 'scholarship.share_detail_title'.tr;
      final imageUrl =
          model != null ? _pickScholarshipImageFromData(item, model) : null;
      unawaited(() async {
        try {
          final shortUrl = await ShortLinkService().getEducationPublicUrl(
            shareId: shareId,
            title: title,
            desc: model != null
                ? _pickScholarshipShareDesc(model)
                : 'scholarship.share_fallback_desc'.tr,
            imageUrl: imageUrl,
          );
          if (shortUrl.trim().isNotEmpty &&
              shortUrl.trim() != 'https://turqapp.com') {
            _shortLinkCache[shareId] = shortUrl;
          }
        } catch (_) {
          // ignore; fallback will be used during share
        } finally {
          _shortLinkInFlight.remove(shareId);
        }
      }());
    }
  }

  String? _pickScholarshipShareImage(IndividualScholarshipsModel model) {
    final img = model.img.trim();
    if (img.isNotEmpty) return img;
    final img2 = model.img2.trim();
    if (img2.isNotEmpty) return img2;
    final logo = model.logo.trim();
    if (logo.isNotEmpty) return logo;
    return _defaultOgImage;
  }

  String _readTextField(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) return '';
    return value.toString().trim();
  }

  String _pickScholarshipTitle(
    Map<String, dynamic> data,
    IndividualScholarshipsModel model,
  ) {
    final fromBaslik = _readTextField(data, 'baslik');
    if (fromBaslik.isNotEmpty) return fromBaslik;
    return model.baslik.trim();
  }

  String? _pickScholarshipImageFromData(
    Map<String, dynamic> data,
    IndividualScholarshipsModel model,
  ) {
    final img = _readTextField(data, 'img');
    if (img.isNotEmpty) return img;
    final img2 = _readTextField(data, 'img2');
    if (img2.isNotEmpty) return img2;
    final logo = _readTextField(data, 'logo');
    if (logo.isNotEmpty) return logo;
    return _pickScholarshipShareImage(model);
  }

  String _pickScholarshipShareDesc(IndividualScholarshipsModel model) {
    final normalizedTitle = normalizeSearchText(model.baslik);
    final shortDesc = model.shortDescription.trim();
    if (shortDesc.isNotEmpty &&
        normalizeSearchText(shortDesc) != normalizedTitle) {
      return shortDesc;
    }
    final provider = model.bursVeren.trim();
    if (provider.isNotEmpty && normalizeSearchText(provider) != normalizedTitle) {
      return provider;
    }
    return 'scholarship.share_fallback_desc'.tr;
  }

  void toggleExpanded(int index) {
    if (index >= 0 && index < isExpandedList.length) {
      isExpandedList[index].value = !isExpandedList[index].value;
    }
  }

  void settings(BuildContext context) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1 / 1.2,
            ),
            itemCount: informations.length,
            itemBuilder: (context, index) {
              final item = informations[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  switch (index) {
                    case 0:
                      Get.to(() => PersonelInfoView());
                      break;
                    case 1:
                      Get.to(() => EducationInfoView());
                      break;
                    case 2:
                      Get.to(() => FamilyInfoView());
                      break;
                    case 3:
                      Get.to(() => DormitoryInfoView());
                      break;
                  }
                },
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item.color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: Colors.white, size: 40),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      item.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _applyHomeSnapshotResource(
    CachedResource<ScholarshipListingSnapshot> resource,
  ) {
    final snapshot = resource.data;
    final items = snapshot?.items ?? const <Map<String, dynamic>>[];
    if (snapshot != null) {
      totalCount.value = snapshot.found;
      _typesensePage = 1;
    }
    if (items.isNotEmpty) {
      unawaited(_primeLocalStateForCombined(items));
      _applyScholarshipStateFromCombined(items);
      _prefetchShortLinksForList(allScholarships);
      hasMoreData.value =
          items.length >= initialBatchSize && allScholarships.length < totalCount.value;
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (allScholarships.isEmpty) {
      isLoading.value = true;
    }
  }

  List<InformationModel> get informations => [
        InformationModel(
          title: 'scholarship.info.personal'.tr,
          color: colors[0],
          icon: icons[0],
        ),
        InformationModel(
          title: 'scholarship.info.school'.tr,
          color: colors[1],
          icon: icons[1],
        ),
        InformationModel(
          title: 'scholarship.info.family'.tr,
          color: colors[2],
          icon: icons[2],
        ),
        InformationModel(
          title: 'scholarship.info.dormitory'.tr,
          color: colors[3],
          icon: icons[3],
        ),
      ];
}

class InformationModel {
  final String title;
  final Color color;
  final IconData icon;

  InformationModel({
    required this.title,
    required this.color,
    required this.icon,
  });
}

List<Color> colors = [
  Colors.blueGrey,
  Colors.teal,
  Colors.deepOrange,
  Colors.indigo,
];

List<IconData> icons = [
  CupertinoIcons.person,
  CupertinoIcons.building_2_fill,
  CupertinoIcons.person_2,
  CupertinoIcons.house_fill,
];
