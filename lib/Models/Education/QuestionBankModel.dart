import 'dart:developer';

class QuestionBankModel {
  final String docID;
  final String anaBaslik;
  final List<dynamic> begeniler;
  final String ders;
  final String diger1;
  final bool diger2;
  final num diger3;
  final String dogruCevap;
  final List<dynamic> dogruCevapVerenler;
  final List<dynamic> goruntuleme;
  final bool iptal;
  final num kacCevap;
  final List<dynamic> paylasanlar;
  final String sinavTuru;
  final String soru;
  final List<dynamic> soruCoz;
  final String soruNo;
  final List<dynamic> yanlisCevapVerenler;
  final String yil;

  QuestionBankModel({
    required this.docID,
    required this.anaBaslik,
    required this.begeniler,
    required this.ders,
    required this.diger1,
    required this.diger2,
    required this.diger3,
    required this.dogruCevap,
    required this.dogruCevapVerenler,
    required this.goruntuleme,
    required this.iptal,
    required this.kacCevap,
    required this.paylasanlar,
    required this.sinavTuru,
    required this.soru,
    required this.soruCoz,
    required this.soruNo,
    required this.yanlisCevapVerenler,
    required this.yil,
  });

  factory QuestionBankModel.fromJson(Map<String, dynamic> json) {
    final docID = json['docID'] as String? ?? '';
    if (docID.isEmpty) {
      log("Hata: Firestore belgesinde geçersiz veya boş docID: ${json['soru']}");
      throw Exception("Geçersiz docID: Boş veya null olamaz");
    }
    return QuestionBankModel(
      docID: docID,
      anaBaslik: json['anaBaslik'] as String? ?? '',
      begeniler: json['begeniler'] as List<dynamic>? ?? [],
      ders: json['ders'] as String? ?? '',
      diger1: json['diger1'] as String? ?? '',
      diger2: json['diger2'] as bool? ?? false,
      diger3: json['diger3'] as num? ?? 0,
      dogruCevap: json['dogruCevap'] as String? ?? '',
      dogruCevapVerenler: json['dogruCevapVerenler'] as List<dynamic>? ?? [],
      goruntuleme: json['goruntuleme'] as List<dynamic>? ?? [],
      iptal: json['iptal'] as bool? ?? false,
      kacCevap: json['kacCevap'] as num? ?? 0,
      paylasanlar: json['paylasanlar'] as List<dynamic>? ?? [],
      sinavTuru: json['sinavTuru'] as String? ?? '',
      soru: json['soru'] as String? ?? '',
      soruCoz: json['soruCoz'] as List<dynamic>? ?? [],
      soruNo: json['soruNo'] as String? ?? '',
      yanlisCevapVerenler: json['yanlisCevapVerenler'] as List<dynamic>? ?? [],
      yil: json['yil'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docID': docID,
      'anaBaslik': anaBaslik,
      'begeniler': begeniler,
      'ders': ders,
      'diger1': diger1,
      'diger2': diger2,
      'diger3': diger3,
      'dogruCevap': dogruCevap,
      'dogruCevapVerenler': dogruCevapVerenler,
      'goruntuleme': goruntuleme,
      'iptal': iptal,
      'kacCevap': kacCevap,
      'paylasanlar': paylasanlar,
      'sinavTuru': sinavTuru,
      'soru': soru,
      'soruCoz': soruCoz,
      'soruNo': soruNo,
      'yanlisCevapVerenler': yanlisCevapVerenler,
      'yil': yil,
    };
  }
}
