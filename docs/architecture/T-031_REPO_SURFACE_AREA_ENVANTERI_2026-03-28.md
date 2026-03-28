# T-031 Repo Surface Area Envanteri

## Genel Gorunum

- Mevcut `lib` Dart dosyasi sayisi: `2768`
- Bu is, toplam dosya sayisini keyfi dusurmek icin degil; sicak akislarin
  dosya yuzeyi maliyetini gormek ve kontrollu sadeleştirme hedefleri
  olusturmak icin yapildi

## Yuzeyi En Buyuk Alanlar

- `Education/Pasaj`: `690`
- `Core Services`: `384`
- `Feed/Playback Surface`: `248`
- `Market/Job`: `150`
- `Agenda`: `105`
- `Story`: `97`
- `Startup/Auth/Session`: `93`
- `JobFinder`: `82`
- `Chat`: `75`
- `Profile/Settings/Admin`: `73`

## Sicak Kume Kırilimlari

### Education/Pasaj

- `Scholarships`: `157`
- `AnswerKey`: `126`
- `Tests`: `114`
- `PracticeExams`: `107`
- `Tutoring`: `92`

### Core Services

- `SegmentCache`: `36`
- `PlaybackIntelligence`: `26`
- `Ads`: `19`
- `CacheFirst`: `18`

### Kullanici Akisina Gore Kume Buyuklukleri

- `Startup/Auth/Session`: `93`
  - `SignIn` + `Splash` + `Services` + `Runtime`
- `Feed/Playback Surface`: `248`
  - `Agenda` + `Short` + `Story` + `hls_player` + `PlaybackRuntime`
- `Creator/Publish`: `54`
  - `PostCreator` + `EditPost`
- `Profile/Settings/Admin`: `73`
- `Market/Job`: `150`

## Sicak Yol Hedef Listesi

### Hedef-1 Startup/Auth/Session

- Mevcut yuzey: `93`
- Hedef: oturum, account-center, splash ve sign-in akislarini daha az dosya
  ile okunur hale getirmek
- Odak dosyalar:
  - `current_user_service*`
  - `account_center_service*`
  - `sign_in_*`
  - `splash_*`
- Sadelestirme butcesi:
  - `10-15` dosya azalis
  - `1` kontrollu dalga

### Hedef-2 Feed/Playback Surface

- Mevcut yuzey: `248`
- Hedef: `Agenda/Short/Story/HLS` etrafindaki playback akislarini daha az
  dosya gecisi ile izlenebilir yapmak
- Odak dosyalar:
  - `agenda_*`
  - `story_*`
  - `short_*`
  - `hls_player/*`
  - `SegmentCache/*`
- Sadelestirme butcesi:
  - `20-30` dosya azalis
  - `2` kontrollu dalga

### Hedef-3 Market/Job + Creator

- Mevcut yuzey: `204`
  - `Market/Job`: `150`
  - `Creator/Publish`: `54`
- Hedef: create/edit/detail akislarinda ayni davranisi anlamak icin acilan
  dosya sayisini azaltmak
- Odak dosyalar:
  - `job_*`
  - `market_*`
  - `post_creator_*`
- Sadelestirme butcesi:
  - `15-25` dosya azalis
  - `2` kontrollu dalga

### Hedef-4 Profile/Settings/Admin

- Mevcut yuzey: `73`
- Hedef: ayarlar, diagnostics ve admin akislarinda library/part gecisini
  azaltmak
- Odak dosyalar:
  - `settings*`
  - `AdsCenter/*`
  - `admin_*`
- Sadelestirme butcesi:
  - `8-12` dosya azalis
  - `1` kontrollu dalga

### Hedef-5 Education/Pasaj

- Mevcut yuzey: `690`
- Hedef: repo genelindeki en buyuk dosya yuzeyi alanini dogrudan toplu merge
  ile degil, alt alan bazli dalgalarla ele almak
- Once alt hedeflenecek alanlar:
  - `Scholarships`
  - `AnswerKey`
  - `Tests`
  - `PracticeExams`
- Sadelestirme butcesi:
  - ilk dalgada yalniz `25-40` dosyalik kontrollu azaltma
  - alt alan bazli ayri plan gerektirir

## Kural

- Repo geneline toplu dosya birlestirme yapilmaz
- Sadece sicak kume bazli ve davranis testleriyle korunan dalgalar acilir
- Dosya sayisi tek basina hedef degildir; okuma yolu ve degisiklik guveni
  ana metriktir

## Dogrulama

- `find lib -name '*.dart' | wc -l`
- `python3` ile alan bazli sayim
- `git diff --check`
