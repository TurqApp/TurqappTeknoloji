import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Services/firebase_my_store.dart';

class AntremanScoreController extends GetxController {
  static const String _scoreCollection = 'questionBankSkor';
  static List<Map<String, dynamic>>? _cachedLeaderboard;
  static DateTime? _cachedAt;
  static String? _cachedMonthKey;
  static const Duration _cacheTtl = Duration(minutes: 2);

  final RxList<Map<String, dynamic>> leaderboard = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final userPoint = 0.obs;
  final userRank = 0.obs;
  final user = Get.find<FirebaseMyStore>();
  final now = DateTime.now();
  final monthName = RxString(monthNames[DateTime.now().month]);
  static const _excludedRozet = {'Turkuaz'};

  String get _monthKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  CollectionReference<Map<String, dynamic>> get _scoreEntriesRef =>
      FirebaseFirestore.instance
          .collection(_scoreCollection)
          .doc(_monthKey)
          .collection('items');

  DocumentReference<Map<String, dynamic>> get _currentUserScoreRef =>
      _scoreEntriesRef.doc(FirebaseAuth.instance.currentUser?.uid);

  static const monthNames = [
    '',
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık'
  ];

  @override
  void onInit() {
    super.onInit();
    final hasWarmCache = _applyWarmCache();
    if (hasWarmCache) {
      unawaited(fetchLeaderboard(showLoader: false));
    } else {
      fetchLeaderboard();
    }
    getUserAntPoint();
  }

  bool _applyWarmCache() {
    final cached = _cachedLeaderboard;
    final cachedAt = _cachedAt;
    if (cached == null || cachedAt == null) return false;
    if (_cachedMonthKey != _monthKey) return false;
    if (DateTime.now().difference(cachedAt) > _cacheTtl) return false;

    leaderboard.assignAll(cached);
    isLoading.value = false;
    return cached.isNotEmpty;
  }

  bool _isEligibleEntry(Map<String, dynamic> data) {
    final rozet = (data['rozet'] ?? '').toString();
    if (_excludedRozet.contains(rozet)) return false;
    final nickname =
        (data['displayName'] ?? data['username'] ?? data['nickname'] ?? '')
            .toString()
            .trim();
    return nickname.isNotEmpty;
  }

