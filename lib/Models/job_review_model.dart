class JobReviewModel {
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
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: (map['comment'] ?? '').toString(),
      timeStamp: (map['timeStamp'] as num?)?.toInt() ?? 0,
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
