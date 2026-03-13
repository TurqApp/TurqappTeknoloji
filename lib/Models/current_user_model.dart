// 📁 lib/Models/CurrentUserModel.dart
// 🎯 Enterprise-grade current user model with comprehensive fields
// 💾 Supports both Firebase sync and local cache serialization

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

class CurrentUserModel {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔑 Core Identity Fields
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String userID;
  final String nickname;
  final String firstName;
  final String lastName;
  final String avatarUrl;
  final String email;
  final String phoneNumber;
  final String tc;
  final String dogumTarihi;
  final String cinsiyet;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 👤 Profile & Social Fields
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String bio;
  final String rozet;
  final bool hesapOnayi;
  final bool gizliHesap;
  final int viewSelection; // 0: Klasik, 1: Modern
  final List<String> ilgialanlari;
  final List<String> favoriMuzikler;
  final String meslekKategori;
  final String calismaDurumu;
  final String medeniHal;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📊 Statistics & Counters
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final int counterOfFollowers;
  final int counterOfFollowings;
  final int counterOfPosts;
  final int counterOfLikes;
  final int antPoint;
  final int dailyDurations;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎓 Education Fields
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String educationLevel; // Önlisans, Lisans, Yüksek Lisans, etc.
  final String universite;
  final String fakulte;
  final String bolum;
  final String ogrenciNo;
  final String ogretimTipi;
  final String sinif;
  final String lise;
  final String ortaOkul;
  final String okul;
  final String okulSehir;
  final String okulIlce;
  final String ortalamaPuan;
  final String ortalamaPuan1;
  final String ortalamaPuan2;

  // Exam & Test Preferences
  final String defAnaBaslik; // LGS, YKS, etc.
  final String defDers;
  final String defSinavTuru;
  final String osymPuanTuru;
  final String osysPuan;
  final String osysPuani1;
  final String osysPuani2;
  final bool yuzlukSistem;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📍 Location & Address Fields
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String adres;
  final String ulke;
  final String city;
  final String town;
  final String il;
  final String ilce;

  // Residence Address
  final String ikametSehir;
  final String ikametIlce;

  // Registration Address
  final String nufusSehir;
  final String nufusIlce;
  final String nufusaKayitliOlduguYer;

  // Location Preference
  final String locationSehir;
  final String kolayAdresSelection;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 👨‍👩‍👧 Family & Scholarship Info
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String familyInfo;
  final int totalLiving;

  // Mother Info
  final String motherName;
  final String motherSurname;
  final String motherPhone;
  final String motherJob;
  final String motherSalary;
  final String motherLiving;

  // Father Info
  final String fatherName;
  final String fatherSurname;
  final String fatherPhone;
  final String fatherJob;
  final String fatherSalary;
  final String fatherLiving;

  // Housing & Financial
  final String evMulkiyeti; // Kira, Mülk, etc.
  final String mulkiyet;
  final String yurt;
  final bool bursVerebilir;
  final String engelliRaporu;
  final bool isDisabled;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💰 Banking & Payment
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String bank;
  final String iban;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔐 Account & Security
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final bool ban;
  final bool deletedAccount;
  final bool bot;
  final String signInMethod; // Email, Phone, Google, etc.
  final String sifre; // ⚠️ Not recommended to store plaintext
  final String refCode;
  final List<String> blockedUsers;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 Device & Technical
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String device;
  final String deviceID;
  final String deviceVersion;
  final String token; // FCM token
  final String createdDate; // Timestamp as string

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔔 Permissions & Preferences
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final bool bildirim;
  final bool aramaIzin;
  final bool mailIzin;
  final bool whatsappIzin;
  final bool rehber;
  final String settings;
  final String themeSettings;

