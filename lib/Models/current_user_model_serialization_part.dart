part of 'current_user_model.dart';

List<String> _cloneCurrentUserStringList(Iterable<dynamic> source) {
  return source
      .map((item) => item.toString())
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

Map<String, int> _cloneCurrentUserStringIntMap(Map source) {
  return source.map(
    (key, value) => MapEntry(
      key.toString(),
      value is int ? value : int.tryParse(value.toString()) ?? 0,
    ),
  );
}

CurrentUserModel _currentUserModelFromFirestore(DocumentSnapshot doc) {
  final data = doc.data() as Map<String, dynamic>? ?? {};
  final education = _asMap(data['education']);
  final family = _asMap(data['family']);
  final profile = _asMap(data['profile']);

  return CurrentUserModel(
    userID: doc.id,
    nickname: (data['nickname'] ??
            data['nickName'] ??
            data['username'] ??
            data['userName'] ??
            data['displayName'] ??
            '')
        .toString(),
    firstName: data['firstName'] ?? '',
    lastName: data['lastName'] ?? '',
    avatarUrl: resolveAvatarUrl(data, profile: profile),
    email: data['email'] ?? '',
    phoneNumber: data['phoneNumber'] ?? '',
    tc: data['tc'] ?? '',
    dogumTarihi: data['dogumTarihi'] ?? '',
    cinsiyet: data['cinsiyet'] ?? '',
    bio: data['bio'] ?? '',
    rozet: (data['rozet'] ?? data['badge'] ?? '').toString(),
    hesapOnayi: (data['isApproved'] ?? false) == true,
    gizliHesap: (data['isPrivate'] ?? false) == true,
    viewSelection: data['viewSelection'] ?? 1,
    ilgialanlari: _cloneCurrentUserStringList(
      data['ilgialanlari'] ?? const [],
    ),
    favoriMuzikler: _cloneCurrentUserStringList(
      data['favoriMuzikler'] ?? const [],
    ),
    meslekKategori: data['meslekKategori'] ?? '',
    calismaDurumu: data['calismaDurumu'] ?? '',
    medeniHal: data['medeniHal'] ?? '',
    counterOfFollowers: _parseToInt(
      data['followerCount'] ??
          data['counterOfFollowers'] ??
          data['takipciSayisi'],
    ),
    counterOfFollowings: _parseToInt(
      data['followingCount'] ??
          data['counterOfFollowings'] ??
          data['takipEdilenSayisi'],
    ),
    counterOfPosts: _parseToInt(
      data['postCount'] ?? data['counterOfPosts'] ?? data['gonderSayisi'],
    ),
    counterOfLikes: data['counterOfLikes'] ?? 0,
    antPoint: data['antPoint'] ?? 100,
    dailyDurations: data['dailyDurations'] ?? 1,
    educationLevel:
        _pickScopedString(data, education, 'educationLevel', fallback: ''),
    universite: _pickScopedString(data, education, 'universite', fallback: ''),
    fakulte: _pickScopedString(data, education, 'fakulte', fallback: ''),
    bolum: _pickScopedString(data, education, 'bolum', fallback: ''),
    ogrenciNo: _pickScopedString(data, education, 'ogrenciNo', fallback: ''),
    ogretimTipi:
        _pickScopedString(data, education, 'ogretimTipi', fallback: ''),
    sinif: _pickScopedString(data, education, 'sinif', fallback: ''),
    lise: _pickScopedString(data, education, 'lise', fallback: ''),
    ortaOkul: _pickScopedString(data, education, 'ortaOkul', fallback: ''),
    okul: _pickScopedString(data, education, 'okul', fallback: ''),
    okulSehir: _pickScopedString(data, education, 'okulSehir', fallback: ''),
    okulIlce: _pickScopedString(data, education, 'okulIlce', fallback: ''),
    ortalamaPuan:
        _pickScopedString(data, education, 'ortalamaPuan', fallback: ''),
    ortalamaPuan1:
        _pickScopedString(data, education, 'ortalamaPuan1', fallback: ''),
    ortalamaPuan2:
        _pickScopedString(data, education, 'ortalamaPuan2', fallback: ''),
    defAnaBaslik:
        _pickScopedString(data, education, 'defAnaBaslik', fallback: ''),
    defDers: _pickScopedString(data, education, 'defDers', fallback: ''),
    defSinavTuru:
        _pickScopedString(data, education, 'defSinavTuru', fallback: ''),
    osymPuanTuru:
        _pickScopedString(data, education, 'osymPuanTuru', fallback: ''),
    osysPuan: _pickScopedString(data, education, 'osysPuan', fallback: ''),
    osysPuani1: _pickScopedString(data, education, 'osysPuani1', fallback: ''),
    osysPuani2: _pickScopedString(data, education, 'osysPuani2', fallback: ''),
    yuzlukSistem:
        _pickScopedBool(data, education, 'yuzlukSistem', fallback: true),
    adres: data['adres'] ?? '',
    ulke: data['ulke'] ?? '',
    city: data['city'] ?? '',
    town: data['town'] ?? '',
    il: data['il'] ?? '',
    ilce: data['ilce'] ?? '',
    ikametSehir: data['ikametSehir'] ?? '',
    ikametIlce: data['ikametIlce'] ?? '',
    nufusSehir: data['nufusSehir'] ?? '',
    nufusIlce: data['nufusIlce'] ?? '',
    nufusaKayitliOlduguYer: data['nufusaKayitliOlduguYer'] ?? '',
    locationSehir: data['locationSehir'] ?? '',
    kolayAdresSelection: data['kolayAdresSelection'] ?? '',
    familyInfo: _pickScopedString(data, family, 'familyInfo', fallback: ''),
    totalLiving: _pickScopedInt(data, family, 'totalLiving', fallback: 0),
    motherName: _pickScopedString(data, family, 'motherName', fallback: ''),
    motherSurname:
        _pickScopedString(data, family, 'motherSurname', fallback: ''),
    motherPhone: _pickScopedString(data, family, 'motherPhone', fallback: ''),
    motherJob: _pickScopedString(data, family, 'motherJob', fallback: ''),
    motherSalary: _pickScopedString(data, family, 'motherSalary', fallback: ''),
    motherLiving: _pickScopedString(data, family, 'motherLiving', fallback: ''),
    fatherName: _pickScopedString(data, family, 'fatherName', fallback: ''),
    fatherSurname:
        _pickScopedString(data, family, 'fatherSurname', fallback: ''),
    fatherPhone: _pickScopedString(data, family, 'fatherPhone', fallback: ''),
    fatherJob: _pickScopedString(data, family, 'fatherJob', fallback: ''),
    fatherSalary: _pickScopedString(data, family, 'fatherSalary', fallback: ''),
    fatherLiving: _pickScopedString(data, family, 'fatherLiving', fallback: ''),
    evMulkiyeti: _pickScopedString(data, family, 'evMulkiyeti', fallback: ''),
    mulkiyet: _pickScopedString(data, family, 'mulkiyet', fallback: ''),
    yurt: _pickScopedString(data, family, 'yurt', fallback: ''),
    bursVerebilir:
        _pickScopedBool(data, family, 'bursVerebilir', fallback: false),
    engelliRaporu:
        _pickScopedString(data, family, 'engelliRaporu', fallback: ''),
    isDisabled: _pickScopedBool(data, family, 'isDisabled', fallback: false),
    bank: data['bank'] ?? '',
    iban: data['iban'] ?? '',
    ban: (data['isBanned'] ?? false) == true,
    moderationStrikeCount: _parseToInt(data['moderationStrikeCount']),
    moderationLevel: _parseToInt(data['moderationLevel']),
    moderationRestrictedUntil: _parseToInt(data['moderationRestrictedUntil']),
    moderationPermanentBan: (data['moderationPermanentBan'] ?? false) == true,
    moderationBanReason: (data['moderationBanReason'] ?? '').toString(),
    moderationUpdatedAt: _parseToInt(data['moderationUpdatedAt']),
    deletedAccount: (data['isDeleted'] ?? false) == true,
    bot: (data['isBot'] ?? false) == true,
    signInMethod: data['signInMethod'] ?? '',
    sifre: '',
    refCode: data['refCode'] ?? '',
    blockedUsers: _cloneCurrentUserStringList(
      data['blockedUsers'] ?? const [],
    ),
    device: data['device'] ?? '',
    deviceID: data['deviceID'] ?? '',
    deviceVersion: data['deviceVersion'] ?? '',
    token: data['token'] ?? '',
    createdDate: _createdDateFromAny(data['createdDate']),
    bildirim: data['bildirim'] ?? false,
    aramaIzin: data['aramaIzin'] ?? false,
    mailIzin: data['mailIzin'] ?? false,
    whatsappIzin: data['whatsappIzin'] ?? false,
    rehber: data['rehber'] ?? false,
    settings: data['settings'] ?? '',
    themeSettings: data['themeSettings'] ?? '',
    canliYayin: data['canliYayin'] ?? '',
    lastSearchList: _cloneCurrentUserStringList(
      data['lastSearchList'] ?? const [],
    ),
    readStories: _cloneCurrentUserStringList(data['readStories'] ?? const []),
    readStoriesTimes: _parseReadStoriesTimes(data['readStoriesTimes']),
    mail: data['mail'] ?? '',
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 💾 To JSON (for SharedPreferences cache)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Map<String, dynamic> _currentUserModelToJson(CurrentUserModel user) {
  return {
    'userID': user.userID,
    'nickname': user.nickname,
    'displayName': user.nickname,
    'firstName': user.firstName,
    'lastName': user.lastName,
    'avatarUrl': user.avatarUrl,
    'email': user.email,
    'phoneNumber': user.phoneNumber,
    'tc': user.tc,
    'dogumTarihi': user.dogumTarihi,
    'cinsiyet': user.cinsiyet,
    'bio': user.bio,
    'rozet': user.rozet,
    'isApproved': user.hesapOnayi,
    'isPrivate': user.gizliHesap,
    'viewSelection': user.viewSelection,
    'ilgialanlari': _cloneCurrentUserStringList(user.ilgialanlari),
    'favoriMuzikler': _cloneCurrentUserStringList(user.favoriMuzikler),
    'meslekKategori': user.meslekKategori,
    'calismaDurumu': user.calismaDurumu,
    'medeniHal': user.medeniHal,
    'counterOfFollowers': user.counterOfFollowers,
    'counterOfFollowings': user.counterOfFollowings,
    'counterOfPosts': user.counterOfPosts,
    'followerCount': user.counterOfFollowers,
    'followingCount': user.counterOfFollowings,
    'postCount': user.counterOfPosts,
    'counterOfLikes': user.counterOfLikes,
    'antPoint': user.antPoint,
    'dailyDurations': user.dailyDurations,
    'educationLevel': user.educationLevel,
    'universite': user.universite,
    'fakulte': user.fakulte,
    'bolum': user.bolum,
    'ogrenciNo': user.ogrenciNo,
    'ogretimTipi': user.ogretimTipi,
    'sinif': user.sinif,
    'lise': user.lise,
    'ortaOkul': user.ortaOkul,
    'okul': user.okul,
    'okulSehir': user.okulSehir,
    'okulIlce': user.okulIlce,
    'ortalamaPuan': user.ortalamaPuan,
    'ortalamaPuan1': user.ortalamaPuan1,
    'ortalamaPuan2': user.ortalamaPuan2,
    'defAnaBaslik': user.defAnaBaslik,
    'defDers': user.defDers,
    'defSinavTuru': user.defSinavTuru,
    'osymPuanTuru': user.osymPuanTuru,
    'osysPuan': user.osysPuan,
    'osysPuani1': user.osysPuani1,
    'osysPuani2': user.osysPuani2,
    'yuzlukSistem': user.yuzlukSistem,
    'adres': user.adres,
    'ulke': user.ulke,
    'city': user.city,
    'town': user.town,
    'il': user.il,
    'ilce': user.ilce,
    'ikametSehir': user.ikametSehir,
    'ikametIlce': user.ikametIlce,
    'nufusSehir': user.nufusSehir,
    'nufusIlce': user.nufusIlce,
    'nufusaKayitliOlduguYer': user.nufusaKayitliOlduguYer,
    'locationSehir': user.locationSehir,
    'kolayAdresSelection': user.kolayAdresSelection,
    'familyInfo': user.familyInfo,
    'totalLiving': user.totalLiving,
    'motherName': user.motherName,
    'motherSurname': user.motherSurname,
    'motherPhone': user.motherPhone,
    'motherJob': user.motherJob,
    'motherSalary': user.motherSalary,
    'motherLiving': user.motherLiving,
    'fatherName': user.fatherName,
    'fatherSurname': user.fatherSurname,
    'fatherPhone': user.fatherPhone,
    'fatherJob': user.fatherJob,
    'fatherSalary': user.fatherSalary,
    'fatherLiving': user.fatherLiving,
    'evMulkiyeti': user.evMulkiyeti,
    'mulkiyet': user.mulkiyet,
    'yurt': user.yurt,
    'bursVerebilir': user.bursVerebilir,
    'engelliRaporu': user.engelliRaporu,
    'isDisabled': user.isDisabled,
    'bank': user.bank,
    'iban': user.iban,
    'isBanned': user.ban,
    'moderationStrikeCount': user.moderationStrikeCount,
    'moderationLevel': user.moderationLevel,
    'moderationRestrictedUntil': user.moderationRestrictedUntil,
    'moderationPermanentBan': user.moderationPermanentBan,
    'moderationBanReason': user.moderationBanReason,
    'moderationUpdatedAt': user.moderationUpdatedAt,
    'isDeleted': user.deletedAccount,
    'isBot': user.bot,
    'signInMethod': user.signInMethod,
    'refCode': user.refCode,
    'blockedUsers': _cloneCurrentUserStringList(user.blockedUsers),
    'device': user.device,
    'deviceID': user.deviceID,
    'deviceVersion': user.deviceVersion,
    'token': user.token,
    'createdDate': user.createdDate,
    'bildirim': user.bildirim,
    'aramaIzin': user.aramaIzin,
    'mailIzin': user.mailIzin,
    'whatsappIzin': user.whatsappIzin,
    'rehber': user.rehber,
    'settings': user.settings,
    'themeSettings': user.themeSettings,
    'canliYayin': user.canliYayin,
    'lastSearchList': _cloneCurrentUserStringList(user.lastSearchList),
    'readStories': _cloneCurrentUserStringList(user.readStories),
    'readStoriesTimes': _cloneCurrentUserStringIntMap(user.readStoriesTimes),
    'mail': user.mail,
  };
}

/// Redacted cache payload for local device storage.
///
/// Keep UX-critical profile fields, but avoid persisting device and push
/// metadata that can be re-hydrated from Firebase/Auth on demand.
Map<String, dynamic> _currentUserModelToCacheJson(CurrentUserModel user) {
  final json = _currentUserModelToJson(user);
  json.remove('device');
  json.remove('deviceID');
  json.remove('deviceVersion');
  json.remove('token');
  return json;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📥 From JSON (for SharedPreferences cache)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
CurrentUserModel _currentUserModelFromJson(Map<String, dynamic> json) {
  final education = _asMap(json['education']);
  final family = _asMap(json['family']);
  final profile = _asMap(json['profile']);

  return CurrentUserModel(
    userID: json['userID'] ?? '',
    nickname: (json['nickname'] ??
            json['nickName'] ??
            json['username'] ??
            json['userName'] ??
            json['displayName'] ??
            '')
        .toString(),
    firstName: json['firstName'] ?? '',
    lastName: json['lastName'] ?? '',
    avatarUrl: resolveAvatarUrl(json, profile: profile),
    email: json['email'] ?? '',
    phoneNumber: json['phoneNumber'] ?? '',
    tc: json['tc'] ?? '',
    dogumTarihi: json['dogumTarihi'] ?? '',
    cinsiyet: json['cinsiyet'] ?? '',
    bio: json['bio'] ?? '',
    rozet: (json['rozet'] ?? json['badge'] ?? '').toString(),
    hesapOnayi: (json['isApproved'] ?? false) == true,
    gizliHesap: (json['isPrivate'] ?? false) == true,
    viewSelection: json['viewSelection'] ?? 1,
    ilgialanlari: _cloneCurrentUserStringList(
      json['ilgialanlari'] ?? const [],
    ),
    favoriMuzikler: _cloneCurrentUserStringList(
      json['favoriMuzikler'] ?? const [],
    ),
    meslekKategori: json['meslekKategori'] ?? '',
    calismaDurumu: json['calismaDurumu'] ?? '',
    medeniHal: json['medeniHal'] ?? '',
    counterOfFollowers: _parseToInt(
      json['followerCount'] ??
          json['counterOfFollowers'] ??
          json['takipciSayisi'],
    ),
    counterOfFollowings: _parseToInt(
      json['followingCount'] ??
          json['counterOfFollowings'] ??
          json['takipEdilenSayisi'],
    ),
    counterOfPosts: _parseToInt(
      json['postCount'] ?? json['counterOfPosts'] ?? json['gonderSayisi'],
    ),
    counterOfLikes: json['counterOfLikes'] ?? 0,
    antPoint: json['antPoint'] ?? 100,
    dailyDurations: json['dailyDurations'] ?? 1,
    educationLevel:
        _pickScopedString(json, education, 'educationLevel', fallback: ''),
    universite: _pickScopedString(json, education, 'universite', fallback: ''),
    fakulte: _pickScopedString(json, education, 'fakulte', fallback: ''),
    bolum: _pickScopedString(json, education, 'bolum', fallback: ''),
    ogrenciNo: _pickScopedString(json, education, 'ogrenciNo', fallback: ''),
    ogretimTipi:
        _pickScopedString(json, education, 'ogretimTipi', fallback: ''),
    sinif: _pickScopedString(json, education, 'sinif', fallback: ''),
    lise: _pickScopedString(json, education, 'lise', fallback: ''),
    ortaOkul: _pickScopedString(json, education, 'ortaOkul', fallback: ''),
    okul: _pickScopedString(json, education, 'okul', fallback: ''),
    okulSehir: _pickScopedString(json, education, 'okulSehir', fallback: ''),
    okulIlce: _pickScopedString(json, education, 'okulIlce', fallback: ''),
    ortalamaPuan:
        _pickScopedString(json, education, 'ortalamaPuan', fallback: ''),
    ortalamaPuan1:
        _pickScopedString(json, education, 'ortalamaPuan1', fallback: ''),
    ortalamaPuan2:
        _pickScopedString(json, education, 'ortalamaPuan2', fallback: ''),
    defAnaBaslik:
        _pickScopedString(json, education, 'defAnaBaslik', fallback: ''),
    defDers: _pickScopedString(json, education, 'defDers', fallback: ''),
    defSinavTuru:
        _pickScopedString(json, education, 'defSinavTuru', fallback: ''),
    osymPuanTuru:
        _pickScopedString(json, education, 'osymPuanTuru', fallback: ''),
    osysPuan: _pickScopedString(json, education, 'osysPuan', fallback: ''),
    osysPuani1: _pickScopedString(json, education, 'osysPuani1', fallback: ''),
    osysPuani2: _pickScopedString(json, education, 'osysPuani2', fallback: ''),
    yuzlukSistem:
        _pickScopedBool(json, education, 'yuzlukSistem', fallback: true),
    adres: json['adres'] ?? '',
    ulke: json['ulke'] ?? '',
    city: json['city'] ?? '',
    town: json['town'] ?? '',
    il: json['il'] ?? '',
    ilce: json['ilce'] ?? '',
    ikametSehir: json['ikametSehir'] ?? '',
    ikametIlce: json['ikametIlce'] ?? '',
    nufusSehir: json['nufusSehir'] ?? '',
    nufusIlce: json['nufusIlce'] ?? '',
    nufusaKayitliOlduguYer: json['nufusaKayitliOlduguYer'] ?? '',
    locationSehir: json['locationSehir'] ?? '',
    kolayAdresSelection: json['kolayAdresSelection'] ?? '',
    familyInfo: _pickScopedString(json, family, 'familyInfo', fallback: ''),
    totalLiving: _pickScopedInt(json, family, 'totalLiving', fallback: 0),
    motherName: _pickScopedString(json, family, 'motherName', fallback: ''),
    motherSurname:
        _pickScopedString(json, family, 'motherSurname', fallback: ''),
    motherPhone: _pickScopedString(json, family, 'motherPhone', fallback: ''),
    motherJob: _pickScopedString(json, family, 'motherJob', fallback: ''),
    motherSalary: _pickScopedString(json, family, 'motherSalary', fallback: ''),
    motherLiving: _pickScopedString(json, family, 'motherLiving', fallback: ''),
    fatherName: _pickScopedString(json, family, 'fatherName', fallback: ''),
    fatherSurname:
        _pickScopedString(json, family, 'fatherSurname', fallback: ''),
    fatherPhone: _pickScopedString(json, family, 'fatherPhone', fallback: ''),
    fatherJob: _pickScopedString(json, family, 'fatherJob', fallback: ''),
    fatherSalary: _pickScopedString(json, family, 'fatherSalary', fallback: ''),
    fatherLiving: _pickScopedString(json, family, 'fatherLiving', fallback: ''),
    evMulkiyeti: _pickScopedString(json, family, 'evMulkiyeti', fallback: ''),
    mulkiyet: _pickScopedString(json, family, 'mulkiyet', fallback: ''),
    yurt: _pickScopedString(json, family, 'yurt', fallback: ''),
    bursVerebilir:
        _pickScopedBool(json, family, 'bursVerebilir', fallback: false),
    engelliRaporu:
        _pickScopedString(json, family, 'engelliRaporu', fallback: ''),
    isDisabled: _pickScopedBool(json, family, 'isDisabled', fallback: false),
    bank: json['bank'] ?? '',
    iban: json['iban'] ?? '',
    ban: (json['isBanned'] ?? false) == true,
    moderationStrikeCount: _parseToInt(json['moderationStrikeCount']),
    moderationLevel: _parseToInt(json['moderationLevel']),
    moderationRestrictedUntil: _parseToInt(json['moderationRestrictedUntil']),
    moderationPermanentBan: (json['moderationPermanentBan'] ?? false) == true,
    moderationBanReason: (json['moderationBanReason'] ?? '').toString(),
    moderationUpdatedAt: _parseToInt(json['moderationUpdatedAt']),
    deletedAccount: (json['isDeleted'] ?? false) == true,
    bot: (json['isBot'] ?? false) == true,
    signInMethod: json['signInMethod'] ?? '',
    sifre: '',
    refCode: json['refCode'] ?? '',
    blockedUsers: _cloneCurrentUserStringList(
      json['blockedUsers'] ?? const [],
    ),
    device: json['device'] ?? '',
    deviceID: json['deviceID'] ?? '',
    deviceVersion: json['deviceVersion'] ?? '',
    token: json['token'] ?? '',
    createdDate: _createdDateFromAny(json['createdDate']),
    bildirim: json['bildirim'] ?? false,
    aramaIzin: json['aramaIzin'] ?? false,
    mailIzin: json['mailIzin'] ?? false,
    whatsappIzin: json['whatsappIzin'] ?? false,
    rehber: json['rehber'] ?? false,
    settings: json['settings'] ?? '',
    themeSettings: json['themeSettings'] ?? '',
    canliYayin: json['canliYayin'] ?? '',
    lastSearchList: _cloneCurrentUserStringList(
      json['lastSearchList'] ?? const [],
    ),
    readStories: _cloneCurrentUserStringList(json['readStories'] ?? const []),
    readStoriesTimes: _parseReadStoriesTimes(json['readStoriesTimes']),
    mail: json['mail'] ?? '',
  );
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔧 Helper: Parse readStoriesTimes safely
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Map<String, int> _parseReadStoriesTimes(dynamic data) {
  if (data == null) return {};
  if (data is Map<String, int>) return _cloneCurrentUserStringIntMap(data);
  if (data is Map) {
    return _cloneCurrentUserStringIntMap(data);
  }
  return {};
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

dynamic _pickScoped(
  Map<String, dynamic> root,
  Map<String, dynamic> scoped,
  String key,
) {
  if (scoped.containsKey(key)) return scoped[key];
  return root[key];
}

String _pickScopedString(
  Map<String, dynamic> root,
  Map<String, dynamic> scoped,
  String key, {
  String fallback = '',
}) {
  final value = _pickScoped(root, scoped, key);
  return value?.toString() ?? fallback;
}

int _pickScopedInt(
  Map<String, dynamic> root,
  Map<String, dynamic> scoped,
  String key, {
  int fallback = 0,
}) {
  final value = _pickScoped(root, scoped, key);
  if (value == null) return fallback;
  return _parseToInt(value);
}

bool _pickScopedBool(
  Map<String, dynamic> root,
  Map<String, dynamic> scoped,
  String key, {
  bool fallback = false,
}) {
  final value = _pickScoped(root, scoped, key);
  return parseFlexibleBool(value, fallback: fallback);
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🛠️ Helper Methods for Type-Safe Parsing
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
int _parseToInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    if (value.isEmpty) return 0;
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String _createdDateFromAny(dynamic value) {
  if (value == null) return '';
  if (value is Timestamp) {
    return value.millisecondsSinceEpoch.toString();
  }
  if (value is DateTime) {
    return value.millisecondsSinceEpoch.toString();
  }
  if (value is int) {
    return value.toString();
  }
  if (value is num) {
    return value.toInt().toString();
  }
  return value.toString();
}
