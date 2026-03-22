class CikmisSoruSonucModel {
  String anaBaslik;
  String sinavTuru;
  String yil;
  String baslik2;
  String baslik3;
  String userID;
  num timeStamp;
  String cikmisSoruID;
  String docID;
  int soruSayisi;
  int dogruSayisi;
  int yanlisSayisi;
  int bosSayisi;
  double net;

  CikmisSoruSonucModel(
      {required this.anaBaslik,
      required this.sinavTuru,
      required this.yil,
      required this.baslik2,
      required this.baslik3,
      required this.userID,
      required this.timeStamp,
      required this.cikmisSoruID,
      required this.docID,
      required this.soruSayisi,
      required this.dogruSayisi,
      required this.yanlisSayisi,
      required this.bosSayisi,
      required this.net});
}
