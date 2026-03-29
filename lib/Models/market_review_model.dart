class MarketReviewModel {
  const MarketReviewModel({
    required this.reviewId,
    required this.userId,
    required this.itemId,
    required this.rating,
    required this.comment,
    required this.timeStamp,
  });

  final String reviewId;
  final String userId;
  final String itemId;
  final int rating;
  final String comment;
  final int timeStamp;

  factory MarketReviewModel.fromMap(
    Map<String, dynamic> map,
    String reviewId,
  ) {
    return MarketReviewModel(
      reviewId: reviewId,
      userId: (map['userID'] ?? map['userId'] ?? '').toString(),
      itemId: (map['itemId'] ?? '').toString(),
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: (map['comment'] ?? '').toString(),
      timeStamp: (map['timeStamp'] as num?)?.toInt() ??
          int.tryParse((map['timeStamp'] ?? '').toString()) ??
          0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'userID': userId,
      'itemId': itemId,
      'rating': rating,
      'comment': comment,
      'timeStamp': timeStamp,
    };
  }
}
