# T-021 Backend Security Regression Paketi

## Amaç

`T-004`, `T-005`, `T-006` ve `T-007` ile kapanan kritik backend/rules risklerini tek bir tekrar kosulabilir regression paketi altina toplamak.

## Paket kapsami

- moderation review auth regression
- users read-surface regression
- market counter write regression
- reports spoofed payload regression
- post/job storage metadata-bypass regression

## Eklenen test dosyalari

- `functions/tests/unit/moderationSecurityRegression.test.js`

## Bu paket tarafindan tekrar kosulan mevcut rules suiteleri

- `functions/tests/rules/firestore.rules.test.js`
- `functions/tests/rules/storage.rules.test.js`

## Regression komutu

- `npm run build`
- `npm run test:security-regressions`

## Beklenen fayda

- kritik authz/rules kapanislari dağinik tekil testlerden cikarak tek bir güvenlik paketi olarak izlenir
- T-024 coverage ve sonraki release gate isleri icin daha net bir backend regression sinyali uretilir
