import 'dart:developer';

class QuestionBankModel {
  final String docID;
  final String anaBaslik;
  final List<dynamic> begeniler;
  final String categoryKey;
  final String ders;
  final String diger1;
  final bool diger2;
  final num diger3;
  final String dogruCevap;
  final int correctCount;
  final int viewCount;
  final bool iptal;
  final num kacCevap;
  final List<dynamic> paylasanlar;
  final int seq;
  final String sinavTuru;
  final String soru;
  final String soruNo;
  final int wrongCount;
  final String yil;
  final bool active;

  QuestionBankModel({
    required this.docID,
    required this.anaBaslik,
    required this.begeniler,
    required this.categoryKey,
    required this.ders,
    required this.diger1,
    required this.diger2,
    required this.diger3,
    required this.dogruCevap,
    required this.correctCount,
    required this.viewCount,
    required this.iptal,
    required this.kacCevap,
    required this.paylasanlar,
    required this.seq,
    required this.sinavTuru,
    required this.soru,
    required this.soruNo,
    required this.wrongCount,
    required this.yil,
    required this.active,
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
      categoryKey: json['categoryKey'] as String? ?? '',
      ders: json['ders'] as String? ?? '',
      diger1: json['diger1'] as String? ?? '',
      diger2: json['diger2'] as bool? ?? false,
      diger3: json['diger3'] as num? ?? 0,
      dogruCevap: json['dogruCevap'] as String? ?? '',
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      iptal: json['iptal'] as bool? ?? false,
      kacCevap: json['kacCevap'] as num? ?? 0,
      paylasanlar: json['paylasanlar'] as List<dynamic>? ?? [],
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      sinavTuru: json['sinavTuru'] as String? ?? '',
      soru: json['soru'] as String? ?? '',
      soruNo: json['soruNo'] as String? ?? '',
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
      yil: json['yil'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docID': docID,
      'anaBaslik': anaBaslik,
      'begeniler': begeniler,
      'categoryKey': categoryKey,
      'ders': ders,
      'diger1': diger1,
      'diger2': diger2,
      'diger3': diger3,
      'dogruCevap': dogruCevap,
      'correctCount': correctCount,
      'viewCount': viewCount,
      'iptal': iptal,
      'kacCevap': kacCevap,
      'paylasanlar': paylasanlar,
      'seq': seq,
      'sinavTuru': sinavTuru,
      'soru': soru,
      'soruNo': soruNo,
      'wrongCount': wrongCount,
      'yil': yil,
      'active': active,
    };
  }
}
