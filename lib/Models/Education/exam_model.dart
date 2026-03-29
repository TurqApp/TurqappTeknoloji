class ExamModel {
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
      bitis: json['bitis'],
      bitisDk: json['bitisDk'],
      cover: json['cover'],
      dersler: _cloneStringList(json['dersler'] ?? const []),
      gecersizSayilanlar:
          _cloneStringList(json['gecersizSayilanlar'] ?? const []),
      kpssSecilenLisans: json['kpssSecilenLisans'],
      isPublic: json['public'],
      sinavAciklama: json['sinavAciklama'],
      sinavAdi: json['sinavAdi'],
      sinavTuru: json['sinavTuru'],
      soruSayilari: _cloneStringList(json['soruSayilari'] ?? const []),
      taslak: json['taslak'],
      timeStamp: json['timeStamp'],
      userID: json['userID'],
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
