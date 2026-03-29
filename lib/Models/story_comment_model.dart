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
      userID: (data['userID'] ?? '').toString(),
      metin: (data['metin'] ?? '').toString(),
      timeStamp: (data['timeStamp'] as num?) ??
          num.tryParse((data['timeStamp'] ?? '').toString()) ??
          0,
      gif: (data['gif'] ?? '').toString(),
    );
  }
}
