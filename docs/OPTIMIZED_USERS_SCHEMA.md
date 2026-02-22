# 🚀 Optimized Users Collection Schema

**Hedef:** Instagram/Twitter/TikTok seviyesinde performans ve kullanıcı deneyimi

## 🎯 Performans Hedefleri

| Metrik | Hedef | Mevcut Durum |
|--------|-------|--------------|
| **Hot Path Read** | <60ms | ~800ms |
| **Document Size (Hot)** | <5KB | 1-2MB |
| **Document Size (Cold)** | <3KB | - |
| **Shard Size** | <1KB | - |
| **Write Amplification** | Kabul edilebilir | Yüksek |
| **Eventual Consistency** | <5s | - |

## 📐 Mimari Prensipler

1. **Separation of Concerns**: Hot (sık kullanılan) ve cold (nadir kullanılan) data ayrımı
2. **PII Protection**: Kişisel bilgiler ayrı subcollection'da
3. **Read Optimization**: Denormalize edilmiş sayaçlar
4. **Write Amplification Trade-off**: Okuma hızı için yazma maliyeti kabul edilebilir
5. **Schema Versioning**: Client contract güvencesi

---

## 🗂️ Collection Yapısı (Genel Bakış)

```
Firestore
├── users/{uid}                                    # HOT: Feed/Profile rendering
│   ├── private/                                   # COLD: PII & sensitive data
│   │   └── profile                                # Kişisel bilgiler
│   ├── education/                                 # COLD: Eğitim geçmişi
│   │   ├── {entryId}                              # YKS, TYT, üniversite
│   │   └── ...
│   ├── relationships/                             # WARM: Sosyal ilişkiler
│   │   ├── {otherUserId}                          # block, mute, close_friend
│   │   └── ...
│   ├── stats/                                     # HOT: Distributed counters
│   │   ├── shard_0                                # Counter shard
│   │   ├── shard_1
│   │   └── ... (10 shards total)
│   └── auditTrail/                                # COLD: Security logs
│       ├── {eventId}                              # Login, device, moderation
│       └── ...
│
└── usernames/{handle}                             # Handle → UID mapping
    └── { uid: "user_9r7h3" }
```

---

## 📄 1. `users/{uid}` - Hot Document (Primary Profile)

**Amaç:** Feed, profil, mesajlaşma gibi hot path'lerde ultra-hızlı okuma

**Boyut:** ~4-5KB

### JSON Schema

```json
{
  "uid": "user_9r7h3",
  "handle": "ahmety",
  "displayName": "Ahmet Yılmaz",

  "avatar": {
    "full": "gs://turqapp/users/ahmety/avatar_1024.jpg",
    "thumb": "gs://turqapp/users/ahmety/avatar_256.jpg",
    "blurHash": "LFE.@D9F01_2%LRjxuxu00"
  },

  "headline": "YKS 2025 • Bilgisayar Mühendisi adayı",
  "bio": "STEM tutkunu, mentor arıyorum. 🚀",

  "badges": ["verified_candidate", "mentor_ready", "early_adopter"],

  "account": {
    "role": "student",              // student | mentor | ambassador | admin
    "tier": "plus",                 // free | plus | elite
    "verified": true,
    "verifiedAt": "2025-01-12T09:45:32Z",
    "createdAt": "2024-06-18T08:01:12Z"
  },

  "engagement": {
    "followers": 1820,
    "following": 322,
    "posts": 94,
    "reactions": 12840,             // Total likes received
    "lastActiveAt": "2025-02-03T12:21:45Z"
  },

  "preferences": {
    "language": "tr",
    "timezone": "Europe/Istanbul",
    "theme": "dark",                // light | dark | system
    "dmPolicy": "followers",        // everyone | followers | none
    "mentionPolicy": "everyone",    // everyone | followers | none
    "showOnlineStatus": true
  },

  "discoverability": {
    "searchable": true,
    "geoHash": "sxk3k",             // 5-char geohash for privacy
    "primaryTags": ["yks", "bilgisayar", "sayisal"],
    "interests": ["programlama", "matematik", "fizik"]
  },

  "safety": {
    "status": "active",             // active | suspended | banned | shadow
    "strikeCount": 0,
    "riskLevel": "low",             // low | medium | high
    "moderationNotes": ""
  },

  "metadata": {
    "schemaVersion": 3,
    "updatedAt": "2025-02-03T12:21:45Z"
  }
}
```

