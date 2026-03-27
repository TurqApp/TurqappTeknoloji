class AntremanCommentModel {
  String metin, userID, docID;
  num timeStamp;
  List<String> begeniler;

  AntremanCommentModel(
      this.docID, this.begeniler, this.userID, this.timeStamp, this.metin);
}
