class AntremanCommentModel {
  String metin, userID, docID;
  num timeStamp;
  List<String> begeniler;

  AntremanCommentModel({
    required this.docID,
    required this.begeniler,
    required this.userID,
    required this.timeStamp,
    required this.metin,
  });
}
