# T-007 Storage Bypass Kapatma Notu

## Amaç

`storage.rules` içindeki hardcoded bypass UID yolunu kaldırmak ve upload yetkisini yalnız meşru iki yola indirmek:

- mevcut belge sahibi kullanıcı
- `uploaderUid` metadata'sı ile kimliği eşleşen yeni upload

## Yapılan Kural Değişiklikleri

- `isStorageUploaderBypass()` helper'ı kaldırıldı.
- `Posts/{postId}/...` upload kuralında:
  - artık `Posts/{postId}` belgesi yok diye otomatik write izni yok
  - mevcut belge sahibi kullanıcı write edebilir
  - yeni upload ancak `uploaderUid == request.auth.uid` metadata'sı ile geçebilir
- `isBul/{jobId}/...` upload kuralında:
  - artık `isBul/{jobId}` belgesi yok diye otomatik write izni yok
  - mevcut ilan sahibi kullanıcı write edebilir
  - yeni upload ancak `uploaderUid == request.auth.uid` metadata'sı ile geçebilir
- `hasMatchingUploaderMetadata()` helper'ı `uploaderUid` alanı yokken evaluation warning üretmeyecek şekilde güvenli hale getirildi.

## Korunan Meşru Akışlar

- Yeni post medya upload
- Mevcut post sahibi için metadata'sız edit upload
- Yeni iş ilanı logo upload
- Mevcut iş ilanı sahibi için metadata'sız edit upload

## Eklenen Doğrulamalar

`functions/tests/rules/storage.rules.test.js` içine şu davranış testleri eklendi:

- metadata'lı yeni post upload izinli
- mevcut post sahibi metadata'sız upload izinli
- eski bypass UID metadata'sız post upload reddedilir
- metadata'lı yeni job upload izinli
- mevcut job sahibi metadata'sız upload izinli
- eski bypass UID metadata'sız job upload reddedilir

## Sonuç

Hardcoded storage bypass kapatıldı. Upload yetkisi artık gizli UID allowlist yerine belge sahipliği veya açık upload metadata'sı ile sınırlandırılıyor.
