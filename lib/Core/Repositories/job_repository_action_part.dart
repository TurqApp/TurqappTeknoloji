part of 'job_repository.dart';

extension JobRepositoryActionPart on JobRepository {
  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
    final count = _asInt(doc.data()?['applicationCount']);
    if (count >= 0) return count;
    await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .update({'applicationCount': 0});
    return 0;
  }

  Future<void> cancelApplication({
    required String jobDocId,
    required String userId,
  }) async {
    if (jobDocId.trim().isEmpty || userId.trim().isEmpty) return;
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
    final jobDocRef = _firestore.collection(JobCollection.name).doc(jobDocId);

    final batch = _firestore.batch();
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
    final ownerNotificationRef =
        NotificationsRepository.ensure().inboxDoc(ownerUserId);
    final jobDocRef = _firestore.collection(JobCollection.name).doc(jobDocId);

    final snap = await applicationRef.get();
    if (snap.exists) {
      await cancelApplication(
        jobDocId: jobDocId,
        userId: userId,
      );
      return;
    }

    final batch = _firestore.batch();
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
    NotificationsRepository.ensure().queueCreateInboxItem(
      batch,
      ownerUserId,
      {
        'type': 'job_application',
        'fromUserID': userId,
        'postID': jobDocId,
        'timeStamp': now,
        'read': false,
        'title': applicantName.isNotEmpty ? applicantName : 'Bir kullanıcı',
        'body': '$jobTitle ilanina basvuru yapti',
        'thumbnail': applicantPfImage,
      },
      docId: ownerNotificationRef.id,
    );
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
    final notificationRef =
        NotificationsRepository.ensure().inboxDoc(applicantUserId);

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
    NotificationsRepository.ensure().queueCreateInboxItem(
      batch,
      applicantUserId,
      {
        'type': 'job_application',
        'fromUserID': actorUid,
        'postID': jobDocId,
        'timeStamp': now,
        'read': false,
        'title': 'Başvuru durumu güncellendi',
        'body': _statusBody(newStatus, title, companyName),
      },
      docId: notificationRef.id,
    );
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
}
