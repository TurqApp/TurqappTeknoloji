# 🚀 Enterprise-Grade Users Collection Schema
## Instagram/Twitter/TikTok Level Architecture

> **Hedef**: Hızlı, ölçeklenebilir, kullanıcı deneyimi odaklı
> **Prensip**: Separation of Concerns + Lazy Loading + Denormalization
> **Performans**: <100ms response time, <5KB core data

---

## 📋 İçindekiler

1. [Mimari Prensipleri](#mimari-prensipleri)
2. [Koleksiyon Yapısı](#koleksiyon-yapısı)
3. [Ana Users Koleksiyonu](#1-users-koleksiyonu)
4. [Private Subcollection](#2-private-subcollection)
5. [Education Subcollection](#3-education-subcollection)
6. [Settings Subcollection](#4-settings-subcollection)
7. [Interactions Subcollection](#5-interactions-subcollection)
8. [Stats Sharding](#6-stats-sharding)
9. [Denormalized Data](#7-denormalized-data)
10. [Performans Karşılaştırması](#performans-karşılaştırması)
11. [Firestore Indexes](#firestore-indexes)
12. [Migration Strategy](#migration-stratejisi)

---

## 🎯 Mimari Prensipleri

### 1. **Split Heavy Documents**
- Ana koleksiyon: **Hot data** (sık erişilen, hafif)
- Subcollections: **Cold data** (nadiren erişilen, ağır)

### 2. **Denormalization for Speed**
- Post'larda kullanıcı bilgisi embed edilir
- Çift yazma kabul edilir (consistency < speed)

### 3. **Sharding for Scale**
- Counter'lar için distributed counters
- Follower sayısı 10 shard'a bölünür

### 4. **Lazy Loading**
- İlk yükleme: 5KB
- Detay gerekince: +3-5KB chunks

### 5. **Cache-First Strategy**
- Memory cache: 5 dakika
- Disk cache: 24 saat
- Network: Last resort

---

## 📊 Koleksiyon Yapısı

```
Firestore Root
│
├── users/{userId}                          [5KB - Hot Data]
│   ├── private/                            [Subcollection]
│   │   ├── profile                         [3KB - Sensitive]
│   │   ├── financial                       [2KB - Encrypted]
│   │   └── health                          [1KB - Optional]
│   │
│   ├── education/                          [Subcollection]
│   │   ├── current                         [4KB - Academic]
│   │   ├── achievements/{achievementId}    [Variable]
│   │   └── courses/{courseId}              [Variable]
│   │
│   ├── settings/                           [Subcollection]
│   │   ├── preferences                     [2KB - App settings]
│   │   └── notifications                   [1KB - Permissions]
│   │
│   ├── interactions/                       [Subcollection]
│   │   ├── blocked/{blockedUserId}         [Scalable]
│   │   ├── muted/{mutedUserId}             [Scalable]
│   │   ├── saved/{savedItemId}             [Scalable]
│   │   └── bookmarks/{bookmarkId}          [Scalable]
│   │
│   ├── stats/                              [Subcollection]
│   │   ├── followers/shard_0               [Sharded counters]
│   │   ├── followers/shard_1
│   │   └── ... (10 shards total)
│   │
│   └── activity/                           [Subcollection]
│       └── {activityId}                    [Log entries]
│
└── usernames/{username}                    [Username → UID mapping]
    └── uid: "user_123"
```

---

## 1. Users Koleksiyonu

### 🎯 Ana Doküman: `users/{userId}`

**Amaç**: Sık erişilen, hafif, cache'lenebilir data
**Boyut**: ~5KB
**Cache**: Memory 5dk, Disk 24 saat

```json
{
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔑 CORE IDENTITY (Değiştirilemez)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "userId": "user_abc123xyz",
  "email": "student@turqapp.com",
  "phoneNumber": "+905551234567",

  // Email & Phone Verification Status
  "emailVerified": true,
  "phoneVerified": true,
  "verifiedAt": "2025-01-15T10:30:00Z",

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 👤 PUBLIC PROFILE (Feed'de görünen)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "profile": {
    "displayName": "Ahmet Yılmaz",          // Görünen isim
    "username": "ahmetyilmaz",              // @username (unique)
    "firstName": "Ahmet",
    "lastName": "Yılmaz",

    // Visual Identity
    "avatarUrl": "https://storage.googleapis.com/turqapp/avatars/abc123.jpg",
    "avatarThumbnail": "https://storage.googleapis.com/.../thumb_abc123.jpg", // 100x100
    "coverPhotoUrl": "https://storage.googleapis.com/turqapp/covers/abc123.jpg",

    // Bio & Status
    "bio": "YKS 2025 | Boğaziçi Bilgisayar Mühendisliği hedefi",
    "bioLinks": [
      {
        "title": "YouTube",
        "url": "https://youtube.com/@ahmet",
        "icon": "youtube"
      }
    ],

    // Badge & Verification
    "verified": false,                      // Mavi tik
    "badge": "gold",                        // null, bronze, silver, gold, platinum
    "badgeIcon": "🏆",

    // User Type
    "role": "student",                      // student, tutor, admin, moderator
    "accountType": "premium",               // free, premium, pro
    "premiumExpiresAt": "2025-12-31T23:59:59Z"
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📊 STATS (Denormalized - Cloud Function ile güncellenir)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "stats": {
    "followersCount": 1250,
    "followingCount": 450,
    "postsCount": 89,
    "storiesCount": 12,
    "shortsCount": 34,
    "reputation": 4850,                     // Ant points
    "totalLikes": 12450,
    "totalViews": 45000
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔒 PRIVACY & VISIBILITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "privacy": {
    "profileVisibility": "public",          // public, followers, private
    "showEmail": false,
    "showPhone": false,
    "showBirthday": false,
    "allowMessagesFrom": "everyone",        // everyone, followers, none
    "allowTagging": "everyone",             // everyone, followers, none
    "allowMentions": "everyone",
    "showOnlineStatus": true,
    "showActivity": true,                   // Activity tab görünürlük
    "searchable": true                      // Arama sonuçlarında görünsün mü
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🌍 LOCATION (Genel bilgi, hassas değil)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "location": {
    "city": "Istanbul",
    "district": "Kadıköy",
    "country": "TR",
    "countryCode": "TR",
    "timezone": "Europe/Istanbul",

    // Geohash for nearby queries (optional)
    "geohash": "sxk3y",                     // 5 char precision (~5km)
    "coordinates": {
      "lat": 40.9903,
      "lng": 29.0264
    }
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎓 QUICK EDUCATION INFO (Detay education/ altında)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "education": {
    "level": "lise",                        // ortaokul, lise, universite, mezun
    "schoolName": "Kadıköy Anadolu Lisesi",
    "grade": 12,
    "targetExam": "YKS",                    // LGS, YKS, KPSS, etc.
    "targetYear": 2025
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💼 PROFESSIONAL (İş arayanlar için)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "professional": {
    "category": "ogrenci",                  // ogrenci, calisan, isarayan, emekli
    "workStatus": "student",                // student, employed, unemployed, retired
    "maritalStatus": "single",              // single, married
    "cvUrl": null                           // CV linki (optional)
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏷️ INTERESTS & TAGS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "interests": [
    "matematik",
    "fizik",
    "yazilim",
    "basketbol"
  ],

  "favoriteMusic": [
    "pop",
    "rock",
    "rap"
  ],

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎮 GAMIFICATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "gamification": {
    "level": 15,
    "xp": 4850,
    "nextLevelXp": 5000,
    "streak": 12,                           // Günlük giriş serisi
    "lastStreakDate": "2025-10-22",
    "totalStudyHours": 345,
    "achievementsBadges": [
      "first_post",
      "100_followers",
      "exam_master"
    ]
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ⚡ STATUS & ACTIVITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "status": {
    "isActive": true,
    "isDeleted": false,
    "isBanned": false,
    "isSuspended": false,

    // Ban/Suspension Details
    "bannedReason": null,
    "bannedUntil": null,
    "bannedBy": null,

    // Online Status
    "onlineStatus": "online",               // online, offline, away, busy
    "lastSeen": "2025-10-22T10:30:00Z",
    "lastActive": "2025-10-22T10:25:00Z"
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 DEVICE & SESSION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "device": {
    "platform": "ios",                      // ios, android, web
    "deviceId": "DEVICE_abc123",
    "deviceModel": "iPhone 14 Pro",
    "osVersion": "iOS 17.2",
    "appVersion": "1.1.3",
    "fcmToken": "FCM_TOKEN_xyz...",         // Push notification token
    "language": "tr",
    "locale": "tr_TR"
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔐 SECURITY & AUTH
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "security": {
    "signInMethod": "email",                // email, phone, google, apple
    "twoFactorEnabled": false,
    "lastPasswordChange": "2025-01-15T10:00:00Z",
    "loginAttempts": 0,                     // Rate limiting için
    "lastFailedLogin": null,
    "accountLocked": false,
    "lockedUntil": null
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎁 REFERRAL & REWARDS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "referral": {
    "code": "AHMET2025",                    // Kendi referral kodu
    "referredBy": null,                     // Kim davet etti (user ID)
    "referredCount": 5,                     // Kaç kişi davet etti
    "rewardPoints": 500
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔍 SEARCH & DISCOVERY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "_search": {
    "keywords": [
      "ahmet",
      "yilmaz",
      "ahmetyilmaz",
      "kadikoy",
      "yks",
      "2025"
    ],
    "fullText": "ahmet yilmaz kadikoy anadolu lisesi yks 2025"
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 TIMESTAMPS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "createdAt": "2024-01-15T09:00:00Z",
  "updatedAt": "2025-10-22T10:30:00Z",
  "lastLoginAt": "2025-10-22T08:15:00Z",

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏗️ METADATA
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "_metadata": {
    "version": 2,                           // Schema version
    "migrated": true,
    "migratedFrom": "users",
    "migratedAt": "2025-10-22T00:00:00Z"
  }
}
```

---

## 2. Private Subcollection

### 📁 `users/{userId}/private/profile`

**Amaç**: Hassas kişisel bilgiler (KVKK/GDPR uyumlu)
**Erişim**: Sadece kullanıcı kendisi
**Şifreleme**: TC, IBAN, Adres şifrelenmiş

```json
{
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🆔 PERSONAL IDENTITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "personalInfo": {
    "firstName": "Ahmet",
    "lastName": "Yılmaz",
    "birthDate": "2005-03-15",              // ISO date
    "age": 19,                              // Calculated
    "gender": "male",                       // male, female, other, prefer_not_to_say
    "nationality": "TR",
    "tcKimlikNo": "ENCRYPTED_12345678901",  // ⚠️ AES-256 Encrypted
    "tcVerified": true
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📞 CONTACT INFO (Detaylı)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "contactInfo": {
    "alternativeEmail": "ahmet.personal@gmail.com",
    "homePhone": "+902161234567",
    "parentPhone": "+905559876543",
    "whatsappNumber": "+905551234567",
    "emergencyContact": {
      "name": "Ayşe Yılmaz",
      "relation": "anne",
      "phone": "+905559876543"
    }
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏠 ADDRESS INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "address": {
    "current": {
      "country": "Turkey",
      "city": "Istanbul",
      "district": "Kadıköy",
      "neighborhood": "Fenerbahçe",
      "street": "ENCRYPTED_...",            // ⚠️ Encrypted
      "buildingNo": "ENCRYPTED_...",        // ⚠️ Encrypted
      "apartmentNo": "ENCRYPTED_...",       // ⚠️ Encrypted
      "zipCode": "34710",
      "fullAddress": "ENCRYPTED_..."        // ⚠️ Encrypted full address
    },

    "registration": {
      "city": "Istanbul",
      "district": "Üsküdar",
      "neighborhood": "Kısıklı"
    },

    "residence": {
      "city": "Istanbul",
      "district": "Kadıköy"
    }
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💰 FINANCIAL INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "financialInfo": {
    "ibanEncrypted": "ENCRYPTED_TR12...",   // ⚠️ AES-256 Encrypted
    "bankName": "Ziraat Bankası",
    "accountHolderName": "Ahmet Yılmaz",
    "branchCode": "1234",
    "accountNumber": "ENCRYPTED_...",       // ⚠️ Encrypted
    "currency": "TRY"
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 👨‍👩‍👧 FAMILY INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "familyInfo": {
    "totalMembers": 4,
    "householdIncome": "10000-15000",       // Range string
    "homeOwnership": "kira",                // kira, mulk, diger
    "livingInDormitory": false,

    "mother": {
      "firstName": "Ayşe",
      "lastName": "Yılmaz",
      "phone": "+905559876543",
      "occupation": "Öğretmen",
      "salary": "15000",
      "isAlive": true
    },

    "father": {
      "firstName": "Mehmet",
      "lastName": "Yılmaz",
      "phone": "+905551234567",
      "occupation": "Mühendis",
      "salary": "25000",
      "isAlive": true
    },

    "siblings": 1
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏥 HEALTH INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "healthInfo": {
    "bloodType": "A+",
    "allergies": ["Polen", "Fıstık"],
    "chronicDiseases": [],
    "specialNeeds": null,
    "disabilityReport": null,
    "isDisabled": false,
    "disabilityPercentage": 0
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 TIMESTAMPS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "createdAt": "2024-01-15T09:00:00Z",
  "updatedAt": "2025-10-22T10:30:00Z"
}
```

---

## 3. Education Subcollection

### 📁 `users/{userId}/education/current`

**Amaç**: Detaylı eğitim bilgileri
**Erişim**: Kullanıcı + Admin
**Güncellik**: Sık güncellenir

```json
{
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎓 CURRENT SCHOOL INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "academicInfo": {
    "educationLevel": "lise",               // ilkokul, ortaokul, lise, onlisans, lisans, yukseklisans, doktora
    "schoolType": "anadolu_lisesi",         // anadolu_lisesi, fen_lisesi, sosyal_bilimler, etc.
    "schoolName": "Kadıköy Anadolu Lisesi",
    "schoolCode": "KAD-AL-001",
    "schoolCity": "Istanbul",
    "schoolDistrict": "Kadıköy",

    // Grade & Class
    "grade": 12,                            // Sınıf
    "classSection": "A",                    // Şube
    "studentNumber": "2024001",
    "currentYear": "2024-2025",

    // GPA
    "gpa": 4.25,                            // 4.0 scale
    "gpaScale": 5.0,                        // Scale (4.0 or 5.0)
    "gpaPercentage": 85.0,                  // Yüzdelik
    "classRank": 3,                         // Sınıf sıralaması
    "gradeRank": 5                          // Genel sıralama
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📚 UNIVERSITY INFO (If applicable)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "universityInfo": {
    "universityName": null,
    "faculty": null,
    "department": null,
    "studentId": null,
    "educationType": null,                  // normal, ikinci_ogretim, uzaktan
    "enrollmentYear": null,
    "expectedGraduationYear": null
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📝 EXAM PREPARATION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "examPreparation": {
    "targetExam": "YKS",                    // LGS, YKS, KPSS, ALES, YDS, DGS, etc.
    "targetYear": 2025,
    "targetScore": 480.0,
    "currentMockScore": 425.5,
    "bestMockScore": 432.0,
    "averageMockScore": 420.0,
    "totalMockExamsTaken": 15,

    // Study Stats
    "studyHoursWeekly": 35,
    "lastStudyDate": "2025-10-22",
    "totalStudyHours": 345,
    "studyStreak": 12,                      // Günlük çalışma serisi

    // Target Universities
    "preferredUniversities": [
      {
        "universityName": "Boğaziçi Üniversitesi",
        "department": "Bilgisayar Mühendisliği",
        "faculty": "Mühendislik Fakültesi",
        "scoreType": "SAY",
        "requiredScore": 480.5,
        "priority": 1
      },
      {
        "universityName": "ODTÜ",
        "department": "Yazılım Mühendisliği",
        "faculty": "Mühendislik Fakültesi",
        "scoreType": "SAY",
        "requiredScore": 475.0,
        "priority": 2
      }
    ],

    // Exam Scores (if taken)
    "examScores": {
      "tyt": {
        "net": {
          "turkce": 35.5,
          "matematik": 38.0,
          "sosyal": 20.0,
          "fen": 18.5
        },
        "correct": 112,
        "wrong": 8,
        "empty": 0,
        "score": 450.5,
        "date": "2025-06-15"
      },
      "ayt": {
        "net": {
          "matematik": 38.0,
          "fizik": 12.5,
          "kimya": 11.0,
          "biyoloji": 10.0
        },
        "correct": 71,
        "wrong": 9,
        "empty": 0,
        "score": 480.5,
        "date": "2025-06-22"
      }
    },

    // Preferred Score Type
    "scoreType": "SAY",                     // SAY, EA, SOZ, DIL

    // Default Subject & Exam Type
    "defaultSubject": "Matematik",
    "defaultExamType": "TYT"
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📖 COURSES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "courses": {
    "enrolled": ["mat101", "fiz201", "kim101"],
    "completed": ["mat100", "fiz100", "kim100"],
    "inProgress": ["mat101", "fiz201"],
    "totalCompleted": 15,
    "totalCredits": 120
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🏆 ACHIEVEMENTS (Mini version - detay subcollection'da)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "achievementsSummary": {
    "totalAchievements": 12,
    "latestAchievements": [
      {
        "id": "ach_1",
        "type": "exam",
        "title": "TYT Deneme 1. Sıralama",
        "date": "2025-01-15",
        "score": 98.5
      }
    ]
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎯 LEARNING PREFERENCES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "learningPreferences": {
    "learningStyle": "visual",              // visual, auditory, kinesthetic
    "preferredStudyTime": "morning",        // morning, afternoon, evening, night
    "dailyGoalMinutes": 120,
    "weakSubjects": ["Fizik", "Kimya"],
    "strongSubjects": ["Matematik", "Türkçe"]
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 💡 SCHOLARSHIP INFO
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "scholarship": {
    "hasScholarship": true,
    "scholarshipProvider": "TurqApp Burs Programı",
    "scholarshipAmount": 5000,
    "scholarshipType": "tam_burs",          // tam_burs, yarim_burs, kismi_burs
    "canReceiveScholarship": true,
    "scholarshipApplications": [
      {
        "provider": "TurqApp",
        "status": "approved",
        "appliedAt": "2025-01-01",
        "approvedAt": "2025-01-15"
      }
    ]
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 EDUCATION HISTORY (Array of past schools)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "educationHistory": [
    {
      "level": "ortaokul",
      "schoolName": "Kadıköy Ortaokulu",
      "city": "Istanbul",
      "startYear": 2018,
      "endYear": 2022,
      "gpa": 4.5
    }
  ],

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 TIMESTAMPS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "createdAt": "2024-01-15T09:00:00Z",
  "updatedAt": "2025-10-22T10:30:00Z"
}
```

---

## 4. Settings Subcollection

### 📁 `users/{userId}/settings/preferences`

**Amaç**: Uygulama ayarları ve tercihler
**Erişim**: Sadece kullanıcı
**Cache**: Memory 30dk, Disk 7 gün

```json
{
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔔 NOTIFICATIONS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "notifications": {
    "push": {
      "enabled": true,
      "posts": true,
      "comments": true,
      "likes": true,
      "follows": true,
      "messages": true,
      "stories": true,
      "shorts": true,
      "examReminders": true,
      "studyReminders": true,
      "courseUpdates": true,
      "scholarships": true
    },

    "email": {
      "enabled": false,
      "weeklyDigest": false,
      "monthlyReport": false,
      "promotions": false,
      "productUpdates": false
    },

    "inApp": {
      "sound": true,
      "vibration": true,
      "badge": true,
      "banner": true
    },

    "quietHours": {
      "enabled": true,
      "startTime": "23:00",
      "endTime": "07:00"
    }
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🎨 APPEARANCE
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "appearance": {
    "theme": "dark",                        // light, dark, auto
    "accentColor": "blue",                  // blue, green, purple, red, orange
    "fontSize": "medium",                   // small, medium, large
    "fontFamily": "default",                // default, dyslexic-friendly
    "viewType": "modern"                    // classic, modern
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🌍 LANGUAGE & REGION
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "language": {
    "app": "tr",                            // tr, en
    "content": "tr",                        // Preferred content language
    "subtitles": "tr"
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📱 CONTENT PREFERENCES
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "content": {
    "autoplayVideos": true,
    "autoplayShorts": true,
    "showMatureContent": false,
    "showSensitiveContent": false,
    "dataUsage": "auto",                    // wifi-only, auto, always
    "videoQuality": "auto",                 // auto, low, medium, high, hd
    "feedAlgorithm": "personalized"         // chronological, personalized
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 🔐 PRIVACY SETTINGS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "privacy": {
    "shareAnalytics": false,
    "personalizedAds": false,
    "dataSharingThirdParty": false,
    "allowCookies": true
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ♿ ACCESSIBILITY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "accessibility": {
    "screenReader": false,
    "highContrast": false,
    "reducedMotion": false,
    "largeText": false,
    "hapticFeedback": true
  },

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // 📅 TIMESTAMPS
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  "updatedAt": "2025-10-22T10:30:00Z"
}
```

---

## 5. Interactions Subcollection

### 📁 `users/{userId}/interactions/blocked/{blockedUserId}`

**Amaç**: Scalable user interactions (Unbounded array yerine)
**Performans**: Query limit 1000, pagination ile sınırsız

```json
{
  "blockedUserId": "user_xyz789",
  "blockedAt": "2025-10-22T10:30:00Z",
  "reason": "spam",                         // spam, harassment, inappropriate

  // Denormalized user info (cache)
  "blockedUser": {
    "displayName": "Spam User",
    "username": "spamuser",
    "avatarUrl": "https://..."
  }
}
```

### 📁 `users/{userId}/interactions/muted/{mutedUserId}`

```json
{
  "mutedUserId": "user_xyz789",
  "mutedAt": "2025-10-22T10:30:00Z",
  "mutedUntil": null                        // null = permanent, timestamp = temporary
}
```

### 📁 `users/{userId}/interactions/saved/{savedItemId}`

```json
{
  "itemId": "post_abc123",
  "itemType": "post",                       // post, story, short, question
  "savedAt": "2025-10-22T10:30:00Z",
  "collectionId": "favorites",              // User-created collections

  // Denormalized item info
  "item": {
    "title": "YKS Matematik Formülleri",
    "thumbnailUrl": "https://...",
    "authorId": "user_xyz",
    "authorName": "Matematik Hoca"
  }
}
```

---

## 6. Stats Sharding

### 📁 `users/{userId}/stats/followers/shard_{0-9}`

**Amaç**: Distributed counters (Hot document problem çözümü)
**Shards**: 10 adet (write throughput 10x artar)

```json
{
  "count": 125,
  "lastUpdated": "2025-10-22T10:30:00Z"
}
```

**Toplam Hesaplama**:
```dart
// Cloud Function ile aggregate edilir, ana dokümana yazılır
final totalFollowers = await Future.wait(
  List.generate(10, (i) =>
    firestore.doc('users/$userId/stats/followers/shard_$i').get()
  )
).then((docs) =>
  docs.fold(0, (sum, doc) => sum + (doc.data()?['count'] ?? 0))
);
```

---

## 7. Denormalized Data

### 🎯 Post'larda Embedded User Data

**Amaç**: N+1 Query problemini çözmek
**Trade-off**: Çift yazma (Write amplification) vs Read performansı

```json
// posts/{postId} içinde
{
  "postId": "post_abc123",
  "content": "YKS hazırlık...",

  // ✅ Author bilgisi embed edilmiş (JOIN yok!)
  "author": {
    "userId": "user_abc123xyz",
    "displayName": "Ahmet Yılmaz",
    "username": "ahmetyilmaz",
    "avatarUrl": "https://storage.googleapis.com/.../thumb_abc123.jpg",
    "avatarThumbnail": "https://storage.googleapis.com/.../thumb_abc123.jpg",
    "verified": false,
    "badge": "gold",
    "role": "student"
  },

  "createdAt": "2025-10-22T10:30:00Z"
}
```

**Güncelleme Stratejisi**:
- User profil fotoğrafı değişince → Cloud Function tüm post'ları günceller
- Background job ile asenkron güncelleme
- Eventual consistency kabul edilir (1-2 saat delay)

---

## 📊 Performans Karşılaştırması

### Senaryo: Feed Yükleme (20 post)

| Metrik | Mevcut Yapı | Yeni Yapı | İyileşme |
|--------|-------------|-----------|----------|
| **Firestore Reads** | 20 post + 20 user = 40 | 20 post = 20 | **2x daha hızlı** |
| **Network Latency** | 200-500ms | 50-150ms | **4x daha hızlı** |
| **Data Transfer** | 500KB (20×25KB) | 100KB (20×5KB) | **5x daha az** |
| **Cache Hit Rate** | ~30% | ~80% | **2.5x daha iyi** |
| **Maliyet (100K user)** | $500-2000/ay | $150-500/ay | **4x daha ucuz** |

### Senaryo: Profil Yükleme

| Metrik | Mevcut Yapı | Yeni Yapı |
|--------|-------------|-----------|
| **İlk Yükleme** | 25KB (tüm veri) | 5KB (core data) |
| **Detay Yükleme** | - | +8KB (on-demand) |
| **Total (detay gerekirse)** | 25KB | 13KB |
| **Sonuç** | Hep yavaş | İlk hızlı, detay lazy |

---

## 🔍 Firestore Indexes

### Composite Indexes

```javascript
// firestore.indexes.json
{
  "indexes": [
    // Search by username
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "profile.username", "order": "ASCENDING" },
        { "fieldPath": "status.isActive", "order": "ASCENDING" }
      ]
    },

    // Discover users by reputation
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status.isActive", "order": "ASCENDING" },
        { "fieldPath": "stats.reputation", "order": "DESCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },

    // Search by location
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "location.city", "order": "ASCENDING" },
        { "fieldPath": "education.targetExam", "order": "ASCENDING" },
        { "fieldPath": "stats.reputation", "order": "DESCENDING" }
      ]
    },

    // Premium users
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "profile.accountType", "order": "ASCENDING" },
        { "fieldPath": "profile.premiumExpiresAt", "order": "ASCENDING" }
      ]
    }
  ],

  "fieldOverrides": [
    {
      "collectionGroup": "users",
      "fieldPath": "_search.keywords",
      "indexes": [
        { "order": "ASCENDING", "queryScope": "COLLECTION" },
        { "arrayConfig": "CONTAINS", "queryScope": "COLLECTION" }
      ]
    }
  ]
}
```

---

## 🔐 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 📁 Users Collection (Public profile)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    match /users/{userId} {
      // Read: Everyone (public profiles)
      allow read: if true;

      // Write: Owner only
      allow write: if request.auth != null
                   && request.auth.uid == userId
                   && !isBannedUser(userId);

      // Validate schema on write
      allow update: if request.auth != null
                    && request.auth.uid == userId
                    && validateUserUpdate(request.resource.data);

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🔒 Private Subcollection
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      match /private/{document=**} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🎓 Education Subcollection
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      match /education/{document=**} {
        allow read: if request.auth != null
                    && (request.auth.uid == userId || isAdmin());
        allow write: if request.auth != null
                     && request.auth.uid == userId;
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // ⚙️ Settings Subcollection
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      match /settings/{document=**} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🚫 Interactions Subcollection
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      match /interactions/{type}/{interactionId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📊 Stats Subcollection (Read-only for users)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      match /stats/{document=**} {
        allow read: if true;
        allow write: if false; // Only Cloud Functions can write
      }

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 📝 Activity Logs (Append-only)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      match /activity/{activityId} {
        allow read: if request.auth != null
                    && request.auth.uid == userId;
        allow create: if request.auth != null
                      && request.auth.uid == userId;
        allow update, delete: if false; // Immutable logs
      }
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 📇 Username Mapping (Unique usernames)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    match /usernames/{username} {
      allow read: if true;
      allow create: if request.auth != null
                    && !exists(/databases/$(database)/documents/usernames/$(username));
      allow delete: if request.auth != null
                    && get(/databases/$(database)/documents/usernames/$(username)).data.uid == request.auth.uid;
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // 🛠️ Helper Functions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    function isAdmin() {
      return request.auth != null
             && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.profile.role == 'admin';
    }

    function isBannedUser(userId) {
      return get(/databases/$(database)/documents/users/$(userId)).data.status.isBanned == true;
    }

    function validateUserUpdate(data) {
      // Kullanıcı kritik alanları değiştiremesin
      return data.userId == resource.data.userId
             && data.email == resource.data.email
             && data.createdAt == resource.data.createdAt;
    }
  }
}
```

---

## 🔄 Migration Stratejisi

### Phase 1: Yeni Koleksiyonu Oluştur (1 hafta)

```dart
// 1. Yeni schema'yı deploy et
// 2. Firestore indexes oluştur
// 3. Security rules güncelle
```

### Phase 2: Dual-Write Period (2 hafta)

```dart
// Hem eski (users) hem yeni (users) koleksiyonlarına yaz
Future<void> updateUser(String userId, Map<String, dynamic> data) async {
  await Future.wait([
    // Old collection
    firestore.collection('users').doc(userId).update(data),

    // New collection
    firestore.collection('users').doc(userId).update(data),
  ]);
}
```

### Phase 3: Background Migration (4 hafta)

```javascript
// Cloud Function: Tüm kullanıcıları migrate et
exports.migrateUsersToNewSchema = functions
  .runWith({ timeoutSeconds: 540, memory: '2GB' })
  .pubsub.schedule('every 1 hours')
  .onRun(async (context) => {
    const batch = firestore.batch();

    const oldUsers = await firestore
      .collection('Users')
      .where('_migrated', '==', false)
      .limit(100)
      .get();

    for (const doc of oldUsers.docs) {
      const oldData = doc.data();

      // Transform to new schema
      const newUserData = transformToNewSchema(oldData);

      batch.set(
        firestore.collection('users').doc(doc.id),
        newUserData
      );

      batch.update(doc.ref, { _migrated: true });
    }

    await batch.commit();
    console.log(`Migrated ${oldUsers.size} users`);
  });
```

### Phase 4: Switch Reads (1 hafta)

```dart
// Tüm read'leri yeni koleksiyona yönlendir
final user = await firestore.collection('users').doc(userId).get();
```

### Phase 5: Archive Old Collection (1 hafta)

```dart
// Eski koleksiyonu arşivle
// Backup al ve sil
```

---

## 🎯 Özet & Tavsiyeler

### ✅ Yapılması Gerekenler

1. **Şimdi**:
   - Bu schema'yı projeye ekle
   - Firestore indexes oluştur
   - Security rules güncelle

2. **1 Hafta İçinde**:
   - Flutter model classları yaz (freezed ile)
   - Repository pattern implementation
   - Cache layer (Hive/GetStorage)

3. **1 Ay İçinde**:
   - Migration script yaz
   - Dual-write başlat
   - Background migration Cloud Function

4. **2 Ay İçinde**:
   - Tüm read'leri yeni schema'ya geçir
   - Eski koleksiyonu arşivle
   - Performans testleri

### 🚀 Beklenen İyileşmeler

- **Performans**: 4x daha hızlı feed yükleme
- **Maliyet**: 4x daha ucuz Firestore maliyeti
- **Ölçeklenebilirlik**: Sınırsız interactions (unbounded array sorunu yok)
- **Güvenlik**: KVKK/GDPR uyumlu şifreli hassas veri
- **Bakım**: Modüler yapı, kolay genişletme

### 💡 Pro Tips

1. **Cache Aggressively**: Memory 5dk, Disk 24 saat
2. **Denormalize for Speed**: Post'larda user embed
3. **Shard Hot Counters**: Follower count 10 shard
4. **Lazy Load Heavy Data**: Education, private data on-demand
5. **Monitor Costs**: Firestore cost dashboard kur

---

## 📚 Sonraki Adımlar

1. ✅ Bu MD dosyasını projeye ekle
2. ⏳ Flutter model classları oluştur (freezed + json_serializable)
3. ⏳ Repository pattern tasarla
4. ⏳ Cache strategy implement et
5. ⏳ Migration script yaz

**Hazır mısın?** Şimdi Flutter model classlarını oluşturalım mı? 🚀
