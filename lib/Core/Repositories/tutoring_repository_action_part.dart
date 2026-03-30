part of 'tutoring_repository.dart';

extension TutoringRepositoryActionPart on TutoringRepository {
  num _readNumericField(
    Map<String, dynamic>? data,
    String key, {
    num fallback = 0,
  }) {
    final value = data?[key];
    if (value is num) return value;
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return fallback;
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
        final count = _readNumericField(docSnap.data(), 'applicationCount');
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
    NotificationsRepository.ensure().queueCreateInboxItem(
      batch,
      ownerUid,
      {
        'type': 'tutoring_application',
        'fromUserID': userId,
        'postID': tutoringId,
        'timeStamp': now,
        'read': false,
        'title': applicantLabel,
        'body': '$tutoringTitle ilanina basvuru yapti',
        'thumbnail': applicantImage,
      },
      docId: ownerNotificationRef.id,
    );
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
      final count = _readNumericField(docSnap.data(), 'applicationCount');
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
    final normalizedTutoringId = tutoringId.trim();
    if (normalizedTutoringId.isEmpty) return;
    final docRef = _firestore.collection('educators').doc(normalizedTutoringId);
    final docSnap = await docRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    final ownerUserId = (docSnap.data()?['userID'] ?? '').toString().trim();
    await docRef.update({
      'ended': true,
      'endedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await TypesenseEducationSearchService.instance.invalidateEntity(
      EducationTypesenseEntity.tutoring,
    );
    await maybeFindTutoringSnapshotRepository()?.invalidateUserScopedSurfaces(
      ownerUserId,
    );
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
}