  // ━━━━━━━━━━━━━━━━━━��━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎬 Activity & Content
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String canliYayin;
  final List<String> lastSearchList;
  final List<String> readStories;
  final Map<String, int> readStoriesTimes;
  final String mail; // Secondary email?

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏗️ Constructor
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CurrentUserModel({
    required this.userID,
    required this.nickname,
    required this.firstName,
    required this.lastName,
    required this.avatarUrl,
    required this.email,
    required this.phoneNumber,
    required this.tc,
    required this.dogumTarihi,
    required this.cinsiyet,
    required this.bio,
    required this.rozet,
    required this.hesapOnayi,
    required this.gizliHesap,
    required this.viewSelection,
    required this.ilgialanlari,
    required this.favoriMuzikler,
    required this.meslekKategori,
    required this.calismaDurumu,
    required this.medeniHal,
    required this.counterOfFollowers,
    required this.counterOfFollowings,
    required this.counterOfPosts,
    required this.counterOfLikes,
    required this.antPoint,
    required this.dailyDurations,
    required this.educationLevel,
    required this.universite,
    required this.fakulte,
    required this.bolum,
    required this.ogrenciNo,
    required this.ogretimTipi,
    required this.sinif,
    required this.lise,
    required this.ortaOkul,
    required this.okul,
    required this.okulSehir,
    required this.okulIlce,
    required this.ortalamaPuan,
    required this.ortalamaPuan1,
    required this.ortalamaPuan2,
    required this.defAnaBaslik,
    required this.defDers,
    required this.defSinavTuru,
    required this.osymPuanTuru,
    required this.osysPuan,
    required this.osysPuani1,
    required this.osysPuani2,
    required this.yuzlukSistem,
    required this.adres,
    required this.ulke,
    required this.city,
    required this.town,
    required this.il,
    required this.ilce,
    required this.ikametSehir,
    required this.ikametIlce,
    required this.nufusSehir,
    required this.nufusIlce,
    required this.nufusaKayitliOlduguYer,
    required this.locationSehir,
    required this.kolayAdresSelection,
    required this.familyInfo,
    required this.totalLiving,
    required this.motherName,
    required this.motherSurname,
    required this.motherPhone,
    required this.motherJob,
    required this.motherSalary,
    required this.motherLiving,
    required this.fatherName,
    required this.fatherSurname,
    required this.fatherPhone,
    required this.fatherJob,
    required this.fatherSalary,
    required this.fatherLiving,
    required this.evMulkiyeti,
    required this.mulkiyet,
    required this.yurt,
    required this.bursVerebilir,
    required this.engelliRaporu,
    required this.isDisabled,
    required this.bank,
    required this.iban,
    required this.ban,
    required this.deletedAccount,
    required this.bot,
    required this.signInMethod,
    required this.sifre,
    required this.refCode,
    required this.blockedUsers,
    required this.device,
    required this.deviceID,
    required this.deviceVersion,
    required this.token,
    required this.createdDate,
    required this.bildirim,
    required this.aramaIzin,
    required this.mailIzin,
    required this.whatsappIzin,
    required this.rehber,
    required this.settings,
    required this.themeSettings,
    required this.canliYayin,
    required this.lastSearchList,
    required this.readStories,
    required this.readStoriesTimes,
    required this.mail,
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏭 Factory: From Firebase Document
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  factory CurrentUserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final education = _asMap(data['education']);
    final family = _asMap(data['family']);
    final profile = _asMap(data['profile']);

    return CurrentUserModel(
      userID: doc.id,
      nickname:
          (data['nickname'] ?? data['username'] ?? data['displayName'] ?? '')
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
      rozet: data['rozet'] ?? '',
      hesapOnayi: (data['isApproved'] ?? false) == true,
      gizliHesap: (data['isPrivate'] ?? false) == true,
      viewSelection: data['viewSelection'] ?? 1,
      ilgialanlari: List<String>.from(data['ilgialanlari'] ?? []),
      favoriMuzikler: List<String>.from(data['favoriMuzikler'] ?? []),
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
      universite:
          _pickScopedString(data, education, 'universite', fallback: ''),
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
      osysPuani1:
          _pickScopedString(data, education, 'osysPuani1', fallback: ''),
      osysPuani2:
          _pickScopedString(data, education, 'osysPuani2', fallback: ''),
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
      motherSalary:
          _pickScopedString(data, family, 'motherSalary', fallback: ''),
      motherLiving:
          _pickScopedString(data, family, 'motherLiving', fallback: ''),
      fatherName: _pickScopedString(data, family, 'fatherName', fallback: ''),
      fatherSurname:
          _pickScopedString(data, family, 'fatherSurname', fallback: ''),
      fatherPhone: _pickScopedString(data, family, 'fatherPhone', fallback: ''),
      fatherJob: _pickScopedString(data, family, 'fatherJob', fallback: ''),
      fatherSalary:
          _pickScopedString(data, family, 'fatherSalary', fallback: ''),
      fatherLiving:
          _pickScopedString(data, family, 'fatherLiving', fallback: ''),
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
      deletedAccount: (data['isDeleted'] ?? false) == true,
      bot: (data['isBot'] ?? false) == true,
      signInMethod: data['signInMethod'] ?? '',
      sifre: '',
      refCode: data['refCode'] ?? '',
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      device: data['device'] ?? '',
      deviceID: data['deviceID'] ?? '',
      deviceVersion: data['deviceVersion'] ?? '',
      token: data['token'] ?? '',
      createdDate:
          _createdDateFromAny(data['createdDate'] ?? data['createdDate']),
      bildirim: data['bildirim'] ?? false,
      aramaIzin: data['aramaIzin'] ?? false,
      mailIzin: data['mailIzin'] ?? false,
      whatsappIzin: data['whatsappIzin'] ?? false,
      rehber: data['rehber'] ?? false,
      settings: data['settings'] ?? '',
      themeSettings: data['themeSettings'] ?? '',
      canliYayin: data['canliYayin'] ?? '',
      lastSearchList: List<String>.from(data['lastSearchList'] ?? []),
      readStories: List<String>.from(data['readStories'] ?? []),
      readStoriesTimes: _parseReadStoriesTimes(data['readStoriesTimes']),
      mail: data['mail'] ?? '',
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💾 To JSON (for SharedPreferences cache)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Map<String, dynamic> toJson() {
    return {
      'userID': userID,
      'nickname': nickname,
      'displayName': nickname,
      'firstName': firstName,
      'lastName': lastName,
      'avatarUrl': avatarUrl,
      'email': email,
      'phoneNumber': phoneNumber,
      'tc': tc,
      'dogumTarihi': dogumTarihi,
      'cinsiyet': cinsiyet,
      'bio': bio,
      'rozet': rozet,
      'isApproved': hesapOnayi,
      'isPrivate': gizliHesap,
      'viewSelection': viewSelection,
      'ilgialanlari': ilgialanlari,
      'favoriMuzikler': favoriMuzikler,
      'meslekKategori': meslekKategori,
      'calismaDurumu': calismaDurumu,
      'medeniHal': medeniHal,
      'counterOfFollowers': counterOfFollowers,
      'counterOfFollowings': counterOfFollowings,
      'counterOfPosts': counterOfPosts,
      'followerCount': counterOfFollowers,
      'followingCount': counterOfFollowings,
      'postCount': counterOfPosts,
      'counterOfLikes': counterOfLikes,
      'antPoint': antPoint,
      'dailyDurations': dailyDurations,
      'educationLevel': educationLevel,
      'universite': universite,
      'fakulte': fakulte,
      'bolum': bolum,
      'ogrenciNo': ogrenciNo,
      'ogretimTipi': ogretimTipi,
      'sinif': sinif,
      'lise': lise,
      'ortaOkul': ortaOkul,
      'okul': okul,
      'okulSehir': okulSehir,
      'okulIlce': okulIlce,
      'ortalamaPuan': ortalamaPuan,
      'ortalamaPuan1': ortalamaPuan1,
      'ortalamaPuan2': ortalamaPuan2,
      'defAnaBaslik': defAnaBaslik,
      'defDers': defDers,
      'defSinavTuru': defSinavTuru,
      'osymPuanTuru': osymPuanTuru,
      'osysPuan': osysPuan,
      'osysPuani1': osysPuani1,
      'osysPuani2': osysPuani2,
      'yuzlukSistem': yuzlukSistem,
      'adres': adres,
      'ulke': ulke,
      'city': city,
      'town': town,
      'il': il,
      'ilce': ilce,
      'ikametSehir': ikametSehir,
      'ikametIlce': ikametIlce,
      'nufusSehir': nufusSehir,
      'nufusIlce': nufusIlce,
      'nufusaKayitliOlduguYer': nufusaKayitliOlduguYer,
      'locationSehir': locationSehir,
      'kolayAdresSelection': kolayAdresSelection,
      'familyInfo': familyInfo,
      'totalLiving': totalLiving,
      'motherName': motherName,
      'motherSurname': motherSurname,
      'motherPhone': motherPhone,
      'motherJob': motherJob,
      'motherSalary': motherSalary,
      'motherLiving': motherLiving,
      'fatherName': fatherName,
      'fatherSurname': fatherSurname,
      'fatherPhone': fatherPhone,
      'fatherJob': fatherJob,
      'fatherSalary': fatherSalary,
      'fatherLiving': fatherLiving,
      'evMulkiyeti': evMulkiyeti,
      'mulkiyet': mulkiyet,
      'yurt': yurt,
      'bursVerebilir': bursVerebilir,
      'engelliRaporu': engelliRaporu,
      'isDisabled': isDisabled,
      'bank': bank,
      'iban': iban,
      'isBanned': ban,
      'isDeleted': deletedAccount,
      'isBot': bot,
      'signInMethod': signInMethod,
      'refCode': refCode,
      'blockedUsers': blockedUsers,
      'device': device,
      'deviceID': deviceID,
      'deviceVersion': deviceVersion,
      'token': token,
      'createdDate': createdDate,
      'bildirim': bildirim,
      'aramaIzin': aramaIzin,
      'mailIzin': mailIzin,
      'whatsappIzin': whatsappIzin,
      'rehber': rehber,
      'settings': settings,
      'themeSettings': themeSettings,
      'canliYayin': canliYayin,
      'lastSearchList': lastSearchList,
      'readStories': readStories,
      'readStoriesTimes': readStoriesTimes,
      'mail': mail,
    };
  }

  /// Redacted cache payload for local device storage.
  ///
  /// Keep UX-critical profile fields, but avoid persisting device and push
  /// metadata that can be re-hydrated from Firebase/Auth on demand.
  Map<String, dynamic> toCacheJson() {
    final json = toJson();
    json.remove('device');
    json.remove('deviceID');
    json.remove('deviceVersion');
    json.remove('token');
    return json;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📥 From JSON (for SharedPreferences cache)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    final education = _asMap(json['education']);
    final family = _asMap(json['family']);
    final profile = _asMap(json['profile']);

    return CurrentUserModel(
      userID: json['userID'] ?? '',
      nickname:
          (json['nickname'] ?? json['username'] ?? json['displayName'] ?? '')
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
      rozet: json['rozet'] ?? '',
      hesapOnayi: (json['isApproved'] ?? false) == true,
      gizliHesap: (json['isPrivate'] ?? false) == true,
      viewSelection: json['viewSelection'] ?? 1,
      ilgialanlari: List<String>.from(json['ilgialanlari'] ?? []),
      favoriMuzikler: List<String>.from(json['favoriMuzikler'] ?? []),
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
      universite:
          _pickScopedString(json, education, 'universite', fallback: ''),
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
      osysPuani1:
          _pickScopedString(json, education, 'osysPuani1', fallback: ''),
      osysPuani2:
          _pickScopedString(json, education, 'osysPuani2', fallback: ''),
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
      motherSalary:
          _pickScopedString(json, family, 'motherSalary', fallback: ''),
      motherLiving:
          _pickScopedString(json, family, 'motherLiving', fallback: ''),
      fatherName: _pickScopedString(json, family, 'fatherName', fallback: ''),
      fatherSurname:
          _pickScopedString(json, family, 'fatherSurname', fallback: ''),
      fatherPhone: _pickScopedString(json, family, 'fatherPhone', fallback: ''),
      fatherJob: _pickScopedString(json, family, 'fatherJob', fallback: ''),
      fatherSalary:
          _pickScopedString(json, family, 'fatherSalary', fallback: ''),
      fatherLiving:
          _pickScopedString(json, family, 'fatherLiving', fallback: ''),
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
      deletedAccount: (json['isDeleted'] ?? false) == true,
      bot: (json['isBot'] ?? false) == true,
      signInMethod: json['signInMethod'] ?? '',
      // Legacy caches may still contain this field; never rehydrate it.
      sifre: '',
      refCode: json['refCode'] ?? '',
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      device: json['device'] ?? '',
      deviceID: json['deviceID'] ?? '',
      deviceVersion: json['deviceVersion'] ?? '',
      token: json['token'] ?? '',
      createdDate:
          _createdDateFromAny(json['createdDate'] ?? json['createdDate']),
      bildirim: json['bildirim'] ?? false,
      aramaIzin: json['aramaIzin'] ?? false,
      mailIzin: json['mailIzin'] ?? false,
      whatsappIzin: json['whatsappIzin'] ?? false,
      rehber: json['rehber'] ?? false,
      settings: json['settings'] ?? '',
      themeSettings: json['themeSettings'] ?? '',
      canliYayin: json['canliYayin'] ?? '',
      lastSearchList: List<String>.from(json['lastSearchList'] ?? []),
      readStories: List<String>.from(json['readStories'] ?? []),
      readStoriesTimes: _parseReadStoriesTimes(json['readStoriesTimes']),
      mail: json['mail'] ?? '',
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔧 Helper: Parse readStoriesTimes safely
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static Map<String, int> _parseReadStoriesTimes(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, int>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(
            key.toString(),
            (value is int) ? value : int.tryParse(value.toString()) ?? 0,
          ));
    }
    return {};
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return const <String, dynamic>{};
  }

  static dynamic _pickScoped(
    Map<String, dynamic> root,
    Map<String, dynamic> scoped,
    String key,
  ) {
    if (scoped.containsKey(key)) return scoped[key];
    return root[key];
  }

  static String _pickScopedString(
    Map<String, dynamic> root,
    Map<String, dynamic> scoped,
    String key, {
    String fallback = '',
  }) {
    final value = _pickScoped(root, scoped, key);
    return value?.toString() ?? fallback;
  }

  static int _pickScopedInt(
    Map<String, dynamic> root,
    Map<String, dynamic> scoped,
    String key, {
    int fallback = 0,
  }) {
    final value = _pickScoped(root, scoped, key);
    if (value == null) return fallback;
    return _parseToInt(value);
  }

  static bool _pickScopedBool(
    Map<String, dynamic> root,
    Map<String, dynamic> scoped,
    String key, {
    bool fallback = false,
  }) {
    final value = _pickScoped(root, scoped, key);
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 CopyWith (for immutable updates)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CurrentUserModel copyWith({
    String? userID,
    String? nickname,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? email,
    String? phoneNumber,
    String? bio,
    String? rozet,
    bool? hesapOnayi,
    bool? gizliHesap,
    int? viewSelection,
    int? counterOfFollowers,
    int? counterOfFollowings,
    int? counterOfPosts,
    int? counterOfLikes,
    List<String>? blockedUsers,
    List<String>? readStories,
    Map<String, int>? readStoriesTimes,
  }) {
    return CurrentUserModel(
      userID: userID ?? this.userID,
      nickname: nickname ?? this.nickname,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      tc: tc,
      dogumTarihi: dogumTarihi,
      cinsiyet: cinsiyet,
      bio: bio ?? this.bio,
      rozet: rozet ?? this.rozet,
      hesapOnayi: hesapOnayi ?? this.hesapOnayi,
      gizliHesap: gizliHesap ?? this.gizliHesap,
      viewSelection: viewSelection ?? this.viewSelection,
      ilgialanlari: ilgialanlari,
      favoriMuzikler: favoriMuzikler,
      meslekKategori: meslekKategori,
      calismaDurumu: calismaDurumu,
      medeniHal: medeniHal,
      counterOfFollowers: counterOfFollowers ?? this.counterOfFollowers,
      counterOfFollowings: counterOfFollowings ?? this.counterOfFollowings,
      counterOfPosts: counterOfPosts ?? this.counterOfPosts,
      counterOfLikes: counterOfLikes ?? this.counterOfLikes,
      antPoint: antPoint,
      dailyDurations: dailyDurations,
      educationLevel: educationLevel,
      universite: universite,
      fakulte: fakulte,
      bolum: bolum,
      ogrenciNo: ogrenciNo,
      ogretimTipi: ogretimTipi,
      sinif: sinif,
      lise: lise,
      ortaOkul: ortaOkul,
      okul: okul,
      okulSehir: okulSehir,
      okulIlce: okulIlce,
      ortalamaPuan: ortalamaPuan,
      ortalamaPuan1: ortalamaPuan1,
      ortalamaPuan2: ortalamaPuan2,
      defAnaBaslik: defAnaBaslik,
      defDers: defDers,
      defSinavTuru: defSinavTuru,
      osymPuanTuru: osymPuanTuru,
      osysPuan: osysPuan,
      osysPuani1: osysPuani1,
      osysPuani2: osysPuani2,
      yuzlukSistem: yuzlukSistem,
      adres: adres,
      ulke: ulke,
      city: city,
      town: town,
      il: il,
      ilce: ilce,
      ikametSehir: ikametSehir,
      ikametIlce: ikametIlce,
      nufusSehir: nufusSehir,
      nufusIlce: nufusIlce,
      nufusaKayitliOlduguYer: nufusaKayitliOlduguYer,
      locationSehir: locationSehir,
      kolayAdresSelection: kolayAdresSelection,
      familyInfo: familyInfo,
      totalLiving: totalLiving,
      motherName: motherName,
      motherSurname: motherSurname,
      motherPhone: motherPhone,
      motherJob: motherJob,
      motherSalary: motherSalary,
      motherLiving: motherLiving,
      fatherName: fatherName,
      fatherSurname: fatherSurname,
      fatherPhone: fatherPhone,
      fatherJob: fatherJob,
      fatherSalary: fatherSalary,
      fatherLiving: fatherLiving,
      evMulkiyeti: evMulkiyeti,
      mulkiyet: mulkiyet,
      yurt: yurt,
      bursVerebilir: bursVerebilir,
      engelliRaporu: engelliRaporu,
      isDisabled: isDisabled,
      bank: bank,
      iban: iban,
      ban: ban,
      deletedAccount: deletedAccount,
      bot: bot,
      signInMethod: signInMethod,
      sifre: sifre,
      refCode: refCode,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      device: device,
      deviceID: deviceID,
      deviceVersion: deviceVersion,
      token: token,
      createdDate: createdDate,
      bildirim: bildirim,
      aramaIzin: aramaIzin,
      mailIzin: mailIzin,
      whatsappIzin: whatsappIzin,
      rehber: rehber,
      settings: settings,
      themeSettings: themeSettings,
      canliYayin: canliYayin,
      lastSearchList: lastSearchList,
      readStories: readStories ?? this.readStories,
      readStoriesTimes: readStoriesTimes ?? this.readStoriesTimes,
      mail: mail,
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎯 Utility Getters
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Full name
  String get fullName => '$firstName $lastName'.trim();

  /// Has profile image
  bool get hasProfileImage => avatarUrl.isNotEmpty;

  /// Is verified account
  bool get isVerified => hesapOnayi;

  /// Is private account
  bool get isPrivate => gizliHesap;

  /// Is banned
  bool get isBanned => ban;

  /// Has bio
  bool get hasBio => bio.isNotEmpty;

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🛠️ Helper Methods for Type-Safe Parsing
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Safely parse dynamic value to int
  /// Handles: int, String (numeric), null, empty string
  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  static String _createdDateFromAny(dynamic value) {
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
}
