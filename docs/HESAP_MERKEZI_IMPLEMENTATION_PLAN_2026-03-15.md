# Hesap Merkezi Implementation Plan

Tarih: 15 Mart 2026
Durum: Planlandi, henuz kodlanmadi
Kapsam: TurqApp icinde ayni cihazda daha once giris yapilmis hesaplar arasinda login ekranina geri donmeden guvenli hesap gecisi

## Amac

Bu planin hedefi, kullanicinin ayni cihazdaki birden fazla hesabini tek bir "Hesap Merkezi" altinda yonetmesini saglamaktir. Kullanici:

- Son aktif hesapla uygulamayi acabilmeli
- Daha once bu cihazda kullanilmis hesaplari gorebilmeli
- Uygulamadan cikis yapmadan hesaplar arasinda gecis yapabilmeli
- Gerekirse hesabi cihazdan kaldirabilmeli
- Tum hesaplardan cikis yapabilmeli

Bu akista "yeni hesap ekleme" her zaman normal login akisi olarak kalir. Hedef, mevcut oturumlari cihaz bazli tekrar kullanilabilir hale getirmektir; auth mantigini by-pass etmek degil, session restore akisini urunlestirmektir.

## Urun Kapsami

Ilk surumde desteklenecek davranis:

- Bu cihazda daha once basarili giris yapmis hesaplar listelenir
- Son aktif hesap uygulama acilisinda otomatik restore edilir
- Hesap secildiginde hizli gecis denenir
- Hizli gecis basarisizsa mini re-auth akisi acilir
- Hesap cihazdan kaldirildiginda sadece local hizli gecis kaydi silinir
- Tum hesaplardan cikis yapildiginda local session kayitlari temizlenir ve aktif auth oturumu kapatilir

Ilk surumde kapsam disi birakilacak konular:

- Ayni anda birden fazla hesabin paralel aktif kalmasi
- Hesap birlestirme
- Sunucu tarafli tam kapsamli anti-abuse karar motoru
- Web panelden uzaktan cihaz temizleme

## Basari Kriterleri

- Kullanici login ekranina donmeden daha once kayitli hesaba gecebilir
- Hesap degisimi sirasinda onceki kullanicinin feed, profil, chat veya notification verisi ekranda kalmaz
- Session restore orani olculebilir hale gelir
- Hesap gecisi nedeniyle auth, FCM veya cache tutarsizligi olusmaz
- Ayni cihazdaki hesap listesi guvenli sekilde saklanir
- Riskli veya suresi dolmus oturumlarda mini re-auth zorunlu olur

## Temel Tasarim Ilkeleri

- Telefon numarasi hesabin kendisi degil, kimlik saglayicilardan biridir
- Device ve account iliskisi ayri modellenir
- Kullaniciya ait operasyonel veri user altinda tutulur
- Cihazlar arasi ve kullanicilar arasi analiz gerektiren veri top-level tutulur
- Local metadata ile secure session verisi ayri saklanir
- Hesap degisimi sadece auth degil, tum app state reset akisidir

## Terminoloji

- Account: Firestore `users/{uid}` altindaki kullanici
- Provider: phone, email, google, apple gibi giris yontemi
- Device: uygulamanin calistigi fiziksel cihaz
- Device session: belli bir kullanici ile belli bir cihaz arasindaki oturum kaydi
- Stored account: cihazda listelenecek hafif hesap metadata kaydi
- Session restore: mevcut kullaniciyi tekrar login ekranina goturmeden aktif auth durumuna getirme
- Mini re-auth: tam login ekrani yerine o hesap icin kisa dogrulama

## Firestore Veri Modeli

### 1. users/{uid}

Kullanicinin ana profili. Hesap secicide hizli goruntulenecek alanlar burada veya optimize edilmis profile view altinda olmalidir.

Onerilen alanlar:

