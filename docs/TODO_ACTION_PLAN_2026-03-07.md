# Yapilacaklar Listesi (2026-03-07)

## P0 - Kritik (Release oncesi zorunlu)
- [ ] k6 threshold ve raporlama tutarsizligini duzelt (`tests/load/k6_turqapp_load_test.js`).
- [ ] `smoke` senaryosundaki `view/search` fail nedenini gider ve tekrar k6 calistir.
- [ ] Tekil "trusted" performans raporu uret:
  - [ ] `k6_summary_smoke_latest.json`
  - [ ] `k6_summary_feed_only_latest.json`
  - [ ] `k6_summary_network_latest.json`
  - [ ] `k6_summary_social_interaction_latest.json`
- [ ] Firestore/Storage rules icin emulator testleri ekle:
  - [ ] unauthorized read/write
  - [ ] private data exposure
  - [ ] rate limit / abuse senaryolari

## P1 - Yuksek Oncelik
- [ ] CI quality gate olustur:
  - [ ] `flutter analyze`
  - [ ] `flutter test`
  - [ ] k6 smoke (kisa profil)
- [ ] Gercek cihaz performans profili cikar:
  - [ ] Android low-end (jank/frame timing)
  - [ ] iOS release (memory/frame timing)
- [ ] Offline/online gecisleri ve duplicate action/message test senaryolarini otomatize et.
- [ ] Mesajlasma modulu icin race condition ve veri butunlugu test paketi ekle.

## P2 - Orta Oncelik
- [ ] UI audit'te kalan top risk dosyalari icin son responsive pass:
  - [ ] `lib/Modules/JobFinder/JobContent/job_content.dart`
  - [ ] `lib/Modules/Agenda/ClassicContent/classic_content.dart`
  - [ ] `lib/Modules/Education/CikmisSorular/cikmis_soru_olustur.dart`
  - [ ] `lib/Modules/Education/Scholarships/scholarships_view.dart`
- [ ] `TextOverflow.ellipsis` ve `maxLines:1` kullanimlarini kritik metinlerde gozden gecir.
- [ ] Kucuk ekran + text scale (1.0 / 1.3 / 1.6) manuel smoke checklist tamamla.

## Operasyonel / Teknik Borc
- [ ] Test artefactlarini duzenle (`tests/load/`, `.runlogs/`).
- [ ] Calisma agacindaki ilgisiz degisiklikleri ayir (ayri branch/commit stratejisi).
- [ ] Test raporlarini tek bir release notu dokumaninda birlestir.

## Tamamlanma Kriteri
- [ ] P0 maddelerinin tamami tamamlandi.
- [ ] P1 maddelerinin en az %80'i tamamlandi.
- [ ] Son k6 raporlarinda threshold durumu tutarli ve aciklanabilir.
- [ ] Release adayi icin bloklayici test bulgusu kalmadi.
