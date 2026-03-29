class OpticalFormModel {
  String docID;
  String name;
  String userID;
  List<String> cevaplar;
  num max;
  num baslangic;
  num bitis;
  bool kisitlama;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  OpticalFormModel({
    required this.docID,
    required this.name,
    required List<String> cevaplar,
    required this.max,
    required this.userID,
    required this.baslangic,
    required this.bitis,
    required this.kisitlama,
  }) : cevaplar = _cloneStringList(cevaplar);

  factory OpticalFormModel.fromMap(Map<String, dynamic> data, String docID) {
    return OpticalFormModel(
      docID: docID,
      name: (data['name'] ?? '').toString(),
      cevaplar: (data['cevaplar'] is List)
          ? (data['cevaplar'] as List).map((e) => e.toString()).toList()
          : <String>[],
      max: data['max'] is num
          ? data['max'] as num
          : num.tryParse((data['max'] ?? '0').toString()) ?? 0,
      userID: (data['userID'] ?? '').toString(),
      baslangic: data['baslangic'] is num
          ? data['baslangic'] as num
          : num.tryParse((data['baslangic'] ?? '0').toString()) ?? 0,
      bitis: data['bitis'] is num
          ? data['bitis'] as num
          : num.tryParse((data['bitis'] ?? '0').toString()) ?? 0,
      kisitlama: data['kisitlama'] == true,
    );
  }
}
