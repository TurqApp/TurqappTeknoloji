# T-008 Re-auth ve Sifre Saklama Donusumu

## Amaç

Cihaz tarafında saklanan parola davranışını sonlandırmak ve password-provider hesaplar için resmi hesap geçiş yolunu açık biçimde `manuel re-auth` yapmak.

## Yapılan Degisiklikler

- `AccountSessionVault` artık parola saklamıyor.
- Vault payload'ı email hint dışında veri tutmuyor.
- Eski payload'larda kalan parola alanları ilk init sırasında scrub ediliyor.
- Password-provider stored account'lar için otomatik switch kapatıldı.
- Account Center içinde password-provider hesap seçildiğinde:
  - mevcut oturum güvenli biçimde kapatılıyor
  - hedef hesap `requiresReauth=true` durumuna alınıyor
  - kullanıcı SignIn ekranına email/identifier prefill ile yönlendiriliyor
- SignIn sonrası account tracking, vault'a yalnız email hint yazıyor.
- Integration smoke re-auth artık cihazdaki saklı parolaya güvenmiyor; `INTEGRATION_LOGIN_EMAIL` ve `INTEGRATION_LOGIN_PASSWORD` zorunlu kaynak oldu.

## Yeni Tek Kaynak Politika

`stored_account_reauth_policy.dart` içindeki politika:

- password provider => manuel re-auth gerekir
- password dışı provider => manuel re-auth gerekmez

Bu politika hem account center işaretlemesinde hem switch kararında kullanılıyor.

## Dogrulanan Davranislar

- legacy vault payload'ı okununca parola yeniden kullanılmıyor
- password-provider hesaplar için manuel re-auth politikası testle doğrulanıyor
- ilgili sign-in/account center/vault dosyaları analyze temiz geçiyor

## Not

`integration_test/core/bootstrap/test_app_bootstrap.dart` için tam compile denemesinde T-008 dışı, önceden var olan üç adet bootstrap hata yüzeyi görüldü. Bu işte düzeltilmedi; ayrı teknik borç olarak değerlendirilmeli.
