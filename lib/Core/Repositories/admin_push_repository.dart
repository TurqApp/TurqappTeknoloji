import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class AdminPushReport {
  final String id;
  final Map<String, dynamic> data;

  const AdminPushReport({
    required this.id,
    required this.data,
  });
}

class AdminPushTargetFilters {
  final String uid;
  final String meslek;
  final String konum;
  final String gender;
  final int? minAge;
  final int? maxAge;

  const AdminPushTargetFilters({
    this.uid = '',
    this.meslek = '',
    this.konum = '',
    this.gender = '',
    this.minAge,
    this.maxAge,
  });
}

class AdminPushRepository extends GetxService {
  static const int pushTargetCutoffMs = 1772409600000;

  static AdminPushRepository? maybeFind() {
    final isRegistered = Get.isRegistered<AdminPushRepository>();
    if (!isRegistered) return null;
    return Get.find<AdminPushRepository>();
  }

  static AdminPushRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AdminPushRepository(), permanent: true);
  }

  final UserRepository _userRepository = UserRepository.ensure();

  CollectionReference<Map<String, dynamic>> get _reportsRef =>
      FirebaseFirestore.instance
          .collection('adminConfig')
          .doc('admin')
          .collection('pushReports');

  Stream<List<AdminPushReport>> watchReports({int limit = 20}) {
    return _reportsRef
        .orderBy('createdDate', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => AdminPushReport(
                  id: doc.id,
                  data: Map<String, dynamic>.from(doc.data()),
                ),
              )
              .toList(growable: false),
        );
  }

  Future<void> deleteReport(String reportId) async {
    if (reportId.isEmpty) return;
    await _reportsRef.doc(reportId).delete();
  }

  Future<void> addReport({
    required String senderUid,
    required String title,
    required String body,
    required String type,
    required int targetCount,
    required AdminPushTargetFilters filters,
  }) async {
    await _reportsRef.add({
      'senderUid': senderUid,
      'title': title,
      'body': body,
      'type': type,
      'targetCount': targetCount,
      'filters': {
        'uid': filters.uid,
        'meslek': filters.meslek,
        'konum': filters.konum,
        'cinsiyet': filters.gender,
        'minAge': filters.minAge,
        'maxAge': filters.maxAge,
      },
      'createdDate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addPostReport({
    required String senderUid,
    required String title,
    required String body,
    required int targetCount,
    required String postId,
    String? imageUrl,
  }) async {
    await _reportsRef.add({
      'senderUid': senderUid,
      'title': title,
      'body': body,
      'type': 'posts',
      if (imageUrl != null && imageUrl.trim().isNotEmpty) 'imageUrl': imageUrl,
      'targetCount': targetCount,
      'postID': postId,
      'createdDate': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<String>> resolveTargetUids({
    required AdminPushTargetFilters filters,
  }) async {
    final uid = filters.uid.trim();
    if (uid.isNotEmpty) {
      final data =
          await _userRepository.getUserRaw(uid) ?? const <String, dynamic>{};
      if (data.isEmpty) return <String>[];
      return _isEligiblePushTarget(uid, data) ? <String>[uid] : <String>[];
    }

    final meslekLc = normalizeSearchText(filters.meslek);
    final konumLc = normalizeSearchText(filters.konum);
    final genderLc = normalizeSearchText(filters.gender);
    final minAge = filters.minAge;
    final maxAge = filters.maxAge;

    final targets = <String>[];
    final seen = <String>{};

    bool matchesFilters(String userId, Map<String, dynamic> data) {
      if (seen.contains(userId)) return false;
      if (!_isEligiblePushTarget(userId, data)) return false;
      final userMeslek = normalizeSearchText(
        (data['meslekKategori'] ?? '').toString(),
      );
      final userGender = normalizeSearchText(
        (data['cinsiyet'] ?? '').toString(),
      );
      final locations = _collectLocationValues(data);
      final age = _extractAge(data);
      final meslekOk = meslekLc.isEmpty || userMeslek == meslekLc;
      final konumOk = konumLc.isEmpty || locations.any((v) => v == konumLc);
      final genderOk = genderLc.isEmpty || userGender == genderLc;
      final minAgeOk = minAge == null || (age != null && age >= minAge);
      final maxAgeOk = maxAge == null || (age != null && age <= maxAge);
      final ok = meslekOk && konumOk && genderOk && minAgeOk && maxAgeOk;
      if (ok) seen.add(userId);
      return ok;
    }

    const pageSize = 350;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .where('createdDate', isGreaterThanOrEqualTo: pushTargetCutoffMs)
        .orderBy('createdDate')
        .limit(pageSize);

    while (true) {
      final users = await query.get();
      if (users.docs.isEmpty) break;

      for (final doc in users.docs) {
        final data = doc.data();
        await _userRepository.seedUser(
          UserSummary.fromMap(doc.id, data),
        );
        if (matchesFilters(doc.id, data)) {
          targets.add(doc.id);
        }
      }

      if (users.docs.length < pageSize) break;
      query = FirebaseFirestore.instance
          .collection('users')
          .where('createdDate', isGreaterThanOrEqualTo: pushTargetCutoffMs)
          .orderBy('createdDate')
          .startAfterDocument(users.docs.last)
          .limit(pageSize);
    }

    final senderUid = CurrentUserService.instance.userId;
    return targets
        .where((targetUid) => targetUid.isNotEmpty && targetUid != senderUid)
        .toList(growable: false);
  }

  Future<void> sendPush({
    required String title,
    required String body,
    required String type,
    required List<String> targetUids,
  }) async {
    if (targetUids.isEmpty) return;
    final senderUid = CurrentUserService.instance.userId.isNotEmpty
        ? CurrentUserService.instance.userId
        : 'admin';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const batchSize = 400;

    for (var i = 0; i < targetUids.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = targetUids.skip(i).take(batchSize);
      for (final targetUid in chunk) {
        final docRef = NotificationsRepository.ensure().inboxDoc(targetUid);
        batch.set(docRef, {
          'type': type,
          'title': title,
          'body': body,
          'fromUserID': senderUid,
          'postID': 'admin-manual-push',
          'adminPush': true,
          'hideInAppInbox': true,
          'timeStamp': nowMs,
          'read': false,
        });
      }
      await batch.commit();
    }
  }

  Future<int> sendPostPush({
    required String postId,
    required String title,
    required String body,
    String? imageUrl,
    AdminPushTargetFilters filters = const AdminPushTargetFilters(),
  }) async {
    final targetUids = await resolveTargetUids(filters: filters);
    if (targetUids.isEmpty) return 0;

    final senderUid = CurrentUserService.instance.userId.isNotEmpty
        ? CurrentUserService.instance.userId
        : 'admin';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const batchSize = 400;
    var written = 0;

    for (var i = 0; i < targetUids.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      final chunk = targetUids.skip(i).take(batchSize);
      for (final targetUid in chunk) {
        final docRef = NotificationsRepository.ensure().inboxDoc(targetUid);
        batch.set(docRef, {
          'type': 'posts',
          'fromUserID': senderUid,
          'postID': postId,
          if (imageUrl != null && imageUrl.trim().isNotEmpty)
            'imageUrl': imageUrl,
          'adminPush': true,
          'hideInAppInbox': true,
          'timeStamp': nowMs,
          'read': false,
          'title': title,
          'body': body,
        });
        written++;
      }
      await batch.commit();
    }

    return written;
  }

  List<String> _collectLocationValues(Map<String, dynamic> data) {
    final values = <String>[];
    for (final key in const <String>[
      'city',
      'il',
      'ilce',
      'locationSehir',
      'ikametSehir',
    ]) {
      final value = normalizeSearchText((data[key] ?? '').toString());
      if (value.isNotEmpty) values.add(value);
    }
    return values;
  }

  int? _extractAge(Map<String, dynamic> data) {
    final raw = (data['dogumTarihi'] ?? '').toString().trim();
    if (raw.isEmpty) return null;

    DateTime? birthDate;
    final asInt = int.tryParse(raw);
    if (asInt != null) {
      final ms = raw.length >= 13 ? asInt : asInt * 1000;
      birthDate = DateTime.fromMillisecondsSinceEpoch(ms);
    } else {
      birthDate = DateTime.tryParse(raw);
      if (birthDate == null && raw.contains('/')) {
        final parts = raw.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) {
            birthDate = DateTime(y, m, d);
          }
        }
      }
    }
    if (birthDate == null) return null;

    final now = DateTime.now();
    var age = now.year - birthDate.year;
    final hadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    if (!hadBirthday) age--;
    return age < 0 ? null : age;
  }

  bool _isEligiblePushTarget(String userId, Map<String, dynamic> data) {
    final rawCreatedDate = data['createdDate'];
    final createdAtMs = rawCreatedDate is num
        ? rawCreatedDate.toInt()
        : int.tryParse(rawCreatedDate?.toString() ?? '') ?? 0;
    return userId.isNotEmpty && createdAtMs >= pushTargetCutoffMs;
  }
}
