# F3-003 Profile / Social Hot-Cluster Secici Sadelestirme

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Amac

`Profile/MyProfile` ve `SocialProfile` sicak kumesinde davranis part'larina
girmeden, sadece mekanik `class/base/facade` mikro parcalarini ana dosyalara
tasiyip dosya yuzeyini azaltmak.

## Secilen Dusuk Riskli Hedefler

- [profile_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/MyProfile/profile_controller.dart)
- [social_profile_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/social_profile_controller.dart)
- [social_qr_code_controller_library.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/SocialQrCode/social_qr_code_controller_library.dart)
- [report_user_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/ReportUser/report_user_controller.dart)
- [social_profile_followers_controller.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/SocialProfileFollowers/social_profile_followers_controller.dart)

## Uygulanan Sadelestirme

Ana dosyalara tasinan bloklar:

- controller class tanimlari
- abstract base tanimlari
- facade / ensure / maybeFind yardimcilari

Silinen mikro part dosyalari:

- [profile_controller_base_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/MyProfile/profile_controller_base_part.dart)
- [profile_controller_class_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/MyProfile/profile_controller_class_part.dart)
- [social_profile_controller_base_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/social_profile_controller_base_part.dart)
- [social_profile_controller_class_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/social_profile_controller_class_part.dart)
- [social_profile_controller_facade_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/social_profile_controller_facade_part.dart)
- [social_qr_code_controller_class_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/SocialQrCode/social_qr_code_controller_class_part.dart)
- [social_qr_code_controller_facade_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/SocialQrCode/social_qr_code_controller_facade_part.dart)
- [report_user_controller_base_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/ReportUser/report_user_controller_base_part.dart)
- [social_profile_followers_controller_base_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/SocialProfileFollowers/social_profile_followers_controller_base_part.dart)

## Olcum

Secilen `Profile/Social` sicak kumesi:

- toplam `.dart` dosyasi: `66 -> 57`
- `*part.dart` dosyasi: `55 -> 46`
- kaldirilan mikro part sayisi: `9`

## Dogrulama

- `dart analyze --no-fatal-warnings` secilen 5 ana dosyada gecti
- `git diff --check` secilen dosyalarda gecti
- docs guard bu is kapsaminda gecti

## Sinir

- `profile_view.dart` ve `social_profile.dart` icindeki agir UI part dagilimi bu iste bilerek tasinmadi
- `DEBT-001` ve `DEBT-002` kapanmadi; yalniz `Profile/Social` sicak kumesinde olculu bir dusus saglandi

## Sonuc

- Sicak `Profile/Social` kumesinde ayni controller/library davranisini okumak icin daha az dosya aciliyor
- Davranis part'lari korunarak, sahte modulerlik ureten mikro giris dosyalari azaltildi
