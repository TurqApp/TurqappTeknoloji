import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/scholarship_repository.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
// Corporate ScholarshipsModel no longer used; only IndividualScholarshipsModel remains
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart';

class ScholarshipsController extends GetxController {
  final UserRepository _userRepository = UserRepository.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final ScholarshipRepository _scholarshipRepository =
      ScholarshipRepository.ensure();
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
  DocumentSnapshot? lastBireyselDoc;
  final RxBool hasMoreData = true.obs;
  final RxInt totalCount = 0.obs;
  Timer? _searchDebounce;
  final int minSearchLength = 2; // minimum search query length
  static const String _scholarshipsCacheKeyPrefix = 'scholarships_cache_v1';
  static const int _scholarshipsCacheLimit = 30;
  int _searchRequestToken = 0;

  String get _scholarshipsCacheKey {
    final uid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (uid.isEmpty) return '$_scholarshipsCacheKeyPrefix:guest';
    return '$_scholarshipsCacheKeyPrefix:$uid';
  }

  bool get hasActiveSearch => searchQuery.value.length >= minSearchLength;

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    refreshTotalCount();
    fetchScholarships();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  Future<void> refreshTotalCount() async {
    try {
      totalCount.value = await _scholarshipRepository.fetchTotalCount(
        preferCache: true,
      );
    } catch (e) {
      // ignore silently; keep last known count
    }
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

  void _sortByTimestamp(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      return (b['timeStamp'] as int).compareTo(a['timeStamp'] as int);
    });
  }

  Future<void> _saveScholarshipsCache(List<Map<String, dynamic>> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = list.take(_scholarshipsCacheLimit).map((item) {
        final model = item['model'] as IndividualScholarshipsModel;
        return <String, dynamic>{
          'docId': item['docId'],
          'type': item['type'],
          'model': model.toJson(),
          'userData': item['userData'] ?? {},
          'likesCount': item['likesCount'] ?? 0,
          'bookmarksCount': item['bookmarksCount'] ?? 0,
          'timeStamp': item['timeStamp'] ?? 0,
          'isSummary': item['isSummary'] ?? false,
        };
      }).toList();
      await prefs.setString(_scholarshipsCacheKey, jsonEncode(payload));
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadScholarshipsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_scholarshipsCacheKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      final list = <Map<String, dynamic>>[];
      for (final e in decoded) {
        if (e is! Map) continue;
        final map = Map<String, dynamic>.from(e);
        final modelMap = Map<String, dynamic>.from(map['model'] as Map? ?? {});
        list.add({
          'model': IndividualScholarshipsModel.fromJson(modelMap),
          'type': map['type'] ?? 'bireysel',
          'userData': Map<String, dynamic>.from(map['userData'] as Map? ?? {}),
          'docId': map['docId'] ?? '',
          'likesCount': map['likesCount'] ?? 0,
          'bookmarksCount': map['bookmarksCount'] ?? 0,
          'timeStamp': map['timeStamp'] ?? 0,
          'isSummary': map['isSummary'] ?? false,
        });
      }
      _sortByTimestamp(list);
      return list;
    } catch (_) {
      return const [];
    }
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
      final docIds =
          await TypesenseEducationSearchService.instance.searchDocIds(
        entity: EducationTypesenseEntity.scholarship,
        query: normalized,
        limit: 40,
      );
      if (requestToken != _searchRequestToken ||
          searchQuery.value.trim() != normalized) {
        return;
      }

      final items = await _fetchScholarshipItemsByDocIds(docIds);
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

  Future<List<Map<String, dynamic>>> _fetchScholarshipItemsByDocIds(
    List<String> docIds,
  ) async {
    final orderedIds = docIds.where((id) => id.trim().isNotEmpty).toList();
    if (orderedIds.isEmpty) return const [];

    final docs = await _scholarshipRepository.fetchByIdsRaw(orderedIds);
    final userIds = docs
        .map((doc) => doc['userID'] as String? ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final userDocsById = await _fetchUsersByIds(userIds);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final items = <Map<String, dynamic>>[];

    for (final doc in docs) {
      final data = Map<String, dynamic>.from(doc);
      final currentDocId = (data['docId'] ?? '').toString();
      final userID = data['userID'] as String? ?? '';
      final userData = _buildUserDataFromDoc(userID, userDocsById[userID]);
      final begeniler = data['begeniler'] as List<dynamic>? ?? [];
      final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];
      final likesCount = (data['likesCount'] as int?) ?? begeniler.length;
      final bookmarksCount =
          (data['bookmarksCount'] as int?) ?? kaydedenler.length;

      items.add({
        'model': IndividualScholarshipsModel.fromJson(data),
        'type': 'bireysel',
        'userData': userData,
        'docId': (data['docId'] ?? '').toString(),
        'likesCount': likesCount,
        'bookmarksCount': bookmarksCount,
        'timeStamp': data['timeStamp'] as int? ?? 0,
        'isSummary': false,
      });

      if (currentUserId.isNotEmpty) {
        likedScholarships[currentDocId] = begeniler.contains(currentUserId) ||
            _likedByCurrentUser.contains(currentDocId);
        bookmarkedScholarships[currentDocId] =
            kaydedenler.contains(currentUserId) ||
                _bookmarkedByCurrentUser.contains(currentDocId);
        if (userID.isNotEmpty && !followedUsers.containsKey(userID)) {
          followedUsers[userID] =
              await _checkFollowStatus(userID, currentUserId);
        }
      }
    }

    return items;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsersByIds(
      List<String> userIds) async {
    final uniqueIds = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) return {};

    return _userRepository.getUsersRaw(uniqueIds);
  }

  Map<String, dynamic> _buildUserDataFromDoc(
    String userId,
    dynamic userDoc,
  ) {
    if (userId.isEmpty || userDoc == null) {
      return {'avatarUrl': '', 'nickname': '', 'userID': userId};
    }
    final data = userDoc is Map<String, dynamic>
        ? userDoc
        : (userDoc.data() as Map<String, dynamic>? ?? {});
    final profileName =
        (data['displayName'] ?? data['username'] ?? data['nickname'] ?? '')
            .toString();
    final profileImage = (data['avatarUrl'] ?? '').toString();
    return {
      'avatarUrl': profileImage,
      'nickname': profileName,
      'displayName': profileName,
      'userID': userId,
      'meslekKategori': data['meslekKategori'] as String? ?? '',
      'firstName': data['firstName'] as String? ?? '',
      'lastName': data['lastName'] as String? ?? '',
    };
  }

  Future<void> fetchScholarships() async {
    if (lastRefresh != null &&
        DateTime.now().difference(lastRefresh!).inSeconds < 2) {
      return;
    }
    lastRefresh = DateTime.now();

    try {
      isLoading.value = true;

      // Önce local cache'ten son 30 bursu göster, sonra ağdan tazele
      if (allScholarships.isEmpty) {
        final cached = await _loadScholarshipsCache();
        if (cached.isNotEmpty) {
          _applyScholarshipStateFromCombined(cached);
        }
      }

      final snapshot = await _scholarshipRepository.fetchLatestPage(
        limit: initialBatchSize,
      );

      final bireyselSnapshot = snapshot;

      // Store last documents for pagination
      lastBireyselDoc =
          bireyselSnapshot.docs.isNotEmpty ? bireyselSnapshot.docs.last : null;
      // Kurumsal burslar kaldırıldı

      final combined = <Map<String, dynamic>>[];
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';

      isExpandedList.clear();
      isExpandedList.addAll(
        List<RxBool>.generate(
          bireyselSnapshot.docs.length,
          (_) => false.obs,
        ),
      );

      // Bireysel burslar için kullanıcı verileri (batch getAll)
      final bireyselDocs = bireyselSnapshot.docs;
      final bireyselUserIds = bireyselDocs
          .map((doc) => doc.data()['userID'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final userDocsById = await _fetchUsersByIds(bireyselUserIds);

      for (var doc in bireyselDocs) {
        final data = doc.data();
        final userID = data['userID'] as String? ?? '';
        final userData = _buildUserDataFromDoc(userID, userDocsById[userID]);

        final begeniler = data['begeniler'] as List<dynamic>? ?? [];
        final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];
        final likesCount = (data['likesCount'] as int?) ?? begeniler.length;
        final bookmarksCount =
            (data['bookmarksCount'] as int?) ?? kaydedenler.length;
        combined.add({
          'model': IndividualScholarshipsModel.fromJson(data),
          'type': 'bireysel',
          'userData': userData,
          'docId': doc.id,
          'likesCount': likesCount,
          'bookmarksCount': bookmarksCount,
          'timeStamp': data['timeStamp'] as int? ?? 0, // Include timeStamp
          'isSummary': false,
        });

        if (userId.isNotEmpty) {
          final liked = begeniler.contains(userId) ||
              _likedByCurrentUser.contains(doc.id);
          final bookmarked = kaydedenler.contains(userId) ||
              _bookmarkedByCurrentUser.contains(doc.id);
          likedScholarships[doc.id] = liked;
          bookmarkedScholarships[doc.id] = bookmarked;
          if (userID.isNotEmpty && !followedUsers.containsKey(userID)) {
            followedUsers[userID] = await _checkFollowStatus(userID, userId);
          }
        }
      }

      // Kurumsal burslar kaldırıldı

      // Sort combined list - only creation time
      _applyScholarshipStateFromCombined(combined);
      if (hasActiveSearch) {
        unawaited(
            _searchFromTypesense(searchQuery.value, ++_searchRequestToken));
      }
      await _saveScholarshipsCache(combined);
      _prefetchShortLinksForList(allScholarships);
      // İlk partiden sonra devam var mı? (toplam sayıya göre)
      hasMoreData.value = allScholarships.length < totalCount.value;
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreScholarships() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      return;
    }
    if (lastBireyselDoc == null) {
      hasMoreData.value = false;
      return;
    }

    try {
      isLoadingMore.value = true;

      final snapshot = await _scholarshipRepository.fetchLatestPage(
        limit: batchSize,
        startAfter: lastBireyselDoc,
      );

      final bireyselSnapshot = snapshot;

      // Update last documents for next pagination
      lastBireyselDoc = bireyselSnapshot.docs.isNotEmpty
          ? bireyselSnapshot.docs.last
          : lastBireyselDoc;
      // Kurumsal burslar kaldırıldı

      final combined = <Map<String, dynamic>>[];
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? '';

      // Update isExpandedList and pageIndices
      isExpandedList.addAll(
        List<RxBool>.generate(
          bireyselSnapshot.docs.length,
          (_) => false.obs,
        ),
      );
      final newPageIndices = Map.fromIterables(
        List.generate(
          bireyselSnapshot.docs.length,
          (i) => allScholarships.length + i,
        ),
        List.generate(
          bireyselSnapshot.docs.length,
          (_) => 0.obs,
        ),
      );
      pageIndices.addAll(newPageIndices);

      // Bireysel burslar için kullanıcı verileri (batch getAll)
      final bireyselDocs = bireyselSnapshot.docs;
      final bireyselUserIds = bireyselDocs
          .map((doc) => doc.data()['userID'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      final userDocsById = await _fetchUsersByIds(bireyselUserIds);

      for (var doc in bireyselDocs) {
        final data = doc.data();
        final userID = data['userID'] as String? ?? '';
        final userData = _buildUserDataFromDoc(userID, userDocsById[userID]);

        final begeniler = data['begeniler'] as List<dynamic>? ?? [];
        final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];
        final likesCount = (data['likesCount'] as int?) ?? begeniler.length;
        final bookmarksCount =
            (data['bookmarksCount'] as int?) ?? kaydedenler.length;
        combined.add({
          'model': IndividualScholarshipsModel.fromJson(data),
          'type': 'bireysel',
          'userData': userData,
          'docId': doc.id,
          'likesCount': likesCount,
          'bookmarksCount': bookmarksCount,
          'timeStamp': data['timeStamp'] as int? ?? 0, // Include timeStamp
          'isSummary': false,
        });

        if (userId.isNotEmpty) {
          final liked = begeniler.contains(userId) ||
              _likedByCurrentUser.contains(doc.id);
          final bookmarked = kaydedenler.contains(userId) ||
              _bookmarkedByCurrentUser.contains(doc.id);
          likedScholarships[doc.id] = liked;
          bookmarkedScholarships[doc.id] = bookmarked;
          if (userID.isNotEmpty && !followedUsers.containsKey(userID)) {
            followedUsers[userID] = await _checkFollowStatus(userID, userId);
          }
        }
      }

      // Kurumsal burslar kaldırıldı

      // Yeni eklenen bursları mevcut listeye ekle (orderBy zaten doğru sırada)
      allScholarships.addAll(combined);
      if (hasActiveSearch) {
        unawaited(
            _searchFromTypesense(searchQuery.value, ++_searchRequestToken));
      } else {
        _setVisibleScholarships(allScholarships);
      }
      _prefetchShortLinksForList(allScholarships);
      // Toplam sayıya göre devam kontrolü
      hasMoreData.value = allScholarships.length < totalCount.value;
    } catch (_) {
      AppSnackbar('Hata', 'Daha fazla burs yüklenemedi.');
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
      AppSnackbar('Hata', 'Lütfen oturum açın.');
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
      AppSnackbar('Hata', 'Beğeni işlemi başarısız.');
    }
  }

  Future<void> toggleBookmark(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppSnackbar('Hata', 'Lütfen oturum açın.');
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
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız.');
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
      AppSnackbar('Yetki', 'Sadece admin ve ilan sahibi paylaşabilir.');
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
      AppSnackbar('Hata', 'Paylaşım için burs ID bulunamadı.');
      return;
    }
    final String shareId = 'scholarship:$docId';
    final String shortTail = docId.length >= 8 ? docId.substring(0, 8) : docId;
    final String fallbackId = 'scholarship-$shortTail';
    final String fallbackUrl = 'https://turqapp.com/e/$fallbackId';
    final String title = _pickScholarshipTitle(scholarshipData, burs);
    final String shortDesc = burs.shortDescription.trim();
    final String providerDesc = burs.bursVeren.trim();
    final String desc = shortDesc.isNotEmpty &&
            shortDesc.toLowerCase() != title.trim().toLowerCase()
        ? shortDesc
        : (providerDesc.isNotEmpty &&
                providerDesc.toLowerCase() != title.trim().toLowerCase()
            ? providerDesc
            : 'TurqApp burs ilani');
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
      AppSnackbar('Hata', 'Paylaşım başarısız.');
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
          : 'TurqApp Eğitim - Burs Detayı';
      final imageUrl =
          model != null ? _pickScholarshipImageFromData(item, model) : null;
      unawaited(() async {
        try {
          final shortUrl = await ShortLinkService().getEducationPublicUrl(
            shareId: shareId,
            title: title,
            desc: model != null
                ? _pickScholarshipShareDesc(model)
                : 'TurqApp burs ilani',
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
    final normalizedTitle = model.baslik.trim().toLowerCase();
    final shortDesc = model.shortDescription.trim();
    if (shortDesc.isNotEmpty && shortDesc.toLowerCase() != normalizedTitle) {
      return shortDesc;
    }
    final provider = model.bursVeren.trim();
    if (provider.isNotEmpty && provider.toLowerCase() != normalizedTitle) {
      return provider;
    }
    return 'TurqApp burs ilani';
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
          "Limit",
          "Günlük takip limitine ulaştınız.",
        );
        return;
      }
      followedUsers[followedId] = outcome.nowFollowing;
    } finally {
      followLoading[followedId] = false;
    }
  }

  final List<InformationModel> informations = [
    InformationModel(title: "Kişisel", color: colors[0], icon: icons[0]),
    InformationModel(title: "Okul", color: colors[1], icon: icons[1]),
    InformationModel(title: "Aile", color: colors[2], icon: icons[2]),
    InformationModel(title: "Yurt", color: colors[3], icon: icons[3]),
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
