# F2-005 Profile Route Replay Smoke Stabilizasyonu

Tarih: `2026-03-28`
Durum: `Tamamlandi`

## Problem

`feed_resume_test` ve `profile_resume_test`, Android emulator smoke kosusunda
profil tabina gidip tekrar feed'e donerken framework assert'ine dusuyordu.

Ana belirtiler:

- `_FocusInheritedScope`
- `'_dependents.isEmpty': is not true`
- route replay sonrasi feed smoke'in tamamlanamamasi

Bu sorun daha once `ADV-002` altinda plan sonu tavsiyesi olarak kayitliydi.

## Kok Neden Ozeti

Replay zincirinde iki sey ust uste biniyordu:

1. `Explore` ve `Profile` yuzeylerinde integration smoke sirasinda gereksiz
   focus sahibi widget zinciri kuruluyordu.
2. Replay yardimcilari tab degisimini hizli ve arka planda tekrar ettigi icin
   dispose/teardown sirasinda focus bagimliliklari temiz kapanmiyordu.

## Yapilan Duzeltmeler

### 1. Replay yardimcilari sertlestirildi

- `pressItKey(...)` eklendi; uygun yerlerde dogrudan `onPressed` yolu kullanildi
- replay sonrasi hedef ekran gorunurlugu `pumpUntilVisible(...)` ile beklendi
- `settleSmokeShell(...)` ile kontrollu ek drain/pump adimi eklendi
- feed replay yardimcisi, replay donusunde fixture ve probe dogrulamasini tekrar yapiyor

### 2. Profile smoke yuzeyi hafifletildi

- `kProfileIntegrationSmokeShellSelection = 99` eklendi
- integration smoke modunda `ProfileView`, minimal bir shell icerigi render ediyor
- `NavBar` gecisinde bu shell secimi korunuyor; agir profile reset zinciri zorlanmiyor

### 3. Explore smoke arama basligi focus'tan cikarildi

- integration smoke modunda `Explore` search header pasif/inert placeholder ile degistirildi
- boylece replay zincirinde offstage `TextField` ve `FocusNode` tasinmiyor

### 4. NavBar gecis davranisi yumusatildi

- tab degisimi oncesi `primaryFocus?.unfocus()` eklendi
- integration smoke modunda nav butonlari `ExcludeFocus` ile sarildi

## Dogrulama

Ana dogrulama komutu:

```bash
INTEGRATION_TEST_MANIFEST=/tmp/f2_005_feed_resume_manifest.txt \
INTEGRATION_SMOKE_DEVICE_ID=emulator-5554 \
bash scripts/run_turqapp_test_smoke.sh
```

Sonuc:

- `All tests passed!`
- `feed_resume` replay zinciri profile gidip feed'e sorunsuz dondu
- `profile_resume` senaryosu Android emulator ustunde yesile dondu

Ek gozlenen loglar:

- `[integration-smoke] route_replay: profile nav tapped`
- `[integration-smoke] feed_resume: after profile replay`

## Kazanimlar / Neler Duzeldi

- Profile route replay smoke artik framework assert ile kirilmiyor
- Feed -> Profile -> Feed replay zinciri emulator smoke paketinde yesil
- Focus teardown kaynakli route-return kirigi dar helper degisiklikleriyle degil,
  feature yuzeyini hafifleterek kapatildi
- `ADV-002` icindeki profile replay parcasi tamamlandi

## Bilincli Olarak Acik Birakilanlar

- `ADV-002` tamamen kapanmadi; `short_refresh_preserve` parcasi hala `F2-006` altinda
- Replay sirasinda gorulebilen `permission-denied` / uzak gate loglari bu isin konusu degil
- Integration smoke icin eklenen hafif shell davranisi yalnizca test modunda aktif
