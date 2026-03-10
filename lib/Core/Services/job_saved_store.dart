import 'package:cloud_firestore/cloud_firestore.dart';

class SavedJobRecord {
  final String jobId;
  final int timeStamp;

  const SavedJobRecord({
    required this.jobId,
    required this.timeStamp,
  });
}

class JobSavedStore {
  JobSavedStore._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _userSavedJobs(String uid) {
    return _firestore.collection('users').doc(uid).collection('savedJobs');
  }

  static DocumentReference<Map<String, dynamic>> _savedJobDoc(
    String uid,
    String jobId,
  ) {
    return _userSavedJobs(uid).doc(jobId);
  }

  static DocumentReference<Map<String, dynamic>> _legacySavedJobDoc(
    String uid,
    String jobId,
  ) {
    return _firestore.collection('SavedIsBul').doc('${uid}_$jobId');
  }

  static Map<String, dynamic> _payload(
      String uid, String jobId, int timeStamp) {
    return <String, dynamic>{
      'userID': uid,
      'jobID': jobId,
      'timeStamp': timeStamp,
    };
  }

  static Future<bool> isSaved(String uid, String jobId) async {
    final currentSnap = await _savedJobDoc(uid, jobId).get();
    if (currentSnap.exists) return true;

    final legacySnap = await _legacySavedJobDoc(uid, jobId).get();
    if (!legacySnap.exists) return false;

    final legacyData = legacySnap.data() ?? const <String, dynamic>{};
    final timeStamp = (legacyData['timeStamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;
    await _migrateLegacyDoc(uid, jobId, timeStamp);
    return true;
  }

  static Future<void> save(String uid, String jobId) async {
    final timeStamp = DateTime.now().millisecondsSinceEpoch;
    final batch = _firestore.batch();
    batch.set(_savedJobDoc(uid, jobId), _payload(uid, jobId, timeStamp));
    batch.delete(_legacySavedJobDoc(uid, jobId));
    await batch.commit();
  }

  static Future<void> unsave(String uid, String jobId) async {
    final batch = _firestore.batch();
    batch.delete(_savedJobDoc(uid, jobId));
    batch.delete(_legacySavedJobDoc(uid, jobId));
    await batch.commit();
  }

  static Future<List<SavedJobRecord>> getSavedJobs(String uid) async {
    final currentSnap =
        await _userSavedJobs(uid).orderBy('timeStamp', descending: true).get();
    final legacySnap = await _firestore
        .collection('SavedIsBul')
        .where('userID', isEqualTo: uid)
        .get();

    final byJobId = <String, SavedJobRecord>{};
    for (final doc in currentSnap.docs) {
      final data = doc.data();
      final jobId = (data['jobID'] ?? doc.id).toString().trim();
      if (jobId.isEmpty) continue;
      byJobId[jobId] = SavedJobRecord(
        jobId: jobId,
        timeStamp: (data['timeStamp'] as num?)?.toInt() ?? 0,
      );
    }

    if (legacySnap.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in legacySnap.docs) {
        final data = doc.data();
        final jobId = (data['jobID'] ?? '').toString().trim();
        if (jobId.isEmpty) continue;
        final timeStamp = (data['timeStamp'] as num?)?.toInt() ??
            DateTime.now().millisecondsSinceEpoch;
        final existing = byJobId[jobId];
        if (existing == null || timeStamp > existing.timeStamp) {
          byJobId[jobId] = SavedJobRecord(jobId: jobId, timeStamp: timeStamp);
        }
        batch.set(_savedJobDoc(uid, jobId), _payload(uid, jobId, timeStamp));
        batch.delete(doc.reference);
      }
      await batch.commit();
    }

    final items = byJobId.values.toList()
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    return items;
  }

  static Future<void> removeSavedJobs(String uid, List<String> jobIds) async {
    if (jobIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final jobId in jobIds) {
      batch.delete(_savedJobDoc(uid, jobId));
      batch.delete(_legacySavedJobDoc(uid, jobId));
    }
    await batch.commit();
  }

  static Future<void> _migrateLegacyDoc(
    String uid,
    String jobId,
    int timeStamp,
  ) async {
    final batch = _firestore.batch();
    batch.set(_savedJobDoc(uid, jobId), _payload(uid, jobId, timeStamp));
    batch.delete(_legacySavedJobDoc(uid, jobId));
    await batch.commit();
  }
}
