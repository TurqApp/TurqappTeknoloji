class TutoringModel {
  final String docID;
  final String aciklama;
  final String baslik;
  final String brans;
  final String cinsiyet;
  final List<String> dersYeri;
  final num end;
  final List<String> favorites;
  final num fiyat;
  final List<String>? imgs;
  final String ilce;
  final bool onayVerildi;
  final String sehir;
  final bool telefon;
  final num timeStamp;
  final String userID;
  final bool whatsapp;
  final bool? ended;
  final num? endedAt;
  final num? viewCount;
  final num? applicationCount;
  final num? averageRating;
  final num? reviewCount;
  final Map<String, List<String>>? availability;
  final double? lat;
  final double? long;
  final bool? verified;
  final List<String>? verificationDocs;
  final String avatarUrl;
  final String displayName;
  final String nickname;
  final String shortId;
  final String shortUrl;
  final String rozet;

  static List<String> _cloneStringList(List<String> source) =>
      List<String>.from(source, growable: false);

  static List<String>? _cloneNullableStringList(List<String>? source) {
    if (source == null) return null;
    return _cloneStringList(source);
  }

  static Map<String, List<String>>? _cloneAvailability(
    Map<String, List<String>>? source,
  ) {
    if (source == null) return null;
    return source.map(
      (key, value) => MapEntry(key, _cloneStringList(value)),
    );
  }

  TutoringModel({
    required this.docID,
    required this.aciklama,
    required this.baslik,
    required this.brans,
    required this.cinsiyet,
    required List<String> dersYeri,
    required this.end,
    required List<String> favorites,
    required this.fiyat,
    required List<String>? imgs,
    required this.ilce,
    required this.onayVerildi,
    required this.sehir,
    required this.telefon,
    required this.timeStamp,
    required this.userID,
    required this.whatsapp,
    this.ended,
    this.endedAt,
    this.viewCount,
    this.applicationCount,
    this.averageRating,
    this.reviewCount,
    Map<String, List<String>>? availability,
    this.lat,
    this.long,
    this.verified,
    List<String>? verificationDocs,
    this.avatarUrl = '',
    this.displayName = '',
    this.nickname = '',
    this.shortId = '',
    this.shortUrl = '',
    this.rozet = '',
  }) : dersYeri = _cloneStringList(dersYeri),
       favorites = _cloneStringList(favorites),
       imgs = _cloneNullableStringList(imgs),
       availability = _cloneAvailability(availability),
       verificationDocs = _cloneNullableStringList(verificationDocs);

  factory TutoringModel.fromJson(Map<String, dynamic> json, String documentId) {
    Map<String, List<String>>? parsedAvailability;
    if (json['availability'] is Map) {
      parsedAvailability = (json['availability'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>?)?.cast<String>() ?? [],
        ),
      );
    }

    return TutoringModel(
      docID: documentId,
      aciklama: json['aciklama'] as String? ?? '',
      baslik: json['baslik'] as String? ?? '',
      brans: json['brans'] as String? ?? '',
      cinsiyet: json['cinsiyet'] as String? ?? '',
      dersYeri: (json['dersYeri'] as List<dynamic>?)?.cast<String>() ?? [],
      end: json['end'] as num? ?? 0,
      favorites: (json['favorites'] as List<dynamic>?)?.cast<String>() ?? [],
      fiyat: json['fiyat'] as num? ?? 0,
      imgs: (json['imgs'] as List<dynamic>?)?.cast<String>(),
      ilce: json['ilce'] as String? ?? '',
      onayVerildi: json['onayVerildi'] as bool? ?? false,
      sehir: json['sehir'] as String? ?? '',
      telefon: json['telefon'] as bool? ?? false,
      timeStamp: json['timeStamp'] as num? ?? 0,
      userID: json['userID'] as String? ?? '',
      whatsapp: json['whatsapp'] as bool? ?? false,
      ended: json['ended'] as bool?,
      endedAt: json['endedAt'] as num?,
      viewCount: json['viewCount'] as num?,
      applicationCount: json['applicationCount'] as num?,
      averageRating: json['averageRating'] as num?,
      reviewCount: json['reviewCount'] as num?,
      availability: parsedAvailability,
      lat: (json['lat'] as num?)?.toDouble(),
      long: (json['long'] as num?)?.toDouble(),
      verified: json['verified'] as bool?,
      verificationDocs:
          (json['verificationDocs'] as List<dynamic>?)?.cast<String>(),
      avatarUrl: json['avatarUrl'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      shortId: json['shortId'] as String? ?? '',
      shortUrl: json['shortUrl'] as String? ?? '',
      rozet: json['rozet'] as String? ?? '',
    );
  }

  factory TutoringModel.fromTypesenseHit(Map<String, dynamic> hit) {
    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value
            .map((e) => '$e')
            .where((e) => e.trim().isNotEmpty)
            .toList();
      }
      return const <String>[];
    }

    num asNum(dynamic value) {
      if (value is num) return value;
      return num.tryParse('$value') ?? 0;
    }

    double? asDoubleOrNull(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse('$value');
    }

    String pick(dynamic primary, dynamic fallback) {
      final first = (primary ?? '').toString().trim();
      if (first.isNotEmpty) return first;
      return (fallback ?? '').toString().trim();
    }

    return TutoringModel(
      docID: (hit['docId'] ?? hit['id'] ?? '').toString(),
      aciklama: (hit['aciklama'] ?? hit['description'] ?? '').toString(),
      baslik: (hit['title'] ?? '').toString(),
      brans: (hit['subtitle'] ?? hit['brans'] ?? '').toString(),
      cinsiyet: (hit['cinsiyet'] ?? '').toString(),
      dersYeri: asStringList(hit['dersYeri']),
      end: 0,
      favorites: const <String>[],
      fiyat: asNum(hit['fiyat']),
      imgs: pick(hit['cover'], hit['img']).isNotEmpty
          ? <String>[pick(hit['cover'], hit['img'])]
          : null,
      ilce: (hit['town'] ?? '').toString(),
      onayVerildi: hit['active'] == true,
      sehir: (hit['city'] ?? '').toString(),
      telefon: hit['telefon'] == true,
      timeStamp: asNum(hit['timeStamp']),
      userID: (hit['ownerId'] ?? '').toString(),
      whatsapp: hit['whatsapp'] == true,
      ended: hit['ended'] == true || hit['active'] == false,
      endedAt: asNum(hit['endedAt']),
      viewCount: asNum(hit['viewCount']),
      applicationCount: asNum(hit['applicationCount']),
      averageRating: asNum(hit['averageRating']),
      reviewCount: asNum(hit['reviewCount']),
      lat: asDoubleOrNull(hit['lat']),
      long: asDoubleOrNull(hit['long']),
      avatarUrl: (hit['avatarUrl'] ?? '').toString(),
      displayName: (hit['displayName'] ?? '').toString(),
      nickname: (hit['nickname'] ?? '').toString(),
      shortId: (hit['shortId'] ?? '').toString(),
      shortUrl: (hit['shortUrl'] ?? '').toString(),
      rozet: (hit['rozet'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aciklama': aciklama,
      'baslik': baslik,
      'brans': brans,
      'cinsiyet': cinsiyet,
      'dersYeri': _cloneStringList(dersYeri),
      'end': end,
      if (favorites.isNotEmpty) 'favorites': _cloneStringList(favorites),
      'fiyat': fiyat,
      'imgs': _cloneNullableStringList(imgs),
      'ilce': ilce,
      'onayVerildi': onayVerildi,
      'sehir': sehir,
      'telefon': telefon,
      'timeStamp': timeStamp,
      'userID': userID,
      'whatsapp': whatsapp,
      if (ended != null) 'ended': ended,
      if (endedAt != null) 'endedAt': endedAt,
      if (viewCount != null) 'viewCount': viewCount,
      if (applicationCount != null) 'applicationCount': applicationCount,
      if (averageRating != null) 'averageRating': averageRating,
      if (reviewCount != null) 'reviewCount': reviewCount,
      if (availability != null) 'availability': _cloneAvailability(availability),
      if (lat != null) 'lat': lat,
      if (long != null) 'long': long,
      if (verified != null) 'verified': verified,
      if (verificationDocs != null)
        'verificationDocs': _cloneNullableStringList(verificationDocs),
      if (avatarUrl.isNotEmpty) 'avatarUrl': avatarUrl,
      if (displayName.isNotEmpty) 'displayName': displayName,
      if (nickname.isNotEmpty) 'nickname': nickname,
      if (shortId.isNotEmpty) 'shortId': shortId,
      if (shortUrl.isNotEmpty) 'shortUrl': shortUrl,
      if (rozet.isNotEmpty) 'rozet': rozet,
    };
  }
}
