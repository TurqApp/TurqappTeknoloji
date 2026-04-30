interface Env {
  TURQ_KV: KVNamespace;
  APP_SCHEME: string;
  IOS_STORE_URL: string;
  ANDROID_STORE_URL: string;
  DEFAULT_OG_IMAGE: string;
  EMAIL_ACTION_CONFIRM_URL: string;
  APP_ADS_TXT?: string;
  AASA_JSON: string;
  ASSETLINKS_JSON: string;
  FIREBASE_PROJECT_ID?: string;
  SHORT_LINK_RESOLVE_URL?: string;
}

type LinkType = "p" | "s" | "u" | "e" | "i" | "m";

type LinkMeta = {
  type?: "post" | "story" | "user" | "edu" | "job" | "market";
  entityId?: string;
  shortId?: string;
  slug?: string;
  token?: string;
  title?: string;
  desc?: string;
  imageUrl?: string;
  expiresAt?: number;
  url?: string;
  status?: "active" | "inactive";
  updatedAt?: number;
};

const CACHE_TTL_SECONDS = 300;
const DEFAULT_APP_ADS_TXT =
  "google.com, pub-4558422035199571, DIRECT, f08c47fec0942fa0";

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const ua = (request.headers.get("user-agent") || "").toLowerCase();

    if (path === "/og-image") {
      return proxyOgImage(request, url, env);
    }

    if (path === "/app-ads.txt") {
      const body = String(env.APP_ADS_TXT || DEFAULT_APP_ADS_TXT).trim();
      return new Response(`${body}\n`, {
        status: 200,
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "public, max-age=3600",
        },
      });
    }

    if (path === "/.well-known/apple-app-site-association") {
      return jsonResponse(env.AASA_JSON, 200, {
        "cache-control": "public, max-age=3600",
      });
    }

    if (path === "/.well-known/assetlinks.json") {
      return jsonResponse(env.ASSETLINKS_JSON, 200, {
        "cache-control": "public, max-age=3600",
      });
    }

    const route = parseRoute(path);
    if (!route) {
      return new Response("Not found", { status: 404 });
    }

    const kvKey = `${route.kind}:${route.id}`;
    let kvRaw = await env.TURQ_KV.get(kvKey);
    if (!kvRaw) {
      const resolvedMeta = await resolveFromFunction(route, env);
      if (resolvedMeta) {
        kvRaw = JSON.stringify(resolvedMeta);
        await env.TURQ_KV.put(kvKey, kvRaw, {
          expirationTtl: CACHE_TTL_SECONDS,
        });
      }
    }

    if (!kvRaw) {
      if (route.kind === "e") {
        const fallback = fallbackHtml({
          title: "TurqApp eğitim bağlantısı",
          desc: "Paylaşımı açmak için uygulamayı kullan.",
          image: env.DEFAULT_OG_IMAGE,
          deepLink: buildDeepLink(env.APP_SCHEME, "e", route.id),
          iosStore: env.IOS_STORE_URL,
          androidStore: env.ANDROID_STORE_URL,
          ctaLabel: "İçeriği İncele",
        });
        return new Response(fallback, {
          headers: htmlHeaders(),
        });
      } else {
        return notFoundHtml("Link bulunamadı");
      }
    }

    let meta: LinkMeta;
    try {
      meta = JSON.parse(kvRaw) as LinkMeta;
    } catch {
      return notFoundHtml("Link verisi bozuk");
    }

    // Eski KV kayitlarinda imageUrl bos / hatali / proxy'siz kalabiliyor.
    // Tum tipler icin function'dan tekrar cozup KV'yi iyilestir.
    const hasImage = String(meta.imageUrl || "").trim().length > 0;
    const isOgProxyImage = String(meta.imageUrl || "").includes("/og-image?src=");
    const isDirectCdnImage = String(meta.imageUrl || "").startsWith("https://cdn.turqapp.com/");
    const shouldRefreshMeta =
      !hasImage ||
      (!isOgProxyImage && !isDirectCdnImage);

    if (shouldRefreshMeta) {
      const refreshed = await resolveFromFunction(route, env);
      if (refreshed) {
        meta = { ...meta, ...refreshed };
        await env.TURQ_KV.put(kvKey, JSON.stringify(meta), {
          expirationTtl: CACHE_TTL_SECONDS,
        });
      }
    }

    if (meta.status === "inactive") {
      return notFoundHtml("Link pasif");
    }

    // Geriye dönük uyumluluk: e/* linkinde token varsa e-posta onayı gibi davran.
    // Eğitim kısa linkleri token içermez; normal deep-link akışına devam eder.
    if (route.kind === "e") {
      const token = String(meta.token || "").trim();
      if (token) {
        const confirmBase = String(env.EMAIL_ACTION_CONFIRM_URL || "").trim();
        if (!confirmBase) return notFoundHtml("Onay servisi yapılandırılmamış");

        const confirmUrl = `${confirmBase}?token=${encodeURIComponent(token)}`;
        try {
          const response = await fetch(confirmUrl, { method: "GET" });
          if (!response.ok) {
            return new Response(
              "<!doctype html><html><body><h3>Bağlantı geçersiz veya süresi dolmuş.</h3></body></html>",
              { status: 410, headers: htmlHeaders() }
            );
          }
          return new Response(
            "<!doctype html><html><body><h3>Onaylandı. Uygulamaya geri dönebilirsiniz.</h3></body></html>",
            { status: 200, headers: htmlHeaders() }
          );
        } catch {
          return new Response(
            "<!doctype html><html><body><h3>Onay servisine ulaşılamadı. Lütfen tekrar deneyin.</h3></body></html>",
            { status: 503, headers: htmlHeaders() }
          );
        }
      }
    }

    if (route.kind === "s" && typeof meta.expiresAt === "number" && meta.expiresAt > 0) {
      if (Date.now() > meta.expiresAt) {
        return expiredHtml();
      }
    }

    const title = safeText(meta.title || "TurqApp");
    const desc = safeText(meta.desc || "TurqApp paylaşımı");
    const image = safeUrl(meta.imageUrl || env.DEFAULT_OG_IMAGE);
    const canonical = `https://${url.host}${path}`;

    if (isBot(ua)) {
      return new Response(ogHtml({ title, desc, image, canonical }), {
        headers: htmlHeaders({
          "cache-control": `public, max-age=${CACHE_TTL_SECONDS}`,
        }),
      });
    }

    const deepLink = buildDeepLink(env.APP_SCHEME, route.kind, route.id);
    return new Response(
      fallbackHtml({
        title,
        desc,
        image,
        deepLink,
        iosStore: env.IOS_STORE_URL,
        androidStore: env.ANDROID_STORE_URL,
        ctaLabel: ctaLabelFor(route, meta),
      }),
      {
        headers: htmlHeaders({
          "cache-control": "no-store",
        }),
      }
    );
  },
};

