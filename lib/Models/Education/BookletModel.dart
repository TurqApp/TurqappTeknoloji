class BookletModel {
  String basimTarihi;
  String baslik;
  String cover;
  String dil;
  List<String> kaydet;
  String sinavTuru;
  num timeStamp;
  String yayinEvi;
  String docID;
  String userID;
  List<String> goruntuleme;

  BookletModel({
    required this.dil,
    required this.sinavTuru,
    required this.cover,
    required this.baslik,
    required this.timeStamp,
    required this.docID,
    required this.kaydet,
    required this.basimTarihi,
    required this.yayinEvi,
    required this.userID,
    required this.goruntuleme,
  });
}
