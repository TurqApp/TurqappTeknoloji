# Pre-launch System Hardening Master Plan

Tarih: 2026-03-20
Proje: TurqApp
Durum: Uygulanabilir ana plan

Sprint hedef cümlesi:

- 5 gunde `P0`'i kapatmak,
- `P1`'i buyuk olcude tamamlamak,
- `P2` icin altyapiyi, sahipligi ve uygulama zeminini hazir hale getirmek

hedeflenir.

## 1. Amac

Bu planin amaci, mevcut TurqApp sistemini kokten yeniden yazmadan, canliya cikmadan once guvenlik, maliyet, performans, veri tutarliligi ve bakim kalitesini belirgin sekilde guclendirmektir.

Bu plan su prensiplere dayanir:

- Buyuk UI redesign yok.
- Mevcut urun akislari korunur.
- Mevcut teknoloji omurgasi korunur.
- Riskli, pahali ve daginik alanlar sistematik olarak sertlestirilir.

## 2. Korunacak Temel Kararlar

Asagidaki kararlar degismeyecek, sadece guclendirilecek:

- `GetX` korunacak.
- `Posts` root collection source of truth olarak kalacak.
- `userFeeds` feed read-model/ref katmani olarak kalacak.
- `Typesense` arama ve kesif omurgasi olarak kalacak.
- Firestore tabanli DM modeli korunacak.
- `users/{userId}/notifications` inbox yapisi korunacak.
- Cache-first yaklasim korunacak.
- `nickname + displayName` modeli korunacak.
- Buyuk ekran akisi ve mevcut UI hissi korunacak.

## 3. Urun Davranisinda Kilit Kararlar

### 3.1 Private hesap

- Private hesap aramada profil karti olarak gorunur.
- Takipci olmayan kullanici private hesapta su alanlari goremez:
  - post listesi
  - yorumlar
  - begeniler
  - story
  - icerik arama sonuclari
- Takipci olmayan kullanici su ozet alanlarini gorebilir:
  - profil adi / avatar
  - bio
  - gonderi sayisi
  - takipci sayisi
  - takip edilen sayisi

### 3.2 Block davranisi

- Instagram benzeri davranis uygulanir.
- Kullanicilar birbirini:
  - aramada gormez
  - profilde gormez
  - feed ve kesifte gormez
- Mevcut DM gecmisi okunabilir kalabilir.
- Yeni mesajlasma ve yeni etkilesim kesilir.

### 3.3 Mute davranisi

- Muted kullanici feed'de gorunmez.
- Story'de gorunmez.
- DM calismaya devam eder.
- Arama ve profil gorunur kalir.
- Notification davranisi mute sebebiyle degismez.

### 3.4 Feed davranisi

- Following feed tam kronolojik olacak.
- For You ilk surumde basit olacak:
  - freshness
  - social proximity
  - temel engagement

### 3.5 Notification davranisi

- Like notification: bundle
- Follow notification: karma
- Comment notification: bundle olabilir
- Reply notification: tekil
- Mention notification: her zaman tekil

### 3.6 DM MVP kapsami

- text: evet
- gorsel: evet
- video: evet
- ses mesaji: evet
- read receipt: evet
- typing indicator: hayir
- delete-for-me: evet
- unsend: hayir
- forward: hayir
- media preview: evet
- link preview: hayir

## 4. Veri Kontrati ve Canonical Alanlar

### 4.0 Mevcut sistem notlari

Projede bugun itibariyla su durumlar gercekten mevcut:

- kullanici kimligi alanlarinda `userID` agirligi halen yaygin
- bazi ozet modellerde `username` alani hala compatibility amacli tasiniyor
- follower counter tarafinda `followerCount` ve `followersCount` birlikte gorulebiliyor
- notification inbox yolu zaten `users/{uid}/notifications` olarak kullaniliyor
- DM tarafinda conversation root map'leri ile `users/{uid}/chatArchives` ve `users/{uid}/chatDeletions` birlikte kullaniliyor

Bu nedenle bu master planin ilk 5 gunluk sprinti:

- semantik canonical karari netlestirir
- write/read ownership'i netlestirir
- breaking field rename'e zorunlu olarak girmez

Yani ilk sprintte hedef:

- fiziksel tum alanlari bir anda yeniden adlandirmak degil
- mevcut repo uzerinde guvenli kontrat ve davranis standardi kurmaktir

Fiziksel alan sadeleştirmesi ancak:

- rules
- write boundary
- notification
- feed
- visibility

hatti oturduktan sonra, ayri migration/backfill karari ile ele alinir.

### 4.1 Kullanici modeli

Canonical alanlar:

- `userId`
- `nickname`
- `nicknameLower`
- `displayName`

Anlamlari:

- `nickname`: benzersiz handle
- `nicknameLower`: arama, uniqueness, mention ve filter icin normalize alan
- `displayName`: gorunen profil adi

Uygulama notu:

- ilk sprintte hedef kavramsal canonical modeldir
- repo icinde bugun halen `userID` ve `username` kullanan alanlar olabilir
- bunlar tek seferde degil, kontrollu sadeleştirme ile ele alinir

### 4.2 Post modeli

- `Posts/{postId}` ana veri kaynagi olarak korunur.
- Feed ve arama icin mevcut optimize read/ref katmanlari korunur.
- Ayrik tam rewrite yapilmaz.

### 4.3 Follow modeli

- `followers/followings` mantigi korunur.
- Counter guncellemeleri daha kontrollu hale gelir.

### 4.4 Notification modeli

- `users/{userId}/notifications/{notificationId}` korunur.
- Ancak `event uretimi` ile `inbox item uretimi` mantigi ayrilir.

Uygulama notu:

- snapshot repository zaten mevcut oldugu icin hedef yeni inbox tasarimi degil
- mevcut inbox'i backend kontrollu hale getirmektir

### 4.5 DM modeli

- `conversations/{conversationId}`
- `conversations/{conversationId}/messages/{messageId}`

korunur.

Ancak unread/read/archive/delete-for-me davranislari daha merkezilesir.

Uygulama notu:

- mevcut sistemde `archived`, `unread`, `pinned`, `muted` map alanlari conversation root'ta
- buna ek olarak `users/{uid}/chatArchives` ve `users/{uid}/chatDeletions` override koleksiyonlari da var
- ilk fazda hedef bu cift yapinin davranisini netlestirmek, aniden kaldirmak degildir

## 5. Mimari Iyilestirme Hedefleri

### 5.1 GetX iyilestirme kurallari

#### Controller

Controller sadece sunlari yonetir:

- ekran state'i
- loading / empty / error
- input / filter / selected tab
- pagination tetikleme
- kullanici aksiyonunu yakalama

Controller sunlari yapmaz:

- dogrudan Firestore veri karari
- business rule karari
- kritik write mantigi
- dağınık notification uretimi

#### Service

Service katmani sunlari tasir:

- privacy / visibility
- follow / like / report kurallari
- notification karar mantigi
- feed visibility ve side-effect kurallari
- DM policy ve access kararlari

#### Repository

Repository katmani sunlari yapar:

- Firestore / Typesense / cache veri erisimi
- query kurma
- map etme
- fallback / hydration

Repository urun karari vermez.

#### Rx kullanimi