async function proxyOgImage(request: Request, url: URL, env: Env): Promise<Response> {
  const src = safeUrl(url.searchParams.get("src") || "");
  const fallback = safeUrl(env.DEFAULT_OG_IMAGE || "");
  const target = src || fallback;
  if (!target) {
    return new Response("Not found", { status: 404 });
  }

  try {
    const upstream = await fetch(target, {
      headers: {
        "user-agent": request.headers.get("user-agent") || "TurqAppBot/1.0",
        "accept": "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
      },
      cf: { cacheTtl: CACHE_TTL_SECONDS, cacheEverything: true },
    });
    if (!upstream.ok) {
      return Response.redirect(fallback, 302);
    }

    const headers = new Headers(upstream.headers);
    headers.set("cache-control", `public, max-age=${CACHE_TTL_SECONDS}`);
    headers.set("access-control-allow-origin", "*");
    headers.set("cross-origin-resource-policy", "cross-origin");
    headers.set("x-content-type-options", "nosniff");
    headers.set("referrer-policy", "no-referrer");
    return new Response(upstream.body, {
      status: upstream.status,
      headers,
    });
  } catch {
    if (fallback && fallback !== target) {
      return Response.redirect(fallback, 302);
    }
    return new Response("Not found", { status: 404 });
  }
}

