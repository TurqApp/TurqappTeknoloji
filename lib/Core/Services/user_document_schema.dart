const String _defaultProfileImageUrl =
    'https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2';

Map<String, dynamic> buildInitialUserDocument({
  required String uid,
  required String firstName,
  required String lastName,
  required String nickname,
  required String email,
  required String phoneNumber,
  required String password,
}) {
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final createdDate = '$nowMs';
  final normalizedNickname = nickname.trim();
  final username = normalizedNickname.toLowerCase();
  final normalizedEmail = email.trim().toLowerCase();
  final normalizedPhone = phoneNumber.trim();
  final normalizedFirstName = firstName.trim();
  final normalizedLastName = lastName.trim();

  const antPoint = 100;
  const counterFollowers = 0;
  const counterFollowings = 0;
  const counterPosts = 0;
  const counterLikes = 0;
  const dailyDurations = 0;
  const viewSelection = 1;

  final education = <String, dynamic>{
    'bolum': '',
    'defAnaBaslik': 'YKS',
    'defDers': 'Türkçe',
    'defSinavTuru': 'TYT',
    'educationLevel': '',
    'fakulte': '',
    'lise': '',
    'ogrenciNo': '',
    'ogretimTipi': '',
    'okul': '',
    'okulIlce': '',
    'okulSehir': '',
    'ortaOkul': '',
    'ortalamaPuan': '',
    'ortalamaPuan1': '',
    'ortalamaPuan2': '',
    'osymPuanTuru': '',
    'osysPuan': '',
    'osysPuani1': '',
    'osysPuani2': '',
    'sinif': '',
    'universite': '',
    'yuzlukSistem': true,
  };

  final family = <String, dynamic>{
    'bursVerebilir': false,
    'engelliRaporu': '',
    'evMulkiyeti': '',
    'familyInfo': '',
    'fatherJob': '',
    'fatherLiving': '',
    'fatherName': '',
    'fatherPhone': '',
    'fatherSalary': '',
    'fatherSurname': '',
    'isDisabled': false,
    'motherJob': '',
    'motherLiving': '',
    'motherName': '',
    'motherPhone': '',
    'motherSalary': '',
    'motherSurname': '',
    'mulkiyet': '',
    'totalLiving': 0,
    'yurt': '',
  };

  return <String, dynamic>{
    'userID': uid,
    'displayName': normalizedNickname,
    'username': username,
    'nickname': normalizedNickname,
    'firstName': normalizedFirstName,
    'lastName': normalizedLastName,
    'email': normalizedEmail,
    'phoneNumber': normalizedPhone,
    'pfImage': _defaultProfileImageUrl,
    'avatarUrl': _defaultProfileImageUrl,
    'photoURL': _defaultProfileImageUrl,
    'profileImageUrl': _defaultProfileImageUrl,
    'fcmToken': '',
    'refCode': '',
    'signInMethod': 'Email',
    'createdDate': createdDate,
    'accountStatus': 'active',
    'emailVerified': false,
    'sifre': password,
    'adres': '',
    'antPoint': antPoint,
    'aramaIzin': false,
    'ban': false,
    'bank': '',
    'bildirim': false,
    'bio': '',
    'blockedUsers': <String>[],
    'bot': false,
    'calismaDurumu': '',
    'canliYayin': '',
    'cinsiyet': '',
    'city': '',
    'counterOfFollowers': counterFollowers,
    'counterOfFollowings': counterFollowings,
    'counterOfLikes': counterLikes,
    'counterOfPosts': counterPosts,
    'dailyDurations': dailyDurations,
    'deletedAccount': false,
    'device': '',
    'deviceID': '',
    'deviceVersion': '',
    'dogumTarihi': '',
    'favoriMuzikler': <String>[],
    'gizliHesap': false,
    'hesapOnayi': false,
    'iban': '',
    'ikametIlce': '',
    'ikametSehir': '',
    'il': '',
    'ilce': '',
    'ilgialanlari': <String>[],
    'kolayAdresSelection': '',
    'lastSearchList': <String>[],
    'locationSehir': '',
    'mail': '',
    'mailIzin': false,
    'medeniHal': '',
    'meslekKategori': '',
    'nufusIlce': '',
    'nufusSehir': '',
    'nufusaKayitliOlduguYer': '',
    'readStories': <String>[],
    'readStoriesTimes': <String, int>{},
    'rehber': false,
    'rozet': '',
    'settings': '',
    'tc': '',
    'themeSettings': '',
    'token': '',
    'town': '',
    'ulke': '',
    'viewSelection': viewSelection,
    'whatsappIzin': false,
    // Structured maps (cold/optional domains only)
    'family': family,
    'education': education,
  };
}
