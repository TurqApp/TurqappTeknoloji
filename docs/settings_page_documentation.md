# Settings Page Documentation (Current State)

## 1) Ana ekran
- Ekran: `SettingsView`
- Dosya: `lib/Modules/Profile/Settings/settings.dart`
- Controller: `SettingsController`
- Kullanıcı verisi kaynağı: `CurrentUserService`

## 2) Ayarlar satırları (mevcut)
| Başlık | Tür | Davranış |
|---|---|---|
| Profili Düzenle | Navigation | `EditProfile` ekranına gider |
| Onaylı Hesap Ol | Conditional Navigation | Sadece rozet yoksa görünür, `BecomeVerifiedAccount` açar |
| Hesap Gizliliği | Toggle | `users/{uid}.gizliHesap` alanını tersine çevirir |
| Kaydedilenler | Navigation | `SavedPosts` |
| Eğitim Ekranı | Toggle | `SharedPreferences: educationScreenIsOn` değerini değiştirir |
| Sistem ve Tanı Menüsü | Bottom Sheet | Tanı alt menüsünü açar |
| Arşiv | Navigation | `Archives` |
| Beğenilenler | Navigation | `LikedPosts` |
| Engellenenler | Navigation | `BlockedUsers` |
| İlgi Alanları | Navigation | `Interests` |
| Özgeçmiş (Cv) | Navigation | `Cv` |
| Bağlantılar | Navigation | `SocialMediaLinks` |
| İzinler | Navigation | `PermissionsView` |
| Yönetim / Push Gönder | Conditional Navigation | Admin claim + `adminConfig/admin.pushSend == true` ise görünür |
| Hakkında | Navigation | `AboutProfile(userID: currentUid)` |
| Politikalar | Navigation | `Policies` |
| Bize Yazın | External Action | `mailto:info@turqapp.com` |
| Oturumu Kapat | Confirmed Action | user token temizleme + logout + `SignIn` |

## 3) “Sistem ve Tanı Menüsü” alt menüsü
- Veri Tüketimi: `NetworkAwarenessService` istatistik popup
- Uygulama Sağlık Paneli: `AppHealthDashboard`
- Video Cache Detayı: `SegmentCacheManager` + `PrefetchScheduler` metrikleri
- Hızlı Aksiyonlar:
  - Veri sayaçlarını sıfırla
  - Prefetch duraklat
  - Prefetch devam et
- Son Hata Özeti: `ErrorHandlingService.getLastErrorSummary()`
- Hata Raporu: `ErrorReportWidget`

## 4) İzinler ekranı (`PermissionsView`)
- Dosya: `lib/Modules/Profile/Settings/permissions_view.dart`
- İzin öğeleri:
  - Kamera (`Permission.camera`)
  - Kişiler (`Permission.contacts`)
  - Konum Servisleri (`Permission.locationWhenInUse`)
  - Mikrofon (`Permission.microphone`)
  - Bildirimler (`Permission.notification`)
  - Fotoğraflar (`Permission.photos`)
- Akış:
  - Durumlar okunur (`permission.status`)
  - Bazılarında direkt request, bazılarında cihaz ayarına yönlendirme (`openAppSettings`)
- Ek ayar:
  - Çevrimdışı izleme kotası
  - `SharedPreferences` key: `offline_cache_quota_gb`
  - Seçenekler: `2/3/4/5 GB`

## 5) Admin Push ekranı (`AdminPushView`)
- Dosya: `lib/Modules/Profile/Settings/admin_push_view.dart`
- Hedefleme girişleri:
  - Tek UID
  - Meslek
  - Konum
  - Cinsiyet
  - Yaş aralığı
- Push tipleri:
  - `posts`, `follow`, `comment`, `message`, `like`, `reshared_posts`, `shared_as_posts`
- Yazdığı Firestore yolları:
  - `users/{targetUid}/notifications/{autoId}` (bildirim kaydı)
  - `adminConfig/admin/pushReports/{autoId}` (rapor kaydı)
- Rapor listesinde son 20 kayıt stream ile gösterilir, tek tek silinebilir.

## 6) Ayarlar modülünün dokunduğu veri alanları
- Firestore:
  - `users/{uid}.gizliHesap`
  - `users/{uid}.token` (çıkışta boşaltılır)
  - `users/{uid}/notifications/*`
  - `adminConfig/admin.pushSend`
  - `adminConfig/admin/pushReports/*`
- SharedPreferences:
  - `educationScreenIsOn`
  - `offline_cache_quota_gb`

## 7) Bilinen isim/UX tutarsızlıkları (mevcut durumda)
- `Hesap Gizliliği` bir menü değil, doğrudan toggle.
- `Eğitim Ekranı` ayarı profil ayarları ile karışık duruyor (ürün alanı farklı).
- `Sistem ve Tanı Menüsü` son kullanıcı ayarlarının içinde, teknik/debug ağırlıklı.
- `Yönetim / Push Gönder` aynı listede; admin ve normal kullanıcı alanları ayrışmıyor.

## 8) İlgili dosyalar
- `lib/Modules/Profile/Settings/settings.dart`
- `lib/Modules/Profile/Settings/settings_controller.dart`
- `lib/Modules/Profile/Settings/permissions_view.dart`
- `lib/Modules/Profile/Settings/admin_push_view.dart`
