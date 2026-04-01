class JobReviewModel {
  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  final String reviewID;
  final String userID;
  final String jobDocID;
  final int rating;
  final String comment;
  final int timeStamp;

  JobReviewModel({
    required this.reviewID,
    required this.userID,
    required this.jobDocID,
    required this.rating,
    required this.comment,
    required this.timeStamp,
  });

  factory JobReviewModel.fromMap(Map<String, dynamic> map, String docID) {
    return JobReviewModel(
      reviewID: docID,
      userID: (map['userID'] ?? '').toString(),
      jobDocID: (map['jobDocID'] ?? '').toString(),
      rating: _asInt(map['rating']),
      comment: (map['comment'] ?? '').toString(),
      timeStamp: _asInt(map['timeStamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userID': userID,
      'jobDocID': jobDocID,
      'rating': rating,
      'comment': comment,
      'timeStamp': timeStamp,
    };
  }
}
