class AntremanCommentModel {
  String metin;
  String userID;
  num timeStamp;
  List<String> begeniler;
  String docID;

  AntremanCommentModel({
    required this.docID,
    required this.begeniler,
    required this.userID,
    required this.timeStamp,
    required this.metin,
  });
}
