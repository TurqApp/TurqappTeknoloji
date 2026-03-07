class CikmisSorularCoverModel {
  String anaBaslik;
  String sinavTuru;
  String docID;

  CikmisSorularCoverModel({
    required this.anaBaslik,
    required this.docID,
    required this.sinavTuru,
  });
}

class CikmisSorularinModeli {
  String soru;
  String ders;
  String dogruCevap;
  num kacCevap;
  String docID;
  String soruNo;

  CikmisSorularinModeli(
      {required this.ders,
      required this.dogruCevap,
      required this.soru,
      required this.kacCevap,
      required this.docID,
      required this.soruNo});
}

class SoruBankasiModel {
  String soru;
  String ders;
  String dogruCevap;
  num kacCevap;
  String docID;
  String soruNo;
  String anaBaslik;
  String sinavTuru;
  String yil;
  String diger1;
  bool diger2;
  num diger3;
  List<String> goruntuleme;
  List<String> soruCoz;
  List<String> dogruCevapVerenler;
  List<String> yanlisCevapVerenler;
  List<String> paylasanlar;
  List<String> begeniler;

  SoruBankasiModel({
    required this.ders,
    required this.dogruCevap,
    required this.soru,
    required this.kacCevap,
    required this.docID,
    required this.soruNo,
    required this.anaBaslik,
    required this.sinavTuru,
    required this.yil,
    required this.diger1,
    required this.diger2,
    required this.diger3,
    required this.goruntuleme,
    required this.soruCoz,
    required this.dogruCevapVerenler,
    required this.yanlisCevapVerenler,
    required this.paylasanlar,
    required this.begeniler,
  });

  // Map from Firestore document to model
  factory SoruBankasiModel.fromMap(Map<String, dynamic> map) {
    return SoruBankasiModel(
      ders: map['ders'],
      dogruCevap: map['dogruCevap'],
      soru: map['soru'],
      kacCevap: map['kacCevap'],
      docID: map['docID'],
      soruNo: map['soruNo'],
      anaBaslik: map['anaBaslik'],
      sinavTuru: map['sinavTuru'],
      yil: map['yil'],
      diger1: map['diger1'],
      diger2: map['diger2'],
      diger3: map['diger3'],
      goruntuleme: List<String>.from(map['goruntuleme'] ?? []),
      soruCoz: List<String>.from(map['soruCoz'] ?? []),
      dogruCevapVerenler: List<String>.from(map['dogruCevapVerenler'] ?? []),
      yanlisCevapVerenler: List<String>.from(map['yanlisCevapVerenler'] ?? []),
      paylasanlar: List<String>.from(map['paylasanlar'] ?? []),
      begeniler: List<String>.from(map['begeniler'] ?? []),
    );
  }
}