### Dart Model Örneği

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String uid,
    required String handle,
    required String displayName,
    required AvatarData avatar,
    required String headline,
    required String bio,
    required List<String> badges,
    required AccountInfo account,
    required EngagementStats engagement,
    required UserPreferences preferences,
    required DiscoverabilitySettings discoverability,
    required SafetyStatus safety,
    required Metadata metadata,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile.fromJson(data);
  }
}

@freezed
class AvatarData with _$AvatarData {
  const factory AvatarData({
    required String full,
    required String thumb,
    required String blurHash,
  }) = _AvatarData;

  factory AvatarData.fromJson(Map<String, dynamic> json) =>
      _$AvatarDataFromJson(json);
}

@freezed
class EngagementStats with _$EngagementStats {
  const factory EngagementStats({
    required int followers,
    required int following,
    required int posts,
    required int reactions,
    required DateTime lastActiveAt,
  }) = _EngagementStats;

  factory EngagementStats.fromJson(Map<String, dynamic> json) =>
      _$EngagementStatsFromJson(json);
}

// ... (Diğer nested models)
```

---

## 🔒 2. `users/{uid}/private/profile` - Cold Document (PII)

**Amaç:** KVKK/GDPR uyumlu kişisel bilgi saklama

**Boyut:** ~2-3KB

**Güvenlik:**
- Sadece kullanıcı ve admin erişebilir
- Firestore Rules ile korunur
- Optional: Cloud Functions ile encryption

### JSON Schema

```json
{
  "contact": {
    "email": "ahmet@example.com",
    "emailVerified": true,
    "phone": "+905551234567",
    "phoneVerified": true,
    "alternativeEmail": "ahmet.yilmaz@gmail.com",
    "guardianPhone": "+905559876543"
  },

  "identity": {
    "firstName": "Ahmet",
    "lastName": "Yılmaz",
    "birthDate": "2005-03-15",
    "gender": "male",                    // male | female | other | prefer_not_to_say
    "nationalIdHash": "sha256:abc...",   // NEVER store plaintext
    "maritalStatus": "single"
  },

  "address": {
    "country": "Turkey",
    "city": "İstanbul",
    "district": "Kadıköy",
    "fullAddress": "Encrypted via Cloud Functions",
    "postalCode": "34710",
    "geoPoint": {
      "lat": 40.9922,
      "lon": 29.0256
    }
  },

  "financial": {
    "ibanTokenized": "TR12****4567",    // Tokenized, not full IBAN
    "bankName": "Ziraat Bankası",
    "accountHolderName": "Ahmet Yılmaz"
  },

  "family": {
    "motherName": "Ayşe Yılmaz",
    "motherPhone": "+905551111111",
    "fatherName": "Mehmet Yılmaz",
    "fatherPhone": "+905552222222",
    "householdIncome": "middle",        // low | middle | high | prefer_not_to_say
    "housingType": "owned"               // rented | owned | dormitory
  },

  "consents": {
    "marketing": true,
    "research": false,
    "dataSharing": false,
    "parentalConsent": true,
    "consentDate": "2024-06-18T08:01:12Z"
  },

  "metadata": {
    "schemaVersion": 2,
    "createdAt": "2024-06-18T08:01:12Z",
    "updatedAt": "2025-02-03T12:21:45Z"
  }
}
```

### Firestore Security Rules

```javascript
match /users/{userId}/private/{document=**} {
  allow read, write: if request.auth.uid == userId;
  allow read: if request.auth.token.admin == true;
}
```

---

## 🎓 3. `users/{uid}/education/{entryId}` - Cold Collection

**Amaç:** Eğitim geçmişi, sınav sonuçları, kurslar

**Lazy Loading:** Sadece profil → eğitim sekmesine tıklandığında yüklenir

### JSON Schema

```json
{
  "type": "exam",                      // school | exam | course | award | certification
  "title": "TYT 2024",
  "institution": "ÖSYM",
  "startDate": "2024-06-15",
  "endDate": "2024-06-16",

  "score": {
    "raw": 481.75,
    "percentile": 94,
    "rank": 12340
  },

  "subjects": [
    { "name": "Matematik", "correct": 38, "wrong": 2, "empty": 0 },
    { "name": "Fizik", "correct": 12, "wrong": 2, "empty": 0 }
  ],

  "tags": ["sayisal", "tyt"],
  "visibility": "followers",           // public | followers | private

  "metadata": {
    "createdAt": "2024-06-20T09:14:00Z",
    "updatedAt": "2024-06-20T09:14:00Z"
  }
}
```

### Örnek Sorgu

```dart
// Sadece eğitim sekmesi açıldığında çağrılır
Stream<List<EducationEntry>> getUserEducation(String uid) {
  return FirebaseFirestore.instance
      .collection('users/$uid/education')
      .orderBy('endDate', descending: true)
      .limit(20)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => EducationEntry.fromFirestore(doc))
          .toList());
}
```

---

## 👥 4. `users/{uid}/relationships/{otherUserId}` - Warm Collection

**Amaç:** Block, mute, close friends yönetimi

**Avantajı:** Kullanıcıya özel Security Rules yazılabilir

### JSON Schema

```json
{
  "type": "blocked",                   // blocked | muted | closeFriend
  "since": "2025-01-15T14:22:10Z",
  "reason": "spam",                    // spam | harassment | inappropriate | other
  "notes": "User reported for spam messages",

  "metadata": {
    "createdAt": "2025-01-15T14:22:10Z",
    "updatedAt": "2025-01-15T14:22:10Z"
  }
}
```

### Firestore Security Rules

```javascript
match /users/{userId}/relationships/{otherUserId} {
  allow read, write: if request.auth.uid == userId;

  // Engellenmiş kullanıcılar birbirlerini göremez
  allow read: if request.auth.uid == otherUserId &&
                 !exists(/databases/$(database)/documents/users/$(userId)/relationships/$(otherUserId));
}
```

---

## 📊 5. `users/{uid}/stats/shard_{0-9}` - Distributed Counters

**Amaç:** Yüksek yazma yükünde counter tutarlılığı (Instagram/Twitter pattern)

**Problem:** 1000 kişi aynı anda beğenirse tek document'a 1000 yazma → conflict
**Çözüm:** 10 shard'a dağıt, Cloud Function ile aggregate et

### JSON Schema

```json
{
  "followers": 182,                    // Bu shard'ın payı
  "following": 32,
  "reactions": 1284,
  "posts": 9,

  "lastUpdated": "2025-02-03T12:21:45Z"
}
```

### Cloud Function (Aggregation)

```typescript
// functions/src/aggregateStats.ts
export const aggregateUserStats = functions.firestore
  .document('users/{userId}/stats/{shardId}')
  .onWrite(async (change, context) => {
    const userId = context.params.userId;

    // 10 shard'ı topla
    const shardsSnapshot = await admin.firestore()
      .collection(`users/${userId}/stats`)
      .get();

    let totalFollowers = 0;
    let totalFollowing = 0;
    let totalReactions = 0;
    let totalPosts = 0;

    shardsSnapshot.forEach((doc) => {
      const data = doc.data();
      totalFollowers += data.followers || 0;
      totalFollowing += data.following || 0;
      totalReactions += data.reactions || 0;
      totalPosts += data.posts || 0;
    });

    // Ana dökümana yaz
    await admin.firestore().doc(`users/${userId}`).update({
      'engagement.followers': totalFollowers,
      'engagement.following': totalFollowing,
      'engagement.reactions': totalReactions,
      'engagement.posts': totalPosts,
    });
  });
