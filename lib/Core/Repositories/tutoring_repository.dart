import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Repositories/notifications_repository.dart';
import 'package:turqappv2/Core/Utils/location_text_utils.dart';
import 'package:turqappv2/Models/Education/tutoring_application_model.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Models/Education/tutoring_review_model.dart';

class TutoringRepository extends GetxService {
  TutoringRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'tutoring_repository_v1';
  final Map<String, _TimedValue<dynamic>> _memory =
      <String, _TimedValue<dynamic>>{};
  SharedPreferences? _prefs;
  static const int _thirtyDaysInMillis = 30 * 24 * 60 * 60 * 1000;

  static TutoringRepository _ensureService() {
    if (Get.isRegistered<TutoringRepository>()) {
      return Get.find<TutoringRepository>();
    }
    return Get.put(TutoringRepository(), permanent: true);
  }

  static TutoringRepository ensure() {
    return _ensureService();
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<TutoringPage> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('educators')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap =
        await query.get(const GetOptions(source: Source.serverAndCache));
    final items = snap.docs
        .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
        .where((t) => !_isExpired(t))
        .toList(growable: false);
    return TutoringPage(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<List<TutoringModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids =
        docIds.where((id) => id.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const <TutoringModel>[];
    final byId = <String, TutoringModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in ids) {
        final cached = await _getCachedMap('doc:$id');
        if (cached != null) {
          final model = TutoringModel.fromJson(cached, id);
          if (!_isExpired(model)) {
            byId[id] = model;
          }
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(ids);
    }

    if (cacheOnly) {
      return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
    }

    const chunkSize = 10;
    for (var i = 0; i < missing.length; i += chunkSize) {
      final end =
          (i + chunkSize > missing.length) ? missing.length : i + chunkSize;
      final chunk = missing.sublist(i, end);
      final snapshot = await _firestore
          .collection('educators')
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snapshot.docs) {
        final model = TutoringModel.fromJson(doc.data(), doc.id);
        if (_isExpired(model)) continue;
        byId[doc.id] = model;
        await _storeMap('doc:${doc.id}', doc.data());
      }
    }
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  Future<TutoringModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool allowExpired = false,
  }) async {
    final key = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedMap(key);
      if (cached != null) {
        final model = TutoringModel.fromJson(cached, docId);
        return !allowExpired && _isExpired(model) ? null : model;
      }
    }
    final doc = await _firestore.collection('educators').doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    await _storeMap(key, data);
    final model = TutoringModel.fromJson(data, doc.id);
    return !allowExpired && _isExpired(model) ? null : model;
  }

  Future<List<TutoringModel>> fetchByOwner(
    String userId, {
    int limit = 100,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'owner:$userId:$limit';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(cacheKey);
      if (cached != null) {
        return cached
            .map(
              (e) => TutoringModel.fromJson(
                Map<String, dynamic>.from((e['data'] as Map?) ?? const {}),
                (e['id'] ?? '').toString(),
              ),
            )
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <TutoringModel>[];

    final snapshot = await _firestore
        .collection('educators')
        .where('userID', isEqualTo: userId)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
        .toList(growable: false);
    await _storeValue(
      cacheKey,
      snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, 'data': doc.data()})
          .toList(growable: false),
    );
    return items;
  }

  bool _isExpired(TutoringModel model) {
    if (model.ended == true) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - model.timeStamp > _thirtyDaysInMillis;
  }

  Future<List<TutoringModel>> fetchByCity(
    String city, {
    int limit = 100,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalizedCity = normalizeCityText(city);
    if (normalizedCity.isEmpty) return const <TutoringModel>[];
    final cacheKey = 'city:$normalizedCity';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(cacheKey);
      if (cached != null) {
        return cached
            .map(
                (e) => TutoringModel.fromJson(e, (e['docID'] ?? '').toString()))
            .where((t) => t.docID.isNotEmpty)
            .toList(growable: false);
      }
    }

    final snapshot = await _firestore
        .collection('educators')
        .where('sehir', isEqualTo: city)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
        .toList(growable: false);
    await _storeValue(
      cacheKey,
      snapshot.docs
          .map((doc) => <String, dynamic>{'docID': doc.id, ...doc.data()})
          .toList(growable: false),
    );
    return items;
  }

  Future<bool> hasApplication(String tutoringId, String userId) async {
    final doc = await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Applications')
        .doc(userId)
        .get(const GetOptions(source: Source.serverAndCache));
    return doc.exists;
  }

  Future<bool> toggleFavorite({
    required String docId,
    required String userId,
    required bool isFavorite,
  }) async {
    final savedRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('educators')
        .doc(docId);

    if (isFavorite) {
      await savedRef.delete();
    } else {
      await savedRef.set({
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return !isFavorite;
  }

  Future<bool> toggleApplication({
    required String tutoringId,
    required String ownerUid,
    required String userId,
    required String tutoringTitle,
    required String tutorName,
    required String tutorImage,
    required String applicantLabel,
    required String applicantImage,
  }) async {
    final educatorAppRef = _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Applications')
        .doc(userId);
    final userAppRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('myTutoringApplications')
        .doc(tutoringId);
    final ownerNotificationRef =
        NotificationsRepository.ensure().inboxDoc(ownerUid);
    final educatorDocRef = _firestore.collection('educators').doc(tutoringId);

    final snap = await educatorAppRef
        .get(const GetOptions(source: Source.serverAndCache));
    final batch = _firestore.batch();

    if (snap.exists) {
      batch.delete(educatorAppRef);
      batch.delete(userAppRef);
      batch.update(
        educatorDocRef,
        {'applicationCount': FieldValue.increment(-1)},
      );
      await batch.commit();

      final docSnap = await educatorDocRef
          .get(const GetOptions(source: Source.serverAndCache));
      if (docSnap.exists) {
        final count = (docSnap.data()?['applicationCount'] ?? 0) as num;
        if (count < 0) {
          await educatorDocRef.update({'applicationCount': 0});
        }
      }
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    batch.set(educatorAppRef, {
      'timeStamp': now,
      'status': 'pending',
      'statusUpdatedAt': now,
      'note': '',
      'tutoringTitle': tutoringTitle,
      'tutorName': tutorName,
      'tutorImage': tutorImage,
    });

    batch.set(userAppRef, {
      'timeStamp': now,
      'tutoringTitle': tutoringTitle,
      'tutorName': tutorName,
      'tutorImage': tutorImage,
      'status': 'pending',
      'userID': userId,
    });

    batch.update(educatorDocRef, {
      'applicationCount': FieldValue.increment(1),
    });
    batch.set(ownerNotificationRef, {
      'type': 'tutoring_application',
      'fromUserID': userId,
      'postID': tutoringId,
      'timeStamp': now,
      'read': false,
      'title': applicantLabel,
      'body': '$tutoringTitle ilanina basvuru yapti',
      'thumbnail': applicantImage,
    });
    await batch.commit();
    return true;
  }

  Future<void> cancelApplication({
    required String tutoringId,
    required String userId,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_firestore
        .collection('users')
        .doc(userId)
        .collection('myTutoringApplications')
        .doc(tutoringId));
    batch.delete(_firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Applications')
        .doc(userId));
    final educatorRef = _firestore.collection('educators').doc(tutoringId);
    batch.update(educatorRef, {'applicationCount': FieldValue.increment(-1)});
    await batch.commit();

    final docSnap =
        await educatorRef.get(const GetOptions(source: Source.serverAndCache));
    if (docSnap.exists) {
      final count = (docSnap.data()?['applicationCount'] ?? 0) as num;
      if (count < 0) {
        await educatorRef.update({'applicationCount': 0});
      }
    }
  }

  Future<void> updateApplicationStatus({
    required String tutoringId,
    required String userId,
    required String status,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.update(
      _firestore
          .collection('educators')
          .doc(tutoringId)
          .collection('Applications')
          .doc(userId),
      {
        'status': status,
        'statusUpdatedAt': now,
      },
    );
    batch.update(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('myTutoringApplications')
          .doc(tutoringId),
      {
        'status': status,
      },
    );
    await batch.commit();
  }

  Future<void> incrementViewCount(String tutoringId) async {
    await _firestore.collection('educators').doc(tutoringId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Future<void> unpublish(String tutoringId) async {
    await _firestore.collection('educators').doc(tutoringId).update({
      'ended': true,
      'endedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<TutoringModel>> fetchSimilarByBranch(
    String brans,
    String currentDocId, {
    int limit = 11,
  }) async {
    final snapshot = await _firestore
        .collection('educators')
        .where('brans', isEqualTo: brans)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map((d) => TutoringModel.fromJson(d.data(), d.id))
        .where((t) => t.docID != currentDocId && t.ended != true)
        .take(10)
        .toList(growable: false);
  }

  Future<List<TutoringReviewModel>> fetchReviews(
    String tutoringId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'reviews:$tutoringId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) => TutoringReviewModel.fromMap(
                  Map<String, dynamic>.from((e['data'] as Map?) ?? const {}),
                  (e['id'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }
    final snapshot = await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Reviews')
        .orderBy('timeStamp', descending: true)
        .limit(50)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((d) => <String, dynamic>{'id': d.id, 'data': d.data()})
        .toList(growable: false);
    await _storeValue(key, raw);
    return snapshot.docs
        .map((d) => TutoringReviewModel.fromMap(d.data(), d.id))
        .toList(growable: false);
  }

  Future<void> submitReview({
    required String tutoringId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Reviews')
        .doc(userId)
        .set({
      'userID': userId,
      'tutoringDocID': tutoringId,
      'rating': rating,
      'comment': comment,
      'timeStamp': now,
    });
    await _recalculateAverageRating(tutoringId);
    _memory.remove('reviews:$tutoringId');
  }

  Future<void> deleteReview({
    required String tutoringId,
    required String reviewId,
  }) async {
    await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Reviews')
        .doc(reviewId)
        .delete();
    await _recalculateAverageRating(tutoringId);
    _memory.remove('reviews:$tutoringId');
  }

  Future<List<TutoringApplicationModel>> fetchApplications(
    String tutoringId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'applications:$tutoringId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) => TutoringApplicationModel(
                  tutoringDocID: tutoringId,
                  userID: (e['userID'] ?? e['_docId'] ?? '').toString(),
                  tutoringTitle: (e['tutoringTitle'] ?? '').toString(),
                  tutorName: (e['tutorName'] ?? '').toString(),
                  tutorImage: (e['tutorImage'] ?? '').toString(),
                  status: (e['status'] ?? 'pending').toString(),
                  timeStamp: (e['timeStamp'] as num?)?.toInt() ?? 0,
                  statusUpdatedAt: (e['statusUpdatedAt'] as num?)?.toInt() ?? 0,
                  note: (e['note'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }

    final snapshot = await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Applications')
        .orderBy('timeStamp', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _storeValue(key, raw);
    return raw
        .map((e) => TutoringApplicationModel(
              tutoringDocID: tutoringId,
              userID: (e['_docId'] ?? '').toString(),
              tutoringTitle: (e['tutoringTitle'] ?? '').toString(),
              tutorName: (e['tutorName'] ?? '').toString(),
              tutorImage: (e['tutorImage'] ?? '').toString(),
              status: (e['status'] ?? 'pending').toString(),
              timeStamp: (e['timeStamp'] as num?)?.toInt() ?? 0,
              statusUpdatedAt: (e['statusUpdatedAt'] as num?)?.toInt() ?? 0,
              note: (e['note'] ?? '').toString(),
            ))
        .toList(growable: false);
  }

  Future<void> _recalculateAverageRating(String tutoringId) async {
    final snapshot = await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Reviews')
        .get(const GetOptions(source: Source.serverAndCache));

    if (snapshot.docs.isEmpty) {
      await _firestore.collection('educators').doc(tutoringId).update({
        'averageRating': null,
        'reviewCount': 0,
      });
      return;
    }

    double total = 0;
    for (final doc in snapshot.docs) {
      total += (doc.data()['rating'] as num? ?? 0).toDouble();
    }
    final avg = total / snapshot.docs.length;

    await _firestore.collection('educators').doc(tutoringId).update({
      'averageRating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': snapshot.docs.length,
    });
  }

  Future<Map<String, dynamic>?> _getCachedMap(String key) async {
    final value = await _getCachedValue(key);
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  Future<List<Map<String, dynamic>>?> _getCachedList(String key) async {
    final value = await _getCachedValue(key);
    if (value is List) {
      return value.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return null;
  }

  Future<dynamic> _getCachedValue(String key) async {
    final memory = _memory[key];
    if (memory != null && DateTime.now().difference(memory.cachedAt) <= _ttl) {
      return memory.value;
    }
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >
          _ttl) {
        return null;
      }
      final value = decoded['v'];
      _memory[key] =
          _TimedValue<dynamic>(value: value, cachedAt: DateTime.now());
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeMap(String key, Map<String, dynamic> value) =>
      _storeValue(key, value);

  Future<void> _storeValue(String key, dynamic value) async {
    final now = DateTime.now();
    _memory[key] = _TimedValue<dynamic>(value: value, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$key',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'v': value,
      }),
    );
  }
}

class TutoringPage {
  const TutoringPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TutoringModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedValue<T> {
  const _TimedValue({
    required this.value,
    required this.cachedAt,
  });

  final T value;
  final DateTime cachedAt;
}
