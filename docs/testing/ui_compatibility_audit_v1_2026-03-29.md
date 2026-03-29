# UI Compatibility Audit v1

Tarih: `2026-03-29`
Is: `T-UI-001`
Durum: `Tamamlandi`

## Kapsam

Ilk audit dalgasi su ekranlar icin calistirildi:

- `SignIn`
- `ChatListing`
- `ChatView`
- `MyProfile`
- `SocialProfile`
- `PostCreator`

Test matrisi:

- `phone_small_android`
- `phone_small_android_large_text`
- `phone_small_ios`
- `phone_small_ios_large_text`
- `phone_android`
- `tablet_android`

Ek odak testleri:

- `ChatViewKeyboard`
- `PostCreatorKeyboard`
- `SignInStoredAccount`

Komut:

```bash
flutter test /Users/turqapp/Desktop/TurqApp/test/widget/responsive
```

## Teknik Not

Audit paketini kosmadan once uygulama genel derlemesinde ayrik bir blokaj vardi:

- [deep_link_service.dart](/Users/turqapp/Desktop/TurqApp/lib/Core/Services/deep_link_service.dart)
  - eksik `MarketItemModel` import'u eklendi

Bu degisiklik davranis degistirmeyen bir compile fix olarak uygulandi; aksi halde audit testleri hic baslayamiyordu.

## Ozet

Temiz gecen ekranlar:

- `ChatListing`
- `ChatView`
- `ChatViewKeyboard`

Kismi temiz gecen ekranlar:

- `SignIn`
  - normal telefon varyantlari temiz
  - kucuk ekran + buyuk font ve stored-account akisinda overflow var
- `PostCreator`
  - normal telefon `phone_android` ve `tablet_android` temiz
  - kucuk ekranlarda overflow var
- `MyProfile`
  - yalniz `tablet_android` temiz
- `SocialProfile`
  - yalniz `tablet_android` temiz

## Bulgular

### 1. SignIn

Fail veren varyantlar:

- `phone_small_android_large_text`
- `phone_small_ios_large_text`
- `SignInStoredAccount / phone_small_android_large_text`

Kayitli bulgu:

- `A RenderFlex overflowed by 10.0 pixels on the right.`
- stored-account akisinda `Multiple exceptions (2)`

Gercek stack satirlari:

- [sign_in_signin_part.dart#L180](/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in_signin_part.dart#L180)
- [sign_in_signin_part.dart#L19](/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in_signin_part.dart#L19)

Yorum:

- buyuk fontta sabit genislikli veya tek satirli action row kiriliyor
- stored-account akisinda hem form ici hem ust satir/hesap karti birlikte sikisiyor

### 2. ChatListing

Tum varyantlar:

- `pass`

Yorum:

- ilk audit dalgasinda header, search ve create action tarafinda gorunen bir layout kirigi cikmadi

### 3. ChatView

Tum varyantlar:

- `pass`

Ek test:

- `ChatViewKeyboard / phone_small_android_large_text` -> `pass`

Yorum:

- composer, trailing action alani ve keyboard gorunurlugu ilk dalgada stabil gorundu

### 4. PostCreator

Fail veren varyantlar:

- `phone_small_android`
- `phone_small_android_large_text`
- `phone_small_ios`
- `phone_small_ios_large_text`
- `PostCreatorKeyboard / phone_small_android_large_text`

Temiz varyantlar:

- `phone_android`
- `tablet_android`

Kayitli bulgu:

- kucuk telefonda `15 px`
- buyuk fontta `195 px`

Muhtemel kaynak:

- [post_creator_shell_content_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/PostCreator/post_creator_shell_content_part.dart)

Not:

- bu eslesme kod incelemesinden cikarildi; log stack'i SignIn/SocialProfile kadar kesin satir vermedi
- merkez baslik + sagdaki publish pill ayni stack icinde oldugu icin kucuk ekran ve buyuk fontta ilk kirilan yuzey burasi gibi gorunuyor

### 5. MyProfile

Fail veren varyantlar:

- `phone_small_android`
- `phone_small_android_large_text`
- `phone_small_ios`
- `phone_small_ios_large_text`
- `phone_android`

Temiz varyant:

- `tablet_android`

Kayitli bulgu:

- `410 px` ile `893 px` arasi sag overflow

Muhtemel kaynak:

- [profile_view_tabs_part.dart](/Users/turqapp/Desktop/TurqApp/lib/Modules/Profile/MyProfile/profile_view_tabs_part.dart)

Not:

- bu eslesme kod incelemesinden cikarildi
- profil sayaç satiri ve alttaki ikon sekme satiri tek satirli/fixed duzende oldugu icin telefon varyantlarinda ana aday burasi

### 6. SocialProfile

Fail veren varyantlar:

- `phone_small_android`
- `phone_small_android_large_text`
- `phone_small_ios`
- `phone_small_ios_large_text`
- `phone_android`

Temiz varyant:

- `tablet_android`

Kayitli bulgu:

- her fail kosusunda `Multiple exceptions (2)`
- ust header row overflow'u:
  - `420 px`, `840 px`, `387 px`
- alt header/text-info row overflow'u:
  - `45 px`, `270 px`, `12 px`

Gercek stack satirlari:

- [social_profile_header_part.dart#L11](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/social_profile_header_part.dart#L11)
- [social_profile_header_part.dart#L229](/Users/turqapp/Desktop/TurqApp/lib/Modules/SocialProfile/social_profile_header_part.dart#L229)

Yorum:

- nickname + rozet + header action satiri dogrudan kiriliyor
- alt text-info row da buyuk fontta ikinci kirik yuzey olarak gozukuyor

## Onceliklendirilmis Duzeltme Sirasi

T-UI-002 icin onerilen sira:

1. `SignIn`
2. `PostCreator`
3. `SocialProfile`
4. `MyProfile`
5. `ChatListing`
6. `ChatView`

Gerekce:

- `SignIn` giris akisinda kritik ve kucuk fonksiyonal alan
- `PostCreator` publish CTA'yi etkiliyor
- `SocialProfile` ve `MyProfile` telefon yuzeylerinde sistematik kirik veriyor
- `ChatListing` ve `ChatView` ilk dalgada temiz

## Sonuc

`T-UI-001` audit amacina ulasti:

- production layout degistirilmedi
- responsive/accessibility audit paketi eklendi
- ekran bazli patlama noktalarini cikardi
- T-UI-002 icin hedef ekranlar ve ilk temas dosyalari netlesti

## Guncel Durum

Tarih: `2026-03-29`
Is: `T-UI-002`
Durum: `Tamamlandi`

Audit sonrasi su ekranlarda kontrollu duzeltme uygulandi:

- `SignIn`
- `MyProfile`
- `SocialProfile`
- `PostCreator`

Ek olarak audit testleri artik sadece log atmiyor; `fail` bulgusu gorurse testi kiran guard haline getirildi:

- `ChatListing`
- `ChatView`
- `SignIn`
- `MyProfile`
- `SocialProfile`
- `PostCreator`

Son teknik sonuc:

- `ChatListing` -> `pass`
- `ChatView` -> `pass`
- `ChatViewKeyboard` -> `pass`
- `SignIn` -> `pass`
- `SignInStoredAccount` -> `pass`
- `MyProfile` -> `pass`
- `SocialProfile` -> `pass`
- `PostCreator` -> `pass`
- `PostCreatorKeyboard` -> `pass`

Kullanilan dogrulama:

```bash
dart analyze test/widget/responsive/chat_listing_responsive_audit_test.dart test/widget/responsive/chat_view_responsive_audit_test.dart test/widget/responsive/sign_in_responsive_audit_test.dart test/widget/responsive/profile_responsive_audit_test.dart test/widget/responsive/social_profile_responsive_audit_test.dart test/widget/responsive/post_creator_responsive_audit_test.dart

flutter test test/widget/responsive/chat_listing_responsive_audit_test.dart test/widget/responsive/chat_view_responsive_audit_test.dart test/widget/responsive/sign_in_responsive_audit_test.dart test/widget/responsive/profile_responsive_audit_test.dart test/widget/responsive/social_profile_responsive_audit_test.dart test/widget/responsive/post_creator_responsive_audit_test.dart
```

Kapanan ana responsive kiriklar:

- `SignIn` buyuk font ve stored-account tasmasi
- `MyProfile` nickname/verify ve header-only shell tasmasi
- `SocialProfile` telefon + buyuk font header/follow aksiyon tasmasi
- `PostCreator` kucuk telefon header/publish tasmasi
