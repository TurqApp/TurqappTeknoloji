class JobModel {
  final String docID;
  final String brand;
  final List<String> calismaGunleri;
  final String calismaSaatiBaslangic;
  final String calismaSaatiBitis;
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
  final int basvuruSayisi;
  final int pozisyonSayisi;
  final int viewCount;
  final int applicationCount;
  final int endedAt;
  final String authorAvatarUrl;
  final String authorDisplayName;
  final String authorNickname;
  final String shortId;
  final String shortUrl;
  final String rozet;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  JobModel({
    required this.docID,
    required this.brand,
    required List<String> calismaGunleri,
    required this.calismaSaatiBaslangic,
    required this.calismaSaatiBitis,
    required List<String> calismaTuru,
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
    required List<String> yanHaklar,
    required this.city,
    required this.town,
    this.kacKm = 0.0,
    this.about = "",
    this.ilanBasligi = "",
    this.deneyimSeviyesi = "",
    this.basvuruSayisi = 0,
    this.pozisyonSayisi = 1,
    this.viewCount = 0,
    this.applicationCount = 0,
    this.endedAt = 0,
    this.authorAvatarUrl = "",
    this.authorDisplayName = "",
    this.authorNickname = "",
    this.shortId = "",
    this.shortUrl = "",
    this.rozet = "",
  }) : calismaGunleri = _cloneStringList(calismaGunleri),
       calismaTuru = _cloneStringList(calismaTuru),
       yanHaklar = _cloneStringList(yanHaklar);

  factory JobModel.fromMap(Map<String, dynamic> map, String docID) {
    return JobModel(
      docID: docID,
      brand: map['brand'] ?? '',
      calismaGunleri: List<String>.from(map['calismaGunleri'] ?? []),
      calismaSaatiBaslangic: map['calismaSaatiBaslangic'] ?? '',
      calismaSaatiBitis: map['calismaSaatiBitis'] ?? '',
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
      basvuruSayisi: map['basvuruSayisi'] ?? 0,
      pozisyonSayisi: map['pozisyonSayisi'] ?? 1,
      viewCount: map['viewCount'] ?? 0,
      applicationCount: map['applicationCount'] ?? 0,
      endedAt: map['endedAt'] ?? 0,
      authorAvatarUrl: map['authorAvatarUrl'] ?? map['avatarUrl'] ?? '',
      authorDisplayName: map['authorDisplayName'] ?? map['displayName'] ?? '',
      authorNickname: map['authorNickname'] ?? map['nickname'] ?? '',
      shortId: map['shortId'] ?? '',
      shortUrl: map['shortUrl'] ?? '',
      rozet: map['rozet'] ?? '',
    );
  }

  factory JobModel.fromTypesenseHit(Map<String, dynamic> hit) {
    int asInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0.0;
    }

    List<String> asStringList(dynamic value) {
      if (value is List) return value.map((e) => '$e').toList(growable: false);
      return const <String>[];
    }

    String firstNonEmpty(dynamic a, dynamic b, [dynamic c]) {
      final values = [a, b, c];
      for (final value in values) {
        final text = (value ?? '').toString().trim();
        if (text.isNotEmpty) return text;
      }
      return '';
    }

    return JobModel(
      docID: (hit['docId'] ?? hit['id'] ?? '').toString(),
      brand: (hit['brand'] ?? hit['subtitle'] ?? '').toString(),
      calismaGunleri: asStringList(hit['calismaGunleri']),
      calismaSaatiBaslangic: (hit['calismaSaatiBaslangic'] ?? '').toString(),
      calismaSaatiBitis: (hit['calismaSaatiBitis'] ?? '').toString(),
      calismaTuru: asStringList(hit['calismaTuru']),
      ended: hit['ended'] == true || hit['active'] == false,
      isTanimi: (hit['isTanimi'] ?? hit['description'] ?? '').toString(),
      lat: asDouble(hit['lat']),
      long: asDouble(hit['long']),
      adres: (hit['adres'] ?? '').toString(),
      logo: firstNonEmpty(hit['logo'], hit['cover']),
      maas1: asInt(hit['maas1']),
      maas2: asInt(hit['maas2']),
      meslek: (hit['meslek'] ?? hit['subtitle'] ?? '').toString(),
      timeStamp: asInt(hit['timeStamp']),
      userID: (hit['ownerId'] ?? '').toString(),
      yanHaklar: asStringList(hit['yanHaklar']),
      city: (hit['city'] ?? '').toString(),
      town: (hit['town'] ?? '').toString(),
      about: (hit['about'] ?? '').toString(),
      ilanBasligi: (hit['ilanBasligi'] ?? hit['title'] ?? '').toString(),
      deneyimSeviyesi: (hit['deneyimSeviyesi'] ?? '').toString(),
      basvuruSayisi: asInt(hit['basvuruSayisi']),
      pozisyonSayisi:
          asInt(hit['pozisyonSayisi']) == 0 ? 1 : asInt(hit['pozisyonSayisi']),
      viewCount: asInt(hit['viewCount']),
      applicationCount: asInt(hit['applicationCount']),
      endedAt: asInt(hit['endedAt']),
      authorAvatarUrl: firstNonEmpty(hit['avatarUrl'], hit['authorAvatarUrl']),
      authorDisplayName:
          firstNonEmpty(hit['displayName'], hit['authorDisplayName']),
      authorNickname: firstNonEmpty(hit['nickname'], hit['authorNickname']),
      shortId: (hit['shortId'] ?? '').toString(),
      shortUrl: (hit['shortUrl'] ?? '').toString(),
      rozet: (hit['rozet'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brand': brand,
      'calismaGunleri': _cloneStringList(calismaGunleri),
      'calismaSaatiBaslangic': calismaSaatiBaslangic,
      'calismaSaatiBitis': calismaSaatiBitis,
      'calismaTuru': _cloneStringList(calismaTuru),
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
      'yanHaklar': _cloneStringList(yanHaklar),
      'city': city,
      'town': town,
      'about': about,
      'ilanBasligi': ilanBasligi,
      'deneyimSeviyesi': deneyimSeviyesi,
      'basvuruSayisi': basvuruSayisi,
      'pozisyonSayisi': pozisyonSayisi,
      'viewCount': viewCount,
      'applicationCount': applicationCount,
      'endedAt': endedAt,
      'authorAvatarUrl': authorAvatarUrl,
      'authorDisplayName': authorDisplayName,
      'authorNickname': authorNickname,
      'shortId': shortId,
      'shortUrl': shortUrl,
      'rozet': rozet,
    };
  }

  JobModel copyWith({
    double? kacKm,
    String? about,
    String? ilanBasligi,
    String? deneyimSeviyesi,
    int? basvuruSayisi,
    String? calismaSaatiBaslangic,
    String? calismaSaatiBitis,
    int? pozisyonSayisi,
    int? viewCount,
    int? applicationCount,
    int? endedAt,
    String? authorAvatarUrl,
    String? authorDisplayName,
    String? authorNickname,
    String? shortId,
    String? shortUrl,
    String? rozet,
  }) {
    return JobModel(
      docID: docID,
      brand: brand,
      calismaGunleri: calismaGunleri,
      calismaSaatiBaslangic:
          calismaSaatiBaslangic ?? this.calismaSaatiBaslangic,
      calismaSaatiBitis: calismaSaatiBitis ?? this.calismaSaatiBitis,
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
      basvuruSayisi: basvuruSayisi ?? this.basvuruSayisi,
      pozisyonSayisi: pozisyonSayisi ?? this.pozisyonSayisi,
      viewCount: viewCount ?? this.viewCount,
      applicationCount: applicationCount ?? this.applicationCount,
      endedAt: endedAt ?? this.endedAt,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorNickname: authorNickname ?? this.authorNickname,
      shortId: shortId ?? this.shortId,
      shortUrl: shortUrl ?? this.shortUrl,
      rozet: rozet ?? this.rozet,
    );
  }
}
