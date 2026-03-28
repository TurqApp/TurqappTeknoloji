# T-027 Runtime Servis Sahiplik ve Erisim Envanteri

## Amac

Upload, playback, cache, network ve device-session runtime servislerinin
sahipligini, dis temas yuzeylerini ve bir sonraki refactor isleri icin sinir
hedeflerini netlestirmek.

## Incelenen Runtime Servisleri

### 1. UploadQueueService

- Ana dosya: [upload_queue_service.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Services/upload_queue_service.dart)
- Dis referans sayisi: `8`
- Dis temas gruplari:
  - `Modules`: `6`
  - `Core`: `2`
- Temel temas ornekleri:
  - [nav_bar_controller_lifecycle_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/NavBar/nav_bar_controller_lifecycle_part.dart)
  - [splash_dependency_registrar.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_dependency_registrar.dart)
  - [post_creator_controller_support_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/PostCreator/post_creator_controller_support_part.dart)
  - [settings.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/settings.dart)
  - [agenda_content_body_widgets_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/AgendaContent/agenda_content_body_widgets_part.dart)
- Sahiplik yorumu:
  - Bu servis `Runtime Data / Upload Pipeline` sahibi olmali.
  - `PostCreator` ve medyali publish akislarinin altyapisi, `NavBar/Splash`
    gibi shell kodlarindan bagimsiz bir runtime boundary ile gorulmeli.

### 2. VideoStateManager

- Ana dosya: [video_state_manager.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Services/video_state_manager.dart)
- Dis referans sayisi: `21`
- Dis temas gruplari:
  - `Modules`: `20`
  - `main.dart`: `1`
- Temel temas ornekleri:
  - [main.dart](/Users/turqapp/Desktop/TurqApp/lib/main.dart)
  - [nav_bar_controller_lifecycle_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/NavBar/nav_bar_controller_lifecycle_part.dart)
  - [agenda_controller_feed_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/agenda_controller_feed_part.dart)
  - [story_viewer.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Story/StoryViewer/story_viewer.dart)
  - [short_view_playback_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart)
  - [profile_controller_selection_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/MyProfile/profile_controller_selection_part.dart)
- Sahiplik yorumu:
  - Bu servis `Runtime Media / Playback Coordination` sahibi olmali.
  - Sorun servis varligi degil; `Agenda`, `Short`, `Story`, `Profile`,
    `NavBar` ve `main` tarafindan cok sayida dogrudan cagri almasi.

### 3. NetworkAwarenessService

- Ana dosya: [network_awareness_service.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Services/network_awareness_service.dart)
- Dis referans sayisi: `23`
- Dis temas gruplari:
  - `Modules`: `12`
  - `Core`: `10`
  - `main.dart`: `1`
- Temel temas ornekleri:
  - [main.dart](/Users/turqapp/Desktop/TurqApp/lib/main.dart)
  - [splash_view_warm_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_view_warm_part.dart)
  - [splash_post_login_warmup.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_post_login_warmup.dart)
  - [chat_controller_support_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/chat_controller_support_part.dart)
  - [creator_content_controller_media_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/PostCreator/CreatorContent/creator_content_controller_media_part.dart)
  - [settings_diagnostics_usage_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/settings_diagnostics_usage_part.dart)
- Sahiplik yorumu:
  - Bu servis `Runtime Policy / Network` sahibi olmali.
  - Hem runtime politika motorlari hem de UI/settings yüzeyleri bu servise
    bakiyor; `T-028` icin ana boundary adayi bu.

### 4. DeviceSessionService

- Ana dosya: [device_session_service.dart](/Users/turqapp/Desktop/TurqApp/lib/Services/device_session_service.dart)
- Dis referans sayisi: `4`
- Dis temas gruplari:
  - `Modules`: `2`
  - `Services`: `2`
- Temel temas ornekleri:
  - [sign_in_application_service.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in_application_service.dart)
  - [sign_in_controller_auth_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in_controller_auth_part.dart)
  - [current_user_service_account_center_role_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Services/current_user_service_account_center_role_part.dart)
  - [account_center_service_accounts_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Services/account_center_service_accounts_part.dart)
- Sahiplik yorumu:
  - Bu servis `Runtime Session / Device Identity` sahibi olmali.
  - Yuzeyi digerlerine gore daha dar; `T-028` icin kontrollu boundary'ye
    alinmasi daha kolay alan.

### 5. SegmentCacheManager

- Ana dosya: [cache_manager.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Services/SegmentCache/cache_manager.dart)
- Dis referans sayisi: `16`
- Dis temas gruplari:
  - `Modules`: `13`
  - `Core`: `2`
  - `main.dart`: `1`
- Temel temas ornekleri:
  - [main.dart](/Users/turqapp/Desktop/TurqApp/lib/main.dart)
  - [splash_post_login_warmup.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_post_login_warmup.dart)
  - [short_view_playback_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_view_playback_part.dart)
  - [explore_controller_feed_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Explore/explore_controller_feed_part.dart)
  - [permissions_view_quota_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/Settings/permissions_view_quota_part.dart)
  - [post_content_base_playback_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/Common/post_content_base_playback_part.dart)
- Sahiplik yorumu:
  - Bu servis `Runtime Media Cache` sahibi olmali.
  - `Short`, `Agenda`, `Explore`, `Settings diagnostics`, `Splash` gibi farkli
    yuzeylerin dogrudan baglanmasi lifecycle riskini buyutuyor.

## Uygulama Duzeyi Sonuc

Kod tabaninda runtime servisleri zaten var; eksik olan sey servislerin kendisi
degil, kimin bu servislere hangi rolde bakabilecegi.

Bugunku dagilim:

- `App shell` dogrudan bootstrap ediyor: [main.dart](/Users/turqapp/Desktop/TurqApp/lib/main.dart)
- `Splash` dogrudan runtime servislerini isindiriyor ve kaydediyor:
  [splash_dependency_registrar.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_dependency_registrar.dart),
  [splash_post_login_warmup.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Splash/splash_post_login_warmup.dart)
- `Feature controller/view` katmani dogrudan servis instance/ensure cagiriyor
- `Settings/diagnostics` de ayni runtime nesnelerine dogrudan baglaniyor

Bu yuzden runtime servisleri paylasilan altyapi olmasina ragmen davranis
sinirlari compile-time veya guard ile korunmuyor.

## T-028 ve T-029 Icin Hedef Cikis

### T-028 Oncelikli Runtime Boundary Alani

- `UploadQueueService`
- `NetworkAwarenessService`
- `DeviceSessionService`

Hedef:

- feature controller'lari bu servislere yalniz application/runtime facade
  uzerinden baksin
- `SignIn`, `PostCreator`, `Chat`, `Splash` ve `Settings` icin acik erisim
  kurali yazilsin

### T-029 Oncelikli Playback / Cache Boundary Alani

- `VideoStateManager`
- `SegmentCacheManager`

Hedef:

- lifecycle ve playback koordinasyonu icin tek runtime ownership tanimi
- `Agenda`, `Short`, `Story`, `Profile`, `Explore` yuzeylerinde dogrudan
  instance dagilimini azaltmak

## Kabul Kriteri Karsiligi

- Runtime servis sahiplik haritasi cikarildi
- Dis erisim envanteri sayisallastirildi
- Sonraki resmi isler icin hedef boundary alanlari netlestirildi
