class SinavModel {
  String cover;
  String sinavAciklama;
  String sinavAdi;
  String sinavTuru;
  num timeStamp;
  String docID;
  String kpssSecilenLisans;
  List<String> dersler;
  List<String> soruSayilari;
  String userID;
  bool taslak;
  bool public;
  num bitisDk;
  num bitis;
  num participantCount;
  SinavModel({
    required this.docID,
    required this.cover,
    required this.sinavTuru,
    required this.timeStamp,
    required this.sinavAciklama,
    required this.sinavAdi,
    required this.kpssSecilenLisans,
    required this.dersler,
    required this.taslak,
    required this.public,
    required this.userID,
    required this.soruSayilari,
    required this.bitis,
    required this.bitisDk,
    this.participantCount = 0,
  });
}