- Sadece gercek gozlenen state `Rx` olur.
- Derived/helper degerler gereksiz yere `Rx` yapilmaz.
- `Obx` kapsamlari kucuk tutulur.

### 5.2 Visibility / policy merkezilesmesi

Tek bir policy mantiginda merkezilenecek alanlar:

- private
- block
- mute
- deleted
- banned

Bu kurallar en az su yuzeylerde ayni mantikla calisacak:

- feed
- search
- profile
- notifications
- DM
- deep link

### 5.3 Current user ve relation summary merkezilesmesi

Asagidaki veriler daha merkezden ve tutarli yonetilecek:

- current user
- relation/follow state
- privacy summary
- basic visibility summary

## 6. P0 Is Akislari

P0, launch oncesi mutlaka kapatilmasi gereken alanlardir.

### P0-1 Firestore rules sertlestirme

Dosya:

- `/Users/turqapp/Desktop/TurqApp/firestore.rules`

Owner:

- backend + guvenlik

Risk seviyesi:

- kritik

Hedef:

- mevcut urun akisini bozmadan rules'i sadeletmek
- client write yuzeyini daraltmak
- koleksiyon bazli ownership ve allow/deny mantigini netlestirmek
- emulator tabanli rules testlerini zorunlu hale getirmek

Ilk kapsama alinacak koleksiyonlar:

- users
- posts
- follows
- notifications
- conversations
- messages
- admin/moderation write path'leri

### P0-2 Sensitive write boundary

Kritik write'lar mumkun oldugunca backend kontrollu hale getirilecek:

- follow / unfollow
- like / unlike
- report
- moderation/admin action
- nickname change
- notification uretimi

Yaklasim:

- client aksiyonu baslatir
- karar ve kalici write backend/function tarafinda standartlasir

Owner:

- backend + mobil veri akis katmani

Risk seviyesi:

- kritik

### P0-3 Notification sertlestirme

Korunacak:

- mevcut inbox yapisi
- mevcut UI hissi

Degisecek:

- event uretimi ile inbox item uretimi ayrilacak
- dedup ve bundle mantigi backend tarafinda merkezilesecek

Owner:

- backend + mobil notification akis katmani

Risk seviyesi:

- yuksek

### P0-4 Feed ve visibility disiplini

Korunacak:

- `Posts`
- `userFeeds`
- `Typesense`

Degisecek:

- visibility policy tek mantiga baglanacak
- following feed davranisi daha netlestirilecek
- For You daha kontrollu ama basit kalacak

Owner:

- mobil feed katmani + backend feed/functions katmani

Risk seviyesi:

- kritik

### P0-5 GetX sorumluluk ayrimi

Oncelikli moduller:

- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn`
- `/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service.dart`

Hedef:

- controller/service/repository ayrimini sertlestirmek
- kritik write ve business rule'u controller'dan cikarmak

Owner:

- mobil mimari

Risk seviyesi:

- yuksek

## 7. P1 Is Akislari

### P1-1 Cache policy standardizasyonu

Asagidaki yuzeyler icin ayri kurallar tanimlanir:

- feed
- profile
- notifications
- search
- comments
- DM

Her yuzey icin tanimlanacak:

- TTL
- refresh trigger
- stale davranisi
- invalidate davranisi

Owner:

- mobil mimari + cache katmani

Risk seviyesi:

- yuksek

### P1-2 Typesense sync hardening

Korunacak:

- Typesense stack

Iyilestirilecek:

- create/update/delete tutarliligi
- stale index fallback
- duplicate/tombstone guard

Odak moduller:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/typesense_post_service.dart`
- `/Users/turqapp/Desktop/TurqApp/functions/src/14_typesensePosts.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/15_typesenseUsersTags.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/21_typesenseEducation.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/25_typesenseMarket.ts`

Teknik risk:

- stale arama sonuclari
- silinmis/veri gizlenmis icerigin indexte kalmasi
- duplicate record
- Firestore ile arama sonucunun celismesi

Kisa vadeli cozum:

- create/update/delete icin tek bir sync kontrati cikarmak
- stale index fallback davranisini belirlemek
- duplicate guard ve delete kontrol noktalarini sabitlemek

Orta vadeli cozum:

- replay edilebilir backfill/sync scriptleri
- tombstone ve idempotent update mantigi

Scale cozum:

- queue tabanli async indexing
- dead-letter ve replay pipeline

Cikti:

- Typesense sync kontrati
- stale fallback kurallari
- duplicate/tombstone kontrol listesi

Done kriteri:

- her entity tipi icin create/update/delete yol haritasi net olmali
- stale index senaryosunda UI davranisi belli olmali

Owner:

- backend search/indexing

Risk seviyesi:

- orta-yuksek

### P1-3 DM summary ve state disiplini

Iyilestirilecek:

- unread/read state
- archive
- delete-for-me
- block sonrasi davranis
- media guvenligi

Odak moduller:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/conversation_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/ChatListing`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/MessageContent`

Teknik risk:

- unread sayaç sapmasi
- farkli ekranlarin farkli chat summary uretmesi
- block sonrasi beklenmeyen erisim
- media mesajlarda guvenlik ve stale state problemleri

Kisa vadeli cozum:

- conversation summary alanlarini netlestirmek
- delete-for-me ve archive davranisini tek mantiga baglamak
- read receipt state akisini merkezilestirmek

Orta vadeli cozum:

- chat policy service
- unread state hesaplamasini controller'lardan cikarip service/repository tarafina tasimak

Scale cozum:

- summary materialization
- attachment delivery policy'lerini ayri katmanda yonetmek

Cikti:

- DM state kontrati
- summary alan listesi
- block/archive/delete-for-me davranis tablosu

Done kriteri:

- chat listesi, message screen ve read state ayni veri mantigina dayanir hale gelmeli

Owner:

- mobil chat katmani + backend veri kontrati

Risk seviyesi:

- yuksek

### P1-4 Counter sertlestirme

Alanlar:

- follower count
- following count
- post stats
- like/comment/share/save sayaclari

Hedef:

- optimistic UI korunur
- kalici sayac yazimi daha guvenilir olur

