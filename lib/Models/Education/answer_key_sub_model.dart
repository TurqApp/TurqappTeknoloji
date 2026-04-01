class AnswerKeySubModel {
  String docID;
  num sira;
  String baslik;
  List<String> dogruCevaplar;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  AnswerKeySubModel(
    this.baslik,
    this.docID,
    List<String> dogruCevaplar,
    this.sira,
  ) : dogruCevaplar = _cloneStringList(dogruCevaplar);
}
