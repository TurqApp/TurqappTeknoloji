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
  final String shortId;
  final String shortUrl;
  final int wrongCount;
  final String yil;
  final bool active;

  static List<dynamic> _cloneDynamicList(List<dynamic> source) =>
      List<dynamic>.from(source, growable: false);

  static String _asString(dynamic value) => (value ?? '').toString();

  static bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static num _asNum(dynamic value, {num fallback = 0}) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static List<dynamic> _asDynamicList(dynamic value) {
    if (value is! List) return const <dynamic>[];
    return List<dynamic>.from(value, growable: false);
  }

  QuestionBankModel({
    required this.docID,
    required this.anaBaslik,
    required List<dynamic> begeniler,
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
    required List<dynamic> paylasanlar,
    required this.seq,
    required this.sinavTuru,
    required this.soru,
    required this.soruNo,
    this.shortId = '',
    this.shortUrl = '',
    required this.wrongCount,
    required this.yil,
    required this.active,
  })  : begeniler = _cloneDynamicList(begeniler),
        paylasanlar = _cloneDynamicList(paylasanlar);

  factory QuestionBankModel.fromJson(Map<String, dynamic> json) {
    final docID = _asString(json['docID']).trim();
    if (docID.isEmpty) {
      log("Hata: Firestore belgesinde geçersiz veya boş docID: ${json['soru']}");
      throw Exception("Geçersiz docID: Boş veya null olamaz");
    }
    return QuestionBankModel(
      docID: docID,
      anaBaslik: _asString(json['anaBaslik']),
      begeniler: _asDynamicList(json['begeniler']),
      categoryKey: _asString(json['categoryKey']),
      ders: _asString(json['ders']),
      diger1: _asString(json['diger1']),
      diger2: _asBool(json['diger2']),
      diger3: _asNum(json['diger3']),
      dogruCevap: _asString(json['dogruCevap']),
      correctCount: _asInt(json['correctCount']),
      viewCount: _asInt(json['viewCount']),
      iptal: _asBool(json['iptal']),
      kacCevap: _asNum(json['kacCevap']),
      paylasanlar: _asDynamicList(json['paylasanlar']),
      seq: _asInt(json['seq']),
      sinavTuru: _asString(json['sinavTuru']),
      soru: _asString(json['soru']),
      soruNo: _asString(json['soruNo']),
      shortId: _asString(json['shortId']),
      shortUrl: _asString(json['shortUrl']),
      wrongCount: _asInt(json['wrongCount']),
      yil: _asString(json['yil']),
      active: _asBool(json['active'], fallback: true),
    );
  }

  factory QuestionBankModel.fromTypesenseHit(Map<String, dynamic> json) {
    final docID = _asString(json['docId']).trim().isNotEmpty
        ? _asString(json['docId']).trim()
        : _asString(json['id']).trim();
    if (docID.isEmpty) {
      throw Exception("Geçersiz docID: Typesense hit boş");
    }
    return QuestionBankModel(
      docID: docID,
      anaBaslik: _asString(json['anaBaslik']),
      begeniler: const [],
      categoryKey: _asString(json['categoryKey']),
      ders: _asString(json['ders']),
      diger1: _asString(json['diger1']),
      diger2: _asBool(json['diger2']),
      diger3: _asNum(json['diger3']),
      dogruCevap: _asString(json['dogruCevap']),
      correctCount: _asInt(json['correctCount']),
      viewCount: _asInt(json['viewCount']),
      iptal: !_asBool(json['active'], fallback: true),
      kacCevap: _asNum(json['kacCevap']),
      paylasanlar: const [],
      seq: _asInt(json['seq']),
      sinavTuru: _asString(json['sinavTuru']),
      soru: _asString(json['soru']).isNotEmpty
          ? _asString(json['soru'])
          : _asString(json['cover']),
      soruNo: _asString(json['soruNo']),
      shortId: _asString(json['shortId']),
      shortUrl: _asString(json['shortUrl']),
      wrongCount: _asInt(json['wrongCount']),
      yil: _asString(json['yil']),
      active: _asBool(json['active'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'docID': docID,
      'anaBaslik': anaBaslik,
      'begeniler': _cloneDynamicList(begeniler),
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
      'paylasanlar': _cloneDynamicList(paylasanlar),
      'seq': seq,
      'sinavTuru': sinavTuru,
      'soru': soru,
      'soruNo': soruNo,
      'shortId': shortId,
      'shortUrl': shortUrl,
      'wrongCount': wrongCount,
      'yil': yil,
      'active': active,
    };
  }
}
