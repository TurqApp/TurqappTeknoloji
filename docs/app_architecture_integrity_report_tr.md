# TurqApp Uygulama Bütünlük Raporu

Branch: `refactor/app-architecture-orchestration`

Amaç: TurqApp'i ekranların ayrı ayrı karar verdiği bir yapıdan, startup, auth, routing, cache, backend ve state sınırları tek mimari akılla çalışan bir uygulama sistemine taşımak.

## 1. Uygulama Bütünlük Raporu

Genel sağlık durumu: iyi ve kapanış aşamasında.

Uygulamanın en riskli merkezi akışları artık testlenebilir ve guard ile korunuyor:

- Splash/auth/startup kararı `StartupDecision` ve `AppDecisionCoordinator` üzerinden ifade ediliyor.
- Root navigation `AppRootNavigationService` arkasında tutuluyor.
- Logout, delete account, ban, account switch ve session displacement gibi çıkış akışları `SessionExitCoordinator` sınırıyla modelleniyor.
- Primary tab kararları `PrimaryTabRouter` ve NavBar `_PrimaryTabLayout` ile feature-aware hale getirildi.
- Splash route hint vocabulary `StartupRouteHint` enum'una toplandı.
- Deep link parsing tek parser'a, education tab routing ise `PrimaryTabRouter` akışına bağlandı.
- Firebase/Auth/Firestore/Functions/Messaging/Storage singleton kullanımları App/Core boundary wrapper'ları arkasına alındı ve guard testlerle korunuyor.
- Local preference singleton erişimi `LocalPreferenceRepository` sınırında tutuluyor.

En büyük mimari kopukluklar:

- Splash daha önce route, auth, cache readiness ve telemetry kararlarını kendi içinde tekrar tekrar hesaplıyordu.
- Feature ekranları bazı yerlerde root navigation, profile/report routing veya tab index kararlarını kendi yapıyordu.
- Aynı `nav_*` startup route vocabulary farklı noktalarda literal olarak bulunabiliyordu.
- Backend singleton erişimi bazı modül/controller katmanlarında doğrudan yapılabiliyordu.
- Local cache/prefs kullanımı ekran bazlı dağılabiliyordu.

En çok sorun çıkaran 5 alan:

1. Splash startup karar zinciri.
2. Root navigation ve auth/session exit akışları.
3. Primary tab index ve education-enabled feature flag kararı.
4. Backend singleton ve repository/service sınırları.
5. Local preferences/cache ownership.

## 2. Tutarsızlık ve Kopukluk Analizi

### Bulgu 1

Seviye: Kritik

Konum:

- `lib/Modules/Splash/splash_view_startup_part.dart`
- `lib/Runtime/app_decision_coordinator.dart`
- `lib/Runtime/startup_decision.dart`

Sorun: Splash, startup root route kararını, route telemetry değerlerini ve warm fallback mantığını ekran içinde birden fazla yerden hesaplayabiliyordu.

Neden kopukluk oluşturuyordu: Splash içinde auth, route hint, manifest freshness ve selected tab kararı birlikte ama dağınık ilerlediğinde ilk açılışta yanlış sayfaya düşme veya telemetry/manifest ile gerçek navigation'ın ayrışması riski oluşuyordu.

Uyumsuz parçalar: Splash, NavBar selected index, startup manifest, playback KPI, runtime health analytics.

Düzeltme: `StartupDecision`, `AppDecisionCoordinator`, `_StartupRouteTelemetryValues`, `_startupNavigationManifestExtra` ve `_trackStartupRuntimeHealthSummary` ile karar ve telemetry aynı captured değerlerden üretildi.

### Bulgu 2

Seviye: Kritik

Konum:

- `lib/Runtime/app_root_navigation_service.dart`
- `lib/Runtime/session_exit_coordinator.dart`
- `lib/Services/current_user_service_lifecycle_part.dart`
- `test/unit/runtime/root_navigation_boundary_test.dart`
- `test/unit/runtime/session_exit_coordinator_test.dart`

Sorun: Root stack temizleyen navigation kararları farklı ekranlardan yapılabiliyordu.

Neden kopukluk oluşturuyordu: Auth çıkışı, ban, delete account veya startup sonrası route değişimi aynı root-stack temizleme davranışını paylaşmazsa kullanıcı geri tuşuyla eski authenticated ekrana dönebilir.

Uyumsuz parçalar: SignIn, Splash, DeleteAccount, CurrentUserService, notification return flows.

Düzeltme: Root navigation `AppRootNavigationService` arkasına alındı, session exit akışları `SessionExitCoordinator` ile korundu, guard testleri eklendi.

### Bulgu 3

Seviye: Kritik

Konum:

