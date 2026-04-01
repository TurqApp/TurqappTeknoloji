# Faz 2 Stored-Account Reauth Hardening

Uretim tarihi: `2026-03-28`

## Kapsam

Bu artifact, `F2-002` kapsaminda stored-account -> manual reauth akisinda kalan dead-end riskini kapatmak icin yapilan davranis degisikliklerini kaydeder.

## Duzeltilen Sorun

Password-provider bir hesap cihazda kayitli olsa da email hint'i yoksa, uygulama username fallback ile SignIn ekranini acabiliyordu.

Bu durumda:

- login formu yanlis identifier ile acilabiliyor
- kullanici gecerli email yerine username ile devam etmeye yonleniyordu
- `storedAccountUid` ile gelen route ilk ekranda bazen start screen'de kalabiliyordu

## Uygulanan Davranis

- password-provider hesaplar icin `preferredIdentifierForStoredAccount(...)` artik email yoksa username fallback yapmiyor
- `storedAccountUid` ile acilan SignIn route'u login formunu senkron olarak aciyor
- stored-account context'i async olarak Account Center init tamamlandiktan sonra tekrar baglaniyor
- identifier bulunamazsa kullanici yine login formunda kaliyor; start screen dead-end'i olusmuyor

## Test Kaniti

Hedefli unit testi:

- `test/unit/modules/sign_in/sign_in_application_service_test.dart`
  - password-provider hesapta email hint yoksa username fallback olmadigi dogrulandi

Hedefli widget testi:

- `test/widget/screens/sign_in_test.dart`
  - `storedAccountUid` ile acilan SignIn route'unun login formunu actigi dogrulandi

## Sonuc

`RISK-002` kapanis gerekcesi:

- password-provider stored-account reauth yolu artik yanlis identifier fallback'i ile dead-end uretmiyor
- route davranisi ve service davranisi testle kilitli
