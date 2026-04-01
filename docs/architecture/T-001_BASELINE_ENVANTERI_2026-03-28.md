# T-001 Baseline Envanteri

Tarih: `2026-03-28`
Plan kaynagi: [TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md](/Users/turqapp/Desktop/TurqApp/docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md)

## Repo Snapshot

| Alan | Deger |
| --- | --- |
| Branch | `codex/final-perf-firebase-baseline` |
| Baseline commit | `35f3b0a9` |
| T-001 oncesi worktree | `clean` |
| Toplam plan puani | `76` |
| Toplam numarali is | `33` |
| Resmi ilk is | `T-001` |

## Kod Tabanı Baseline Metrikleri

| Metrik | Deger | Not |
| --- | --- | --- |
| `lib` altindaki `.dart` dosyasi | `2753` | uygulama ana yuzeyi |
| `test + integration_test` altindaki `.dart` dosyasi | `126` | test yuzeyi |
| `functions/src` altindaki `.ts` dosyasi | `28` | Firebase Functions |
| `cloudflare-shortlink-worker/src` altindaki kaynak dosya | `1` | worker deployable |
| `Get.find/put/delete/isRegistered` kullanimlari | `1034` | gizli bagimlilik yogunlugu |
| `extends GetxController` sayisi | `196` | controller yuzeyi |
| sessiz `catch (_) {}` sayisi | `874` | fail-silent riski |
| `lib/Modules/Education` altindaki `.dart` dosyasi | `690` | Pasaj shell + alt alanlar |
| `Agenda + Story + Short + Chat + Profile` toplam `.dart` dosyasi | `604` | sosyal ve profil omurgasi |

## Baslangic Risk Snapshot

Bu tablo plan icindeki aktif kayitlarin T-001 baslangic anindaki ozetidir.

| Kayit | Tip | Siddet | Durum | Kisa not |
| --- | --- | --- | --- | --- |
| `RISK-001` | Risk | Yuksek | Acik | rules daraltma sirasinda profil/upload akislari kirilabilir |
| `RISK-002` | Risk | Yuksek | Acik | parola saklama kalkarken hesap gecisi bozulabilir |
| `RISK-003` | Risk | Orta | Acik | architecture guard false-positive uretebilir |
| `RISK-004` | Risk | Yuksek | Acik | feed contract yanlis sabitlenirse fallback'e bagimli akislar kirilabilir |
| `RISK-005` | Risk | Yuksek | Acik | runtime/playback/cache boundary degisikligi arka plan regresyonu uretebilir |
| `DEBT-001` | Debt | Orta | Acik | part-sprawl okuma maliyetini artiriyor |
| `DEBT-002` | Debt | Orta | Acik | repo surface area cok buyuk; dosya takibi pahali |

## Checkpoint Snapshot

| Checkpoint | Durum | Not |
| --- | --- | --- |
| `CP-001` | Kaydedildi | T-001 oncesi guvenli geri donus noktasi `35f3b0a9` |
| `CP-002` - `CP-007` | Acik | kritik degisikliklerden once doldurulacak |

## T-001 Kapanis Beklentisi

- baseline risk/checkpoint kaydi sabitlenmis olacak
- artifact register icinde `ART-001` dolu olacak
- bir sonraki ise gecmeden once kullanici onayi alinacak

## Uretim Komutlari

Bu artifact asagidaki komutlardan gelen ciktilarla olusturuldu:

```bash
git -C /Users/turqapp/Desktop/TurqApp rev-parse --short HEAD
git -C /Users/turqapp/Desktop/TurqApp branch --show-current
git -C /Users/turqapp/Desktop/TurqApp status --short
find /Users/turqapp/Desktop/TurqApp/lib -name '*.dart' | wc -l
find /Users/turqapp/Desktop/TurqApp/test /Users/turqapp/Desktop/TurqApp/integration_test -name '*.dart' | wc -l
find /Users/turqapp/Desktop/TurqApp/functions/src -name '*.ts' | wc -l
find /Users/turqapp/Desktop/TurqApp/cloudflare-shortlink-worker/src -name '*.ts' -o -name '*.js' | wc -l
rg -o "Get\\.(find|put|delete|isRegistered)" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | wc -l
rg -o "extends GetxController" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib | wc -l
rg -o "catch \\(_\\)" -g '*.dart' /Users/turqapp/Desktop/TurqApp/lib /Users/turqapp/Desktop/TurqApp/test /Users/turqapp/Desktop/TurqApp/integration_test | wc -l
```

## Reviewer Notu

- Teknik tutarlilik kontrolu: gecildi
- Final approval: kullanici onayi bekleniyor
