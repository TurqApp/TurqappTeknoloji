// 📁 lib/Models/CurrentUserModel.dart
// 🎯 Enterprise-grade current user model with comprehensive fields
// 💾 Supports both Firebase sync and local cache serialization

import 'package:cloud_firestore/cloud_firestore.dart';

class CurrentUserModel {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔑 Core Identity Fields
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  final String userID;
  final String nickname;
  final String firstName;
  final String lastName;
  final String pfImage;
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
    required this.pfImage,
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

    return CurrentUserModel(
      userID: doc.id,
      nickname: data['nickname'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      pfImage: data['pfImage'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      tc: data['tc'] ?? '',
      dogumTarihi: data['dogumTarihi'] ?? '',
      cinsiyet: data['cinsiyet'] ?? '',
      bio: data['bio'] ?? '',
      rozet: data['rozet'] ?? '',
      hesapOnayi: data['hesapOnayi'] ?? false,
      gizliHesap: data['gizliHesap'] ?? false,
      viewSelection: data['viewSelection'] ?? 1,
      ilgialanlari: List<String>.from(data['ilgialanlari'] ?? []),
      favoriMuzikler: List<String>.from(data['favoriMuzikler'] ?? []),
      meslekKategori: data['meslekKategori'] ?? '',
      calismaDurumu: data['calismaDurumu'] ?? '',
      medeniHal: data['medeniHal'] ?? '',
      counterOfFollowers: data['counterOfFollowers'] ?? 0,
      counterOfFollowings: data['counterOfFollowings'] ?? 0,
      counterOfPosts: data['counterOfPosts'] ?? 0,
      counterOfLikes: data['counterOfLikes'] ?? 0,
      antPoint: data['antPoint'] ?? 100,
      dailyDurations: data['dailyDurations'] ?? 1,
      educationLevel: data['educationLevel'] ?? '',
      universite: data['universite'] ?? '',
      fakulte: data['fakulte'] ?? '',
      bolum: data['bolum'] ?? '',
      ogrenciNo: data['ogrenciNo'] ?? '',
      ogretimTipi: data['ogretimTipi'] ?? '',
      sinif: data['sinif'] ?? '',
      lise: data['lise'] ?? '',
      ortaOkul: data['ortaOkul'] ?? '',
      okul: data['okul'] ?? '',
      okulSehir: data['okulSehir'] ?? '',
      okulIlce: data['okulIlce'] ?? '',
      ortalamaPuan: data['ortalamaPuan'] ?? '',
      ortalamaPuan1: data['ortalamaPuan1'] ?? '',
      ortalamaPuan2: data['ortalamaPuan2'] ?? '',
      defAnaBaslik: data['defAnaBaslik'] ?? '',
      defDers: data['defDers'] ?? '',
      defSinavTuru: data['defSinavTuru'] ?? '',
      osymPuanTuru: data['osymPuanTuru'] ?? '',
      osysPuan: data['osysPuan'] ?? '',
      osysPuani1: data['osysPuani1'] ?? '',
      osysPuani2: data['osysPuani2'] ?? '',
      yuzlukSistem: data['yuzlukSistem'] ?? true,
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
      familyInfo: data['familyInfo'] ?? '',
      totalLiving: _parseToInt(data['totalLiving']),
      motherName: data['motherName'] ?? '',
      motherSurname: data['motherSurname'] ?? '',
      motherPhone: data['motherPhone'] ?? '',
      motherJob: data['motherJob'] ?? '',
      motherSalary: data['motherSalary'] ?? '',
      motherLiving: data['motherLiving'] ?? '',
      fatherName: data['fatherName'] ?? '',
      fatherSurname: data['fatherSurname'] ?? '',
      fatherPhone: data['fatherPhone'] ?? '',
      fatherJob: data['fatherJob'] ?? '',
      fatherSalary: data['fatherSalary'] ?? '',
      fatherLiving: data['fatherLiving'] ?? '',
      evMulkiyeti: data['evMulkiyeti'] ?? '',
      mulkiyet: data['mulkiyet'] ?? '',
      yurt: data['yurt'] ?? '',
      bursVerebilir: data['bursVerebilir'] ?? false,
      engelliRaporu: data['engelliRaporu'] ?? '',
      isDisabled: data['isDisabled'] ?? false,
      bank: data['bank'] ?? '',
      iban: data['iban'] ?? '',
      ban: data['ban'] ?? false,
      deletedAccount: data['deletedAccount'] ?? false,
      bot: data['bot'] ?? false,
      signInMethod: data['signInMethod'] ?? '',
      sifre: data['sifre'] ?? '',
      refCode: data['refCode'] ?? '',
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      device: data['device'] ?? '',
      deviceID: data['deviceID'] ?? '',
      deviceVersion: data['deviceVersion'] ?? '',
      token: data['token'] ?? '',
      createdDate: data['createdDate'] ?? '',
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
      'firstName': firstName,
      'lastName': lastName,
      'pfImage': pfImage,
      'email': email,
      'phoneNumber': phoneNumber,
      'tc': tc,
      'dogumTarihi': dogumTarihi,
      'cinsiyet': cinsiyet,
      'bio': bio,
      'rozet': rozet,
      'hesapOnayi': hesapOnayi,
      'gizliHesap': gizliHesap,
      'viewSelection': viewSelection,
      'ilgialanlari': ilgialanlari,
      'favoriMuzikler': favoriMuzikler,
      'meslekKategori': meslekKategori,
      'calismaDurumu': calismaDurumu,
      'medeniHal': medeniHal,
      'counterOfFollowers': counterOfFollowers,
      'counterOfFollowings': counterOfFollowings,
      'counterOfPosts': counterOfPosts,
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
      'ban': ban,
      'deletedAccount': deletedAccount,
      'bot': bot,
      'signInMethod': signInMethod,
      'sifre': sifre,
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📥 From JSON (for SharedPreferences cache)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  factory CurrentUserModel.fromJson(Map<String, dynamic> json) {
    return CurrentUserModel(
      userID: json['userID'] ?? '',
      nickname: json['nickname'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      pfImage: json['pfImage'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      tc: json['tc'] ?? '',
      dogumTarihi: json['dogumTarihi'] ?? '',
      cinsiyet: json['cinsiyet'] ?? '',
      bio: json['bio'] ?? '',
      rozet: json['rozet'] ?? '',
      hesapOnayi: json['hesapOnayi'] ?? false,
      gizliHesap: json['gizliHesap'] ?? false,
      viewSelection: json['viewSelection'] ?? 1,
      ilgialanlari: List<String>.from(json['ilgialanlari'] ?? []),
      favoriMuzikler: List<String>.from(json['favoriMuzikler'] ?? []),
      meslekKategori: json['meslekKategori'] ?? '',
      calismaDurumu: json['calismaDurumu'] ?? '',
      medeniHal: json['medeniHal'] ?? '',
      counterOfFollowers: json['counterOfFollowers'] ?? 0,
      counterOfFollowings: json['counterOfFollowings'] ?? 0,
      counterOfPosts: json['counterOfPosts'] ?? 0,
      counterOfLikes: json['counterOfLikes'] ?? 0,
      antPoint: json['antPoint'] ?? 100,
      dailyDurations: json['dailyDurations'] ?? 1,
      educationLevel: json['educationLevel'] ?? '',
      universite: json['universite'] ?? '',
      fakulte: json['fakulte'] ?? '',
      bolum: json['bolum'] ?? '',
      ogrenciNo: json['ogrenciNo'] ?? '',
      ogretimTipi: json['ogretimTipi'] ?? '',
      sinif: json['sinif'] ?? '',
      lise: json['lise'] ?? '',
      ortaOkul: json['ortaOkul'] ?? '',
      okul: json['okul'] ?? '',
      okulSehir: json['okulSehir'] ?? '',
      okulIlce: json['okulIlce'] ?? '',
      ortalamaPuan: json['ortalamaPuan'] ?? '',
      ortalamaPuan1: json['ortalamaPuan1'] ?? '',
      ortalamaPuan2: json['ortalamaPuan2'] ?? '',
      defAnaBaslik: json['defAnaBaslik'] ?? '',
      defDers: json['defDers'] ?? '',
      defSinavTuru: json['defSinavTuru'] ?? '',
      osymPuanTuru: json['osymPuanTuru'] ?? '',
      osysPuan: json['osysPuan'] ?? '',
      osysPuani1: json['osysPuani1'] ?? '',
      osysPuani2: json['osysPuani2'] ?? '',
      yuzlukSistem: json['yuzlukSistem'] ?? true,
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
      familyInfo: json['familyInfo'] ?? '',
      totalLiving: json['totalLiving'] ?? 0,
      motherName: json['motherName'] ?? '',
      motherSurname: json['motherSurname'] ?? '',
      motherPhone: json['motherPhone'] ?? '',
      motherJob: json['motherJob'] ?? '',
      motherSalary: json['motherSalary'] ?? '',
      motherLiving: json['motherLiving'] ?? '',
      fatherName: json['fatherName'] ?? '',
      fatherSurname: json['fatherSurname'] ?? '',
      fatherPhone: json['fatherPhone'] ?? '',
      fatherJob: json['fatherJob'] ?? '',
      fatherSalary: json['fatherSalary'] ?? '',
      fatherLiving: json['fatherLiving'] ?? '',
      evMulkiyeti: json['evMulkiyeti'] ?? '',
      mulkiyet: json['mulkiyet'] ?? '',
      yurt: json['yurt'] ?? '',
      bursVerebilir: json['bursVerebilir'] ?? false,
      engelliRaporu: json['engelliRaporu'] ?? '',
      isDisabled: json['isDisabled'] ?? false,
      bank: json['bank'] ?? '',
      iban: json['iban'] ?? '',
      ban: json['ban'] ?? false,
      deletedAccount: json['deletedAccount'] ?? false,
      bot: json['bot'] ?? false,
      signInMethod: json['signInMethod'] ?? '',
      sifre: json['sifre'] ?? '',
      refCode: json['refCode'] ?? '',
      blockedUsers: List<String>.from(json['blockedUsers'] ?? []),
      device: json['device'] ?? '',
      deviceID: json['deviceID'] ?? '',
      deviceVersion: json['deviceVersion'] ?? '',
      token: json['token'] ?? '',
      createdDate: json['createdDate'] ?? '',
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

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔄 CopyWith (for immutable updates)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CurrentUserModel copyWith({
    String? userID,
    String? nickname,
    String? firstName,
    String? lastName,
    String? pfImage,
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
      pfImage: pfImage ?? this.pfImage,
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
  bool get hasProfileImage => pfImage.isNotEmpty;

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
}