- `lib/Runtime/primary_tab_router.dart`
- `lib/Modules/NavBar/nav_bar_controller_support_part.dart`
- `lib/Modules/NavBar/nav_bar_controller_lifecycle_part.dart`
- `test/unit/runtime/primary_tab_router_test.dart`

Sorun: Education/Profile tab index kararı feature flag'e bağlı olduğu halde farklı yerlerde tekrar hesaplanıyordu.

Neden kopukluk oluşturuyordu: Education kapalıyken profile index kayabilir; deep link, startup restore, NavBar lifecycle veya route hint persistence farklı index üretirse kullanıcı yanlış primary tab'e düşer.

Uyumsuz parçalar: NavBar, Splash, deep link, startup manifest, education tab visibility.

Düzeltme: `PrimaryTabRouter` semantic tab mapping sahibi oldu; NavBar içinde `_PrimaryTabLayout` helper'ı eğitim/profil index hesabını tek noktaya aldı.

### Bulgu 4

Seviye: Kritik

Konum:

- `lib/Core/Services/app_firebase_auth.dart`
- `lib/Core/Services/app_firestore.dart`
- `lib/Core/Services/app_cloud_functions.dart`
- `lib/Core/Services/app_firebase_storage.dart`
- `lib/Core/Services/app_firebase_messaging.dart`
- `test/unit/runtime/*boundary_test.dart`

Sorun: Feature/module kodu SDK singleton'larına doğrudan gidebiliyordu.

Neden kopukluk oluşturuyordu: Aynı veri/entity için farklı query, mapping, cache invalidation veya auth/session davranışı üretilme riski vardı.

Uyumsuz parçalar: Modules, Core services, repositories, upload flows, notification flows.

Düzeltme: App wrapper boundary'leri ve repository/service guard testleriyle singleton erişimi merkezi katmanlara çekildi.

### Bulgu 5

Seviye: Orta

Konum:

- `lib/Core/Repositories/local_preference_repository.dart`
- `lib/Services/current_user_service*.dart`
- `lib/Modules/**`
- `test/unit/runtime/*preferences*_boundary_test.dart`

Sorun: `SharedPreferences.getInstance()` ekran/modül seviyesinde tekrar açılabiliyordu.

Neden kopukluk oluşturuyordu: User-scoped key üretimi, cache invalidation, active uid ve startup restore akışlarında farklı kaynak kararları oluşabiliyordu.

Uyumsuz parçalar: CurrentUserService, NavBar selected tab restore, Splash startup manifest, module listing selections, offline/cache services.

Düzeltme: Local preference erişimi `LocalPreferenceRepository` üzerinden yapılıyor ve guard testleriyle korunuyor.

### Bulgu 6

Seviye: Orta

Konum:

- `lib/Core/Utils/deep_link_utils.dart`
- `lib/Core/Services/deep_link_service_*`
- `test/unit/utils/deep_link_utils_test.dart`
- `test/unit/runtime/deep_link_parser_boundary_test.dart`

Sorun: Deep link parsing ve education routing davranışı servis içinde tekrar üretilebilecek durumdaydı.

Neden kopukluk oluşturuyordu: Web link, custom scheme, query/fragment ve path-tail varyasyonlarında farklı route identity üretme riski vardı.

Uyumsuz parçalar: DeepLinkService, education routing, profile routing, startup tab router.

Düzeltme: Parser `deep_link_utils.dart` içine alındı; service parser'a delege ediyor; education open `PrimaryTabRouter` ile çalışıyor.

## 3. Merkezileştirme Önerisi

### Merkezi App Decision Flow

Kural: Root target ve primary tab kararı `AppDecisionCoordinator` dışında üretilmemeli.

Merkez:

- `StartupDecision`
- `StartupDecisionInput`
- `AppDecisionCoordinator`

### Splash Karar Akışı

Sıra:

1. Manifest/cache context hydrate edilir.
2. Auth/effective user id okunur.
3. Authenticated ise primary surfaces readiness hazırlanır.
4. Requested/effective/resolved route telemetry tek kez capture edilir.
5. `AppDecisionCoordinator` startup kararını üretir.
6. Nav selected index `PrimaryTabRouter` üzerinden hesaplanır.
7. Manifest navigation ve analytics aynı karar objesiyle yazılır.
8. Root navigation `AppRootNavigationService` ile yapılır.

### Auth + Onboarding Yönlendirme Düzeni

Kural: Auth unknown iken kullanıcı sign-in/home'a itilmemeli; splash/degraded state korunmalı.

Kural: Session exit feature ekranlarından doğrudan root navigation yapmamalı; `SessionExitCoordinator` kullanılmalı.

### Cache Stratejisi

Kural: Disk/local preference erişimi `LocalPreferenceRepository` üzerinden yapılmalı.

Kural: Startup manifest/shard store, screen cache ve user-scoped preference aynı uid disiplinini takip etmeli.

### Navigation Standardı

