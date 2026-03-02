class JobModel {
  final String docID;
  final String brand;
  final List<String> calismaTuru;
  final bool ended;
  final String isTanimi;
  final double lat;
  final double long;
  final String logo;
  final String adres;
  final int maas1;
  final int maas2;
  final String meslek;
  final int timeStamp;
  final String userID;
  final List<String> yanHaklar;
  final double kacKm;
  final String city;
  final String town;
  final String about;
  final String ilanBasligi;
  final String deneyimSeviyesi;
  final int pozisyonSayisi;
  final int viewCount;
  final int applicationCount;
  final int endedAt;

  JobModel({
    required this.docID,
    required this.brand,
    required this.calismaTuru,
    required this.ended,
    required this.isTanimi,
    required this.lat,
    required this.long,
    required this.adres,
    required this.logo,
    required this.maas1,
    required this.maas2,
    required this.meslek,
    required this.timeStamp,
    required this.userID,
    required this.yanHaklar,
    required this.city,
    required this.town,
    this.kacKm = 0.0,
    this.about = "",
    this.ilanBasligi = "",
    this.deneyimSeviyesi = "",
    this.pozisyonSayisi = 1,
    this.viewCount = 0,
    this.applicationCount = 0,
    this.endedAt = 0,
  });

  factory JobModel.fromMap(Map<String, dynamic> map, String docID) {
    return JobModel(
      docID: docID,
      brand: map['brand'] ?? '',
      calismaTuru: List<String>.from(map['calismaTuru'] ?? []),
      ended: map['ended'] ?? false,
      isTanimi: map['isTanimi'] ?? '',
      lat: map['lat']?.toDouble() ?? 0.0,
      long: map['long']?.toDouble() ?? 0.0,
      logo: map['logo'] ?? '',
      adres: map['adres'] ?? '',
      maas1: map['maas1'] ?? 0,
      maas2: map['maas2'] ?? 0,
      meslek: map['meslek'] ?? '',
      timeStamp: map['timeStamp'] ?? 0,
      userID: map['userID'] ?? '',
      yanHaklar: List<String>.from(map['yanHaklar'] ?? []),
      city: map['city'] ?? '',
      town: map['town'] ?? '',
      about: map['about'] ?? '',
      ilanBasligi: map['ilanBasligi'] ?? '',
      deneyimSeviyesi: map['deneyimSeviyesi'] ?? '',
      pozisyonSayisi: map['pozisyonSayisi'] ?? 1,
      viewCount: map['viewCount'] ?? 0,
      applicationCount: map['applicationCount'] ?? 0,
      endedAt: map['endedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'calismaTuru': calismaTuru,
      'ended': ended,
      'isTanimi': isTanimi,
      'lat': lat,
      'long': long,
      'logo': logo,
      'maas1': maas1,
      'maas2': maas2,
      'meslek': meslek,
      'adres': adres,
      'timeStamp': timeStamp,
      'userID': userID,
      'yanHaklar': yanHaklar,
      'city': city,
      'town': town,
      'about': about,
      'ilanBasligi': ilanBasligi,
      'deneyimSeviyesi': deneyimSeviyesi,
      'pozisyonSayisi': pozisyonSayisi,
      'viewCount': viewCount,
      'applicationCount': applicationCount,
      'endedAt': endedAt,
    };
  }

  JobModel copyWith({
    double? kacKm,
    String? about,
    String? ilanBasligi,
    String? deneyimSeviyesi,
    int? pozisyonSayisi,
    int? viewCount,
    int? applicationCount,
    int? endedAt,
  }) {
    return JobModel(
      docID: docID,
      brand: brand,
      calismaTuru: calismaTuru,
      ended: ended,
      isTanimi: isTanimi,
      lat: lat,
      long: long,
      logo: logo,
      adres: adres,
      maas1: maas1,
      maas2: maas2,
      meslek: meslek,
      timeStamp: timeStamp,
      userID: userID,
      yanHaklar: yanHaklar,
      city: city,
      town: town,
      kacKm: kacKm ?? this.kacKm,
      about: about ?? this.about,
      ilanBasligi: ilanBasligi ?? this.ilanBasligi,
      deneyimSeviyesi: deneyimSeviyesi ?? this.deneyimSeviyesi,
      pozisyonSayisi: pozisyonSayisi ?? this.pozisyonSayisi,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}
