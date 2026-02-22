class ExamModel {
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
    required this.dersler,
    required this.gecersizSayilanlar,
    required this.kpssSecilenLisans,
    required this.isPublic,
    required this.sinavAciklama,
    required this.sinavAdi,
    required this.sinavTuru,
    required this.soruSayilari,
    required this.taslak,
    required this.timeStamp,
    required this.userID,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      bitis: json['bitis'],
      bitisDk: json['bitisDk'],
      cover: json['cover'],
      dersler: List<String>.from(json['dersler']),
      gecersizSayilanlar: List<String>.from(json['gecersizSayilanlar']),
      kpssSecilenLisans: json['kpssSecilenLisans'],
      isPublic: json['public'],
      sinavAciklama: json['sinavAciklama'],
      sinavAdi: json['sinavAdi'],
      sinavTuru: json['sinavTuru'],
      soruSayilari: List<String>.from(json['soruSayilari']),
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
      'dersler': dersler,
      'gecersizSayilanlar': gecersizSayilanlar,
      'kpssSecilenLisans': kpssSecilenLisans,
      'public': isPublic,
      'sinavAciklama': sinavAciklama,
      'sinavAdi': sinavAdi,
      'sinavTuru': sinavTuru,
      'soruSayilari': soruSayilari,
      'taslak': taslak,
      'timeStamp': timeStamp,
      'userID': userID,
    };
  }
}