Kural: Root-clearing navigation yalnızca `AppRootNavigationService`.

Kural: Primary tab open/index kararları `PrimaryTabRouter`.

Kural: Entity/profile/report/detail açılışları ilgili navigation service üzerinden yapılmalı.

### Ortak State Yönetim Yaklaşımı

Kural: App/session state `CurrentUserService`, runtime decision ve central services tarafında; geçici UI state ekran/controller içinde kalabilir.

Bilinçli istisna: PostCreator kendi creator-local tab state'ini yönetebilir; bu primary app tab state değildir.

### Veri Erişim Standardı

Kural: UI/controller doğrudan Firebase singleton açmamalı.

Kural: Typesense-backed search/listing/read akışları Typesense kalmalı; Firestore'a sessiz çevrilmemeli.

Kural: Firestore writes repository/service boundary arkasından yapılmalı.

### Ortak Loading/Error/Empty State Standardı

Durum: Startup/auth/navigation/backend boundary tarafı büyük ölçüde toparlandı. UI state standardı uzun vadeli aşamaya bırakıldı.

Öneri: Sonraki ayrı fazda `AppStateView` / shared loading-empty-error component standardı genişletilmeli.

## 4. Refactor Yol Haritası

### Hemen Yapılacaklar

- Final branch-level doğrulama sonuçlarını PR/commit açıklamasına ekle.
- Bilinçli istisnaları PR açıklamasında koru: Typesense, App* wrappers, PostCreator local tab state.
- Yeni kod girişlerinde guard testlerini CI'da çalıştır.

### İkinci Aşama

- UI loading/empty/error/retry standardını domain bazında genişlet.
- Media placeholder, load-more, button progress ve form submit success/fail standardını ortak component yaklaşımına taşı.
- Entity route resolver kapsamını gerekirse daha fazla detail route'a genişlet.

### Uzun Vadede

- Domain repository contract dokümantasyonu yaz.
- Startup/cache telemetry event sözlüğünü ayrıca versiyonla.
- Feature flag kararlarını Runtime/AppConfig seviyesinde daha görünür hale getir.

## 5. Son Karar

Uygulama şu an ne kadar dağınık?

- Başlangıca göre ciddi şekilde toparlandı.
- Çekirdek startup/auth/navigation/cache/backend boundary'leri artık merkezi ve testlerle korunuyor.
- Kalan dağınıklık daha çok UI state standardı ve bazı domain-specific navigation/service ownership alanlarında.

En önce hangi kopukluk çözülmeliydi?

- Splash/auth/root navigation kopukluğu. Bu çözüldü ve guard testleriyle kapatıldı.

Uygulamayı orkestra gibi uyumlu hale getiren en etkili 3 müdahale:

1. `AppDecisionCoordinator` + `StartupDecision` ile startup kararını tek modele almak.
2. `AppRootNavigationService`, `SessionExitCoordinator`, `PrimaryTabRouter` ile navigation kararlarını merkezi hale getirmek.
3. Backend/local preference singleton erişimini App/Core boundary ve guard testleriyle kilitlemek.

## Final Doğrulama

Son doğrulama komutları:

- `flutter analyze`: no issues found.
- `flutter test test/unit/runtime`: 193 tests passing.
- `flutter test test/unit/modules/splash`: 12 tests passing.
- Startup/navigation focused tests: 55 tests passing.
- Deep-link focused tests: 15 tests passing.
- Classic/Agenda content navigation boundary tests: 2 tests passing.

Tam suite durumu:

- Güncel fresh `flutter test`: 662 passed, 1 skipped, 0 failed.
- Functions TypeScript build yeşil: `npm run build`.
- Functions unit testleri yeşil: `npm run test:unit`, 36 test passing.
- Firestore/Storage rules emulator testleri yeşil: `npm run test:rules`, 99 test passing.
- Security regression gate yeşil: `npm run test:security-regressions`, 5 unit test + 99 emulator rules test passing.
- Integration suite registry, integration key coverage ve QA Lab catalog registry yeşile alındı.
- Onay sonrası feed/short/playback davranış kontrat hizalaması yapıldı.
- Hedefli davranış testleri yeşil: feed render ordering/window, prefetch scheduler visible-window/boost, playback selection policy, short feed application plan/delegation, short/feed launch motor ve agenda warm range toplam 38 test passing.
- Envanter kontratları yeşil: integration suite registry, integration key coverage ve QA Lab catalog registry toplam 9 test passing.
- QA Lab recorder kontratı yeşil: 44 test passing.
- Touched file analyze: no issues found.
- Tam suite artık yeşil; kalan bilinen durum yalnızca 1 skipped test.

Son not:

- Typesense/search/listing akışları bilinçli olarak korunmuştur.
- Bu çalışma sessiz Firestore read migration'ı yapmaz.
