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

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  TestsModel({
    required this.userID,
    required this.timeStamp,
    required this.aciklama,
    required List<String> dersler,
    required this.img,
    required this.docID,
    required this.paylasilabilir,
    required this.testTuru,
    required this.taslak,
  }) : dersler = _cloneStringList(dersler);
}
