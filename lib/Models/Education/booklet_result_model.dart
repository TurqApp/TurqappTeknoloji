class BookletResultModel {
  String baslik;
  num bos;
  num dogru;
  num yanlis;
  num puan;
  num timeStamp;
  List<String> cevaplar;
  List<String> dogruCevaplar;
  String kitapcikID;
  String docID;

  BookletResultModel({
    required this.cevaplar,
    required this.docID,
    required this.baslik,
    required this.timeStamp,
    required this.yanlis,
    required this.dogru,
    required this.bos,
    required this.kitapcikID,
    required this.dogruCevaplar,
    required this.puan,
  });
}
