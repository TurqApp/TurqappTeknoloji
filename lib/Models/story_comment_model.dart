class StoryCommentModel {
  static num _asNum(Object? value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString()) ?? 0;
  }

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
      timeStamp: _asNum(data['timeStamp']),
      gif: (data['gif'] ?? '').toString(),
    );
  }
}
