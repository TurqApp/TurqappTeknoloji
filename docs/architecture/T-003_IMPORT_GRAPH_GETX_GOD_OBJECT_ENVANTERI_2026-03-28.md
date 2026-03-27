# T-003 Import Graph, GetX Locator ve God-Object Envanteri

Tarih: `2026-03-28`
Plan kaynagi: [TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md](/Users/turqapp/Desktop/TurqApp/docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md)

Bu artifact, `T-003` kapsaminda yalnizca mevcut mimari yuzeyi gorunur hale getirmek icin uretildi.
Bu dosya guard uygulamaz; guard kurallari `T-009` kapsamindadir.

## 1. Ozet Snapshot

| Metrik | Deger |
| --- | --- |
| `lib` altindaki `.dart` dosyasi | `2753` |
| package import satiri | `5639` |
| `Modules/*` hedefli import satiri | `821` |
| `Get.find/put/delete/isRegistered` kullanimi | `1034` |
| `maybeFind* / ensure*` helper kullanimi | `2700` |
| `extends GetxController` sayisi | `196` |

Ana okuma:

- import yogunlugu yuksek
- feature-to-feature baglanti dogrudan import ve locator uzerinden akiyor
- gizli bagimliliklar yalniz `Get.find` ile sinirli degil; `maybeFind* / ensure*` wrapper'lari daha buyuk bir yuzey olusturuyor

## 2. Import Graph Envanteri

### 2.1 Kök bağımlılık dağılımı

`lib` altindaki package importlari en cok asagidaki koklere gidiyor:

| Kok | Sayi |
| --- | --- |
| `Core` | `2008` |
| `Modules` | `821` |
| `Models` | `306` |
| `Services` | `260` |

Okuma:

- yatay kok bagimliligi cok yuksek
- `Core` gercek ortak cekirdekten cok "her sey buradan goruluyor" yuzeyi gibi davraniyor

### 2.2 Feature-to-feature import baskısı

`Modules/*` hedefli importlarin dagilimi:

| Hedef feature | Sayi |
| --- | --- |
| `Education` | `387` |
| `Profile` | `137` |
| `Agenda` | `74` |
| `Story` | `47` |
| `Market` | `38` |
| `Chat` | `28` |
| `JobFinder` | `24` |

Okuma:

- en agir feature baglanti merkezi `Education / Pasaj`
- `Profile`, `Agenda`, `Story`, `Market`, `Chat` ve `JobFinder` de yuksek baglanti yuzeyi tasiyor

### 2.3 En çok import yapan dosyalar

| Dosya | Package import sayisi |
| --- | --- |
| [education_view.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Education/education_view.dart) | `67` |
| [settings.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/settings.dart) | `66` |
| [profile_view.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/MyProfile/profile_view.dart) | `54` |
| [agenda_content.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content.dart) | `54` |
| [classic_content.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/ClassicContent/classic_content.dart) | `44` |
| [social_profile.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/social_profile.dart) | `42` |
| [chat_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/chat_controller.dart) | `30` |

Okuma:

- shell/giris dosyalari cok fazla bagimlilik topluyor
- `Education`, `Settings`, `Profile` ve `Agenda` ekranlari "toplayici dosya" davranisi gosteriyor

### 2.4 Feature içinden service/repository bağımlılığı en yüksek dosyalar

| Dosya | `Services/Core/Services/Core/Repositories` import sayisi |
| --- | --- |
| [settings.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/settings.dart) | `22` |
| [short_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_controller.dart) | `16` |
| [agenda_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/agenda_controller.dart) | `15` |
| [splash_view.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_view.dart) | `14` |
| [profile_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/MyProfile/profile_controller.dart) | `14` |
| [classic_content.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/ClassicContent/classic_content.dart) | `14` |
| [agenda_content.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content.dart) | `14` |
| [chat_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/chat_controller.dart) | `11` |

Okuma:

- presentation ve feature controller dosyalari service/repository yuzeyi ile asiri temasli
- `Splash`, `Settings`, `Agenda`, `Short`, `Profile`, `Chat` T-009 guard tasariminda once ele alinacak alanlar

## 3. GetX Locator Envanteri

### 3.1 Dogrudan GetX locator kullanimi

| Kullanım | Sayi |
| --- | --- |
| `Get.find / Get.put / Get.delete / Get.isRegistered` toplam | `1034` |

### 3.2 Wrapper/yardımcı locator kullanımı

| Kullanım | Sayi |
| --- | --- |
| `maybeFind* / ensure*` toplam | `2700` |

Okuma:

- gizli bagimlilik problemi `Get.find` ile sinirli degil
- repo genelinde locator davranisi yardimci wrapper'larla genisletilmis
- `T-009` yalnizca `Get.find` degil, bu wrapper yuzeylerini de kural setine almak zorunda

### 3.3 Locator trafiği en yüksek dosyalar

