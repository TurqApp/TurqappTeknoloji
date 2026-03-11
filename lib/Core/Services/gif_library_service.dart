import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GifLibraryService {
  GifLibraryService._();

  static final GifLibraryService instance = GifLibraryService._();

  CollectionReference<Map<String, dynamic>> get _globalCollection =>
      FirebaseFirestore.instance.collection('giphyGif');

  Future<void> recordUsage(
    String url, {
    required String source,
    required String category,
  }) async {
    final cleanUrl = url.trim();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (cleanUrl.isEmpty || uid == null || uid.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final docId = _stableId(cleanUrl);
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('giphyGif')
        .doc(docId);
    final globalRef = _globalCollection.doc(docId);

    final payload = {
      'url': cleanUrl,
      'source': source,
      'category': category,
      'lastUsedAt': now,
      'createdAt': now,
      'useCount': FieldValue.increment(1),
      'lastUsedBy': uid,
    };

    await Future.wait([
      ref.set(payload, SetOptions(merge: true)),
      globalRef.set(payload, SetOptions(merge: true)),
    ]);
  }

  Future<List<Map<String, dynamic>>> fetchGlobalLibrary({
    int limit = 60,
    String? category,
  }) async {
    Query<Map<String, dynamic>> query =
        _globalCollection.orderBy('lastUsedAt', descending: true);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    final snap = await query.limit(limit).get();

    return snap.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .where((item) => (item['url'] ?? '').toString().trim().isNotEmpty)
        .toList(growable: false);
  }

  String _stableId(String input) {
    var hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }
}
