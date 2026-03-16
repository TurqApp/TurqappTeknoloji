import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Models/market_review_model.dart';

class MarketReviewService {
  const MarketReviewService();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String itemId) {
    return _firestore.collection('marketStore').doc(itemId).collection('Reviews');
  }

  Future<List<MarketReviewModel>> fetchReviews(String itemId) async {
    final snapshot = await _reviewsRef(itemId)
        .orderBy('timeStamp', descending: true)
        .limit(50)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map((doc) => MarketReviewModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
  }

  Future<void> submitReview({
    required String itemId,
    required String ownerId,
    required int rating,
    required String comment,
  }) async {
    final uid = _user?.uid ?? '';
    if (uid.isEmpty) {
      throw Exception('auth_required');
    }
    if (uid == ownerId) {
      throw Exception('own_item_review_not_allowed');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await _reviewsRef(itemId).doc(uid).set({
      'userID': uid,
      'itemId': itemId,
      'rating': rating,
      'comment': comment.trim(),
      'timeStamp': now,
    });
    await _refreshAverageRating(itemId);
  }

  Future<void> deleteReview({
    required String itemId,
    required String reviewId,
  }) async {
    final uid = _user?.uid ?? '';
    if (uid.isEmpty || uid != reviewId) {
      throw Exception('forbidden');
    }
    await _reviewsRef(itemId).doc(reviewId).delete();
    await _refreshAverageRating(itemId);
  }

  Future<void> _refreshAverageRating(String itemId) async {
    final reviews = await fetchReviews(itemId);
    final itemRef = _firestore.collection('marketStore').doc(itemId);
    if (reviews.isEmpty) {
      await itemRef.update({'averageRating': null, 'reviewCount': 0});
      return;
    }
    double total = 0;
    for (final review in reviews) {
      total += review.rating.toDouble();
    }
    final avg = total / reviews.length;
    await itemRef.update({
      'averageRating': double.parse(avg.toStringAsFixed(1)),
      'reviewCount': reviews.length,
    });
  }
}