```

### Dart Helper (Write)

```dart
import 'dart:math';

class CounterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  Future<void> incrementFollowerCount(String userId) async {
    // Rastgele shard seç (0-9)
    final shardId = 'shard_${_random.nextInt(10)}';

    await _firestore
        .collection('users/$userId/stats')
        .doc(shardId)
        .set({
          'followers': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    // Cloud Function otomatik aggregate eder
  }
}
```

---

## 🔐 6. `users/{uid}/auditTrail/{eventId}` - Audit Logs

**Amaç:** Güvenlik, compliance, moderasyon için log tutma

**Retention:** 30 gün (Cloud Scheduler ile otomatik temizlik)

### JSON Schema

```json
{
  "event": "login",                    // login | password_change | profile_update | suspension
  "timestamp": "2025-02-03T08:15:30Z",
  "ipAddress": "176.42.123.45",
  "userAgent": "TurqApp/1.1.3 (iOS 17.2; iPhone 14 Pro)",
  "device": {
    "type": "mobile",
    "os": "iOS",
    "version": "17.2",
    "deviceId": "device_abc123"
  },
  "location": {
    "city": "İstanbul",
    "country": "Turkey",
    "geoHash": "sxk3k"
  },
  "metadata": {
    "notes": "Successful login via email"
  }
}
```

---

## 🔗 7. `usernames/{handle}` - Handle → UID Mapping

**Amaç:** Handle benzersizliği ve hızlı lookup

### JSON Schema

```json
{
  "uid": "user_9r7h3",
  "createdAt": "2024-06-18T08:01:12Z"
}
```

### Firestore Security Rules

```javascript
match /usernames/{handle} {
  allow read: if true;  // Public lookup

  allow create: if request.auth != null &&
                   request.resource.data.uid == request.auth.uid &&
                   !exists(/databases/$(database)/documents/usernames/$(handle));

  allow update, delete: if false;  // Handle değişikliği Cloud Function ile
}
```

---

## 🚀 Performans Optimizasyonları

### 1. Caching Strategy

```dart
class UserProfileCache {
  final Duration _cacheExpiration = Duration(minutes: 5);
  final Map<String, CachedProfile> _cache = {};

