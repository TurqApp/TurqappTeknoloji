import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/admin_access_service.dart';
import 'package:turqappv2/Core/Services/share_action_guard.dart';
import 'package:turqappv2/Core/Services/share_link_service.dart';
import 'package:turqappv2/Core/Services/short_link_service.dart';
import 'package:turqappv2/Core/Services/scholarship_firestore_path.dart';
import 'package:turqappv2/Core/Services/network_awareness_service.dart';
// Corporate ScholarshipsModel no longer used; only IndividualScholarshipsModel remains
import 'package:turqappv2/Models/Education/individual_scholarships_model.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/dormitory_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/family_info_view.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/personel_info_view.dart';

class ScholarshipsController extends GetxController {
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
  // Search helpers
  Timer? _searchDebounce;
  final int minSearchResults = 20; // target count during active search
  final RxBool caseSensitive = false.obs; // search case-sensitivity
  final int minSearchLength = 2; // minimum search query length
  static const String _scholarshipsCacheKey = 'scholarships_cache_v1';
  static const int _scholarshipsCacheLimit = 30;
  static const int _maxUserFetchBatch = 30;

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
      final agg = await ScholarshipFirestorePath.collection().count().get();
      totalCount.value = agg.count ?? 0;
    } catch (e) {
      // ignore silently; keep last known count
    }
  }

  void setSearchQuery(String q) {
    searchQuery.value = q.trim();
    isSearching.value = searchQuery.value.isNotEmpty;
    _applySearchFilter();

    // Debounced prefetch to widen search scope dynamically
    _searchDebounce?.cancel();
    if (searchQuery.value.isEmpty) {
      isSearching.value = false;
      return;
    }

    // Daha hızlı yanıt için debounce süresini azalttım
    _searchDebounce = Timer(const Duration(milliseconds: 150), () async {
      isSearching.value = true;
      // Try targeted boost by matching nickname directly (e.g., @turqapp)
      await _boostByUserNickname(searchQuery.value);
      await _prefetchForSearch();
      isSearching.value = searchQuery.value.isNotEmpty;
    });
  }

  // Reset search state and show all
  void resetSearch() {
    _searchDebounce?.cancel();
    searchQuery.value = '';
    isSearching.value = false;
    caseSensitive.value = false;
    _applySearchFilter();
  }

  // If query seems like a username (or any string), try fetching that user's
  // scholarships directly and merge into results to ensure matches appear.
  Future<void> _boostByUserNickname(String raw) async {
    try {
      var q = raw.trim();
      if (q.isEmpty) return;
      if (q.startsWith('@')) q = q.substring(1);
      // Nickname queries are exact-match; keep as-is but also try lowercase
      final candidates = {q, q.toLowerCase()};

      QuerySnapshot? userSnap;
      for (final nick in candidates) {
        if (nick.isEmpty) continue;
        userSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('nickname', isEqualTo: nick)
            .limit(1)
            .get();
        if (userSnap.docs.isNotEmpty) break;
      }
      if (userSnap == null || userSnap.docs.isEmpty) return;

      final userDoc = userSnap.docs.first;
      final userId = userDoc.id;
      final Map<String, dynamic> userMap =
          (userDoc.data() as Map<String, dynamic>? ?? <String, dynamic>{});

      final bursSnap = await ScholarshipFirestorePath.collection()
          .where('userID', isEqualTo: userId)
          .orderBy('timeStamp', descending: true)
          .limit(20)
          .get();

      if (bursSnap.docs.isEmpty) return;

      // Build a quick lookup of existing docIds to avoid duplicates
      final existingIds =
          allScholarships.map((e) => e['docId'] as String).toSet();

      for (final d in bursSnap.docs) {
        if (existingIds.contains(d.id)) continue;
        final data = d.data();
        final userData = {
          'avatarUrl': userMap['avatarUrl'] as String? ?? '',
          'nickname': userMap['nickname'] as String? ?? '',
          'userID': userId,
          'meslekKategori': userMap['meslekKategori'] as String? ?? '',
          'firstName': userMap['firstName'] as String? ?? '',
          'lastName': userMap['lastName'] as String? ?? '',
        };
        final begeniler = data['begeniler'] as List<dynamic>? ?? [];
        final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];
        allScholarships.add({
          'model': IndividualScholarshipsModel.fromJson(data),
          'type': 'bireysel',
          'userData': userData,
          'docId': d.id,
          'likesCount': begeniler.length,
          'bookmarksCount': kaydedenler.length,
          'timeStamp': data['timeStamp'] as int? ?? 0,
          'isSummary': false,
        });
      }

      _applySearchFilter();
    } catch (_) {
      // fail silently; search still works with local cache/pagination
    }
  }

  void toggleCaseSensitivity() {
    caseSensitive.value = !caseSensitive.value;
    _applySearchFilter();
  }

  void _applySearchFilter() {
    final qRaw = searchQuery.value.replaceAll('@', '');
    final qLower = qRaw.toLowerCase();
    final q = caseSensitive.value ? qRaw : _normalizeTr(qLower);

    // Boş veya çok kısa aramalar için tüm listeyi göster
    if (q.isEmpty || q.length < minSearchLength) {
      visibleScholarships.assignAll(allScholarships);
      return;
    }

    // Arama önceliği hesaplama (düşük değer = yüksek öncelik)
    int calculateSearchPriority(Map<String, dynamic> item, String query) {
      try {
        final model = item['model'] as IndividualScholarshipsModel;
        final user = item['userData'] as Map<String, dynamic>?;

        // Normalize edilmiş alanlar
        final baslikNorm = caseSensitive.value
            ? model.baslik
            : _normalizeTr(model.baslik.toLowerCase());
        final bursVerenNorm = caseSensitive.value
            ? model.bursVeren
            : _normalizeTr(model.bursVeren.toLowerCase());
        final aciklamaNorm = caseSensitive.value
            ? model.aciklama
            : _normalizeTr(model.aciklama.toLowerCase());

        // Öncelik sırası:
        // 1 = Başlıkta tam eşleşme
        if (baslikNorm.contains(query)) return 1;

        // 2 = Burs verende eşleşme
        if (bursVerenNorm.contains(query)) return 2;

        // 3 = Kullanıcı adında eşleşme
        if (user != null) {
          final nickname = caseSensitive.value
              ? (user['nickname']?.toString() ?? '')
              : _normalizeTr(
                  (user['nickname']?.toString() ?? '').toLowerCase());
          if (nickname.isNotEmpty && nickname.contains(query)) return 3;
        }

        // 4 = Şehir/üniversite/ilçede eşleşme
        final sehirlerNorm = model.sehirler
            .map((s) => caseSensitive.value ? s : _normalizeTr(s.toLowerCase()))
            .join(' ');
        final universitelerNorm = model.universiteler
            .map((s) => caseSensitive.value ? s : _normalizeTr(s.toLowerCase()))
            .join(' ');
        final ilcelerNorm = model.ilceler
            .map((s) => caseSensitive.value ? s : _normalizeTr(s.toLowerCase()))
            .join(' ');

        if (sehirlerNorm.contains(query) ||
            universitelerNorm.contains(query) ||
            ilcelerNorm.contains(query)) {
          return 4;
        }

        // 5 = Açıklamada eşleşme
        if (aciklamaNorm.contains(query)) return 5;

        // 6 = Diğer alanlarda eşleşme
        return 6;
      } catch (_) {
        return 999; // Hata durumunda en düşük öncelik
      }
    }

    bool matches(Map<String, dynamic> item) {
      try {
        final model = item['model'] as IndividualScholarshipsModel;
        final user = item['userData'] as Map<String, dynamic>?;
        final fieldsList = <String>[
          model.baslik,
          model.aciklama,
          model.website,
          model.tutar,
          model.bursVeren,
          ...model.sehirler,
          ...model.ilceler,
          ...model.universiteler,
          if (user != null) (user['nickname']?.toString() ?? ''),
          if (user != null)
            (('${user['firstName']?.toString() ?? ''} ${user['lastName']?.toString() ?? ''}')
                .trim()),
        ];
        final fieldsCombined = fieldsList.join(' ');
        final haystack = caseSensitive.value
            ? fieldsCombined
            : _normalizeTr(fieldsCombined.toLowerCase());
        return haystack.contains(q);
      } catch (_) {
        return false;
      }
    }

    // Filtreleme ve önceliklendirme
    final filtered = allScholarships.where(matches).map((item) {
      return {
        ...item,
        '_searchPriority': calculateSearchPriority(item, q),
      };
    }).toList();

    // Önce arama önceliği, sonra sadece oluşturma zamanı (timeStamp)
    filtered.sort((a, b) {
      // Öncelik karşılaştırması
      final priorityA = a['_searchPriority'] as int;
      final priorityB = b['_searchPriority'] as int;
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // Son olarak timeStamp'e göre
      return (b['timeStamp'] as int).compareTo(a['timeStamp'] as int);
    });

    // _searchPriority alanını kaldır (geçici kullanıldı)
    final cleanedFiltered = filtered.map((item) {
      final cleaned = Map<String, dynamic>.from(item);
      cleaned.remove('_searchPriority');
      return cleaned;
    }).toList();

    visibleScholarships.assignAll(cleanedFiltered);
  }

  int _prefetchPageLimitForQuery(String q) {
    final length = q.trim().replaceAll('@', '').length;
    int base;
    if (length <= 3) {
      base = 2;
    } else if (length <= 6) {
      base = 4;
    } else {
      base = 6;
    }

    if (Get.isRegistered<NetworkAwarenessService>()) {
      final net = Get.find<NetworkAwarenessService>();
      if (net.isOnCellular) {
        return base.clamp(0, 2);
      }
      if (net.isOnWiFi) {
        return base;
      }
    }

    return base.clamp(0, 2);
  }

  Future<void> _prefetchForSearch() async {
    final raw = searchQuery.value.trim().replaceAll('@', '');
    if (raw.length < minSearchLength) return;
    // While searching, load more pages until enough results or data ends
    int safetyPages = 0;
    final limit = _prefetchPageLimitForQuery(searchQuery.value);
    while (searchQuery.value.isNotEmpty &&
        hasMoreData.value &&
        lastBireyselDoc != null &&
        visibleScholarships.length < minSearchResults &&
        safetyPages < limit) {
      // If nothing is loading, fetch the next page
      await loadMoreScholarships();
      // Re-apply filter after new data arrives
      _applySearchFilter();
      safetyPages++;
    }
  }

  // Normalize Turkish specific characters to ASCII-like forms for search
  String _normalizeTr(String s) {
    return s
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('i̇', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u');
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
    _applySearchFilter();
    isExpandedList.clear();
    isExpandedList.addAll(
      List<RxBool>.generate(combined.length, (_) => false.obs),
    );
    pageIndices.clear();
    pageIndices.addAll(
      Map.fromIterables(
        List.generate(combined.length, (i) => i),
        List.generate(combined.length, (_) => 0.obs),
      ),
    );
  }

  Future<Map<String, DocumentSnapshot>> _fetchUsersByIds(
      List<String> userIds) async {
    final uniqueIds = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (uniqueIds.isEmpty) return {};

    final Map<String, DocumentSnapshot> result = {};

    for (var i = 0; i < uniqueIds.length; i += _maxUserFetchBatch) {
      final end = (i + _maxUserFetchBatch) > uniqueIds.length
          ? uniqueIds.length
          : (i + _maxUserFetchBatch);
      final batchIds = uniqueIds.sublist(i, end);
      if (batchIds.isEmpty) continue;
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();
      for (final doc in snap.docs) {
        result[doc.id] = doc;
      }
    }

    return result;
  }

  Map<String, dynamic> _buildUserDataFromDoc(
    String userId,
    DocumentSnapshot? userDoc,
  ) {
    if (userId.isEmpty || userDoc == null || !userDoc.exists) {
      return {'avatarUrl': '', 'nickname': '', 'userID': userId};
    }
    final data = userDoc.data() as Map<String, dynamic>? ?? {};
    final profileName =
        (data['displayName'] ?? data['username'] ?? data['nickname'] ?? '')
            .toString();
    final profileImage =
        (  data['avatarUrl'] ?? '')
            .toString();
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
      print('Skipping fetch, too soon since last refresh');
      return;
    }
    lastRefresh = DateTime.now();

    try {
      isLoading.value = true;
      print('Starting fetchScholarships at ${DateTime.now()}');

      // Önce local cache'ten son 30 bursu göster, sonra ağdan tazele
      if (allScholarships.isEmpty) {
        final cached = await _loadScholarshipsCache();
        if (cached.isNotEmpty) {
          _applyScholarshipStateFromCombined(cached);
          print('Loaded scholarships from local cache: ${cached.length}');
        }
      }

      final startQueryTime = DateTime.now();
      final snapshot = await ScholarshipFirestorePath.collection()
          .orderBy('timeStamp', descending: true)
          .limit(initialBatchSize)
          .get();
      print(
        'Firestore queries took: ${DateTime.now().difference(startQueryTime).inMilliseconds}ms',
      );

      final bireyselSnapshot = snapshot;
      print('Bireysel docs: ${bireyselSnapshot.docs.length}');

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
      final startUserFetch = DateTime.now();
      final userDocsById = await _fetchUsersByIds(bireyselUserIds);
      print(
        'users fetch (getAll) took: ${DateTime.now().difference(startUserFetch).inMilliseconds}ms',
      );

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
      await _saveScholarshipsCache(combined);
      _prefetchShortLinksForList(allScholarships);
      // İlk partiden sonra devam var mı? (toplam sayıya göre)
      hasMoreData.value = allScholarships.length < totalCount.value;
      print(
        'Total scholarships: ${combined.length}, fetch completed at ${DateTime.now()}',
      );
    } catch (e) {
      print('fetchScholarships error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreScholarships() async {
    if (isLoadingMore.value || !hasMoreData.value) {
      print('Skipping loadMoreScholarships: already loading or no more data');
      return;
    }
    if (lastBireyselDoc == null) {
      hasMoreData.value = false;
      print('Skipping loadMoreScholarships: pagination cursor is null');
      return;
    }

    try {
      isLoadingMore.value = true;
      print('Starting loadMoreScholarships at ${DateTime.now()}');

      final startQueryTime = DateTime.now();
      final snapshot = await ScholarshipFirestorePath.collection()
          .orderBy('timeStamp', descending: true)
          .startAfterDocument(lastBireyselDoc!)
          .limit(batchSize)
          .get();
      print(
        'Firestore queries for loadMore took: ${DateTime.now().difference(startQueryTime).inMilliseconds}ms',
      );

      final bireyselSnapshot = snapshot;
      print('Bireysel docs (more): ${bireyselSnapshot.docs.length}');

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
      final startUserFetch = DateTime.now();
      final userDocsById = await _fetchUsersByIds(bireyselUserIds);
      print(
        'users fetch (getAll) for loadMore took: ${DateTime.now().difference(startUserFetch).inMilliseconds}ms',
      );

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

      _applySearchFilter();
      _prefetchShortLinksForList(allScholarships);
      // Toplam sayıya göre devam kontrolü
      hasMoreData.value = allScholarships.length < totalCount.value;
      print(
        'Total scholarships after loadMore: ${allScholarships.length}, loadMore completed at ${DateTime.now()}',
      );
    } catch (e) {
      AppSnackbar('Hata', 'Daha fazla burs yüklenemedi.');
      print('loadMoreScholarships error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void updatePageIndex(int scholarshipIndex, int pageIndex) {
    pageIndices[scholarshipIndex]?.value = pageIndex;
    print('Updated page index for scholarship $scholarshipIndex: $pageIndex');
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
      final docRef = ScholarshipFirestorePath.doc(docId);
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
        _applySearchFilter();
      }

      await docRef.update({
        'begeniler': wasLiked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'likesCount': FieldValue.increment(wasLiked ? -1 : 1),
      });
    } catch (e) {
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
        _applySearchFilter();
      }
      AppSnackbar('Hata', 'Beğeni işlemi başarısız.');
      print('toggleLike error: $e');
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
      final docRef = ScholarshipFirestorePath.doc(docId);
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
        _applySearchFilter();
      }

      await docRef.update({
        'kaydedenler': wasBookmarked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'bookmarksCount': FieldValue.increment(wasBookmarked ? -1 : 1),
      });
    } catch (e) {
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
        _applySearchFilter();
      }
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız.');
      print('toggleBookmark error: $e');
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
        print('Sharing: $shortUrl');
      });
    } catch (e) {
      AppSnackbar('Hata', 'Paylaşım başarısız.');
      print('Error downloading or sharing the image: $e');
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
      print(
        'Toggled expanded for index $index: ${isExpandedList[index].value}',
      );
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
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(followedId)
        .collection('followers')
        .doc(followerId)
        .get();
    return doc.exists;
  }

  Future<void> toggleFollow(String followedId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final followerId = currentUser.uid;

    if (followedUsers[followedId] ?? false) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(followedId)
          .collection('followers')
          .doc(followerId)
          .delete();
      followedUsers[followedId] = false;
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(followedId)
          .collection('followers')
          .doc(followerId)
          .set({
        'followerId': followerId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }, SetOptions(merge: true));
      followedUsers[followedId] = true;
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
