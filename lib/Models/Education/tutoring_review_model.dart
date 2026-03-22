class TutoringReviewModel {
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
      userID: map['userID'] ?? '',
      tutoringDocID: map['tutoringDocID'] ?? '',
      rating: map['rating'] ?? 0,
      comment: map['comment'] ?? '',
      timeStamp: map['timeStamp'] ?? 0,
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
