class ExamModel {
  static num _asNum(Object? value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString()) ?? 0;
  }

  static bool _asBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return fallback;
      switch (normalized) {
        case 'true':
        case '1':
        case 'yes':
        case 'y':
        case 'on':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'n':
        case 'off':
          return false;
      }
    }
    return fallback;
  }

  static List<String> _cloneStringList(Iterable<dynamic> source) {
    return source
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  final num bitis;
  final num bitisDk;
  final String cover;
  final List<String> dersler;
  final List<String> gecersizSayilanlar;
  final String kpssSecilenLisans;
  final bool isPublic;
  final String sinavAciklama;
  final String sinavAdi;
  final String sinavTuru;
  final List<String> soruSayilari;
  final bool taslak;
  final num timeStamp;
  final String userID;

  ExamModel({
    required this.bitis,
    required this.bitisDk,
    required this.cover,
    required List<String> dersler,
    required List<String> gecersizSayilanlar,
    required this.kpssSecilenLisans,
    required this.isPublic,
    required this.sinavAciklama,
    required this.sinavAdi,
    required this.sinavTuru,
    required List<String> soruSayilari,
    required this.taslak,
    required this.timeStamp,
    required this.userID,
  })  : dersler = _cloneStringList(dersler),
        gecersizSayilanlar = _cloneStringList(gecersizSayilanlar),
        soruSayilari = _cloneStringList(soruSayilari);

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      bitis: _asNum(json['bitis']),
      bitisDk: _asNum(json['bitisDk']),
      cover: (json['cover'] ?? '').toString(),
      dersler: _cloneStringList(json['dersler'] ?? const []),
      gecersizSayilanlar:
          _cloneStringList(json['gecersizSayilanlar'] ?? const []),
      kpssSecilenLisans: (json['kpssSecilenLisans'] ?? '').toString(),
      isPublic: _asBool(json['public']),
      sinavAciklama: (json['sinavAciklama'] ?? '').toString(),
      sinavAdi: (json['sinavAdi'] ?? '').toString(),
      sinavTuru: (json['sinavTuru'] ?? '').toString(),
      soruSayilari: _cloneStringList(json['soruSayilari'] ?? const []),
      taslak: _asBool(json['taslak']),
      timeStamp: _asNum(json['timeStamp']),
      userID: (json['userID'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bitis': bitis,
      'bitisDk': bitisDk,
      'cover': cover,
      'dersler': _cloneStringList(dersler),
      'gecersizSayilanlar': _cloneStringList(gecersizSayilanlar),
      'kpssSecilenLisans': kpssSecilenLisans,
      'public': isPublic,
      'sinavAciklama': sinavAciklama,
      'sinavAdi': sinavAdi,
      'sinavTuru': sinavTuru,
      'soruSayilari': _cloneStringList(soruSayilari),
      'taslak': taslak,
      'timeStamp': timeStamp,
      'userID': userID,
    };
  }
}
