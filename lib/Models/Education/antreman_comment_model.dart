class AntremanCommentModel {
  String metin, userID, docID;
  num timeStamp;
  List<String> begeniler;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  AntremanCommentModel(
    this.docID,
    List<String> begeniler,
    this.userID,
    this.timeStamp,
    this.metin,
  ) : begeniler = _cloneStringList(begeniler);
}
