interface Env {
  TURQ_KV: KVNamespace;
  APP_SCHEME: string;
  IOS_STORE_URL: string;
  ANDROID_STORE_URL: string;
  DEFAULT_OG_IMAGE: string;
  AASA_JSON: string;
  ASSETLINKS_JSON: string;
}

type LinkType = "p" | "s" | "u";

type LinkMeta = {
  type?: "post" | "story" | "user";
  entityId?: string;
  shortId?: string;
  slug?: string;
  title?: string;
  desc?: string;
  imageUrl?: string;
  expiresAt?: number;
  url?: string;
  status?: "active" | "inactive";
  updatedAt?: number;
};

const CACHE_TTL_SECONDS = 300;

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname;
    const ua = (request.headers.get("user-agent") || "").toLowerCase();

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
    const kvRaw = await env.TURQ_KV.get(kvKey);
    if (!kvRaw) {
      return notFoundHtml("Link bulunamadı");
    }

    let meta: LinkMeta;
    try {
      meta = JSON.parse(kvRaw) as LinkMeta;
    } catch {
      return notFoundHtml("Link verisi bozuk");
    }

    if (meta.status === "inactive") {
      return notFoundHtml("Link pasif");
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
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": `public, max-age=${CACHE_TTL_SECONDS}`,
        },
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
      }),
      {
        headers: {
          "content-type": "text/html; charset=utf-8",
          "cache-control": "no-store",
        },
      }
    );
  },
};

function parseRoute(pathname: string): { kind: LinkType; id: string } | null {
  const match = pathname.match(/^\/(p|s|u)\/([A-Za-z0-9._-]{2,40})$/);
  if (!match) return null;
  return { kind: match[1] as LinkType, id: match[2] };
}

function buildDeepLink(appScheme: string, kind: LinkType, id: string): string {
  const base = appScheme.endsWith("://") ? appScheme.slice(0, -3) : appScheme.replace(/:$/, "");
  if (kind === "p") return `${base}://post/${id}`;
  if (kind === "s") return `${base}://story/${id}`;
  return `${base}://profile/${id}`;
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
}): string {
  return `<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${input.title}</title>
  <meta property="og:title" content="${input.title}" />
  <meta property="og:description" content="${input.desc}" />
  <meta property="og:image" content="${input.image}" />
  <style>
    body { font-family: -apple-system, system-ui, Segoe UI, Roboto, sans-serif; margin: 0; padding: 24px; background: #f8f9fb; color: #111; }
    .card { max-width: 480px; margin: 48px auto; background: white; border-radius: 14px; padding: 20px; box-shadow: 0 6px 24px rgba(0,0,0,.08); }
    h1 { font-size: 18px; margin: 0 0 8px; }
    p { font-size: 14px; margin: 0 0 16px; color: #444; }
    button { width: 100%; border: 0; border-radius: 10px; background: #111; color: white; padding: 12px; font-size: 15px; }
  </style>
</head>
<body>
  <div class="card">
    <h1>${input.title}</h1>
    <p>${input.desc}</p>
    <button id="openBtn">Uygulamada Aç</button>
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
    { status: 410, headers: { "content-type": "text/html; charset=utf-8" } }
  );
}

function notFoundHtml(message: string): Response {
  return new Response(
    `<!doctype html><html><body><h3>${safeText(message)}</h3></body></html>`,
    { status: 404, headers: { "content-type": "text/html; charset=utf-8" } }
  );
}

function jsonResponse(jsonText: string, status = 200, extraHeaders?: Record<string, string>): Response {
  return new Response(jsonText, {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      ...(extraHeaders || {}),
    },
  });
}

