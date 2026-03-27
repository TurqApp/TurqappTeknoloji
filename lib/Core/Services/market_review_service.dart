import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/market_review_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MarketReviewService {
  const MarketReviewService();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  String get _currentUserId => CurrentUserService.instance.effectiveUserId;

  CollectionReference<Map<String, dynamic>> _reviewsRef(String itemId) {
    return _firestore
        .collection('marketStore')
        .doc(itemId)
        .collection('Reviews');
  }

  Future<List<MarketReviewModel>> fetchReviews(String itemId) async {
    final snapshot = await _reviewsRef(itemId)
        .orderBy('timeStamp', descending: true)
        .limit(50)
        .get(const GetOptions(source: Source.serverAndCache));
    final reviews = snapshot.docs
        .map((doc) => MarketReviewModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    final uniqueByUser = <String, MarketReviewModel>{};
    for (final review in reviews) {
      uniqueByUser.putIfAbsent(review.userId, () => review);
    }
    return uniqueByUser.values.toList(growable: false);
  }

  Future<void> submitReview({
    required String itemId,
    required String ownerId,
    required int rating,
    required String comment,
  }) async {
    final uid = _currentUserId;
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
  }

  Future<void> deleteReview({
    required String itemId,
    required String reviewId,
  }) async {
    final uid = _currentUserId;
    if (uid.isEmpty || uid != reviewId) {
      throw Exception('forbidden');
    }
    await _reviewsRef(itemId).doc(reviewId).delete();
  }
}