| Dosya | Locator/wrapper sinyali |
| --- | --- |
| [education_view_actions_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Education/education_view_actions_part.dart) | `33` |
| [splash_view_startup_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_view_startup_part.dart) | `28` |
| [photo_short_content_controller_post_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Social/PhotoShorts/photo_short_content_controller_post_part.dart) | `22` |
| [splash_view_warm_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_view_warm_part.dart) | `21` |
| [settings.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/settings.dart) | `21` |
| [short_content_controller_actions_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_content_controller_actions_part.dart) | `19` |
| [agenda_content_header_navigation_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content_header_navigation_part.dart) | `17` |
| [qa_lab_bridge.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Services/qa_lab_bridge.dart) | `17` |
| [post_delete_service.dart](/Users/turqapp/Desktop/TurqApp/lib/Services/post_delete_service.dart) | `16` |
| [education_controller_search_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Education/education_controller_search_part.dart) | `16` |

Okuma:

- `Pasaj`, `Splash`, `Short`, `Agenda` ve `Settings` locator baglantisinin en yogun oldugu alanlar
- `qa_lab_bridge.dart` test/runtime koyu bagimliliklarin da locator uzerinden aktigini gosteriyor

## 4. God-Object / God-Cluster Adaylari

Bu bolum kesin hukum degil, envanter amacli "yuksek riskli aday" listesidir.
Asagidaki adaylar satir hacmi, import baskisi ve/veya locator yogunlugu ile secildi.

### 4.1 Buyuk dosya adaylari

| Dosya | Satir |
| --- | --- |
| [app_translations.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Localization/app_translations.dart) | `19828` |
| [external_profession_data_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/external_profession_data_part.dart) | `9106` |
| [admob_kare.dart](/Users/turqapp/Desktop/TurqApp/lib/Ads/admob_kare.dart) | `1202` |
| [device_log_reporter.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Services/device_log_reporter.dart) | `787` |
| [classic_content_body_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/ClassicContent/classic_content_body_part.dart) | `763` |
| [turqapp_suggestion_admin_view.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/AdsCenter/turqapp_suggestion_admin_view.dart) | `740` |
| [explore_controller_feed_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Explore/explore_controller_feed_part.dart) | `696` |
| [post_repository_query_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository_query_part.dart) | `668` |

Not:

- `app_translations.dart` ve veri listesi dosyalari islevsel olarak "god object" degil; bunlar buyuk statik yuk adaylari
- `post_repository_query_part.dart`, `explore_controller_feed_part.dart`, `classic_content_body_part.dart` ise davranis tasiyan buyuk sicak dosyalardir

### 4.2 Buyuk merkez kümeleri

| Kume | Toplam satir |
| --- | --- |
| `current_user_service*` | `2039` |
| `education_controller* + education_view* + pasaj_tabs.dart` | `1743` |
| `splash_view*` | `1270` |
| `agenda_controller*` | `3043` |

Okuma:

- sorun sadece buyuk tekil dosya degil; buyuk "part kumesi" de var
- `Agenda`, `CurrentUserService`, `Pasaj shell` ve `Splash` T-010/T-012/T-017 hattinin merkez adaylari olarak teyit edildi

## 5. T-009 Icin Net Ciktilar

Bu envanter, `T-009` icin asagidaki guard hedeflerini dogrudan destekliyor:

- `presentation_cannot_touch_infra`
- `no_cross_feature_internal_imports`
- `no_service_locator_outside_root`
- `legacy_folder_freeze`
- `no_new_part_sprawl`

Ilk guard dalgasinda once odaklanilacak alanlar:

- `lib/Modules/Education/**`
- `lib/Modules/Splash/**`
- `lib/Modules/Agenda/**`
- `lib/Modules/Short/**`
- `lib/Modules/Profile/**`
- `lib/Modules/Chat/**`
- `lib/Services/current_user_service*`

## 6. Uretim Komutlari

```bash
rg -n "^import 'package:[^']+';" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | wc -l
rg -n "^import 'package:[^']+/Modules/" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | wc -l
rg -n "^import 'package:[^']+/(Core|Modules|Services|Models)/" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | awk ...
rg -n "^import 'package:[^']+/Modules/" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib/Modules | awk ...
rg -n "^import 'package:[^']+/Services/|^import 'package:[^']+/Core/Services/|^import 'package:[^']+/Core/Repositories/" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib/Modules | awk ...
rg -o "Get\\.(find|put|delete|isRegistered)" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | wc -l
rg -o "\\b(maybeFind[A-Za-z0-9_]*|ensure[A-Za-z0-9_]*)\\b" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | wc -l
rg -n "Get\\.(find|put|delete|isRegistered)|\\b(maybeFind[A-Za-z0-9_]*|ensure[A-Za-z0-9_]*)\\b" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | awk ...
find /Users/turqapp/Desktop/TurqApp/lib -type f -name '*.dart' -print0 | xargs -0 wc -l | sort -nr | head -n 20
find /Users/turqapp/Desktop/TurqApp/lib/Services -type f -name 'current_user_service*.dart' -print0 | xargs -0 wc -l | tail -n 1
find /Users/turqapp/Desktop/TurqApp/lib/Modules/Splash -type f -name 'splash_view*.dart' -print0 | xargs -0 wc -l | tail -n 1
find /Users/turqapp/Desktop/TurqApp/lib/Modules/Education -type f \( -name 'education_controller*.dart' -o -name 'education_view*.dart' -o -name 'pasaj_tabs.dart' \) -print0 | xargs -0 wc -l | tail -n 1
find /Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda -type f -name 'agenda_controller*.dart' -print0 | xargs -0 wc -l | tail -n 1
```
