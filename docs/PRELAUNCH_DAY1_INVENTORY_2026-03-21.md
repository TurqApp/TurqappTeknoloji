# Pre-launch Day 1 Inventory

Tarih: 2026-03-21
Proje: TurqApp
Amac: Master planin Day 1 teslimlerini repo gercegi ile netlestirmek

## 1. Ozet

Ilk tarama sonucu su net:

- Mimari semantik olarak `userId + nickname + displayName` yonune gitmek istiyor.
- Fiziksel veri ve istemci kodu halen `userID`, `username`, `followerCount/followersCount` gibi compatibility alanlari tasiyor.
- Kritik write yuzeyi tam merkezilesmemis.
- Notification uretimi halen birden fazla istemci noktasindan yapiliyor.
- DM tarafinda root conversation map'leri ile user override koleksiyonlari birlikte kullaniliyor.
- GetX tarafinda en riskli alanlar current user, feed, notification, sign-in ve deep link ekseninde toplanmis.

Bu nedenle ilk implementasyon sprintinde hedef:

- buyuk field rename degil
- ownership ve davranis standardi
- write boundary daraltma
- rules, notifications ve feed tarafinda kontrollu sertlestirme

## 2. Canonical Veri Kontrati

### 2.1 Kullanici semantigi

Hedef canonical semantik:

- `userId`
- `nickname`
- `nicknameLower`
- `displayName`

Repo gercegi:

- `CurrentUserModel` halen `userID` kullaniyor
- `UserSummary` halen hem `nickname` hem `username` tasiyor
- `StoredAccount` halen `uid` + `username` tasiyor

Etkilenen dosyalar:

- `lib/Models/current_user_model.dart`
- `lib/Models/stored_account.dart`
- `lib/Core/Repositories/user_repository.dart`

Karar:

- Ilk sprintte fiziksel field rename yok
- Semantik canonical tablo net
- Compatibility alanlari kontrollu olarak tasinacak

### 2.2 Post semantigi

Hedef:

- `Posts/{postId}` source of truth olarak kalir
- feed/search icin read-model katmanlari korunur

Repo gercegi:

- `PostsModel` halen `userID` tasiyor
- Denormalized author alanlari zaten mevcut:
  - `authorNickname`
  - `authorDisplayName`
  - `authorAvatarUrl`
- `stats` map zorunlu mantikla kullaniliyor

Etkilenen dosyalar:

- `lib/Models/posts_model.dart`
- `lib/Core/Repositories/post_repository.dart`
- `functions/src/hybridFeed.ts`
- `functions/src/authorDenorm.ts`

Karar:

- Post modeli rewrite edilmeyecek
- Feed/search hydration ownership'i netlestirilecek

### 2.3 Notification semantigi

Hedef:

- `users/{userId}/notifications/{notificationId}` korunur
- event production ile inbox item production ayrilir

Repo gercegi:

- Notification inbox repository net:
  - `lib/Core/Repositories/notifications_repository.dart`
- Ancak inbox'a dogrudan yazan client akislari halen var

Karar:

- Yeni inbox collection acilmayacak
- Notification uretimi backend merkezli hale getirilecek

### 2.4 DM semantigi

Hedef:

- `conversations/{conversationId}` + `messages`
- root summary davranisi korunur
- archive/delete/read ownership'i netlesir

Repo gercegi:

- root conversation map alanlari var:
  - `unread`
  - `archived`
  - `pinned`
  - `muted`
- buna ek olarak user override koleksiyonlari var:
  - `users/{uid}/chatArchives`
  - `users/{uid}/chatDeletions`

Etkilenen dosya:

- `lib/Core/Repositories/conversation_repository.dart`

Karar:

- Cift yapinin davranisi netlestirilecek
- Ilk sprintte bu yapi kaldirilmiyor

## 3. Sensitive Write Inventory

### 3.1 Backend kontrollu olanlar

Su alanlarda function/callable kullanimi zaten mevcut:

- report submit/review
- nickname degistirme
- ban / badge admin
- bazi feed backfill akislari
- email / phone verification yardimci akislari

Etkilenen dosyalar:

- `lib/Core/Repositories/report_repository.dart`
- `lib/Modules/Profile/EditorNickname/editor_nickname_controller.dart`
- `lib/Modules/Profile/Settings/admin_approvals_view.dart`
- `functions/src/24_reports.ts`
- `functions/src/26_userBanAdmin.ts`
- `functions/src/27_nicknameChange.ts`
- `functions/src/22_badgeAdmin.ts`

Yorum:

- Bu alanlar hedef mimariye daha yakin
- Asil acik kalan yuzey client-side direct write tarafinda

### 3.2 Halen client-side direct write yapan kritik alanlar

#### Follow

`lib/Core/follow_service.dart`

- `users/{current}/followings/{other}`
- `users/{other}/followers/{current}`
- transaction ile client'tan yaziliyor
- local `AgendaController.followingIDs` de dogrudan mutasyona ugruyor

Risk:

- rules sertlestiginde kirilma
- social graph ve counter senkron sapmasi
- business rule daginikligi

#### Post interaction

`lib/Services/post_interaction_service.dart`

- likes / saves / reshares / comments / reports status
- post alt koleksiyonlari ve user alt koleksiyonlari birlikte yurutuluyor
- notification uretimi de bu servis icinde client tarafindan yapiliyor

Risk:

- duplicate side effect
- write fan-out
- notification spam / dedup eksigi

#### Notification direct writers

Bu dosyalar inbox'a dogrudan yaziyor:

- `lib/Services/post_interaction_service.dart`
- `lib/Core/Services/market_notification_service.dart`
- `lib/Core/Repositories/job_repository.dart`
- `lib/Core/Repositories/tutoring_repository.dart`
- `lib/Core/Repositories/admin_push_repository.dart`

Risk:

- inbox uretimi tek policy'de toplanmiyor
- bundle/dedup davranisi dagiliyor

#### Offline mode side effects

`lib/Services/offline_mode_service.dart`

- liked_posts
- saved_posts
- comments
- followers/followings

Risk:

- online/offline write ownership'i ayri policy'ye bagli degil

### 3.3 Ilk P0 hedef write boundary listesi

Ilk dalgada backend-first veya service policy-first hale getirilmesi gerekenler:

1. notification production
2. follow/unfollow
3. post like/save/reshare side effects
4. moderation/report side effects

## 4. Privacy / Visibility Enforcement Bulgu Ozeti

Ilk taramadan gorunen durum:

- private hesap, block ve mute mantigi birden fazla yuzeyde ayri ayri ele aliniyor
- search, feed, profile ve deep link tarafinda tek policy katmani henuz yok

En riskli yuzeyler:

- `lib/Modules/Agenda/agenda_controller.dart`
- `lib/Modules/Explore/explore_controller.dart`
- `lib/Core/Services/deep_link_service.dart`
- `lib/Modules/Short/short_controller.dart`

Ilk hedef:

- visibility kararini tek bir service/policy katmanina toplamak
- UI seviyesinde sadece sonucu tuketmek

## 5. GetX Sorumluluk Hotspotlari

Satir sayisi ve sorumluluk yogunluguna gore ilk riskli moduller:

- `lib/Services/current_user_service.dart` -> 954 satir
- `lib/Modules/Agenda/agenda_controller.dart` -> 616 satir
- `lib/Core/Services/deep_link_service.dart` -> 575 satir
- `lib/Modules/InAppNotifications/in_app_notifications_controller.dart` -> 490 satir
- `lib/Modules/SignIn/sign_in_controller.dart` -> 445 satir
- `lib/Modules/Chat/chat_controller.dart` -> 236 satir

Yorum:

- Sorun tek basina satir sayisi degil
- state, side effect, cache ve navigation kararlarinin ayni yerde toplanmasi

Ilk refactor hedefleri:

1. `CurrentUserService`
2. `AgendaController`
3. `Notifications`
4. `SignIn`
5. `DeepLinkService`

## 6. Day 1 Sonucu Olarak Secilecek Ilk P0 Is

Repo bulgularina gore ilk uygulanabilir P0 kod isi:

### Onerilen ilk is

`P0-3 Notification sertlestirme`

Sebep:

- zaten repository omurgasi var
- client-side daginik write source sayisi fazla
- launch oncesi maliyet, spam ve tutarsizlik riski yuksek
- follow/feed kadar genis capli olmayan, ama hizli fayda uretecek bir sertlestirme alani

### Hemen arkasindan

1. `P0-2 Sensitive write boundary` icinde follow/write ownership
2. `P0-4 Feed ve visibility disiplini`
3. `P0-5 GetX ilk sorumluluk ayrimi`

## 7. Acik Notlar

- `userId` canonical semantik karari korunuyor; repo icinde bugun `userID` halen aktif
- `username` field'i halen compatibility ve local account secimi tarafinda tasiniyor
- `followerCount` ve `followersCount` birlikte goruluyor
- ilk sprintte migration/backfill yerine ownership ve policy standardi kurulacak
