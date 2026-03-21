# Android Ekran Test Matrisi

Tarih: 21 Mart 2026

## Amac

Bu not, Android tarafinda tum uygulama yuzeylerini ekran ekran taramak, hangi alanin otomatik yesil oldugunu, hangisinin manuel dogrulandigini ve hangisinin hala acik oldugunu tek yerde tutmak icin acildi.

Bu dosya, Android cihaz smoke turlari icin kanonik checklist olarak kullanilsin.

## Legend

- `OTOMATIK_YESIL`: integration smoke veya scripted replay ile gecti
- `MANUEL_YESIL`: gercek Android cihazda elle dogrulandi
- `ANDROID_ACIK`: Android ozel tuning veya runtime sorunlari var
- `KAPSAM_BEKLIYOR`: yuzey var ama bu fazda sistematik sweep yapilmadi
- `DUSUK_ONCELIK`: cekirdek akis degil, son turda taranabilir

## Android Tarafinda iOS'tan Geri Kalan Ana Nedenler

1. `Short` ve `Feed` video gecisleri Android'de `AndroidView + ExoPlayer` uzerinden gidiyor; iOS tarafi `AVPlayer` ile daha stabil.
2. Android Exo buffer profili daha agresif; iOS tarafindaki gibi stability-first degil.
3. Android non-fullscreen reveal yolu daha erken aciliyor; siyah frame / gec first-frame hissi uretebiliyor.
4. Android playback telemetry halen iOS kadar zengin degil; dropped frame / rebuffer / bitrate switch sinyalleri az.
5. Platform-view, reklam ve scroll geometri hassasiyeti Android'de daha yuksek.

## Bu Fazda Yesil Olanlar

### Otomatik yesil

- `Feed`
- `Explore`
- `Profile`
- `Short`
- `Notifications`

### Manuel yesil

- `Market`
- `Is Veren`
- `Ozel Ders`
- `Online Sinav`
- `Cevap Anahtari`
- `MyProfile`
- `SocialProfile`

## Android Sweep Oncelik Sirasi

1. `Feed`
2. `Short`
3. `MyProfile`
4. `SocialProfile`
5. `Notifications`
6. `SavedPosts`
7. `Explore/SearchedUser`
8. `Market`
9. `Is Veren`
10. `Ozel Ders`
11. `Online Sinav`
12. `Cevap Anahtari`
13. `Chat`
14. `Story`
15. `PostCreator`
16. `Scholarships / PreviousQuestions / CikmisSorular / Tests`
17. `Settings / raw-form ekranlari`

## Matris

