import 'dart:developer';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/antreman_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/rozet_permissions.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';

class AntremanScoreController extends GetxController {
  static List<Map<String, dynamic>>? _cachedLeaderboard;
  static DateTime? _cachedAt;
  static String? _cachedMonthKey;
  static const Duration _cacheTtl = Duration(minutes: 2);

  final RxList<Map<String, dynamic>> leaderboard = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final userPoint = 0.obs;
  final userRank = 0.obs;
  final now = DateTime.now();
  static const _excludedRozet = {'turkuaz'};
  final AntremanRepository _antremanRepository = AntremanRepository.ensure();
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  String get monthName => _monthKeyFor(DateTime.now().month).tr;

  String get _monthKey {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    return '${now.year}-$month';
  }

  String _monthKeyFor(int month) {
    switch (month) {
      case 1:
        return 'common.month.january';
      case 2:
        return 'common.month.february';
      case 3:
        return 'common.month.march';
      case 4:
        return 'common.month.april';
      case 5:
        return 'common.month.may';
      case 6:
        return 'common.month.june';
      case 7:
        return 'common.month.july';
      case 8:
        return 'common.month.august';
      case 9:
        return 'common.month.september';
      case 10:
        return 'common.month.october';
      case 11:
        return 'common.month.november';
      case 12:
        return 'common.month.december';
      default:
        return 'common.month.january';
    }
  }

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
    final rozet = normalizeRozetValue((data['rozet'] ?? '').toString());
    if (_excludedRozet.contains(rozet)) return false;
    final nickname =
        (data['displayName'] ?? data['username'] ?? data['nickname'] ?? '')
            .toString()
            .trim();
    return nickname.isNotEmpty;
  }

  DateTime _resolveUpdatedAt(Map<String, dynamic> data) {
    final rawUpdatedAt = data['updatedDate'];
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
      final avatarUrl = (entry['avatarUrl'] ?? '').toString().trim();
      final firstName = (entry['firstName'] ?? '').toString().trim();
      final lastName = (entry['lastName'] ?? '').toString().trim();
      return avatarUrl.isEmpty || firstName.isEmpty || lastName.isEmpty;
    }).toList();

    if (missingEntries.isEmpty) return entries;

    final userIds = missingEntries
        .map((entry) => (entry['userID'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final summaries = await _userSummaryResolver.resolveMany(
      userIds,
      preferCache: true,
    );
    await Future.wait(
      missingEntries.map((entry) async {
        final userId = (entry['userID'] ?? '').toString();
        if (userId.isEmpty) return;

        final summary = summaries[userId];
        if (summary != null) {
          if ((entry['avatarUrl'] ?? '').toString().trim().isEmpty &&
              summary.avatarUrl.trim().isNotEmpty) {
            entry['avatarUrl'] = summary.avatarUrl;
          }
          if ((entry['displayName'] ?? '').toString().trim().isEmpty &&
              summary.displayName.trim().isNotEmpty) {
            entry['displayName'] = summary.displayName;
          }
          if ((entry['nickname'] ?? '').toString().trim().isEmpty &&
              summary.preferredName.trim().isNotEmpty) {
            entry['nickname'] = summary.preferredName;
          }
          if ((entry['rozet'] ?? '').toString().trim().isEmpty &&
              summary.rozet.trim().isNotEmpty) {
            entry['rozet'] = summary.rozet;
          }
          _fillNamePartsFromSummary(entry, summary);
        }

        final needsRawFallback =
            (entry['firstName'] ?? '').toString().trim().isEmpty ||
                (entry['lastName'] ?? '').toString().trim().isEmpty;
        if (!needsRawFallback) return;

        final userData = await _userRepository.getUserRaw(
          userId,
          preferCache: true,
        );
        if (userData == null) return;
        for (final field in ['firstName', 'lastName']) {
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

  void _fillNamePartsFromSummary(
    Map<String, dynamic> entry,
    UserSummary summary,
  ) {
    final display = summary.displayName.trim();
    if (display.isEmpty) return;
    final currentFirst = (entry['firstName'] ?? '').toString().trim();
    final currentLast = (entry['lastName'] ?? '').toString().trim();
    if (currentFirst.isNotEmpty && currentLast.isNotEmpty) return;

    final parts = display.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return;
    if (currentFirst.isEmpty) {
      entry['firstName'] = parts.first;
    }
    if (currentLast.isEmpty && parts.length > 1) {
      entry['lastName'] = parts.skip(1).join(' ');
    }
  }

  Future<void> fetchLeaderboard({bool showLoader = true}) async {
    try {
      if (showLoader && leaderboard.isEmpty) {
        isLoading.value = true;
      }
      final tempLeaderboard = <Map<String, dynamic>>[];
      const int limit = 40;
      const int pageSize = 200;
      DocumentSnapshot<Map<String, dynamic>>? lastDocument;
      userRank.value = 0;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

      while (tempLeaderboard.length < limit) {
        final page = await _antremanRepository.fetchLeaderboardPage(
          monthKey: _monthKey,
          pageSize: pageSize,
          lastDocument: lastDocument,
        );
        if (page.isEmpty) break;

        for (final entry in page) {
          final data = Map<String, dynamic>.from(entry)
            ..remove('_doc');
          final userId = (data['userID'] ?? '').toString();
          if (_isEligibleEntry(data) &&
              !tempLeaderboard.any((user) => user['userID'] == userId)) {
            tempLeaderboard.add(data);
          }
        }

        final doc = page.last['_doc'];
        if (doc is DocumentSnapshot<Map<String, dynamic>>) {
          lastDocument = doc;
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final monthlyScore = await _antremanRepository.getMonthlyScore(uid);
    if (monthlyScore != null) {
      userPoint.value = monthlyScore;
    } else {
      final userData = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
      );
      userPoint.value = ((userData?["antPoint"] ?? 100) as num).toInt();
    }
    if (uid.isNotEmpty) {
      unawaited(_computeUserRank(uid));
    }
  }

  Future<void> _computeUserRank(String currentUserId) async {
    try {
      int rank = 1;
      DocumentSnapshot<Map<String, dynamic>>? lastDocument;
      const int pageSize = 400;
      while (true) {
        final page = await _antremanRepository.fetchLeaderboardPage(
          monthKey: _monthKey,
          pageSize: pageSize,
          lastDocument: lastDocument,
        );
        if (page.isEmpty) break;

        final eligibleDocs = page.where((entry) {
          return _isEligibleEntry(entry);
        }).toList()
          ..sort(_compareEntries);

        for (final doc in eligibleDocs) {
          if (doc['userID'] == currentUserId) {
            userRank.value = rank;
            return;
          }
          rank++;
        }

        final last = page.last['_doc'];
        if (last is DocumentSnapshot<Map<String, dynamic>>) {
          lastDocument = last;
        } else {
          break;
        }
      }
    } catch (e) {
      log("Sıralama hesaplanamadı: $e");
    }
  }
}
