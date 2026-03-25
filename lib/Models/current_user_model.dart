// 📁 lib/Models/CurrentUserModel.dart
// 🎯 Enterprise-grade current user model with comprehensive fields
// 💾 Supports both Firebase sync and local cache serialization

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';
import 'package:turqappv2/Core/Utils/bool_utils.dart';

part 'current_user_model_utils_part.dart';
part 'current_user_model_serialization_part.dart';

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
  final int moderationStrikeCount;
  final int moderationLevel;
  final int moderationRestrictedUntil;
  final bool moderationPermanentBan;
  final String moderationBanReason;
  final int moderationUpdatedAt;
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

  String get fullName => '$firstName $lastName'.trim();
  bool get isVerified => hesapOnayi;
  bool get isPrivate => gizliHesap;

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
    required this.moderationStrikeCount,
    required this.moderationLevel,
    required this.moderationRestrictedUntil,
    required this.moderationPermanentBan,
    required this.moderationBanReason,
    required this.moderationUpdatedAt,
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

  factory CurrentUserModel.fromFirestore(DocumentSnapshot doc) =>
      _currentUserModelFromFirestore(doc);

  Map<String, dynamic> toJson() => _currentUserModelToJson(this);

  Map<String, dynamic> toCacheJson() => _currentUserModelToCacheJson(this);

  factory CurrentUserModel.fromJson(Map<String, dynamic> json) =>
      _currentUserModelFromJson(json);
}
