class SoruModel{
  int id;
  String soru;
  String ders;
  String konu;
  String dogruCevap;
  String docID;

  SoruModel({
    required this.id,
    required this.soru,
    required this.ders,
    required this.konu,
    required this.dogruCevap,
    required this.docID
});
}