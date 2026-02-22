
class CikmisSoruSonucModel{
  String anaBaslik;
  String sinavTuru;
  String yil;
  String baslik2;
  String baslik3;
  String userID;
  List<String> cevaplar;
  List<String> dogruCevaplar;
  num timeStamp;
  String cikmisSoruID;
  String docID;

  CikmisSoruSonucModel({
    required this.anaBaslik,
    required this.sinavTuru,
    required this.yil,
    required this.baslik2,
    required this.baslik3,
    required this.userID,
    required this.cevaplar,
    required this.timeStamp,
    required this.cikmisSoruID,
    required this.dogruCevaplar,
    required this.docID
});
}