# T-013 SignIn Application Service

## Amac

`SignInController` icindeki password sign-in ve stored-account orkestrasyonunu
ekran state'inden ayirmak.

## Yapilanlar

- `SignInApplicationService` eklendi.
- Password sign-in denemesi artik application service uzerinden yurutuluyor.
- Stored-account identifier cozumleme ve re-auth isaretleme mantigi application
  service'e tasindi.
- Post-auth task scheduling ve account tracking mantigi controller yerine
  service'e cekildi.

## Kapsam Disi Birakilanlar

- Sign-in ekran navigation karari controller'da kaldi.
- Snackbar / translation / UI message mapping controller'da kaldi.
- Password reset ve signup akislarina dokunulmadi.

## Kabul Kriteri Kaniti

- Controller auth/account part'lari application service'e delegasyon yapiyor.
- Sign-in orchestration icin hedefli birim testleri eklendi.
