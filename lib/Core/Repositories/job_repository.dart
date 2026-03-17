import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/job_collection_helper.dart';
import 'package:turqappv2/Models/job_review_model.dart';
import 'package:turqappv2/Models/job_model.dart';
import 'package:turqappv2/Models/job_application_model.dart';

class JobRepository extends GetxService {
  JobRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'job_repository_v1';
  final Map<String, _TimedJobs> _memory = <String, _TimedJobs>{};
  final Map<String, _TimedBool> _boolMemory = <String, _TimedBool>{};
  SharedPreferences? _prefs;

  static JobRepository ensure() {
    if (Get.isRegistered<JobRepository>()) {
      return Get.find<JobRepository>();
    }
    return Get.put(JobRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<JobModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null && memory.isNotEmpty) return memory.first;
      final disk = await _getFromPrefsEntry(cacheKey);
      if (disk != null && disk.items.isNotEmpty) {
        _memory[cacheKey] = _TimedJobs(
          items: List<JobModel>.from(disk.items),
          cachedAt: disk.cachedAt,
        );
        return disk.items.first;
      }
    }

    if (cacheOnly) return null;

    final doc =
        await _firestore.collection(JobCollection.name).doc(docId).get();
    if (!doc.exists) return null;
    final item = JobModel.fromMap(doc.data() ?? const {}, doc.id);
    await _store(cacheKey, <JobModel>[item]);
    return item;
  }

  Future<List<JobModel>> fetchLatestJobs({
    int limit = 150,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'latest:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedJobs(
          items: List<JobModel>.from(disk.items),
          cachedAt: disk.cachedAt,
        );
        return List<JobModel>.from(disk.items);
      }
    }

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => JobModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<JobModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids = docIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <JobModel>[];

    final resolved = <String, JobModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in ids) {
        final memory = _getFromMemory('doc:$id');
        if (memory != null && memory.isNotEmpty) {
          resolved[id] = memory.first;
          continue;
        }
        final disk = await _getFromPrefsEntry('doc:$id');
        if (disk != null && disk.items.isNotEmpty) {
          _memory['doc:$id'] = _TimedJobs(
            items: List<JobModel>.from(disk.items),
            cachedAt: disk.cachedAt,
          );
          resolved[id] = disk.items.first;
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(ids);
    }

    if (cacheOnly) {
      return ids
          .map((id) => resolved[id])
          .whereType<JobModel>()
          .toList(growable: false);
    }

    for (final chunk in _chunkIds(missing, 10)) {
      final snap = await _firestore
          .collection(JobCollection.name)
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = JobModel.fromMap(doc.data(), doc.id);
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <JobModel>[item]);
      }
    }

    return ids
        .map((id) => resolved[id])
        .whereType<JobModel>()
        .toList(growable: false);
  }

  Future<List<JobModel>> fetchByOwnerAndEnded(
    String uid, {
    required bool ended,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'owner:$uid:ended:$ended';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedJobs(
          items: List<JobModel>.from(disk.items),
          cachedAt: disk.cachedAt,
        );
        return List<JobModel>.from(disk.items);
      }
    }

    if (cacheOnly) return const <JobModel>[];

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .where('userID', isEqualTo: uid)
        .where('ended', isEqualTo: ended)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => JobModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<JobModel>> fetchSimilarByProfession(
    String meslek, {
    int limit = 15,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalized = meslek.trim().toLowerCase();
    final cacheKey = 'profession:$normalized:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedJobs(
          items: List<JobModel>.from(disk.items),
          cachedAt: disk.cachedAt,
        );
        return List<JobModel>.from(disk.items);
      }
    }

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .where('meslek', isEqualTo: meslek)
        .where('ended', isEqualTo: false)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => JobModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<bool> hasApplication(
    String jobDocId,
    String uid,
  ) async {
    final cacheKey = 'application:$jobDocId:$uid';
    final cached = _boolMemory[cacheKey];
    if (cached != null && DateTime.now().difference(cached.cachedAt) <= _ttl) {
      return cached.value;
    }

    final snap = await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Applications')
        .doc(uid)
        .get(const GetOptions(source: Source.serverAndCache));
    _boolMemory[cacheKey] = _TimedBool(
      value: snap.exists,
      cachedAt: DateTime.now(),
    );
    return snap.exists;
  }

  Future<List<JobApplicationModel>> fetchApplications(
    String jobDocId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'applications:$jobDocId';
    if (!forceRefresh && preferCache) {
      final raw = await _readList(cacheKey);
      if (raw != null) {
        return raw
            .map((data) => JobApplicationModel(
                  jobDocID: jobDocId,
                  userID: (data['_docId'] ?? '').toString(),
                  jobTitle: (data['jobTitle'] ?? '').toString(),
                  companyName: (data['companyName'] ?? '').toString(),
                  companyLogo: (data['companyLogo'] ?? '').toString(),
                  applicantName: (data['applicantName'] ?? '').toString(),
                  applicantNickname:
                      (data['applicantNickname'] ?? '').toString(),
                  applicantPfImage: (data['applicantPfImage'] ?? '').toString(),
                  status: (data['status'] ?? 'pending').toString(),
                  timeStamp: (data['timeStamp'] as num?)?.toInt() ?? 0,
                  statusUpdatedAt:
                      (data['statusUpdatedAt'] as num?)?.toInt() ?? 0,
                  note: (data['note'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Applications')
        .orderBy('timeStamp', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _writeList(cacheKey, raw);
    return raw
        .map((data) => JobApplicationModel(
              jobDocID: jobDocId,
              userID: (data['_docId'] ?? '').toString(),
              jobTitle: (data['jobTitle'] ?? '').toString(),
              companyName: (data['companyName'] ?? '').toString(),
              companyLogo: (data['companyLogo'] ?? '').toString(),
              applicantName: (data['applicantName'] ?? '').toString(),
              applicantNickname: (data['applicantNickname'] ?? '').toString(),
              applicantPfImage: (data['applicantPfImage'] ?? '').toString(),
              status: (data['status'] ?? 'pending').toString(),
              timeStamp: (data['timeStamp'] as num?)?.toInt() ?? 0,
              statusUpdatedAt: (data['statusUpdatedAt'] as num?)?.toInt() ?? 0,
              note: (data['note'] ?? '').toString(),
            ))
        .toList(growable: false);
  }

  Future<List<JobReviewModel>> fetchReviews(
    String jobDocId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'reviews:$jobDocId';
    if (!forceRefresh && preferCache) {
      final raw = await _readList(cacheKey);
      if (raw != null) {
        return raw
            .map((data) => JobReviewModel.fromMap(
                  Map<String, dynamic>.from(data),
                  (data['_docId'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <JobReviewModel>[];

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Reviews')
        .orderBy('timeStamp', descending: true)
        .limit(50)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _writeList(cacheKey, raw);
    return raw
        .map((data) => JobReviewModel.fromMap(
              Map<String, dynamic>.from(data),
              (data['_docId'] ?? '').toString(),
            ))
        .toList(growable: false);
  }

  Future<void> incrementViewCount(String jobDocId) async {
    if (jobDocId.trim().isEmpty) return;
    await _firestore.collection(JobCollection.name).doc(jobDocId.trim()).update(
      {'viewCount': FieldValue.increment(1)},
    );
  }

  Future<void> saveReview({
    required String jobDocId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Reviews')
        .doc(userId)
        .set({
      'userID': userId,
      'jobDocID': jobDocId,
      'rating': rating.clamp(1, 5),
      'comment': comment.trim(),
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _invalidateListCache('reviews:$jobDocId');
  }

  Future<void> deleteReview({
    required String jobDocId,
    required String reviewId,
  }) async {
    await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Reviews')
        .doc(reviewId)
        .delete();
    await _invalidateListCache('reviews:$jobDocId');
  }

  Future<void> refreshAverageRating(String jobDocId) async {
    try {
      final reviews = await fetchReviews(
        jobDocId,
        preferCache: false,
        forceRefresh: true,
      );
      final jobDocRef = _firestore.collection(JobCollection.name).doc(jobDocId);

      if (reviews.isEmpty) {
        await jobDocRef.update({'averageRating': null, 'reviewCount': 0});
        return;
      }

      double total = 0;
      for (final review in reviews) {
        total += review.rating.toDouble();
      }
      final avg = total / reviews.length;
      await jobDocRef.update({
        'averageRating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': reviews.length,
      });
    } catch (_) {}
  }

  Future<int> normalizeApplicationCount(String jobDocId) async {
    final doc = await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .get(const GetOptions(source: Source.serverAndCache));
    if (!doc.exists) return 0;
    final count = (doc.data()?['applicationCount'] as num?)?.toInt() ?? 0;
    if (count >= 0) return count;
    await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .update({'applicationCount': 0});
    return 0;
  }

  Future<void> toggleApplication({
    required String jobDocId,
    required String ownerUserId,
    required String userId,
    required String jobTitle,
    required String companyName,
    required String companyLogo,
    required String applicantName,
    required String applicantNickname,
    required String applicantPfImage,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final applicationRef = _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Applications')
        .doc(userId);
    final userApplicationRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myApplications')
        .doc(jobDocId);
    final ownerNotificationRef = _firestore
        .collection('users')
        .doc(ownerUserId)
        .collection('notifications')
        .doc();
    final jobDocRef = _firestore.collection(JobCollection.name).doc(jobDocId);

    final snap = await applicationRef.get();
    final batch = _firestore.batch();
    if (snap.exists) {
      batch.delete(applicationRef);
      batch.delete(userApplicationRef);
      batch.update(jobDocRef, {'applicationCount': FieldValue.increment(-1)});
      await batch.commit();
      _boolMemory['application:$jobDocId:$userId'] = _TimedBool(
        value: false,
        cachedAt: DateTime.now(),
      );
      await _invalidateListCache('applications:$jobDocId');
      await normalizeApplicationCount(jobDocId);
      return;
    }

    final payload = <String, dynamic>{
      'timeStamp': now,
      'status': 'pending',
      'statusUpdatedAt': now,
      'note': '',
      'jobTitle': jobTitle,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'applicantName': applicantName,
      'applicantNickname': applicantNickname,
      'applicantPfImage': applicantPfImage,
      'userID': userId,
    };
    batch.set(applicationRef, payload);
    batch.set(userApplicationRef, payload);
    batch.update(jobDocRef, {
      'applicationCount': FieldValue.increment(1),
    });
    batch.set(ownerNotificationRef, {
      'type': 'job_application',
      'fromUserID': userId,
      'postID': jobDocId,
      'timeStamp': now,
      'read': false,
      'title': applicantName.isNotEmpty ? applicantName : 'Bir kullanıcı',
      'body': '$jobTitle ilanina basvuru yapti',
      'thumbnail': applicantPfImage,
    });
    await batch.commit();
    _boolMemory['application:$jobDocId:$userId'] = _TimedBool(
      value: true,
      cachedAt: DateTime.now(),
    );
    await _invalidateListCache('applications:$jobDocId');
  }

  Future<void> updateApplicationStatus({
    required String jobDocId,
    required String applicantUserId,
    required String actorUid,
    required String newStatus,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final applicationRef = _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Applications')
        .doc(applicantUserId);
    final userApplicationRef = _firestore
        .collection('users')
        .doc(applicantUserId)
        .collection('myApplications')
        .doc(jobDocId);
    final notificationRef = _firestore
        .collection('users')
        .doc(applicantUserId)
        .collection('notifications')
        .doc();

    final applicationSnap = await applicationRef.get();
    if (!applicationSnap.exists) {
      throw Exception('application_not_found');
    }

    final applicationData = applicationSnap.data() ?? const <String, dynamic>{};
    final title = (applicationData['jobTitle'] ?? '').toString().trim();
    final companyName =
        (applicationData['companyName'] ?? '').toString().trim();

    final batch = _firestore.batch();
    batch.set(
      applicationRef,
      {
        'status': newStatus,
        'statusUpdatedAt': now,
      },
      SetOptions(merge: true),
    );
    batch.set(
      userApplicationRef,
      {
        'timeStamp': applicationData['timeStamp'] ?? now,
        'jobTitle': applicationData['jobTitle'] ?? '',
        'companyName': applicationData['companyName'] ?? '',
        'companyLogo': applicationData['companyLogo'] ?? '',
        'status': newStatus,
        'statusUpdatedAt': now,
        'userID': applicantUserId,
        'applicantName': applicationData['applicantName'] ?? '',
        'applicantNickname': applicationData['applicantNickname'] ?? '',
        'applicantPfImage': applicationData['applicantPfImage'] ?? '',
        'note': applicationData['note'] ?? '',
      },
      SetOptions(merge: true),
    );
    batch.set(notificationRef, {
      'type': 'job_application',
      'fromUserID': actorUid,
      'postID': jobDocId,
      'timeStamp': now,
      'read': false,
      'title': 'Başvuru durumu güncellendi',
      'body': _statusBody(newStatus, title, companyName),
    });
    await batch.commit();
    await _invalidateListCache('applications:$jobDocId');
  }

  Future<void> unpublishJob(String jobDocId) async {
    await _firestore.collection(JobCollection.name).doc(jobDocId).update({
      'ended': true,
      'endedAt': DateTime.now().millisecondsSinceEpoch,
    });
    _memory.remove('doc:$jobDocId');
  }

  Future<void> clearAll() async {
    _memory.clear();
    _boolMemory.clear();
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(_prefsPrefix))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  List<JobModel>? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) > _ttl) {
      _memory.remove(key);
      return null;
    }
    return List<JobModel>.from(entry.items);
  }

  Future<_TimedJobs?> _getFromPrefsEntry(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix::$key');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
      await prefs.remove('$_prefsPrefix::$key');
      return null;
    }
    final items =
        (decoded['items'] as List<dynamic>? ?? const <dynamic>[]).map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      return JobModel.fromMap(
        Map<String, dynamic>.from(map['data'] as Map),
        map['docID'] as String? ?? '',
      );
    }).toList(growable: false);
    return _TimedJobs(items: items, cachedAt: cachedAt);
  }

  Future<void> _store(String key, List<JobModel> items) async {
    _memory[key] =
        _TimedJobs(items: List<JobModel>.from(items), cachedAt: DateTime.now());
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final payload = jsonEncode(<String, dynamic>{
      'cachedAt': DateTime.now().toIso8601String(),
      'items': items
          .map((item) => <String, dynamic>{
                'docID': item.docID,
                'data': item.toMap(),
              })
          .toList(growable: false),
    });
    await prefs.setString('$_prefsPrefix::$key', payload);
  }

  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix::$key');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
      await prefs.remove('$_prefsPrefix::$key');
      return null;
    }
    return (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsPrefix::$key',
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
  }

  Future<void> _invalidateListCache(String key) async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix::$key');
  }

  String _statusBody(String status, String title, String companyName) {
    final displayTitle = title.isNotEmpty
        ? title
        : companyName.isNotEmpty
            ? companyName
            : 'ilan';
    switch (status) {
      case 'accepted':
        return '$displayTitle başvurun kabul edildi.';
      case 'reviewing':
        return '$displayTitle başvurun incelemeye alındı.';
      case 'rejected':
        return '$displayTitle başvurun reddedildi.';
      default:
        return '$displayTitle başvuru durumun güncellendi.';
    }
  }

  List<List<String>> _chunkIds(List<String> input, int size) {
    if (input.isEmpty) return const <List<String>>[];
    final chunks = <List<String>>[];
    for (var i = 0; i < input.length; i += size) {
      final end = (i + size > input.length) ? input.length : i + size;
      chunks.add(input.sublist(i, end));
    }
    return chunks;
  }
}

class _TimedJobs {
  const _TimedJobs({
    required this.items,
    required this.cachedAt,
  });

  final List<JobModel> items;
  final DateTime cachedAt;
}

class _TimedBool {
  const _TimedBool({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
