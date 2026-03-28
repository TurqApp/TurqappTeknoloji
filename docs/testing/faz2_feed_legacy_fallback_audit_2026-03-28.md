# F2-009 Feed Legacy Fallback Audit

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Amac

`feed_home_primary_hybrid_v1` kontratinin yanlis sabitlenmesi veya route replay
sonrasi sessizce legacy path'e dusmesi riskini gorunur hale getirmek ve resmi
regression paketine baglamak.

## Audit Ozeti

Legacy fallback giris noktalari hedefli olarak sayildi ve siniflandi:

1. `FeedSnapshotRepository.fetchHomePage(...)`
   - `usePrimaryFeedPaging == false` veya `userId` bos ise dogrudan
     `_loadLegacyPage(...)`
2. `fetchHomePage(...)`
   - `primary_empty` durumunda once `personalFallback`, sonra `legacy`
3. `fetchHomePage(...)`
   - `visible_empty` durumunda once `personalFallback`, sonra `legacy`
4. `AgendaController`
   - aktif kullanici UID'i yoksa `_loadLegacyAgendaSourcePage(...)`

Bu audit ile legacy path'in beklenmedik ek girisler acmadan yalniz tanimli
degenerasyon kosullarinda calistigi dogrulandi.

## Regresyon Guclendirmesi

Su sinyaller resmi testlere baglandi:

- feed probe artik `usesPrimaryFeedPaging`
- feed probe artik `feedContractId`
- startup smoke `primary contract` bekliyor
- primary bootstrap smoke `primary contract` bekliyor
- route replay smoke replay sonrasi da `primary contract` bekliyor
- replay smoke ayrica `count` degerinin sifira dusmedigini kontrol ediyor

## Dogrulama

- unit audit:
  - `test/unit/repositories/feed_home_contract_test.dart`
- emulator smoke:
  - `integration_test/auth/auth_startup_session_restore_test.dart`
  - `integration_test/feed/feed_primary_bootstrap_contract_test.dart`
  - `integration_test/feed/feed_resume_test.dart`
- resmi regression paketi:
  - `config/test_suites/auth_session_feed_regression.txt`
  - Android emulator sonucu: `6/6 suite yesil`

## Sonuc

- `RISK-004` kapandi
- `RISK-007` icindeki `feed_blank_surface` parcası kapatilamadi ama daraltildi:
  - startup/bootstrap/replay testleri primary contract'ta stabilize oluyor
  - buna ragmen QA loglari acilis sirasinda gecici `feed_blank_surface` sinyali uretiyor
- kalan `RISK-007` kapsamı:
  - `permission-denied`
  - `remote gate watch`
  - gecici `feed_blank_surface` QA loglari
  - bunlar `F2-010` icinde izlenecek