- `username`
- `displayName`
- `photoUrl`
- `isVerified`
- `isPrivate`
- `accountState`
- `lastActiveAt`
- `primaryProvider`

Not:
Bu dokuman mevcut kullanici semasini tamamen yeniden yazmaz. Hesap Merkezi sadece secici ve session mantigi icin gereken alanlari belirler.

### 2. users/{uid}/linkedProviders/{providerId}

Amac:
Kullanicinin bagli giris saglayicilarini tutmak.

Onerilen alanlar:

- `providerType`: `phone`, `email`, `google`, `apple`
- `providerUid`
- `maskedPhone`
- `email`
- `linkedAt`
- `lastVerifiedAt`
- `isPrimary`
- `status`

Neden alt koleksiyon:
Bu veri dogrudan kullaniciya aittir ve cogu zaman sadece o kullanicinin ayarlar veya guvenlik ekraninda okunur.

### 3. users/{uid}/deviceSessions/{sessionId}

Amac:
Bu kullaniciya ait cihaz oturumlarini tutmak.

Onerilen alanlar:

- `deviceId`
- `providerType`
- `sessionState`: `active`, `expired`, `revoked`, `reauth_required`
- `createdAt`
- `lastUsedAt`
- `expiresAt`
- `requiresReauth`
- `revokedReason`
- `appVersion`
- `platform`
- `lastRefreshAt`
- `riskSnapshot`

Neden alt koleksiyon:
"Bu kullanicinin cihazlari" veya "bu kullanicinin aktif oturumlari" ekranlari icin dogal model budur.

### 4. devices/{deviceId}

Amac:
Cihaz bazli merkezi kayit.

Onerilen alanlar:

- `platform`
- `platformVersion`
- `appVersion`
- `firstSeenAt`
- `lastSeenAt`
- `status`
- `riskScore`
- `accountCount`
- `lastKnownCountry`
- `lastKnownIpHash`
- `appCheckState`

Neden top-level:
Bir telefonla kac hesap acildi, cihaz cluster'i, ban evasion ve admin analizi gibi sorgular user altinda verimli degildir.

### 5. devices/{deviceId}/accounts/{uid}

Amac:
Bu cihazda gorulmus hesaplarin cihaz tarafli index'i.

Onerilen alanlar:

- `firstLinkedAt`
- `lastUsedAt`
- `status`
- `providerTypes`
- `sessionCount`
- `riskFlag`

Neden gerekli:
Sadece `users/{uid}/deviceSessions` ile gidersen ayni cihazdaki hesap kumelerini sonradan cikarmak maliyetli olur. Bu alt koleksiyon cihaz merkezli sorguyu ucuzlatir.

### 6. loginEvents/{eventId}

Amac:
Global login denemeleri, session restore basarisi ve hata analizi.

Onerilen alanlar:

- `uid`
- `deviceId`
- `providerType`
- `flowType`: `full_login`, `account_switch`, `silent_restore`, `mini_reauth`
- `result`: `success`, `failure`
- `errorCode`
- `createdAt`

Neden top-level:
Global analiz, alarm ve oransal raporlama gerektirir.

### 7. riskEvents/{eventId}

Amac:
Cihaz, kullanici ve oturum kaynakli supheli davranis olaylari.

Onerilen alanlar:

- `uid`
- `deviceId`
- `type`
- `severity`
- `context`
- `createdAt`
- `status`

### 8. accountClusters/{clusterId}

Amac:
Ayni cihaz, benzer network izi veya davranis paterni ile iliskili hesap kumeleri.

Bu ilk release'te zorunlu degil ancak orta vadede anti-abuse gorunurlugu icin onemli.

## Local Storage Modeli

Hesap Merkezi iki katmanli local storage kullanmalidir.

### 1. SharedPreferences veya benzeri hafif local store

Burada saklanacaklar:

- hesap listesi metadata
- aktif hesap `uid`
- son kullanilan hesap
- UI durum bayraklari