| Alan | Ekranlar | Kapsam | Durum | Android odak / acik |
|---|---|---|---|---|
| App shell | `Splash`, `SignIn`, `NavBar`, `Maintenance` | smoke + manuel | `OTOMATIK_YESIL` | login, route ve ana nav aciliyor; uzun sureli auth/session churn icin son sweep yine gerekli |
| Feed / Agenda | `Feed`, `ClassicContent`, `SinglePost`, `Comments`, `TopTags`, `TagPosts`, `FloodListing`, `PostLikeListing`, `PostReshareListing` | smoke + manuel | `ANDROID_ACIK` | ilk tuning sonrasi siyah frame yakalanmadi; feed video loop kapandi ve replay overlay geldi; current user + feed/story avatar cozulumu temiz. Kalan acik: uzun scroll autoplay tuning ve decoder warning gozlemi |
| Short | `Short`, `DynamicShort`, `SingleShort`, `PhotoShorts` | smoke + manuel | `ANDROID_ACIK` | ilk tuning sonrasi acilis, 4-swipe stress ve feed geri donus temiz. Kalan acik: uzun swipe serilerinde decoder/churn sinyali olcumu |
| Explore | `Explore`, `SearchedUser`, recent search | smoke + manuel | `MANUEL_YESIL` | ana explore ve `SearchedUser` arama sonucu temiz acildi; preview gate ve uzun arama/geri donus turu yine ikinci sweep ister |
| Notifications | `InAppNotifications`, `notification_content` | smoke + manuel | `MANUEL_YESIL` | empty state Android cihazda temiz acildi; uzun liste + route return + content derinligi icin ikinci sweep gerekli |
| My Profile | `MyProfile`, `LikedPosts`, `Archives`, `MyStatistic`, `MyQRCode` | manuel | `MANUEL_YESIL` | profil video sekmesi acildi, video detail acildi ve geri donuste ayni video gridine temiz dondu |
| Social Profile | `SocialProfile`, followers, report, qr | manuel | `MANUEL_YESIL` | feed'den baska kullanici profili acildi ve geri donuste feed'e temiz dondu |
| Profile settings | `EditProfile`, `AddressSelector`, `JobSelector`, `Interests`, `AboutProfile`, `Settings`, `Policies`, `DeleteAccount`, `Cv`, `BiographyMaker`, `Editor*`, `LangSelector`, `ViewChanger`, `SocialMediaLinks`, `BecomeVerifiedAccount`, `ProfileContact` | manuel parcali | `KAPSAM_BEKLIYOR` | bunlarin bir kismi bilincli raw; warm-open ve form state Android sweep'i eksik |
| Saved profile surfaces | `SavedPosts`, `BlockedUsers`, `FollowingFollowers` | parcali manuel | `MANUEL_YESIL` | `SavedPosts`, `BlockedUsers` ve `FollowingFollowers` Android cihazda temiz acildi; relation counters icin test hook eklendi ve liste acilisi dogrulandi |
| Market | `Market`, `detail`, `search`, `saved`, `offers`, `my items`, `create`, `filter` | manuel | `MANUEL_YESIL` | ilk acilis stabil; `Ilan Detayi -> liste` geri donusu temiz, owner `Tekliflerim` ekrani veriyle acildi, `Kaydettiklerim` ve `Ilanlarim` yuzeyleri Android cihazda veriyle dogrulandi. `Ilan Ekle` akisi sehir seciciye kadar acildi; `filter` sheet `Sehir / Fiyat Araligi / Siralama / Temizle / Uygula` ile temiz acildi |
| Job | `JobContent`, `JobDetails`, `SavedJobs`, `MyApplications`, `MyJobAds`, `CareerProfile`, `FindingJobApply`, `JobCreator`, `ApplicationReview` | manuel + omurga sweep | `ANDROID_ACIK` | ana liste stabil; owner `JobDetails` ve listeye geri donus temiz. Gercek applicant hesabi ile `Basvur` akis sweep'i eksik |
| Tutoring | `Tutoring`, `detail`, `saved`, `my tutorings`, `location based`, `create` | manuel + omurga sweep | `ANDROID_ACIK` | ana liste stabil; `detail` Android cihazda temiz acildi. `create/save` akislarinin genis turu eksik |
| Practice exams | `Online Sinav`, `saved`, `my exams`, `type list`, `sonuclarim` | manuel + omurga sweep | `ANDROID_ACIK` | `Online Sinav` liste, detail modal ve owner CTA Android cihazda temiz dogrulandi; `Denemeler` tip listesinde `LGS` karti acilip `LGS Testleri` ekrani dogrulandi. Ayrı applicant hesapla gercek `Basvur` akisi ve `sonuclarim`/saved sweep'i henuz eksik |
| Answer key | `Cevap Anahtari`, `book detail`, `saved books`, `optics published` | manuel + omurga sweep | `ANDROID_ACIK` | liste stabil; `Kitap Detayi` ve `Cevap Anahtarlari` preview Android cihazda temiz acildi. `saved books/optics published` ikinci sweep gerektiriyor |
| Other education | `Scholarships`, `PreviousQuestions`, `CikmisSorular`, `Tests`, `Antreman3`, `QuestionBank` | parcali | `ANDROID_ACIK` | `Burslar` liste ve `Burs Detayi` Android cihazda temiz acildi. `Soru Bankasi` icin LGS/YKS vb. kartlara test hook eklendi ve `LGS` karti Android cihazda acildi. Ortak search focus davranisi daraltildi; dump'ta `EditText` artik `focused=false`. Kalan acik: genis UX sweep ve diger alt yuzeyler |
| Story | `StoryRow`, `StoryViewer`, `StoryMaker`, `StoryMusic`, `Highlights`, `DeletedStories` | parcali | `KAPSAM_BEKLIYOR` | video/media ve gesture davranisi Android'de mutlaka sweep ister |
| Chat | `ChatListing`, `CreateChat`, `MessageContent`, `LocationShareView` | parcali | `KAPSAM_BEKLIYOR` | liste, acilis, geri donus ve attachment akis turu gerekli |
| Post creation | `PostCreator`, `CreatorContent`, `EditPost`, `UrlPostMaker`, `hashtag_text_post` | parcali | `KAPSAM_BEKLIYOR` | upload, local insert, refresh persistence, route return Android sweep'i gerekli |
| Share / misc | `ShareGrid`, `RecommendedUserList`, `SpotifySelector`, `TypeWriter` | parcali | `DUSUK_ONCELIK` | cekirdek akis degil; son turda taranabilir |

## Feed / Short Android Ozel Kabul Kriterleri

### Feed

- cold open sonrasi ilk gorunur postta siyah frame olmamali
- scroll penceresinde `player recreate` dalgasi gozle gorulur seviyede olmamali
- refresh sonrasi liste bosalmamali
- detail ve profile gidis-donusunde ayni bolgeye stabil donmeli

### Short

- ilk acilista siyah ekran olmamali
- yukari/asagi gecislerde ses-goruntu gec baglanmamali
- yeni short'a geciste onceki player gec cozulup yeni player gec acilmamali
- geri donuste aktif short korunmali

## Sonraki Android Sweep Uygulamasi

### Dalga 1

- `Feed`
- `Short`
- `MyProfile`
- `SocialProfile`
- `Notifications`
- `SavedPosts`
- `Explore/SearchedUser`

Durum:

- `Feed`: kismi kapandi
- `Short`: kismi kapandi
- `MyProfile`: kapandi
- `SocialProfile`: kapandi
- `Notifications`: kapandi
- `SavedPosts`: kapandi
- `Explore/SearchedUser`: kapandi

### Dalga 2

- `Market`
- `Is Veren`
- `Ozel Ders`
- `Online Sinav`
- `Cevap Anahtari`
- `Scholarships`
- `PreviousQuestions`
- `CikmisSorular`

### Dalga 3

- `Chat`
- `Story`
- `PostCreator`
- `Settings/raw-form` ekranlari

## Bu Dosya Ile Master Plan Iliskisi

- Stratejik plan ve genel ilerleme:
  [TURQAPP_YAPILACAKLAR_2026-03-20.md](/Users/turqapp/Desktop/TurqApp/docs/TURQAPP_YAPILACAKLAR_2026-03-20.md)
- Mimari audit ve cache-first notlari:
  [cache_first_audit_2026_03_19.md](/Users/turqapp/Desktop/TurqApp/docs/architecture/cache_first_audit_2026_03_19.md)

Bu matris, master planin Android saha uygulama ekidir.
