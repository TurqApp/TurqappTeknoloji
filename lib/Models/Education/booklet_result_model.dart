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

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  BookletResultModel({
    required List<String> cevaplar,
    required this.docID,
    required this.baslik,
    required this.timeStamp,
    required this.yanlis,
    required this.dogru,
    required this.bos,
    required this.kitapcikID,
    required List<String> dogruCevaplar,
    required this.puan,
  }) : cevaplar = _cloneStringList(cevaplar),
       dogruCevaplar = _cloneStringList(dogruCevaplar);
}