Burada saklanmayacaklar:

- ham auth token
- password
- hassas provider credential

### 2. Secure storage

Burada saklanacaklar:

- provider restore payload
- session restore anahtarlari
- device-bound custom session referanslari
- reauth gereksinimi bayraklari

Onerilen key yapisi:

- `account_center.active_uid`
- `account_center.accounts`
- `account_session.<uid>.provider`
- `account_session.<uid>.session_id`
- `account_session.<uid>.payload`
- `account_session.<uid>.requires_reauth`

## Flutter Domain Modeli

Kodlama basladiginda en az su model ve servisler gerekir.

### StoredAccount

Amac:
Hesap secicide listelenecek hafif model.

Alanlar:

- `uid`
- `username`
- `displayName`
- `avatarUrl`
- `providers`
- `lastUsedAt`
- `isSessionValid`
- `requiresReauth`
- `accountState`

### AccountSessionRef

Amac:
Secure storage veya backend session id referans modeli.

Alanlar:

- `uid`
- `providerType`
- `sessionId`
- `lastRefreshAt`
- `expiresAt`
- `requiresReauth`

### AccountCenterState

Amac:
UI ve servis seviyesinde merkezi state.

Alanlar:

- `activeUid`
- `accounts`
- `isSwitching`
- `lastSwitchError`
- `lastRestoreSource`

## Servis Mimarisi

### 1. AccountCenterService

Ana sorumluluk:

- cihazdaki kayitli hesaplari yuklemek
- aktif hesabi yonetmek
- hesap eklemek
- hesap kaldirmak
- hesap degistirmek
- uygulama acilisinda auto-restore tetiklemek

Public sorumluluklar:

- `init()`
- `addCurrentAccount()`
- `switchToAccount(uid)`
- `removeAccount(uid)`
- `signOutAll()`
- `refreshStoredAccounts()`

### 2. AccountSessionRestoreService

Ana sorumluluk:

- belirli bir hesap icin session restore stratejisini secmek
- backend custom token ile restore denemek
- provider-specific fallback calistirmak
- restore sonucunu standardize etmek

### 3. AccountStateResetService

Ana sorumluluk:

- hesap degisimi oncesi onceki kullaniciya ait tum state'i temizlemek
- hesap degisimi sonrasi yeni kullanici bootstrap'ini calistirmak

Bu servis kritik cunku uygulamadaki asil risk auth degil, eski kullanici verisinin yeni kullanicida gorunmesidir.

### 4. DeviceSessionService

Ana sorumluluk:

- mevcut cihazin `deviceId` yonetimi
- backend `deviceSessions` kayit/guncelleme
- account-device linking

### 5. AccountRiskService

Ilk release'te hafif olabilir. Amac:

- ayni cihazda hesap sayisini takip etmek
- supheli hizli hesap gecislerini isaretlemek
- gerektiğinde mini re-auth zorlamak

## Session Restore Stratejisi

Hizli hesap gecisi icin en guvenli ve urunsel olarak temiz model:

1. Cihaz local olarak `sessionId` veya benzeri restore referansi tutar
2. Backend bu session icin kisa omurlu token uretir
3. Uygulama bu token ile auth durumunu geri yukler
4. Basarisizsa mini re-auth acilir

### Neden sadece local token saklamak zayif

- provider'a gore degisir
- revoke/expiry kontrolu zorlasir
- cihaz hirsizligi veya stale token senaryolari artar

### Onerilen backend-akis

- kullanici normal login olur
- backend cihaz icin bir `deviceSession` olusturur
- istemci secure storage'a sadece `sessionId` ve ilgili guvenli metadata yazar
- hesap degisimi sirasinda istemci `sessionId` ile restore talebi yapar
- backend risk ve suresini kontrol eder
- uygunsa kisa omurlu login token dondurur

## Provider Bazli Davranis

### Phone

Phone oturumlari session restore tarafinda en kirilgan alanlardan biridir.

