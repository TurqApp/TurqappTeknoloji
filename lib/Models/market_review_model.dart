class MarketReviewModel {
  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

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
      rating: _asInt(map['rating']),
      comment: (map['comment'] ?? '').toString(),
      timeStamp: _asInt(map['timeStamp']),
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