Odak moduller:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Services/post_interaction_service.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/user_repository.dart`
- ilgili function/callable write path'leri

Teknik risk:

- sayac sapmasi
- ayni aksiyonun iki kez yazilmasi
- optimistic UI ile kalici state'in ayrismasi

Kisa vadeli cozum:

- sayaclari etkileyen tum write path'leri listelemek
- hangi sayacin server-authoritative olacagini netlestirmek
- UI optimistic davranisini rollback kurallariyla eslemek

Orta vadeli cozum:

- counter update'leri backend destekli hale getirmek
- aggregation ve repair script mantigi tanimlamak

Scale cozum:

- precomputed aggregate jobs
- periodic reconciliation

Cikti:

- counter write matrisi
- optimistic rollback kurallari
- server-authoritative counter listesi

Done kriteri:

- follower/following ve temel post stats icin nihai otorite belli olmali

Owner:

- backend veri butunlugu + mobil interaction katmani

Risk seviyesi:

- yuksek

## 8. P2 Is Akislari

### P2-1 Moderation tooling

- moderator queue
- admin workflow
- escalation path

Odak moduller:

- `/Users/turqapp/Desktop/TurqApp/functions/src/24_reports.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/22_badgeAdmin.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/26_userBanAdmin.ts`
- admin/moderation UI dosyalari

Teknik risk:

- report yiginlari elle yonetilemez hale gelir
- aksiyon takibi kaybolur
- moderation surecleri kisilere bagimli kalir

Kisa vadeli cozum:

- report state'lerini standartlastirmak
- moderator karar akisini belgelemek
- audit log'u standardize etmek

Orta vadeli cozum:

- moderator queue
- triage ekranlari
- escalation akisi

Scale cozum:

- risk skoru
- otomatik siniflandirma
- case management

Cikti:

- moderation workflow notu
- audit ve state modeli

Done kriteri:

- bir report'un acilisindan aksiyona kadar izlenecek yol dokumante olmali

Owner:

- trust & safety + backend admin akis katmani

Risk seviyesi:

- orta

### P2-2 Observability

- dashboard
- alarm
- teknik KPI takibi

Odak alanlar:

- crash analytics
- performance monitoring
- Firestore read/write latency
- search latency
- notification lag
- media upload success/failure
- moderation events

Teknik risk:

- canliya cikinca sorunlar gec fark edilir
- feed/search/notification regressions sessiz kalir

Kisa vadeli cozum:

- cekirdek metrik listesini sabitlemek
- haftalik takip KPI setini cikarmak

Orta vadeli cozum:

- dashboard ve alarm tanimlari
- teknik SLO ve threshold'lar

Scale cozum:

- incident playbook
- release bazli regresyon alarmi

Cikti:

- observability metric listesi
- dashboard backlog'u
- alarm oncelik listesi

Done kriteri:

- launch sonrasi neyi takip edecegimiz net olmali

Owner:

- release / operasyon

Risk seviyesi:

- orta

### P2-3 Feature flag ve release control

- remote config
- rollout discipline
- rollback checklist

Odak alanlar:

- Remote Config
- release gate
- kill switch
- rollout notlari

Teknik risk:

- problemli ozellikler kapatilamaz
- rollback dogaclama ilerler

Kisa vadeli cozum:

- hangi feature'larin flaggable oldugunu listelemek
- launch check ve rollback adimlarini dokumante etmek

Orta vadeli cozum:

- feature flag naming standardi
- rollout kural seti

Scale cozum:

- progressive rollout
- cohort bazli acma/kapama

Cikti:

- release control matrisi
- rollback checklist

Done kriteri:

- en az kritik akislar icin disable/fallback kararlari net olmalı

Owner:

- release / mobil altyapi

Risk seviyesi:

- orta

### P2-4 Gelismis abuse prevention

- report spam korumasi
- bot-like behavior alarmi
- fake engagement patternleri

Odak alanlar:

- follow spam
- like spam
- comment spam
- DM spam
- report brigading
- search poisoning

Teknik risk:

- launch sonrasi kotu niyetli kullanici akislari sistemi bozar
- sahte etkileşimler kaliteyi ve maliyeti bozar

Kisa vadeli cozum:

- abuse event listesi
- ilk sinir ve throttle noktalarini cikarmak

Orta vadeli cozum:

- rate limit ve device/account davranis analizi
- ilk alarm kurallari

Scale cozum:

- risk scoring
- coordinated abuse detection

Cikti:

- abuse baseline listesi
- throttle backlog'u

Done kriteri:

- ilk surumde hangi abuse risklerini aktif engelledigimiz net olmalı

Owner:

- trust & safety + backend koruma katmani

Risk seviyesi:

- orta

## 9. Admin ve Moderation Kararlari

Korunacak:

- admin/moderation UI

Iyilestirilecek:

- privilege boundary
- backend kontrollu write
- audit log
- report dedup
- tekrarli report spam korumasi

Her admin/moderation aksiyonu icin en az su iz tutulur:

- kim yapti
- ne zaman yapti
- hangi hedefte yapti
- hangi aksiyon uygulandi

## 10. Medya ve Upload Hatti

Korunacak:

- mevcut upload/media akisi

Iyilestirilecek:

- thumbnail policy
- multi-size delivery
- cache-control
- erisim guvenligi

Hedef:

- media pipeline rewrite yok
- guvenlik ve sunum disiplini var

## 11. Auth ve Profile Bootstrap

Korunacak:

- onboarding UI
- auth UI
- profile completion UI

Iyilestirilecek:

- kullanici dokumani bootstrap
- nickname uniqueness kontrolu
- current user cache load
- profile bootstrap merkezi akisi

## 12. Deep Link ve Short Link Kurallari

Korunacak:

- mevcut link ve deep link akislari

Iyilestirilecek:

- private/block/deleted enforcement
- web fallback
- in-app acilma karari
- guvenli yonlendirme

## 13. Release Gate

Canli oncesi minimum zorunlu gate:

- `dart analyze`
- kritik smoke testler
- rules testleri
- auth temel akis kontrolu
- feed temel akis kontrolu
- post create kontrolu
- comment/reply kontrolu
- follow kontrolu
- notification kontrolu
- DM kontrolu

Sadece "build aliyor" yeterli kabul edilmeyecek.

## 14. 5 Gunluk Uygulama Sirasi

Bu plan, 5 gunluk hizlandirilmis sertlestirme sprinti olarak uygulanabilir.

### Gun 1 - Envanter ve kontrat dondurma

Hedef:

- canonical veri kontrati
- sensitive write inventory
- privacy/block/mute enforcement matrisi
- GetX sorumluluk haritasi
- rules test kapsami

Odak dosyalar:

- `/Users/turqapp/Desktop/TurqApp/lib/Models/current_user_model.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Models/posts_model.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/user_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/notifications_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/conversation_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Explore`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat`
- `/Users/turqapp/Desktop/TurqApp/firestore.rules`

### Gun 2 - Rules ve kritik write path

Hedef:

- rules sadeletme baslangici
- emulator tabanli test omurgasi
- kritik backend write boundary tanimlari

Odak:

- `/Users/turqapp/Desktop/TurqApp/firestore.rules`
- `/Users/turqapp/Desktop/TurqApp/functions/src`

### Gun 3 - Notification ve moderation write modeli

Hedef:

- notification event/inbox ayrimi
- dedup ve bundle kurallari
- report/moderation flow sertlestirme

Odak:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/notifications_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications`
- `/Users/turqapp/Desktop/TurqApp/functions/src/24_reports.ts`

### Gun 4 - Feed, visibility ve search consistency

Hedef:

- visibility policy service taslagi
- feed read-path temizligi
- search visibility standardi

Odak:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda`
- `/Users/turqapp/Desktop/TurqApp/functions/src/hybridFeed.ts`

### Gun 5 - GetX cleanup, cache policy ve release gate

Hedef:

- controller/service/repository ilk ayristirma
- cache policy cizelgesi
- smoke checklist
- release gate tanimi

Odak:

- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn`
- `/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service.dart`

## 15. Ilk Refactor Dalga Sirasi

Ilk dokunulacak moduller:

1. `/Users/turqapp/Desktop/TurqApp/firestore.rules`
2. `/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service.dart`
3. `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository.dart`
4. `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository.dart`
5. `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/notifications_repository.dart`
6. `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/conversation_repository.dart`
7. `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda`
8. `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications`
9. `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat`
10. `/Users/turqapp/Desktop/TurqApp/functions/src/hybridFeed.ts`

## 16. Basari Kriterleri

Bu plan basarili sayilacaksa en az su kosullar saglanmali:

- kurallar ve gorunurluk davranisi yuzeyler arasinda celismiyor
- kritik write'lar client'ta daginik degil
- notification spam ve duplicate davranisi azaliyor
- feed ve search visibility tutarli calisiyor
- controller dosyalari daha okunur hale geliyor
- release gate olmadan cikis yapilmiyor

## 17. Planin Sinirlari

Bu plan bilerek su alanlara girmiyor:

- koklu UI redesign
- state management migration
- tum Firestore semasinin yeniden yazilmasi
- DM altyapisinin baska sisteme tasinmasi
- komple feed rewrite

Bu alanlar ikinci faz ihtiyaci olursa ayrica planlanir.

## 18. Gun 1 Ayrintili Is Plani

Gun 1'in amaci, kod degistirmeden once neyi koruyup neyi sertlestirecegimizi netlestirmektir.

Toplam hedef:

- 12-16 saat net calisma
- girdi: mevcut repo
- cikti: karar, envanter, sorumluluk ve risk haritasi

### 18.1 Blok A - Canonical veri kontrati envanteri

Tahmini sure:

- 2.5 - 3 saat

Odak dosyalar:

- `/Users/turqapp/Desktop/TurqApp/lib/Models/current_user_model.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Models/posts_model.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Models/stored_account.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/user_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/conversation_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/notifications_repository.dart`

Yapilacak:

- `userId`, `nickname`, `nicknameLower`, `displayName` kullanimlarini cikar
- posts tarafinda source-of-truth alanlarini listele
- notification tarafinda event verisi ile inbox verisini ayir
- DM tarafinda summary alanlari ile mesaj alanlarini ayir
- alanlari su sekilde siniflandir:
  - canonical
  - derived
  - legacy
  - server-authoritative

Cikti:

- kisa ama net kontrat listesi
- "dokunulacak alanlar / korunacak alanlar" ayrimi

Done kriteri:

- kullanici, post, notification ve DM icin canonical alan tablosu cikmis olmali

### 18.2 Blok B - Sensitive write inventory

Tahmini sure:

- 2 - 2.5 saat

Odak dosyalar:

- `/Users/turqapp/Desktop/TurqApp/lib/Services`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories`
- `/Users/turqapp/Desktop/TurqApp/functions/src`
- `/Users/turqapp/Desktop/TurqApp/functions/src/22_badgeAdmin.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/24_reports.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/26_userBanAdmin.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/27_nicknameChange.ts`

Yapilacak:

- su write path'lerin mevcut akislarini cikar:
  - follow
  - like
  - report
  - moderation
  - nickname change
  - notification create
- her biri icin sunu isle:
  - client'ta mi basliyor
  - direkt Firestore write mi
  - function/callable var mi
  - hangi veri alanlarini degistiriyor

Cikti:

- 3'lu write listesi:
  - client-safe
  - backend-only olmali
  - gecis surecinde tasinacak

Done kriteri:

- hangi kritik write'in ilk dalgada backend'e alinacagi net olmali

### 18.3 Blok C - Privacy / block / mute enforcement matrisi

Tahmini sure:

- 2 - 2.5 saat

Odak moduller:

- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Explore`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/deep_link_service.dart`

Yapilacak:

- private hesap davranisinin tum yuzeylerdeki kontrol noktalarini bul
- block sonrasi gorunurluk ve erisim noktalarini cikar
- mute sonrasi feed/story davranislarini isaretle
- mevcut celiskileri not al

Cikti:

- tek bir enforcement matrisi
- hangi yuzeyde policy service ihtiyaci oldugu netlesir

Done kriteri:

- feed/search/profile/notifications/DM/deep link icin visibility karar noktasi cikmis olmali

### 18.4 Blok D - GetX sorumluluk haritasi

Tahmini sure:

- 2 - 3 saat

Odak dosyalar:

- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/agenda_controller.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications/in_app_notifications_controller.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/chat_controller.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in_controller.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service.dart`

Yapilacak:

- her controller icin asagidaki sorumluluklari isaretle:
  - UI state
  - business logic
  - repository access
  - side effect
  - cache access
  - backend call
- controller'da kalacaklar ile service/repository'ye tasinacaklari ayir

Cikti:

- ilk refactor dalgasi icin controller risk listesi

Done kriteri:

- en riskli 3 controller ve tasinacak sorumluluklar netlesmis olmali

### 18.5 Blok E - Rules test kapsami

Tahmini sure:

- 2 saat

Odak dosyalar:

- `/Users/turqapp/Desktop/TurqApp/firestore.rules`
- `/Users/turqapp/Desktop/TurqApp/functions/package.json`
- mevcut rules test dosyalari

Yapilacak:

- ilk testlenecek senaryolari cikar:
  - own profile update allow
  - diger kullanici profile update deny
  - private content deny
  - blocked access deny
  - DM own conversation/message access
  - notification own-user access
  - admin olmayan icin moderation deny

Cikti:

- Day 2 implementasyonu icin net test listesi

Done kriteri:

- en az 10 kritik rules senaryosu yazili hale gelmeli

### 18.6 Gun 1 sonunda teslim edilecekler

- canonical veri kontrati listesi
- sensitive write inventory
- privacy/block/mute enforcement matrisi
- GetX sorumluluk haritasi
- rules test kapsami

### 18.7 Gun 1 basari kriteri

- Day 2'de neyi degistirecegimiz tartismasiz net olacak

## 19. Gun 2 Ayrintili Is Plani

Gun 2'nin amaci, guvenlik ve write boundary tarafinda ilk gercek teknik omurgayi kurmaktir.

Toplam hedef:

- 12-16 saat net calisma

### 19.1 Blok A - Rules refactor taslagi

Tahmini sure:

- 3 - 4 saat

Odak dosya:

- `/Users/turqapp/Desktop/TurqApp/firestore.rules`

Yapilacak:

- helper bolumlerini yeniden gruplandir
- koleksiyon bazli kurallari daha okunur hale getir
- write izinlerini ownership bazli daralt
- field whitelist gerekiyorsa not et

Cikti:

- ilk sade rules taslagi

Done kriteri:

- users/posts/follows/notifications/conversations icin ana izin modeli okunur hale gelmeli

### 19.2 Blok B - Emulator rules test iskeleti

Tahmini sure:

- 2 - 3 saat

Odak:

- `/Users/turqapp/Desktop/TurqApp/functions/package.json`
- mevcut rules test dosyalari

Yapilacak:

- test setup dogrula
- minimum kritik testleri ekle
- test naming ve fixture yapisini sabitle

Cikti:

- ilk calisan kritik rules test seti

Done kriteri:

- en az users, posts ve notifications icin ilk testler kosabiliyor olmali

### 19.3 Blok C - Sensitive write boundary ilk dalga

Tahmini sure:

- 3 - 4 saat

Odak dosyalar:

- `/Users/turqapp/Desktop/TurqApp/functions/src/24_reports.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/27_nicknameChange.ts`
- ilgili service/repository dosyalari

Yapilacak:

- backend kontrollu olmasi gereken ilk path'leri ayir
- client'tan dogrudan write eden riskli noktalari isaretle
- function/callable kontratini netlestir

Cikti:

- ilk backend-only write listesi ve gecis notlari

Done kriteri:

- report ve nickname change icin kalici write yolu netlesmis olmali

### 19.4 Blok D - Admin/moderation privilege boundary

Tahmini sure:

- 2 - 3 saat

Odak:

- `/Users/turqapp/Desktop/TurqApp/functions/src/22_badgeAdmin.ts`
- `/Users/turqapp/Desktop/TurqApp/functions/src/26_userBanAdmin.ts`
- `/Users/turqapp/Desktop/TurqApp/firestore.rules`

Yapilacak:

- admin olmayan kullanicinin hangi write'lari asla yapamayacagini netlestir
- allowlist/claim/rules sinirlarini belgeleyip uygulama planina bagla

Cikti:

- privilege boundary listesi

Done kriteri:

- admin/moderation icin deny-by-default siniri netlesmis olmali

### 19.5 Gun 2 sonunda teslim edilecekler

- sade rule taslagi
- ilk rules testleri
- backend-only write listesi
- admin/moderation privilege boundary

### 19.6 Gun 2 basari kriteri

- kritik write'lar ve kurallar artik soyut degil, uygulanabilir hale gelmis olacak

## 20. Gun 3 Ayrintili Is Plani

Gun 3'un amaci, notification ve moderation write hattini spam, maliyet ve tutarlilik acisindan duzene sokmaktir.

Toplam hedef:

- 12-16 saat net calisma

### 20.1 Blok A - Notification event ile inbox item ayrimi

Tahmini sure:

- 3 - 4 saat

Odak dosyalar:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/notifications_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/notifications_snapshot_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications`