Politika:

- session restore backend session mantigi ile denenir
- ek risk veya expiry varsa mini OTP gerekir
- phone provider icin tam sessiz restore garanti varsayilmaz

### Email/Password

Politika:

- password local'de tutulmaz
- session restore sadece backend session veya secure custom token tabanli olur
- restore yoksa email login ekranina dusulur

### Google

Politika:

- silent sign-in desteklenebiliyorsa kullanilir
- degilse backend session restore tercih edilir
- fallback olarak provider re-auth kullanilir

### Apple

Politika:

- cihaz ve session guvenli ise backend restore kullanilir
- yoksa hizli Apple re-auth akisi acilir

## UI Tasarimi

Hesap Merkezi ilk etapta Profil veya Ayarlar altinda bir giris olarak dusunulmelidir.

### Ana ekran davranisi

- aktif hesap en ustte gorunur
- altta bu cihazdaki diger hesaplar listelenir
- her satirda avatar, display name, username, provider badge ve son kullanma bilgisi bulunur

### Aksiyonlar

- `Hesaba gec`
- `Hesap ekle`
- `Bu cihazdan kaldir`
- `Tum hesaplardan cikis yap`

### Hesap satiri durumlari

- aktif hesap
- gecis yapilabilir hesap
- re-auth gerekli hesap
- devre disi veya revoked hesap

### UX kurallari

- yeni hesap eklemek her zaman normal login'e gider
- riskli hesapta tek dokunuslu gecis kapatilir
- hesabin cihaza ekli olmasi, o hesapta otomatik sonsuz oturum hakki vermez

## Hesap Gecisi Akisi

Standart switch akisi:

1. Kullanici Hesap Merkezi ekraninda bir hesap secer
2. `AccountCenterService` secimi kilitler ve `isSwitching=true` yapar
3. `AccountStateResetService` onceki kullanici state reset oncesi guvenli gecis hazirligini yapar
4. `AccountSessionRestoreService` restore dener
5. Restore basariliysa yeni auth user aktif olur
6. Tum user-scoped servisler yeni uid ile bootstrap edilir
7. `lastUsedAt` guncellenir
8. UI ana akisa doner

Basarisizlik akisi:

1. Restore reddedilir veya suresi dolmustur
2. Hesap `requiresReauth=true` olur
3. Kullanici mini re-auth ekranina alinir
4. Basariliysa session yenilenir ve hesap listesi guncellenir

## Hesap Gecisi Sirasinda Reset Edilecek Alanlar

Bu liste implementasyon sirasinda kontrol listesi olarak kullanilmalidir.

### Auth ve kullanici state

- `FirebaseAuth.currentUser` bagli state
- current user service
- profile cache
- account-scoped permission state

### Feed ve sosyal veri

- ana feed cache
- profile posts cache
- shorts/video cache
- stories cache
- interaction cache

### Gercek zamanli abonelikler

- Firestore listeners
- stream subscriptions
- socket veya foreground event subscriptions

### Bildirim ve cihaz baglantilari

- FCM token user sync
- local badge counters
- push routing state

### UI controller'lari

- GetX user-scoped controller'lar
- secili tab icinde user'a bagli state
- scroll state sadece gerekiyorsa korunur, user'a bagli data korunmaz

### Diger

- analytics user id
- crash reporting user context
- upload queue user'a bagliysa yeniden baglanir

## Guvenlik Kurallari

Hesap gecisi sartsiz olmamalidir. Asagidaki kosullarda mini re-auth zorlanmalidir:

- session `expired`
- session `revoked`
- provider baglantisi kopmus
- cihaz risk skoru esigi asmis
- hesap uzun suredir kullanilmamis
- supheli ardarda hesap gecisi paterni gorulmus

Asagidaki kosullarda local hesap listesinde kalabilir ama tek dokunuslu gecis kapatilabilir:

