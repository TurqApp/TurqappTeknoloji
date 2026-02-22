import 'package:dio/dio.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/AppSnackbar.dart';
// Corporate ScholarshipsModel no longer used; only IndividualScholarshipsModel remains
import 'package:turqappv2/Models/Education/IndividualScholarshipsModel.dart';
import 'package:turqappv2/Modules/Education/Scholarships/Applications/ApplicationsView.dart';
import 'package:turqappv2/Modules/Education/Scholarships/BankInfo/BankInfoView.dart';
import 'package:turqappv2/Modules/Education/Scholarships/DormitoryInfo/DormitoryInfoView.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/EducationInfoView.dart';
import 'package:turqappv2/Modules/Education/Scholarships/FamilyInfo/FamilyInfoView.dart';
import 'package:turqappv2/Modules/Education/Scholarships/PersonelInfo/PersonelInfoView.dart';
import 'package:turqappv2/Modules/Education/Scholarships/SavedItems/SavedItemsView.dart';
import 'package:turqappv2/Modules/Education/Scholarships/ScholarshipProviders/ScholarshipProvidersView.dart';

class ScholarshipsController extends GetxController {
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
  DateTime? lastRefresh;
  final RxMap<int, RxInt> pageIndices = <int, RxInt>{}.obs;
  final RxDouble scrollOffset = 0.0.obs;
  final int batchSize = 5;
  DocumentSnapshot? lastBireyselDoc;
  final RxBool hasMoreData = true.obs;
  final RxInt totalCount = 0.obs;
  // Search helpers
  Timer? _searchDebounce;
  final int minSearchResults = 20; // target count during active search
  final RxBool caseSensitive = false.obs; // search case-sensitivity
  final int minSearchLength = 2; // minimum search query length

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
    super.onClose();
  }

  Future<void> refreshTotalCount() async {
    try {
      final agg = await FirebaseFirestore.instance
          .collection('BireyselBurslar')
          .count()
          .get();
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

      final bursSnap = await FirebaseFirestore.instance
          .collection('BireyselBurslar')
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
          'pfImage': userMap['pfImage'] as String? ?? '',
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
        });
      }

      // Keep ordering consistent - süresi dolmayanlar önce
      _sortByDeadline(allScholarships);
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
              : _normalizeTr((user['nickname']?.toString() ?? '').toLowerCase());
          if (nickname.isNotEmpty && nickname.contains(query)) return 3;
        }

        // 4 = Şehir/üniversite/ilçede eşleşme
        final sehirlerNorm = model.sehirler
            .map((s) =>
                caseSensitive.value ? s : _normalizeTr(s.toLowerCase()))
            .join(' ');
        final universitelerNorm = model.universiteler
            .map((s) =>
                caseSensitive.value ? s : _normalizeTr(s.toLowerCase()))
            .join(' ');
        final ilcelerNorm = model.ilceler
            .map((s) =>
                caseSensitive.value ? s : _normalizeTr(s.toLowerCase()))
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

    // Önce önceliğe göre, sonra süre durumuna göre sırala
    filtered.sort((a, b) {
      // Öncelik karşılaştırması
      final priorityA = a['_searchPriority'] as int;
      final priorityB = b['_searchPriority'] as int;
      if (priorityA != priorityB) {
        return priorityA.compareTo(priorityB);
      }

      // Aynı öncelikteyse süre durumuna göre
      final modelA = a['model'];
      final modelB = b['model'];
      if (modelA is IndividualScholarshipsModel &&
          modelB is IndividualScholarshipsModel) {
        final expiredA = _isScholarshipExpired(modelA);
        final expiredB = _isScholarshipExpired(modelB);
        if (expiredA != expiredB) {
          return expiredA ? 1 : -1;
        }
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

  Future<void> _prefetchForSearch() async {
    // While searching, load more pages until enough results or data ends
    int safetyPages = 0;
    while (searchQuery.value.isNotEmpty &&
        hasMoreData.value &&
        lastBireyselDoc != null &&
        visibleScholarships.length < minSearchResults &&
        safetyPages < 6) {
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

  // Süresi dolmamış bursları başa, dolmuş olanları sona sıralayan metot
  void _sortByDeadline(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final modelA = a['model'];
      final modelB = b['model'];

      // Her ikisi de IndividualScholarshipsModel değilse normal timeStamp sıralaması
      if (modelA is! IndividualScholarshipsModel ||
          modelB is! IndividualScholarshipsModel) {
        return (b['timeStamp'] as int).compareTo(a['timeStamp'] as int);
      }

      // Bitiş tarihlerini hesapla
      final isExpiredA = _isScholarshipExpired(modelA);
      final isExpiredB = _isScholarshipExpired(modelB);

      // Eğer biri dolmuş diğeri dolmamışsa, dolmayanı öne al
      if (isExpiredA && !isExpiredB) return 1;
      if (!isExpiredA && isExpiredB) return -1;

      // İkisi de aynı durumdaysa (ya ikisi de dolmamış ya da ikisi de dolmuş)
      // timeStamp'e göre sırala
      return (b['timeStamp'] as int).compareTo(a['timeStamp'] as int);
    });
  }

  // Bursun süresinin dolup dolmadığını kontrol eden yardımcı metot
  bool _isScholarshipExpired(IndividualScholarshipsModel burs) {
    try {
      if (burs.bitisTarihi.isEmpty) return false;

      final endDate = DateFormat('dd.MM.yyyy').parse(burs.bitisTarihi);
      final endDateOnly = DateTime(endDate.year, endDate.month, endDate.day);
      final today = DateTime.now();
      final todayOnly = DateTime(today.year, today.month, today.day);

      return endDateOnly.isBefore(todayOnly);
    } catch (e) {
      return false; // Hata durumunda süresi dolmamış say
    }
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

      final startQueryTime = DateTime.now();
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('BireyselBurslar')
            .orderBy('timeStamp', descending: true)
            .limit(batchSize)
            .get(),
      ]);
      print(
        'Firestore queries took: ${DateTime.now().difference(startQueryTime).inMilliseconds}ms',
      );

      final bireyselSnapshot = futures[0];
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

      // Bireysel burslar için kullanıcı verileri
      final bireyselUserIds = <String>[];
      final bireyselDocs = bireyselSnapshot.docs;
      for (var doc in bireyselDocs) {
        final userID = doc.data()['userID'] as String? ?? '';
        if (userID.isNotEmpty) bireyselUserIds.add(userID);
      }
      final startUserFetch = DateTime.now();
      final bireyselUserFutures = bireyselUserIds
          .where((id) => id.isNotEmpty) // Boş ID'leri filtrele
          .map(
            (id) => FirebaseFirestore.instance
                .collection('users')
                .doc(id)
                .get(),
          )
          .toList();
      final bireyselUserDocs = bireyselUserFutures.isNotEmpty
          ? await Future.wait(bireyselUserFutures)
          : [];
      print(
        'users fetch took: ${DateTime.now().difference(startUserFetch).inMilliseconds}ms',
      );

      for (var doc in bireyselDocs) {
        final data = doc.data();
        final userID = data['userID'] as String? ?? '';
        var userData = {'pfImage': '', 'nickname': '', 'userID': userID};

        if (userID.isNotEmpty) {
          final index = bireyselUserIds.indexOf(userID);
          if (index != -1 && bireyselUserDocs[index].exists) {
            userData = {
              'pfImage':
                  bireyselUserDocs[index].data()?['pfImage'] as String? ?? '',
              'nickname':
                  bireyselUserDocs[index].data()?['nickname'] as String? ?? '',
              'userID': userID,
              'meslekKategori': bireyselUserDocs[index]
                      .data()?['meslekKategori'] as String? ??
                  '',
              'firstName':
                  bireyselUserDocs[index].data()?['firstName'] as String? ?? '',
              'lastName':
                  bireyselUserDocs[index].data()?['lastName'] as String? ?? '',
            };
          }
        }

        final begeniler = data['begeniler'] as List<dynamic>? ?? [];
        final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];
        combined.add({
          'model': IndividualScholarshipsModel.fromJson(data),
          'type': 'bireysel',
          'userData': userData,
          'docId': doc.id,
          'likesCount': begeniler.length,
          'bookmarksCount': kaydedenler.length,
          'timeStamp': data['timeStamp'] as int? ?? 0, // Include timeStamp
        });

        if (userId.isNotEmpty) {
          likedScholarships[doc.id] = begeniler.contains(userId);
          bookmarkedScholarships[doc.id] = kaydedenler.contains(userId);
          followedUsers[userID] = await _checkFollowStatus(userID, userId);
        }
      }

      // Kurumsal burslar kaldırıldı

      pageIndices.clear();
      isExpandedList.clear();
      isExpandedList.addAll(
        List<RxBool>.generate(
          bireyselSnapshot.docs.length,
          (_) => false.obs,
        ),
      );
      pageIndices.addAll(
        Map.fromIterables(
          List.generate(
            bireyselSnapshot.docs.length,
            (i) => i,
          ),
          List.generate(
            bireyselSnapshot.docs.length,
            (_) => 0.obs,
          ),
        ),
      );

      // Sort combined list - süresi dolmayanlar önce, dolmuşlar sonda
      _sortByDeadline(combined);

      allScholarships.clear();
      allScholarships.addAll(combined);
      _applySearchFilter();
      hasMoreData.value = bireyselSnapshot.docs.length == batchSize;
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

    try {
      isLoadingMore.value = true;
      print('Starting loadMoreScholarships at ${DateTime.now()}');

      final startQueryTime = DateTime.now();
      final futures = await Future.wait([
        FirebaseFirestore.instance
            .collection('BireyselBurslar')
            .orderBy('timeStamp', descending: true)
            .startAfterDocument(lastBireyselDoc!)
            .limit(batchSize)
            .get(),
      ]);
      print(
        'Firestore queries for loadMore took: ${DateTime.now().difference(startQueryTime).inMilliseconds}ms',
      );

      final bireyselSnapshot = futures[0];
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

      // Bireysel burslar için kullanıcı verileri
      final bireyselUserIds = <String>[];
      final bireyselDocs = bireyselSnapshot.docs;
      for (var doc in bireyselDocs) {
        final userID = doc.data()['userID'] as String? ?? '';
        if (userID.isNotEmpty) bireyselUserIds.add(userID);
      }
      final startUserFetch = DateTime.now();
      final bireyselUserFutures = bireyselUserIds
          .where((id) => id.isNotEmpty) // Boş ID'leri filtrele
          .map(
            (id) => FirebaseFirestore.instance
                .collection('users')
                .doc(id)
                .get(),
          )
          .toList();
      final bireyselUserDocs = bireyselUserFutures.isNotEmpty
          ? await Future.wait(bireyselUserFutures)
          : [];
      print(
        'users fetch for loadMore took: ${DateTime.now().difference(startUserFetch).inMilliseconds}ms',
      );

      for (var doc in bireyselDocs) {
        final data = doc.data();
        final userID = data['userID'] as String? ?? '';
        var userData = {'pfImage': '', 'nickname': '', 'userID': userID};

        if (userID.isNotEmpty) {
          final index = bireyselUserIds.indexOf(userID);
          if (index != -1 && bireyselUserDocs[index].exists) {
            userData = {
              'pfImage':
                  bireyselUserDocs[index].data()?['pfImage'] as String? ?? '',
              'nickname':
                  bireyselUserDocs[index].data()?['nickname'] as String? ?? '',
              'userID': userID,
              'meslekKategori': bireyselUserDocs[index]
                      .data()?['meslekKategori'] as String? ??
                  '',
              'firstName':
                  bireyselUserDocs[index].data()?['firstName'] as String? ?? '',
              'lastName':
                  bireyselUserDocs[index].data()?['lastName'] as String? ?? '',
            };
          }
        }

        final begeniler = data['begeniler'] as List<dynamic>? ?? [];
        final kaydedenler = data['kaydedenler'] as List<dynamic>? ?? [];
        combined.add({
          'model': IndividualScholarshipsModel.fromJson(data),
          'type': 'bireysel',
          'userData': userData,
          'docId': doc.id,
          'likesCount': begeniler.length,
          'bookmarksCount': kaydedenler.length,
          'timeStamp': data['timeStamp'] as int? ?? 0, // Include timeStamp
        });

        if (userId.isNotEmpty) {
          likedScholarships[doc.id] = begeniler.contains(userId);
          bookmarkedScholarships[doc.id] = kaydedenler.contains(userId);
          followedUsers[userID] = await _checkFollowStatus(userID, userId);
        }
      }

      // Kurumsal burslar kaldırıldı

      // Yeni eklenen bursları da mevcut listeye ekledikten sonra tüm listeyi sırala
      allScholarships.addAll(combined);

      // Tüm listeyi süresi dolmayanlar önce, dolmuşlar sonda olacak şekilde sırala
      _sortByDeadline(allScholarships);

      _applySearchFilter();
      hasMoreData.value = bireyselSnapshot.docs.length == batchSize;
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

    try {
      final docRef =
          FirebaseFirestore.instance.collection('BireyselBurslar').doc(docId);

      final doc = await docRef.get();
      if (!doc.exists) {
        AppSnackbar('Hata', 'Burs bulunamadı.');
        return;
      }

      final begeniler = List<String>.from(doc.data()?['begeniler'] ?? []);
      if (begeniler.contains(userId)) {
        begeniler.remove(userId);
        likedScholarships[docId] = false;
      } else {
        begeniler.add(userId);
        likedScholarships[docId] = true;
      }

      await docRef.update({'begeniler': begeniler});
      print('Updated begeniler for $docId: $begeniler');

      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        allScholarships[index]['likesCount'] = begeniler.length;
        allScholarships.refresh();
        _applySearchFilter();
        print('Updated likesCount for $docId: ${begeniler.length}');
      }
    } catch (e) {
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

    try {
      final docRef =
          FirebaseFirestore.instance.collection('BireyselBurslar').doc(docId);

      final doc = await docRef.get();
      if (!doc.exists) {
        AppSnackbar('Hata', 'Burs bulunamadı.');
        return;
      }

      final kaydedenler = List<String>.from(doc.data()?['kaydedenler'] ?? []);
      if (kaydedenler.contains(userId)) {
        kaydedenler.remove(userId);
        bookmarkedScholarships[docId] = false;
      } else {
        kaydedenler.add(userId);
        bookmarkedScholarships[docId] = true;
      }

      await docRef.update({'kaydedenler': kaydedenler});
      print('Updated kaydedenler for $docId: $kaydedenler');

      final index = allScholarships.indexWhere((s) => s['docId'] == docId);
      if (index != -1) {
        allScholarships[index]['bookmarksCount'] = kaydedenler.length;
        allScholarships.refresh();
        _applySearchFilter();
        print('Updated bookmarksCount for $docId: ${kaydedenler.length}');
      }
    } catch (e) {
      AppSnackbar('Hata', 'Kaydetme işlemi başarısız.');
      print('toggleBookmark error: $e');
    }
  }

  Future<void> shareScholarship(
    Map<String, dynamic> scholarshipData,
    BuildContext context,
  ) async {
    final burs = scholarshipData['model'];
    final userData = scholarshipData['userData'] as Map<String, dynamic>?;

    final title = "${burs.baslik} BURS BAŞVURULARI";
    final provider = (userData?['nickname'] ?? 'Kullanıcı');
    final description = burs.aciklama.length > 100
        ? '${burs.aciklama.substring(0, 100)}...'
        : burs.aciklama;
    final imageUrl = burs.img.isNotEmpty ? burs.img : '';

    final shareText = '''
Bu bursun sana uygun olduğunu düşünüyorum.

$title

Daha fazla bilgi için TurqApp Uygulaması'nı ziyaret edin!

AppStore:
https://apps.apple.com/tr/app/turqapp/id6740809479?l=tr

Google Play: 
https://play.google.com/store/apps/details?id=com.turqapp.app
''';

    try {
      if (imageUrl.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/tempImage.png';

        await Dio().download(imageUrl, filePath);

        await Share.shareXFiles(
          [XFile(filePath)],
          text: shareText,
          subject: title,
        );
      } else {
        await Share.share(shareText, subject: title);
      }
      print('Sharing: $shareText');
    } catch (e) {
      AppSnackbar('Hata', 'Paylaşım başarısız.');
      print('Error downloading or sharing the image: $e');
    }
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
                    case 4:
                      Get.to(() => SavedItemsView());
                      break;
                    case 5:
                      Get.to(() => BankInfoView());
                      break;
                    case 6:
                      Get.to(() => ScholarshipProvidersView());
                      break;
                    case 7:
                      Get.to(() => ApplicationsView());
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
        .collection('Takipciler')
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
          .collection('Takipciler')
          .doc(followerId)
          .delete();
      followedUsers[followedId] = false;
    } else {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(followedId)
          .collection('Takipciler')
          .doc(followerId)
          .set({
        'followerId': followerId,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      followedUsers[followedId] = true;
    }
  }

  final List<InformationModel> informations = [
    InformationModel(title: "Kişisel", color: colors[0], icon: icons[0]),
    InformationModel(title: "Okul", color: colors[1], icon: icons[1]),
    InformationModel(title: "Aile", color: colors[2], icon: icons[2]),
    InformationModel(title: "Yurt", color: colors[3], icon: icons[3]),
    InformationModel(title: "Kayıtlar", color: colors[4], icon: icons[4]),
    InformationModel(title: "Banka", color: colors[5], icon: icons[5]),
    InformationModel(title: "Bursverenler", color: colors[6], icon: icons[6]),
    InformationModel(title: "Başvurular", color: colors[7], icon: icons[7]),
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
  Colors.orange,
  Colors.green,
  Colors.purple,
  Colors.pink,
];

List<IconData> icons = [
  CupertinoIcons.person,
  CupertinoIcons.building_2_fill,
  CupertinoIcons.person_2,
  CupertinoIcons.house_fill,
  CupertinoIcons.bookmark,
  CupertinoIcons.creditcard,
  CupertinoIcons.add,
  CupertinoIcons.doc_plaintext,
];