function parseRoute(pathname: string): { kind: LinkType; id: string } | null {
  const match = pathname.match(/^\/(p|s|u|e|i|m)\/([A-Za-z0-9._-]{2,80})$/);
  if (!match) return null;
  return { kind: match[1] as LinkType, id: match[2] };
}

function buildDeepLink(appScheme: string, kind: LinkType, id: string): string {
  const base = appScheme.endsWith("://") ? appScheme.slice(0, -3) : appScheme.replace(/:$/, "");
  if (kind === "p") return `${base}://post/${id}`;
  if (kind === "s") return `${base}://story/${id}`;
  if (kind === "e") return `${base}://e/${id}`;
  if (kind === "i") return `${base}://job/${id}`;
  if (kind === "m") return `${base}://market/${id}`;
  return `${base}://profile/${id}`;
}

function ctaLabelFor(route: { kind: LinkType; id: string }, meta?: LinkMeta): string {
  const entityId = String(meta?.entityId || "");
  if (route.kind === "e" && entityId.startsWith("scholarship:")) {
    return "Bursu İncele";
  }
  if (entityId.startsWith("practice-exam:")) {
    return "Testi İncele";
  }
  if (entityId.startsWith("answer-key:")) {
    return "Cevap Anahtarını İncele";
  }
  if (entityId.startsWith("question:")) {
    return "Soruyu İncele";
  }
  if (entityId.startsWith("tutoring:")) {
    return "Özel Dersi İncele";
  }
  if (entityId.startsWith("job:") || route.kind === "i") {
    return "İlanı İncele";
  }
  if (route.kind === "m" || String(meta?.type || "") === "market") {
    return "İlanı İncele";
  }
  return "Uygulamada Aç";
}

function isBot(ua: string): boolean {
  const botHints = [
    "whatsapp",
    "telegram",
    "twitterbot",
    "facebookexternalhit",
    "facebot",
    "discordbot",
    "slackbot",
    "linkedinbot",
    "bot",
    "crawler",
    "spider",
  ];
  return botHints.some((h) => ua.includes(h));
}