- suresi yaklasan oturum
- eski app version ile olusmus session
- eksik device trust sinyali

## Abuse ve Cihaz Takibi

Bu planin ana amaci kullanici deneyimi olsa da cihaz bazli abuse gorunurlugu zorunludur.

Asgari kurallar:

- `devices/{deviceId}.accountCount` tutulur
- ayni cihazda hesap sayisi artis trendi izlenir
- cok hizli hesap ekleme veya gecis risk event uretir
- mini re-auth gerektiren durumlar merkezi loglanir

Ilk release'te sert engelleme yerine:

- log
- risk score artisi
- mini re-auth
- gerekirse belirli aksiyon kisiti

tercih edilmelidir.

## Firestore Index ve Sorgu Ihtiyaclari

Beklenen temel sorgular:

- bir kullanicinin cihaz oturumlari: `users/{uid}/deviceSessions` by `lastUsedAt desc`
- bir cihazin hesaplari: `devices/{deviceId}/accounts` by `lastUsedAt desc`
- bir hesap secicide local metadata kullanilir, Firestore fallback yalnizca yenileme icin gerekir
- login event analizi: `loginEvents` by `deviceId + createdAt`
- risk event analizi: `riskEvents` by `uid + createdAt`, `deviceId + createdAt`

Kodlama asamasinda `firestore.indexes.json` icin ayri checklist hazirlanmalidir.

## Gozlemlenebilirlik

Olculmesi gereken metrikler:

- account switch deneme sayisi
- account switch basari orani
- mini re-auth oranı
- restore basarisizlik nedenleri
- switch latency p50/p95
- stale-cache kaynakli hata sayisi
- device basina hesap sayisi dagilimi

Log event onerileri:

- `account_center_opened`
- `account_switch_started`
- `account_switch_succeeded`
- `account_switch_failed`
- `account_switch_reauth_required`
- `account_added_to_device`
- `account_removed_from_device`
- `account_sign_out_all`

## Implementasyon Fazlari

### Faz 0 - Kesinlestirme

Hedef:
Kod yazmadan once proje icinde hangi mevcut servislerin user-scoped oldugunu netlestirmek.

Teslimler:

- mevcut auth akisinin analizi
- mevcut current user servis baglantilarinin listesi
- user-scoped cache ve controller envanteri
- hangi ekranda Hesap Merkezi acilacak karari

### Faz 1 - Veri Sozlesmeleri

Hedef:
Firestore ve local model sozlesmelerini sabitlemek.

Teslimler:

- `deviceSessions` semasi
- `devices` semasi
- `linkedProviders` semasi
- secure storage key names
- analytics event listesi

### Faz 2 - Local Account Registry

Hedef:
Cihazda hesap listesini dogru saklamak.

Teslimler:

- `StoredAccount` modeli
- local save/load mantigi
- aktif hesap persistence
- hesap ekleme ve silme altyapisi

### Faz 3 - Session Restore Engine

Hedef:
Hizli hesap gecisini gercekten calistiracak cekirdek restore akisinin eklenmesi.

Teslimler:

- `AccountSessionRestoreService`
- backend session restore contract
- mini re-auth fallback

### Faz 4 - State Reset

Hedef:
Hesap degisiminde veri sizmasini engellemek.

Teslimler:

- `AccountStateResetService`
- cache clear contract
- listener restart contract
- FCM ve analytics rebind

### Faz 5 - UI

Hedef:
Kullaniciya acik Hesap Merkezi ekranini cikarmak.

Teslimler:

- profil/ayarlar girisi
- hesap listesi
- hesap degistirme akisi
- hesap ekle
- cihazdan kaldir
- tum hesaplardan cikis yap

### Faz 6 - Risk ve Telemetry

Hedef:
Abuse gorunurlugu ve urun sagligini eklemek.

Teslimler:

- login event kayitlari
- risk event kayitlari
- metrik dashboard girdileri

### Faz 7 - Rollout