Yapilacak:

- event kaynaklarini cikar
- kullaniciya gorunen inbox item alanlarini ayir
- UI'nin hangi alani gercekten tukettigini netlestir

Cikti:

- event vs inbox veri kontrati

Done kriteri:

- notification ekraninin hangi alanlari event degil, display modeli oldugu netlesmis olmali

### 20.2 Blok B - Bundle ve dedup kurallari

Tahmini sure:

- 2 - 3 saat

Yapilacak:

- like bundle kurali
- follow karma kurali
- comment bundle / reply tekil / mention tekil kurali
- duplicate event davranisi

Cikti:

- notification aggregation kurallari tablosu

Done kriteri:

- her event tipi icin inbox uretim karari yazili olmalı

### 20.3 Blok C - Backend notification uretim yolu

Tahmini sure:

- 3 - 4 saat

Odak:

- function/callable tabanli mevcut event kaynaklari
- notification write eden service/repository alanlari

Yapilacak:

- client'ta daginik notification ureten yerleri azalt
- backend tarafinda karar verme mantigini belirle
- idempotency ve duplicate guard notlarini ekle

Cikti:

- backend-first notification uretim akisi

Done kriteri:

- hangi aksiyonun notification'i hangi tarafta urettigi netlesmis olmali

### 20.4 Blok D - Report akisi ve abuse korumasi

Tahmini sure:

- 2 - 3 saat

Odak:

- `/Users/turqapp/Desktop/TurqApp/functions/src/24_reports.ts`

Yapilacak:

- ayni kullanicinin ayni hedefe tekrarli report spam korumasi
- report dedup
- admin gorunurlugu icin veri alanlari
- ilk audit izi

Cikti:

- report hardening listesi

Done kriteri:

- report akisinin abuse aciklari buyuk olcude listelenmis ve ilk cozumleri tanimlanmis olmali

### 20.5 Gun 3 sonunda teslim edilecekler

- event/inbox notification kontrati
- bundle/dedup kurallari
- backend-first notification uretim yolu
- report hardening listesi

### 20.6 Gun 3 basari kriteri

- notification sistemi artik "her yerden yazilan daginik eventler" durumundan cikmis olmali

## 21. Gun 4 Ayrintili Is Plani

Gun 4'un amaci, feed, search ve visibility davranislarini tek urun mantigina baglamaktir.

Toplam hedef:

- 12-16 saat net calisma

### 21.1 Blok A - Feed read-path envanteri

Tahmini sure:

- 3 saat

