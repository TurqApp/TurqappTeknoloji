class AnswerKeySubModel {
  String docID;
  num sira;
  String baslik;
  List<String> dogruCevaplar;

  AnswerKeySubModel({
    required this.baslik,
    required this.docID,
    required this.dogruCevaplar,
    required this.sira,
  });
}
