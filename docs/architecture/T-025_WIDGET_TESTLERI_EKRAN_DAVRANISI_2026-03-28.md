# T-025 Widget Testlerini Ekran Davranisina Baglama

## Kapsam

- `test/widget/screens/sign_in_test.dart`
- `test/widget/screens/chat_search_widget_test.dart`

## Problem

Bu iki dosya `screen` testi gibi adlandirilmis olsa da, gercek ekran widget'larini
degil test icinde uretilen sahte harness yapilarini calistiriyordu. Bu nedenle:

- `SignIn` ekraninin gercek route/screen davranisi olculmuyordu
- `ChatListing` ekraninin gercek shell/search yuzeyi olculmuyordu
- testler sahte guven uretiyordu

## Uygulanan donusum

### SignIn

- sahte `_LoginFlowHarness` ve `MyApp` tamamen kaldirildi
- testler artik gercek [SignIn](/Users/turqapp/Desktop/TurqApp/lib/Modules/SignIn/sign_in.dart) widget'ini pump ediyor
- dogrulanan gercek davranis:
  - ekran `screenSignIn` key'i ile aciliyor
  - baslangicta `login_button` gorunuyor
  - tiklaninca gercek `email/password/login_submit_button` alanlari aciliyor
  - `initialIdentifier` login formuna korunarak tasiniyor

### Chat

- sahte `_ChatSearchHarness` kaldirildi
- testler artik gercek [ChatListing](/Users/turqapp/Desktop/TurqApp/lib/Modules/Chat/ChatListing/chat_listing.dart) ekranini pump ediyor
- ekranin uzaktan veri cekmesini onlemek icin test-local controller enjekte edildi
- dogrulanan gercek davranis:
  - ekran `screenChat` key'i ile aciliyor
  - gercek `inputChatSearch` alani gorunuyor
  - gercek tab shell'i (`all/unread/archive`) render oluyor
  - arama girildiginde ekran `common.no_results` bos durumuna geciyor

## Teknik dogrulama

- `flutter test test/widget/screens/sign_in_test.dart test/widget/screens/chat_search_widget_test.dart`
- `dart analyze --no-fatal-warnings test/widget/screens/sign_in_test.dart test/widget/screens/chat_search_widget_test.dart`

## Sonuc

`screen` sinifindaki widget testleri artik sahte uygulama/harness degil, gercek
ekran widget'lari uzerinden davranis olcuyor.