function safeText(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function safeUrl(value: string): string {
  if (!value) return "";
  if (value.startsWith("http://") || value.startsWith("https://")) {
    return value;
  }
  return "";
}

function baseSecurityHeaders(extra?: Record<string, string>): Record<string, string> {
  return {
    "x-content-type-options": "nosniff",
    "referrer-policy": "no-referrer",
    "x-frame-options": "DENY",
    "permissions-policy": "camera=(), microphone=(), geolocation=()",
    ...(extra || {}),
  };
}

function htmlHeaders(extra?: Record<string, string>): Record<string, string> {
  return baseSecurityHeaders({
    "content-type": "text/html; charset=utf-8",
    "content-security-policy":
      "default-src 'none'; img-src https: data:; style-src 'unsafe-inline'; script-src 'unsafe-inline'; connect-src https:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
    ...(extra || {}),
  });
}

function ogHtml(input: { title: string; desc: string; image: string; canonical: string }): string {
  return `<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${input.title}</title>
  <link rel="canonical" href="${input.canonical}" />
  <meta property="og:type" content="website" />
  <meta property="og:title" content="${input.title}" />
  <meta property="og:description" content="${input.desc}" />
  <meta property="og:image" content="${input.image}" />
  <meta property="og:image:secure_url" content="${input.image}" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta property="og:url" content="${input.canonical}" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${input.title}" />
  <meta name="twitter:description" content="${input.desc}" />
  <meta name="twitter:image" content="${input.image}" />
</head>
<body></body>
</html>`;
}

function fallbackHtml(input: {
  title: string;
  desc: string;
  image: string;
  deepLink: string;
  iosStore: string;
  androidStore: string;
  ctaLabel: string;
}): string {
  return `<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${input.title}</title>
  <meta property="og:type" content="website" />
  <meta property="og:title" content="${input.title}" />
  <meta property="og:description" content="${input.desc}" />
  <meta property="og:image" content="${input.image}" />
  <meta property="og:image:secure_url" content="${input.image}" />
  <meta property="og:image:width" content="1200" />
  <meta property="og:image:height" content="630" />
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${input.title}" />
  <meta name="twitter:description" content="${input.desc}" />
  <meta name="twitter:image" content="${input.image}" />
  <style>
    body { font-family: -apple-system, system-ui, Segoe UI, Roboto, sans-serif; margin: 0; padding: 24px; background: #f8f9fb; color: #111; }
    .card { max-width: 480px; margin: 48px auto; background: white; border-radius: 14px; padding: 20px; box-shadow: 0 6px 24px rgba(0,0,0,.08); }
    h1 { font-size: 18px; margin: 0 0 8px; }
    p { font-size: 14px; margin: 0 0 16px; color: #444; }
    button {
      width: 100%;
      border: 0;
      border-radius: 12px;
      background: linear-gradient(135deg, #2a4f76 0%, #3a6a98 100%);
      color: white;
      padding: 13px;
      font-size: 15px;
      font-weight: 700;
      letter-spacing: 0.2px;
      box-shadow: 0 8px 22px rgba(42,79,118,.35);
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>${input.title}</h1>
    <p>${input.desc}</p>
    <button id="openBtn">${input.ctaLabel}</button>
  </div>
  <script>
    (function () {
      var ua = navigator.userAgent.toLowerCase();
      var isAndroid = ua.indexOf('android') !== -1;
      var store = isAndroid ? ${JSON.stringify(input.androidStore)} : ${JSON.stringify(input.iosStore)};
      var deep = ${JSON.stringify(input.deepLink)};
      var opened = false;

      function openApp() {
        if (opened) return;
        opened = true;
        window.location.href = deep;
        setTimeout(function () {
          window.location.href = store;
        }, 900);
      }

      document.getElementById('openBtn').addEventListener('click', openApp);
      openApp();
    })();
  </script>
</body>
</html>`;
}

function expiredHtml(): Response {
  return new Response(
    "<!doctype html><html><body><h3>Story süresi dolmuş.</h3></body></html>",
    { status: 410, headers: htmlHeaders() }
  );
}

function notFoundHtml(message: string): Response {
  return new Response(
    `<!doctype html><html><body><h3>${safeText(message)}</h3></body></html>`,
    { status: 404, headers: htmlHeaders() }
  );
}

function jsonResponse(jsonText: string, status = 200, extraHeaders?: Record<string, string>): Response {
  return new Response(jsonText, {
    status,
    headers: baseSecurityHeaders({
      "content-type": "application/json; charset=utf-8",
      ...(extraHeaders || {}),
    }),
  });
}

async function resolveFromFunction(
  route: { kind: LinkType; id: string },
  env: Env
): Promise<LinkMeta | null> {
  const type = route.kind === "p"
    ? "post"
    : route.kind === "s"
    ? "story"
    : route.kind === "u"
    ? "user"
    : route.kind === "i"
    ? "job"
    : route.kind === "m"
    ? "market"
    : "edu";

  const explicitUrl = String(env.SHORT_LINK_RESOLVE_URL || "").trim();
  const projectId = String(env.FIREBASE_PROJECT_ID || "").trim();
  const endpoint =
    explicitUrl ||
    (projectId
      ? `https://us-central1-${projectId}.cloudfunctions.net/resolveShortLink`
      : "");

  if (!endpoint) return null;

  try {
    const response = await fetch(endpoint, {
      method: "POST",
      headers: { "content-type": "application/json" },
      body: JSON.stringify({
        data: {
          type,
          id: route.id,
        },
      }),
    });

    if (!response.ok) return null;
    const json = (await response.json()) as {
      result?: { data?: LinkMeta };
    };
    return json.result?.data || null;
  } catch {
    return null;
  }
}