Odak:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository.dart`
- `/Users/turqapp/Desktop/TurqApp/functions/src/hybridFeed.ts`

Yapilacak:

- following feed source yolunu netlestir
- for you candidate mantigini not et
- hydrate edilen post karti alanlarini cikar

Cikti:

- feed read-path cizelgesi

Done kriteri:

- feed'de hangi veri nereden geliyor sorusu tek tabloda cevaplanmali

### 21.2 Blok B - Visibility policy service taslagi

Tahmini sure:

- 2.5 - 3 saat

Odak moduller:

- Agenda
- Explore
- Profile
- Chat
- Notifications

Yapilacak:

- private/block/mute/deleted/banned kararlarini tek policy listesine indir
- ekranlarda kullanilacak ortak karar noktalarini belirle

Cikti:

- visibility/policy service icin sorumluluk listesi

Done kriteri:

- ayni icerik/user icin farkli ekranlarda farkli gorunurluk karari ureten noktalar isaretlenmis olmali

### 21.3 Blok C - Search visibility standardi

Tahmini sure:

- 2 - 3 saat

Odak:

- Typesense kullanan user/post arama akislari

Yapilacak:

- private hesap arama karti davranisini standardize et
- block/mute/private sonrasinda sonuc filtreleme noktasini netlestir
- "searchte gorunuyor ama profile gidince acilmiyor" tipindeki celiskileri azaltacak kurallari yaz

Cikti:

- search visibility standardi

Done kriteri:

- user search ve post search icin net urun davranis kurali cikmis olmali

### 21.4 Blok D - Deep link ve external visibility

Tahmini sure:

- 2 saat

Odak:

- `/Users/turqapp/Desktop/TurqApp/lib/Core/Services/deep_link_service.dart`

Yapilacak:

- private/block/deleted content acilis kurallari
- in-app vs web fallback davranisi
- guvenli yonlendirme notlari

Cikti:

- deep link visibility listesi

Done kriteri:

- linkten gelen bir icerigin hangi durumda acilacagi netlesmis olmali

### 21.5 Gun 4 sonunda teslim edilecekler

- feed read-path cizelgesi
- visibility policy service taslagi
- search visibility standardi
- deep link visibility listesi

### 21.6 Gun 4 basari kriteri

- feed/search/profile/DM/deep link arasindaki gorunurluk mantigi ayni urun diline baglanmis olmali

## 22. Gun 5 Ayrintili Is Plani

Gun 5'in amaci, ilk refactor sinirlarini cizmek, cache davranisini standardize etmek ve launch gate'i tanimlamaktir.

Toplam hedef:

- 12-16 saat net calisma

### 22.1 Blok A - GetX refactor ilk dalga listesi

Tahmini sure:

- 3 - 4 saat

Odak:

- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/InAppNotifications`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat`
- `/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn`
- `/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service.dart`

Yapilacak:

- her modulde ilk tasinacak sorumluluklari listele
- controller'da kalacak state alanlarini ayir
- service/repository'ye inmesi gereken ilk method'lari belirle

Cikti:

- ilk refactor backlog'u

Done kriteri:

- en az 5 modulde ilk tasinacak sorumluluklar net olmalı

### 22.2 Blok B - Cache policy matrix

Tahmini sure:

- 2.5 - 3 saat

Odak yuzeyler:

- feed
- profile
- notifications
- search
- comments
- DM

Yapilacak:

- TTL
- force refresh
- invalidate trigger
- stale ekran davranisi
- optimistic rollback davranisi

kurallarini cikart

Cikti:

- cache policy matrix

Done kriteri:

- her yuzey icin minimum bir gecerlilik ve refresh kurali yazili olmali

### 22.3 Blok C - Release gate tanimi

Tahmini sure:

- 2 - 2.5 saat

Yapilacak:

- zorunlu teknik gate listesini yaz
- smoke test listesini sabitle
- rules test zorunlulugunu bagla

Cikti:

- release gate checklist taslagi

Done kriteri:

- launch oncesi minimum gate listesi yazili ve uygulanabilir olmali

### 22.4 Blok D - Son risk ve eksik listesi

Tahmini sure:

- 2 - 3 saat

Yapilacak:

- P0 kapanmadiysa nedenini yaz
- P1/P2'ye kalan maddeleri ayir
- "simdi yapilmazsa launch'ta risk" listesini netlestir

Cikti:

- final risk triage listesi

Done kriteri:

- sprint sonunda neyin bittigi ve neyin sonraya kaldigi tartismasiz net olmali

### 22.5 Gun 5 sonunda teslim edilecekler

- GetX ilk refactor backlog'u
- cache policy matrix
- release gate checklist taslagi
- final risk triage listesi

### 22.6 Gun 5 basari kriteri

- artik sadece fikir degil, uygulanabilir backlog ve launch gate elimizde olmali

## 23. 5 Gun Sonunda Beklenen Toplam Cikti

Bu sprint sonunda asagidaki ciktilar elde edilmis olmali:

- canonical veri kontrati
- sensitive write boundary listesi
- sade Firestore rules taslagi
- ilk rules test seti
- notification event/inbox ayrimi
- bundle/dedup kurallari
- feed read-path cizelgesi
- visibility policy service sorumluluk listesi
- search visibility standardi
- GetX refactor backlog'u
- cache policy matrix
- release gate checklist taslagi
- final risk triage listesi

## 24. Bu Planin Uygulama Kurali

Bu plan uygulanirken su siraya uyulur:

1. once envanter ve kontrat
2. sonra rules ve write boundary
3. sonra notification ve feed
4. sonra GetX ve cache standardi
5. en son smoke, gate ve triage

Bu sira bozulursa:

- gereksiz refactor
- yanlis oncelik
- sessiz davranis kirigi
- launch oncesi tekrar is

riski artar.

## 25. 5 Gunde Kesin Bitmesi Hedeflenenler

Bu bolum, 5 gunluk sprint sonunda gercekci olarak bitirilmesi hedeflenen alanlari tanimlar.

### 25.1 Plan ve kontrat seviyesinde kesin bitmesi gerekenler

- canonical veri kontrati listesi
- sensitive write inventory
- privacy/block/mute enforcement matrisi
- GetX sorumluluk haritasi
- rules test kapsami
- feed read-path cizelgesi
- notification event/inbox ayrimi
- cache policy matrix
- release gate checklist taslagi
- final risk triage listesi

### 25.2 Uygulama seviyesinde kesin bitmesi hedeflenenler

- Firestore rules icin ilk sadeleştirme dalgasi
- users/posts/follows/notifications/conversations icin ilk kritik rules testleri
- backend-only olmasi gereken write'larin ilk listesi ve ilk gecisleri
- notification bundle/dedup kurallarinin netlestirilmesi
- visibility policy service icin sorumluluk sinirlarinin netlesmesi
- GetX refactor ilk dalga backlog'unun cikmasi

### 25.3 "Bitmis" sayilma kriteri

Bir alan 5 gun sonunda "bitmis" sayilacaksa:

- karar seviyesi net olacak
- etkilenen dosya/moduller belli olacak
- risk ve sahiplik net olacak
- sonraki implementasyon tartismasiz baslayabilecek durumda olacak

## 26. 5 Gunde Zor Ama Kismen Yetişebilecekler

Bu bolum, 5 gunde kismen ilerlemesi gercekci olan ama tam kapanmasi zor alanlari tanimlar.

### 26.1 GetX refactor implementasyonu

Gercekci durum:

- hangi sorumluluklar tasinacak netlesir
- bazi controller'larda ilk tasima yapilabilir
- ama tum controller'lar temizlenmez

### 26.2 Notification backend write gecisi

Gercekci durum:

- uretim kurallari netlesir
- ilk backend-first akislar kurulabilir
- ama tum eski client write noktalarini ayni sprintte kapatmak zor olabilir

### 26.3 Feed / visibility ortak policy uygulamasi

Gercekci durum:

- policy service taslagi cikar
- birkac kritik yuzeyde uygulanabilir
- ama tum feed/search/profile/deep link yuzeylerini ayni anda tam kapatmak zor olabilir

### 26.4 DM summary temizligi

Gercekci durum:

- unread/archive/delete-for-me kontrati netlesir
- bazi daginik noktalar temizlenebilir
- ama chat tarafi cok yuzeyli oldugu icin tum state daginikligini kapatmak zor olabilir

### 26.5 Typesense sync hardening

Gercekci durum:

- create/update/delete kontrati netlesir
- stale fallback kurallari yazilir
- ama replay/backfill ve tam idempotent pipeline 5 gunu asabilir

## 27. 5 Gunde Bilinclı Olarak Sonraya Birakilacaklar

Bu bolum, ilk sprintte bilerek tamamlanmasi hedeflenmeyen alanlari tanimlar.

### 27.1 Fiziksel alan rename / tam migration

Ornekler:

- `userID` -> `userId` toplu fiziksel gecis
- `username` alaninin repo genelinde tamamen kaldirilmasi
- `followersCount` / `followerCount` ciftlerinin tam sadeleştirilmesi

Neden sonraya kaliyor:

- bu is migration/backfill ve compatibility karari gerektirir
- ilk sprintte hedef davranis ve sahiplik standardidir

### 27.2 Tum GetX controller'larin tam temizlenmesi

Neden sonraya kaliyor:

- ilk sprintte hedef tum sistemi yeniden duzenlemek degil
- once en riskli controller'lar ve kurallar hedeflenir

### 27.3 Gelismis observability ve operasyon altyapisi

Neden sonraya kaliyor:

- dashboard, alarm, SLO ve incident playbook cikarimi kritik ama ilk sprintte launch blocker degil

### 27.4 Gelismis abuse engine

Neden sonraya kaliyor:

- ilk sprintte baseline abuse korumalari ve report dedup yeterli
- risk scoring ve coordinated abuse tespiti sonraki fazdir

### 27.5 Ileri feed ranking ve recommendation

Neden sonraya kaliyor:

- For You ilk surumde bilerek basit tutuluyor
- ranking sophistication ilk launch blocker degil

### 27.6 Chat altyapisinin buyuk yeniden tasarimi

Neden sonraya kaliyor:

- mevcut Firestore tabanli DM modeli korunacak
- ilk hedef state, visibility ve guvenlik tutarliligidir

## 28. Sprint Sonu Gercekci Beklenti

5 gun sonunda asagidaki sonucu hedefliyoruz:

- launch-blocker risklerin buyuk bolumu gorunur ve adreslenmis olacak
- ana write boundary kararlari netlesmis olacak
- rules artik testli ve daha dar olacak
- notification/feed/privacy davranisi daha tutarli hale gelecek
- GetX cleanup rastgele degil, planli ilerleyecek

Ancak 5 gun sonunda su iddia edilmeyecek:

- tum teknik borc bitti
- tum moduller refactor edildi
- tum edge-case testleri tamamlandi
- tum operasyonel olgunluk kuruldu

Bu sprintin amaci:

- sistemi launch'a yaklastirmak
- sonraki refactor ve sertlestirme islerini kaotik olmaktan cikarmak

## 29. Launch Blocker Tanimi

Asagidaki maddeler kapanmadan launch karari alinmamali:

- kritik rules boslugu
- private/block/mute davranis celiskisi
- notification write daginikligi nedeniyle veri veya spam riski
- backend-only olmasi gereken write'in client'ta acik kalmasi
- auth/current user bootstrap tutarsizligi
- release gate eksikligi

Asagidaki maddeler launch sonrasi da tasinabilir:

- tam field migration
- ileri recommendation
- tam observability paketi
- gelismis abuse motoru

## 30. Planin Son Kontrol Notu

Bu planin ilk sprint yorumu su sekilde okunmalidir:

- "her seyi 5 gunde bitirecegiz" degil
- "launch oncesi en tehlikeli alanlari kontrol altina alacagiz"

Bu ayirim korunmazsa:

- kapsam patlar
- yarim refactor olur
- sessiz kiriklar artar

Bu ayirim korunursa:

- sistem daha guvenli hale gelir
- sonraki fazlar daha sakin ilerler
- launch oncesi teknik panik azalir

## 31. Proje Uzerinden Dogrulanan Koleksiyon Gercekligi

Bu bolum, statik tarama ile dogrulanan gercek koleksiyon omurgasini ozetler.

### 31.1 Ana root koleksiyonlar

Kod taramasinda aktif gorulen ana koleksiyonlar:

- `users`
- `Posts`
- `conversations`
- `stories`
- `phoneAccounts`
- `userFeeds`
- `celebAccounts`
- `practiceExams`
- `books`
- `educators`
- `questionBank`
- `questions`
- `scholarships`
- `marketStore`
- `tags`
- `adminConfig`
- `ads_campaigns`
- `ads_daily_stats`
- `ads_delivery_logs`
- `ads_impressions`
- `ads_clicks`
- `ads_targeting_index`
- `system_flags`
- `catalog`

### 31.2 `users/{uid}` alt koleksiyonlari

Kodda aktif gorulen ana alt koleksiyonlar:

- `followers`
- `followings`
- `notifications`
- `settings`
- `chatArchives`
- `chatDeletions`
- `account_actions`
- `liked_posts`
- `saved_posts`
- `commented_posts`
- `reshared_posts`
- `readStories`
- `ad`

Uygulama notu:

- onceki bazi eski inventory notlarinda `Takipciler` / `TakipEdilenler` gibi adlar geciyor
- gunluk aktif kod sinyali bugun daha cok `followers` / `followings` cizgisini gosteriyor
- plan bu yuzden yeni sprintte mevcut kod gercegini baz alir

### 31.3 `Posts/{postId}` alt koleksiyonlari

Aktif gorulen ana alt koleksiyonlar:

- `likes`
- `saveds`
- `comments`
- `reshares`
- `postSharers`
- `tags`
- `hashtags`
- `_counters`

Uygulama notu:

- feed ve interaction maliyeti uzerindeki ana baski burada olusur
- planin feed, counter ve notification sertlestirmesi bu yuzden dogrudan `Posts` etrafinda kurgulanmistir

### 31.4 Chat koleksiyon gercekligi

Aktif yapilar:

- `conversations/{conversationId}`
- `conversations/{conversationId}/messages/{messageId}`
- `users/{uid}/chatArchives/{otherUid}`
- `users/{uid}/chatDeletions/{otherUid}`

Uygulama notu:

- DM tarafi sadece tek bir conversation root map yapisi degil
- user bazli archive/delete override koleksiyonlari da aktif
- bu nedenle ilk sprintte hedef "chat'i bastan tasarlamak" degil, bu cift yapinin davranisini netlestirmektir

### 31.5 Notification koleksiyon gercekligi

Aktif yol:

- `users/{uid}/notifications/{notificationId}`

Destekleyici yol:

- `users/{uid}/settings/notifications`

Uygulama notu:

- notification inbox yapisi zaten aktif ve repository/snapshot katmanina bagli
- bu nedenle plan yeni inbox tasarimi degil, mevcut inbox'in backend kontrollu sertlestirilmesidir

## 32. Proje Uzerinden Dogrulanan Function Gercekligi

Bu bolum, function tarafinda gercekten mevcut olan kritik omurgayi ozetler.

### 32.1 Aktif function gruplari

Kod taramasinda aktif gorulen ana function aileleri:

- user schema normalization
- mandatory follow enforcement
- phoneAccounts sync/backfill
- notification write triggers
- scheduled account deletion
- scheduled content publishing
- hybrid feed fan-out / fan-in
- counter sharding
- author denormalization
- Typesense posts
- Typesense users/tags
- Typesense education
- Typesense market
- reports
- badge admin
- user ban admin
- nickname change
- short links
- ads center
- HLS transcode
- thumbnails
- story archive

### 32.2 Kritik bulgu: sistemde zaten normalizer var

`functions/src/index.ts` icinde aktif olarak:

- `users/{uid}` uzerinde schema normalize eden trigger var
- `usernameLower`, `username`, `nickname`, `displayName` normalize ediliyor
- `userID` root alani delete ediliyor
- advertiser data `users/{uid}/ad/info` altina tasiniyor

Bu nedenle ilk sprintte:

- tum alanlari teorik olarak yeniden adlandirma hedefi dogru degil
- mevcut normalizer ile uyumlu, kontrollu kontrat sertlestirmesi dogru hedeftir

### 32.3 Kritik bulgu: functions zaten backfill ve admin omurgasi tasiyor

Aktif olarak mevcut olan callable / schedule alanlari:

- backfill user/phone/post alanlari
- nickname change callable
- badge admin callable
- user ban admin callable
- reports callable
- Typesense reindex callable'lari
- hybrid feed backfill callable'i

Bu nedenle planin sensitive write boundary kismi:

- sifirdan backend yazmak degil
- var olan function omurgasini temizce sahiplik altina almak uzerine kurulmalidir

### 32.4 Kritik bulgu: eski dokumantasyonun bir kismi tam guncel degil

Ozellikle:

- `/Users/turqapp/Desktop/TurqApp/docs/FIRESTORE_COLLECTION_INVENTORY_2026-03-05.md`

dosyasi degerli bir referans olsa da, bugunku aktif kodun tamamini birebir yansitmiyor.

Ornek:

- eski inventory'de `Takipciler` / `TakipEdilenler` on planda
- bugunku aktif kod taramasinda `followers` / `followings` belirgin

Bu nedenle uygulama sirasinda:

- eski inventory notlari tek kaynak kabul edilmeyecek
- aktif kod taramasi ve mevcut repository/function gercegi baz alinacak

## 33. Bu Kontrol Sonrasi Guncellenen Uygulama Kuralı

Bu plan uygulanirken su 3 kural korunur:

1. aktif repo gercegi teorik idealden once gelir
2. ilk sprintte davranis ve ownership standardi hedeflenir, tam migration degil
3. mevcut function omurgasi yeniden icat edilmez, temizlenip sertlestirilir

## 34. Ek Kritik Basliklar

Bu bolum, ilk tur planlamada kolayca gozden kacabilecek ama launch oncesi mutlaka dikkate alinmasi gereken alanlari toplar.

### 34.1 Data migration ve geri donus plani

Risk:

- migration veya alan standardizasyonu sirasinda beklenmeyen veri kaybi
- yanlis field cleanup sonrasi client uyumsuzlugu

Eksik kalmaması gerekenler:

- migration once-sirasi-sonrasi kontrol listesi
- geri donus stratejisi
- hangi alanlar soft-deprecate, hangileri fiziksel silinecek

Karar:

- ilk sprintte migration rewrite yok
- ama migration/rollback oyunu ayri backlog olarak cikacak

### 34.2 Storage ve media guvenligi

Risk:

- private icerik URL sizmasi
- silinmis ya da yasakli icerige media erisiminin acik kalmasi
- cache-control yanlislari nedeniyle stale private media

Eksik kalmaması gerekenler:

- `storage.rules` kontrolu
- media erisim politikalari
- signed access gereksinimi
- private/deleted content icin medya davranisi

Karar:

- media pipeline rewrite yok
- ama storage security ve access policy launch oncesi ayri kontrol edilir

### 34.3 Offline / retry storm / duplicate submit

Risk:

- ag gidip gelince cift write
- optimistic state ile kalici state'in ayrismasi
- queue tekrar oynatma sonrasi duplicate interaction

Eksik kalmaması gerekenler:

- offline mode servisleri
- retry queue
- duplicate submit korumalari
- rollback davranisi

Karar:

- launch oncesi en az kritik write path'lerde duplicate/ retry davranisi test backlog'una eklenecek

### 34.4 Eski istemci / minimum surum politikasi

Risk:

- yeni rules veya yeni function davranisi ile eski client cakisabilir

Eksik kalmaması gerekenler:

- minimum client version stratejisi
- breaking backend degisikliklerinde version gate
- Remote Config ile disable/fallback plani

Karar:

- uygulama canli degil diye bu alan sifir risk degil
- launch oncesi release policy backlog'una eklenir

### 34.5 Firestore index ve query maliyeti

Risk:

- sorgular mantiken dogru olsa da pahali veya indeks bagimli olabilir

Eksik kalmaması gerekenler:

- `firestore.indexes.json` ile sorgu kullanimlarinin capraz kontrolu
- pahali query kombinasyonlari
- feed, notifications, chat listing ve search hydration icin indeks notlari

Karar:

- bu alan launch blocker olabilir
- ilk sprintte en az indeks audit backlog'u cikarilir

### 34.6 Delete lifecycle ve orphan cleanup

Risk:

- post silinince yorum, reshare, media, notification artiklari kalabilir
- user silinince graph/media/cache artigi kalabilir

Eksik kalmaması gerekenler:

- post delete akisi
- user delete akisi
- story delete/media cleanup
- orphan data cleanup standardi

Karar:

- silme yasam dongusu ayri checklist olarak backlog'a eklenecek

### 34.7 App Check ve abuse gate'leri

Risk:

- function ve upload akislarinda App Check veya rate limit eksigi abuse'a yol acabilir

Eksik kalmaması gerekenler:

- hangi callable'larda App Check zorunlu
- signup/search/upload abuse noktalarinda rate limit
- bot ve script kullanimina karsi baseline savunma

Karar:

- App Check var sayip gecilmeyecek
- hangi akis icin ne koruma oldugu dokumante edilecek

### 34.8 Push delivery politikasi

Risk:

- inbox mantigi dogru olsa da push spam veya eksik push davranisi ortaya cikabilir

Eksik kalmaması gerekenler:

- hangi event push olur
- hangi event sadece inbox olur
- bundle push mantigi
- high priority / normal priority ayrimi

Karar:

- notification planina push delivery tablosu eklenir

### 34.9 Rollback ve kill switch pratigi

Risk:

- canliya cikis sonrasi problemli degisiklik kapatilamaz

Eksik kalmaması gerekenler:

- function rollback adimi
- rules rollback adimi
- Remote Config kill switch
- sorunlu feature icin acil kapatma yolu

Karar:

- release gate checklist'i tek basina yeterli sayilmayacak
- rollback pratigi de backlog'a yazilacak

### 34.10 Analytics event taxonomy

Risk:

- launch sonrasi retention/funnel/abuse/recommendation sinyalleri eksik kalir

Eksik kalmaması gerekenler:

- temel event listesi
- isimlendirme standardi
- hangi event teknik KPI, hangisi urun KPI

Karar:

- ilk sprintte implementasyon degil ama event taxonomy backlog'u cikarilir

## 35. Ek Kritik Basliklarin Onceligi

Bu basliklar arasinda launch oncesi en kritik ilk 5 alan:

1. storage ve media guvenligi
2. offline / retry storm / duplicate submit
3. delete lifecycle ve orphan cleanup
4. push delivery politikasi
5. rollback ve kill switch pratigi

Bu alanlar launch blocker seviyesine yukselebilir.

## 36. Launch Karar Tablosu

### 36.1 Launch icin sart olanlar

- `P0-1` Firestore rules sertlestirme
- `P0-2` sensitive write boundary
- `P0-3` notification write/aggregation sertlestirmesi
- `P0-4` feed ve visibility disiplini
- `P0-5` GetX ilk sorumluluk ayrimi backlog'u ve en riskli alanlar icin ilk uygulama
- kritik rules testlerinin calisiyor olmasi
- release gate checklist'inin tanimli ve uygulanabilir olmasi
- private/block/mute davranislarinin ana yuzeylerde tutarli olmasi

### 36.2 Launch sonrasi da tasinabilir olanlar

- `P1-2` Typesense sync hardening'in ileri seviyesi
- `P1-3` DM state disiplini tam kapanisi
- `P1-4` counter sertlestirmenin ileri evresi
- tum GetX controller'larin derin temizlik refactor'u
- `P2-1` moderation tooling'in tam urunlesmesi
- `P2-2` observability dashboard ve alarm olgunlugu
- `P2-3` feature flag / rollout sisteminin ileri seviyesi
- `P2-4` gelismis abuse engine
- fiziksel field migration ve tam backfill temizlikleri

### 36.3 Launch karari icin kisa kural

Su mantik uygulanir:

- `P0` kapanmadan launch yok
- `P1` buyuk olcude tamamlanmadan launch riskli
- `P2` backlog + sahiplik + zemin hazirsa launch sonrasi tasinabilir