  Future<UserProfile> getProfile(String uid) async {
    final cached = _cache[uid];

    if (cached != null && !cached.isExpired) {
      return cached.profile;
    }

    final profile = await _fetchFromFirestore(uid);
    _cache[uid] = CachedProfile(profile, DateTime.now());
    return profile;
  }
}
```

### 2. Composite Indexes

```javascript
// firestore.indexes.json
{
  "indexes": [
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "discoverability.primaryTags", "arrayConfig": "CONTAINS" },
        { "fieldPath": "engagement.followers", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "users",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "account.role", "order": "ASCENDING" },
        { "fieldPath": "safety.status", "order": "ASCENDING" },
        { "fieldPath": "metadata.updatedAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```

### 3. Offline Support

```dart
void enableOfflinePersistence() {
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}
```

---

## 📏 Boyut Karşılaştırması

| Collection | Önceki Boyut | Yeni Boyut | İyileşme |
|------------|--------------|------------|----------|
| **users/{uid}** (Hot) | 1-2MB | ~4KB | **99.6%** ⬇️ |
| **private/profile** | - | ~2KB | - |
| **education/{id}** | - | ~1KB | - |
| **relationships/{id}** | - | 500B | - |
| **stats/shard_{0-9}** | - | 200B | - |

---

## 🔄 Migration Stratejisi

### Adım 1: Mevcut "users" Collection'ını Oku

```dart
Future<void> migrateUser(String uid) async {
  final oldDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  final oldData = oldDoc.data()!;

  // ... transform logic
}
```

### Adım 2: Yeni Schema'ya Transform Et

```dart
UserProfile transformToNewSchema(Map<String, dynamic> oldData) {
  return UserProfile(
    uid: oldData['userID'],
    handle: oldData['nickname'],
    displayName: '${oldData['firstName']} ${oldData['lastName']}',
    // ... mapping logic
  );
}
```

### Adım 3: Yeni Collection'a Yaz

```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .set(newProfile.toJson());
```

---

## ✅ Checklist: Production Hazırlığı

- [ ] Firestore Security Rules tamamlandı
- [ ] Composite Indexes oluşturuldu
- [ ] Cloud Functions deploy edildi
- [ ] Dart Freezed models generate edildi
- [ ] Caching layer implement edildi
- [ ] Offline persistence aktif
- [ ] Migration script test edildi
- [ ] Rollback planı hazır
- [ ] Performance monitoring kuruldu
- [ ] KVKK/GDPR compliance check yapıldı

---

## 🎓 Best Practices

1. **ASLA plaintext şifre saklama** → Firebase Auth kullan
2. **Hot document'ı küçük tut** → <5KB
3. **PII'ı ayrı subcollection'da tut** → Güvenlik
4. **Distributed counters kullan** → Yüksek yazma yükü için
5. **Schema versioning yap** → Migration kolaylığı
6. **Freezed ile immutable models** → Type safety
7. **Cache aggressively** → Firestore read maliyeti düşsün

---

**Hazırlayan:** Claude (Senior Flutter/Firebase Architect)
**Tarih:** 2025-02-03
**Versiyon:** 1.0
**İletişim:** Sorular için GitHub issue açın