Hedef:
Ozelligi kontrollu yayina almak.

Teslimler:

- feature flag
- internal test
- limited rollout
- telemetry review
- tam acilis

## Test Plani

### Unit test

- local stored account serializer
- session restore sonuc durumlari
- requires reauth durumlari
- state reset sirasi

### Widget test

- hesap listesi render
- aktif hesap vurgusu
- re-auth gerekli badge
- tum hesaplardan cikis onayi

### Integration test

- yeni hesap ekle -> cihaz listesine yaz
- hesap gecisi -> feed ve profil yeni kullanicida dogru gelir
- session expired -> mini re-auth acilir
- cihazdan kaldir -> local kayit temizlenir

### Manual QA

- Android
- iOS
- zayif network
- app restart sonrasi auto-restore
- notification geldikten sonra hesap degisimi
- video/feed/chat ekrani acikken hesap degisimi

## Riskler

### 1. Eski kullanici verisinin yeni hesapta gorunmesi

Bu en kritik urunsel hatadir. En buyuk odak burada olmalidir.

### 2. Provider restore farkliliklari

Phone, Apple, Google ve email farkli davranabilir. Ortak abstraction sarttir.

### 3. FCM ve notification routing tutarsizligi

Hesap degisimi sonrasi bildirimler yanlis uid ile eslenirse guvenlik problemi dogar.

### 4. GetX global state kalintilari

Mevcut projede bircok controller ve cache yapisi oldugu icin hesap degisiminde sizinti riski yuksektir.

### 5. Session restore ile auth mantigi arasinda cakişma

Ozellikle uygulama acilisinda auto-login ve hesap secici mantigi birbiriyle yarismamalidir.

## Rollout Stratejisi

### Asama 1

- internal dev/test kullanicilari
- yalnizca debug ve internal build

### Asama 2

- feature flag altinda sinirli test grubu
- restore success ve reauth oranlarini izle

### Asama 3

- tum plus/test kullanicilarina ac
- crash ve stale state izleme

### Asama 4

- genel yayin

## Kodlama Basladiginda Dosya ve Moduller

Bu kisim yonlendirici backlog'dur. Kesin dosya isimleri repo yapisina gore netlestirilebilir.

Muhtemel eklenecek alanlar:

- `lib/Services/account_center_service.dart`
- `lib/Services/account_session_restore_service.dart`
- `lib/Services/account_state_reset_service.dart`
- `lib/Models/stored_account_model.dart`
- `lib/Modules/Profile/Settings/...` veya uygun bir profil/ayarlar altina `Hesap Merkezi` UI

Mevcut sistemle baglanacak yerler:

- current user service
- auth bootstrap
- splash/acilis rotasi
- profile/settings navigation
- analytics
- notification token sync

## Handoff Notu

Bu dokuman, baska bir hesaptan devam edilmek uzere proje icine kalici olarak eklenmistir.

Devam edecek kisi veya hesap icin net karar:

- Bu ozellik proje icinde `Hesap Merkezi` adi ile ele alinacak
- Kod yazma asamasinda once bu dokuman referans alinacak
- Ilk is, Faz 0 kapsaminda mevcut user-scoped servis ve cache envanterini cikarmak olacak
- Kodlama sirasinda bu plana gore ilerlenmeli; rastgele auth patch'leri ile ilerlenmemeli

## Son Karar Ozet

Bu proje icin dogru model:

- user altinda: `linkedProviders`, `deviceSessions`
- top-level: `devices`, `loginEvents`, `riskEvents`, gerekirse `accountClusters`
- local metadata + secure session ref ayrimi
- hesap gecisi = auth restore + tam app state reset
- login ekranina donmeden gecis sadece daha once bu cihazda kullanilmis ve geçerli session'i olan hesaplar icin

Bu plan, Hesap Merkezi kodlamasinin resmi baslangic dokumani olarak kabul edilmelidir.
