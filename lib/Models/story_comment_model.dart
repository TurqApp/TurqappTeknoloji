class StoryCommentModel {
  String docID;
  num timeStamp;
  String metin;
  String gif;
  String userID;

  StoryCommentModel({
    required this.docID,
    required this.userID,
    required this.metin,
    required this.timeStamp,
    required this.gif,
  });

  factory StoryCommentModel.fromMap(Map<String, dynamic> data,
      {required String docID}) {
    return StoryCommentModel(
      docID: docID,
      userID: data['userID'] ?? '',
      metin: data['metin'] ?? '',
      timeStamp: data['timeStamp'] ?? 0,
      gif: data['gif'] ?? '',
    );
  }
}
