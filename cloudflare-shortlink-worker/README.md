# TurqApp Short Link Worker

Bu Worker, web sitesi olmadan kısa link + OG preview + deep link fallback sağlar.

## Link Formatı

- Post: `https://turqapp.com/p/{id}`
- Story: `https://turqapp.com/s/{id}`
- User: `https://turqapp.com/u/{slug}`

## KV Şeması

- `p:{id}` -> post meta JSON
- `s:{id}` -> story meta JSON (`expiresAt` ile)
- `u:{slug}` -> user meta JSON

Örnek değer:

```json
{
  "type": "post",
  "entityId": "POST_DOC_ID",
  "shortId": "Ab39Kd1",
  "title": "TurqApp Post",
  "desc": "Açıklama",
  "imageUrl": "https://cdn.turqapp.com/og/post.jpg",
  "status": "active",
  "updatedAt": 1772000000000
}
```

## Çalışma Mantığı

1. Bot (WhatsApp/Telegram/X) gelirse OG meta HTML döner.
2. Kullanıcı gelirse app deep link dener.
3. App yoksa Store fallback.

## DNS / Route

Cloudflare'da:

1. `turqapp.com` proxied olmalı.
2. Worker route eklenmeli:
   - `turqapp.com/p/*`
   - `turqapp.com/s/*`
   - `turqapp.com/u/*`
   - `turqapp.com/.well-known/*`

## Well-known Dosyaları

`wrangler.toml` içindeki:

- `AASA_JSON` -> iOS Universal Links
- `ASSETLINKS_JSON` -> Android App Links

değerleri gerçek app bilgileriyle güncellenmeli.

## Kurulum

```bash
cd cloudflare-shortlink-worker
npm i -g wrangler
wrangler login
wrangler deploy
```

## Fonksiyon Tarafı

Firebase Functions modülü: `functions/src/17_shortLinksIndex.ts`

- `upsertShortLink`
- `resolveShortLink`
- `shortLinkIndexConfig`

Bu modül, `shortLinks` koleksiyonuna yazar ve Cloudflare KV'ye sync eder.
