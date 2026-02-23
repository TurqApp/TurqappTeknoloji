class TestsModel {
  String aciklama;
  List<String> dersler;
  String img;
  String timeStamp;
  String userID;
  String docID;
  String testTuru;
  bool paylasilabilir;
  bool taslak;

  TestsModel({
    required this.userID,
    required this.timeStamp,
    required this.aciklama,
    required this.dersler,
    required this.img,
    required this.docID,
    required this.paylasilabilir,
    required this.testTuru,
    required this.taslak,
  });
}