  DateTime _resolveUpdatedAt(Map<String, dynamic> data) {
    final rawUpdatedAt = data['updatedAt'];
    if (rawUpdatedAt is Timestamp) {
      return rawUpdatedAt.toDate();
    }
    if (rawUpdatedAt is String) {
      return DateTime.tryParse(rawUpdatedAt) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _compareEntries(Map<String, dynamic> a, Map<String, dynamic> b) {
    final aPoint = ((a['antPoint'] ?? 0) as num).toInt();
    final bPoint = ((b['antPoint'] ?? 0) as num).toInt();
    final pointCompare = bPoint.compareTo(aPoint);
    if (pointCompare != 0) return pointCompare;

    final updatedCompare = _resolveUpdatedAt(a).compareTo(_resolveUpdatedAt(b));
    if (updatedCompare != 0) return updatedCompare;

    final aNickname = (a['displayName'] ?? a['username'] ?? a['nickname'] ?? '')
        .toString()
        .toLowerCase();
    final bNickname = (b['displayName'] ?? b['username'] ?? b['nickname'] ?? '')
        .toString()
        .toLowerCase();
    return aNickname.compareTo(bNickname);
  }

  Future<List<Map<String, dynamic>>> _hydrateMissingProfiles(
    List<Map<String, dynamic>> entries,
  ) async {
    final missingEntries = entries.where((entry) {
      final pfImage =
          (entry['avatarUrl'] ?? entry['pfImage'] ?? '').toString().trim();
      final firstName = (entry['firstName'] ?? '').toString().trim();
      final lastName = (entry['lastName'] ?? '').toString().trim();
      return pfImage.isEmpty || firstName.isEmpty || lastName.isEmpty;
    }).toList();

    if (missingEntries.isEmpty) return entries;

    await Future.wait(
      missingEntries.map((entry) async {
        final userId = (entry['userID'] ?? '').toString();
        if (userId.isEmpty) return;

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final userData = userDoc.data();
        if (userData == null) return;

        final profileImage = (userData['avatarUrl'] ??
                userData['pfImage'] ??
                userData['photoURL'] ??
                userData['profileImageUrl'] ??
                '')
            .toString()
            .trim();
        if ((entry['avatarUrl'] ?? '').toString().trim().isEmpty &&
            profileImage.isNotEmpty) {
          entry['avatarUrl'] = profileImage;
        }
        if ((entry['pfImage'] ?? '').toString().trim().isEmpty &&
            profileImage.isNotEmpty) {
          entry['pfImage'] = profileImage;
        }

        final profileName = (userData['displayName'] ??
                userData['username'] ??
                userData['nickname'] ??
                '')
            .toString()
            .trim();
        if ((entry['displayName'] ?? '').toString().trim().isEmpty &&
            profileName.isNotEmpty) {
          entry['displayName'] = profileName;
        }
        if ((entry['nickname'] ?? '').toString().trim().isEmpty &&
            profileName.isNotEmpty) {
          entry['nickname'] = profileName;
        }

        for (final field in ['firstName', 'lastName', 'rozet']) {
          final currentValue = (entry[field] ?? '').toString().trim();
          final fallbackValue = (userData[field] ?? '').toString().trim();
          if (currentValue.isEmpty && fallbackValue.isNotEmpty) {
            entry[field] = userData[field];
          }
        }
      }),
    );

    return entries;
  }

  Future<void> fetchLeaderboard({bool showLoader = true}) async {
    try {
      if (showLoader && leaderboard.isEmpty) {
        isLoading.value = true;
      }
      final tempLeaderboard = <Map<String, dynamic>>[];
      const int limit = 40;
      const int pageSize = 200;
      DocumentSnapshot? lastDocument;
      userRank.value = 0;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      while (tempLeaderboard.length < limit) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection(_scoreCollection)
            .doc(_monthKey)
            .collection('items')
            .orderBy('antPoint', descending: true)
            .limit(pageSize);

        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) break;

        for (var doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['userID'] = doc.id;
          if (_isEligibleEntry(data) &&
              !tempLeaderboard.any((user) => user['userID'] == doc.id)) {
            tempLeaderboard.add(data);
          }
        }

        if (snapshot.docs.isNotEmpty) {
          lastDocument = snapshot.docs.last;
        } else {
          break;
        }

        if (tempLeaderboard.length >= limit) break;
      }

      tempLeaderboard.sort(_compareEntries);
      final limited = tempLeaderboard.take(limit).toList();
      await _hydrateMissingProfiles(limited);
      for (var i = 0; i < limited.length; i++) {
        limited[i]['rank'] = i + 1;
        if (limited[i]['userID'] == currentUserId) {
          userRank.value = i + 1;
        }
      }
      leaderboard.assignAll(limited);
      _cachedLeaderboard = List<Map<String, dynamic>>.from(limited);
      _cachedAt = DateTime.now();
      _cachedMonthKey = _monthKey;
      if (currentUserId.isNotEmpty && userRank.value == 0) {
        unawaited(_computeUserRank(currentUserId));
      }
    } catch (e) {
      log("Lider tablosu çekilirken hata: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getUserAntPoint() async {
    final monthlyDoc = await _currentUserScoreRef.get();
    if (monthlyDoc.exists) {
      userPoint.value =
          ((monthlyDoc.data()?["antPoint"] ?? 100) as num).toInt();
    } else {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .get();
      userPoint.value = ((userDoc.data()?["antPoint"] ?? 100) as num).toInt();
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      unawaited(_computeUserRank(uid));
    }
  }

  Future<void> _computeUserRank(String currentUserId) async {
    try {
      int rank = 1;
      DocumentSnapshot? lastDocument;
      const int pageSize = 400;
      while (true) {
        Query<Map<String, dynamic>> query = FirebaseFirestore.instance
            .collection(_scoreCollection)
            .doc(_monthKey)
            .collection('items')
            .orderBy('antPoint', descending: true)
            .limit(pageSize);
        if (lastDocument != null) {
          query = query.startAfterDocument(lastDocument);
        }
        final snapshot = await query.get();
        if (snapshot.docs.isEmpty) break;

        final eligibleDocs = snapshot.docs.where((doc) {
          return _isEligibleEntry(doc.data());
        }).toList()
          ..sort((a, b) => _compareEntries(
                <String, dynamic>{...a.data(), 'userID': a.id},
                <String, dynamic>{...b.data(), 'userID': b.id},
              ));

        for (final doc in eligibleDocs) {
          if (doc.id == currentUserId) {
            userRank.value = rank;
            return;
          }
          rank++;
        }

        lastDocument = snapshot.docs.last;
      }
    } catch (e) {
      log("Sıralama hesaplanamadı: $e");
    }
  }
}
