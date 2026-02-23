class OpticalFormModel {
  String docID;
  String name;
  String userID;
  List<String> cevaplar;
  num max;
  num baslangic;
  num bitis;
  bool kisitlama;

  OpticalFormModel({
    required this.docID,
    required this.name,
    required this.cevaplar,
    required this.max,
    required this.userID,
    required this.baslangic,
    required this.bitis,
    required this.kisitlama,
  });
}
