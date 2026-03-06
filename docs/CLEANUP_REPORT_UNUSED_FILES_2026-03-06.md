# TurqApp Kullanılmayan Dosya Temizliği Raporu
Tarih: 2026-03-06
Kapsam: Uygulama kodu, not/dokümantasyon dosyaları, migration scriptleri

## 1) Yüksek Güvenli Silinebilir Dosyalar (Kod)
Bu dosyalar `lib/` altında referans almıyor (import/usage yok):

- `lib/post_test.dart`
- `lib/test_firebase.dart`
- `lib/test_screen.dart`
- `lib/test_users.dart`

Durum: Silinmeye uygun.

## 2) Migration Checkpoint Dosyaları
`functions/scripts/*.state.json` dosyaları tek seferlik migration checkpoint dosyalarıdır.

Önceki durum: 10 adet
- `migrate_kitapciklar_to_books_webp.state.json`
- `migrate_cikmis_to_questions_webp.state.json`
- `migrate_sinavlar_to_practiceexams.state.json`
- `migrate_old_ozeldersverenler_to_educators.state.json`
- `migrate_isbul_to_isbul.state.json`
- `migrate_sorubankasi_to_questionbank.state.json`
- `migrate_questionbank_minimal_schema.state.json`
- `migrate_questionbankskor_to_monthly.state.json`
- `migrate_ozeldersverenler_to_educators.state.json`
- `migrate_marketsiniflandirma_to_market.state.json`

Mevcut durum: **0 adet (silindi)**.

Etki: Canlı uygulamaya etkisi yok. Aynı migration tekrar koşulursa “kaldığı yerden devam” bilgisi olmaz.

## 3) Migration Scriptleri (Arşivlenebilir)
Klasör: `functions/scripts/`

`migrate_*.js` sayısı: 14
Bu dosyalar operasyonel/tek seferlik taşıma scriptleridir, runtime sırasında kullanılmaz.

Öneri:
- Aktif repoda tutulacaksa `functions/scripts/archive/` altına taşı.
- Daha temiz yaklaşım: ayrı operasyon/migration repolarına taşı.

## 4) Notlar / Audit / Cutover Dokümanları (Arşivlenebilir)
Kökte:
- `CACHE_PERFORMANCE_AUDIT.md`
- `VIDEO_PERFORMANCE_AUDIT.md`

`docs/` içeriğinde tarihli release/cutover/checklist ve migration plan dosyaları bulunuyor.
Toplam doküman dosyası: 23

Öneri:
- Yaşayan dokümanları bırak (`README`, aktif mimari kılavuzu).
- Tarihli raporları `docs/archive/2026-03/` altına taşı.

## 5) Silinmemesi Gereken Çekirdek Dosyalar
- `firestore.rules`
- `firestore.indexes.json`
- `functions/src/**`
- `lib/**` (test/deneme dosyaları hariç)
- `firebase.json`, `pubspec.yaml`, `pubspec.lock`

## 6) Teknik Not
- `userID` alanı users root dokümanından kaldırıldı.
- `sifre` alanı users root dokümanından kaldırıldı.
- `syncUserSchemaAndFlags` canlıda aktif ve şema temizliğini enforce ediyor.

## 7) Önerilen Temizlik Sırası
1. `lib/` kökündeki 4 test/deneme dosyasını kaldır.
2. `functions/scripts/migrate_*.js` dosyalarını arşiv klasörüne taşı.
3. `docs` altındaki tarihli checklist/release/migration notlarını arşive al.
4. Arşiv sonrası `flutter analyze` ve `functions` build tekrar çalıştır.
