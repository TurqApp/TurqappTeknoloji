class TutoringReviewModel {
  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  final String reviewID;
  final String userID;
  final String tutoringDocID;
  final int rating; // 1-5
  final String comment;
  final int timeStamp;

  TutoringReviewModel({
    required this.reviewID,
    required this.userID,
    required this.tutoringDocID,
    required this.rating,
    required this.comment,
    required this.timeStamp,
  });

  factory TutoringReviewModel.fromMap(Map<String, dynamic> map, String docID) {
    return TutoringReviewModel(
      reviewID: docID,
      userID: (map['userID'] ?? '').toString(),
      tutoringDocID: (map['tutoringDocID'] ?? '').toString(),
      rating: _asInt(map['rating']),
      comment: (map['comment'] ?? '').toString(),
      timeStamp: _asInt(map['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'tutoringDocID': tutoringDocID,
      'rating': rating,
      'comment': comment,
      'timeStamp': timeStamp,
    };
  }
}
