#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";

const PROJECT_ID = "turqappteknoloji";
const STORAGE_BUCKET = "turqappteknoloji.firebasestorage.app";
const DEFAULT_INPUT = "/Users/turqapp/Desktop/turqapp_curated_user_import_ready_184.json";
const DEFAULT_MAPPING = "/Users/turqapp/Desktop/turqapp_curated_source_user_mapping_fresh_2026-05-21.json";
const DEFAULT_OUT_DIR = "/Users/turqapp/Desktop/TurqApp/artifacts/curated_avatars";
const DEFAULT_MANIFEST = "/Users/turqapp/Desktop/turqapp_curated_avatar_manifest_184.json";
const DEFAULT_SERVICE_ACCOUNT =
  "/Users/turqapp/Desktop/TurqApp_Firebase/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";
const AVATAR_VERSION = "v2";

const require = createRequire(import.meta.url);
const admin = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/firebase-admin",
));
const sharp = require(path.resolve(
  path.dirname(new URL(import.meta.url).pathname),
  "../functions/node_modules/sharp",
));

const TOPIC_PALETTES = {
  tech_ai: { bg1: "#07111F", bg2: "#123A5C", main: "#60A5FA", accent: "#22D3EE", warm: "#A7F3D0" },
  auto_mobility: { bg1: "#111827", bg2: "#3F1D1D", main: "#EF4444", accent: "#FBBF24", warm: "#D1D5DB" },
  art_visual: { bg1: "#211626", bg2: "#5B2148", main: "#F472B6", accent: "#FDE68A", warm: "#93C5FD" },
  home_style: { bg1: "#1C1917", bg2: "#57534E", main: "#D6D3D1", accent: "#A3E635", warm: "#FDBA74" },
  knowledge_science: { bg1: "#0F172A", bg2: "#164E63", main: "#67E8F9", accent: "#FDE047", warm: "#E0F2FE" },
  faith_values: { bg1: "#102018", bg2: "#22543D", main: "#D9F99D", accent: "#FACC15", warm: "#F5E6C8" },
  world_history_news: { bg1: "#1F2937", bg2: "#5A3E2B", main: "#D6B37A", accent: "#38BDF8", warm: "#F5E7C4" },
  entertainment_humor: { bg1: "#18181B", bg2: "#4C1D95", main: "#A78BFA", accent: "#F472B6", warm: "#FDE68A" },
  sports: { bg1: "#052E16", bg2: "#166534", main: "#BBF7D0", accent: "#F97316", warm: "#E2E8F0" },
  food_cafe: { bg1: "#2A1508", bg2: "#7C2D12", main: "#FED7AA", accent: "#F59E0B", warm: "#FEF3C7" },
  music: { bg1: "#111827", bg2: "#312E81", main: "#C4B5FD", accent: "#FDE047", warm: "#F9A8D4" },
  travel_nature: { bg1: "#0C1F17", bg2: "#14532D", main: "#86EFAC", accent: "#38BDF8", warm: "#FDE68A" },
  motivation_life: { bg1: "#1E1B4B", bg2: "#7C2D12", main: "#FDBA74", accent: "#FDE047", warm: "#C7D2FE" },
  craft_work: { bg1: "#171717", bg2: "#44403C", main: "#D4D4D4", accent: "#F97316", warm: "#FACC15" },
  health_people: { bg1: "#062B2B", bg2: "#0E7490", main: "#CCFBF1", accent: "#F472B6", warm: "#FFFFFF" },
  general_culture: { bg1: "#111827", bg2: "#334155", main: "#CBD5E1", accent: "#FBBF24", warm: "#BFDBFE" },
};

function parseArgs(argv) {
  const options = {
    input: DEFAULT_INPUT,
    mapping: DEFAULT_MAPPING,
    outDir: DEFAULT_OUT_DIR,
    manifest: DEFAULT_MANIFEST,
    serviceAccount: process.env.GOOGLE_APPLICATION_CREDENTIALS || DEFAULT_SERVICE_ACCOUNT,
    apply: false,
    limit: 0,
  };

  for (let index = 2; index < argv.length; index += 1) {
    const arg = String(argv[index] || "").trim();
    if (!arg) continue;
    if (arg === "--input") {
      options.input = String(argv[index + 1] || "").trim() || options.input;
      index += 1;
      continue;
    }
    if (arg === "--mapping") {
      options.mapping = String(argv[index + 1] || "").trim() || options.mapping;
      index += 1;
      continue;
    }
    if (arg === "--out-dir") {
      options.outDir = String(argv[index + 1] || "").trim() || options.outDir;
      index += 1;
      continue;
    }
    if (arg === "--manifest") {
      options.manifest = String(argv[index + 1] || "").trim() || options.manifest;
      index += 1;
      continue;
    }
    if (arg === "--service-account") {
      options.serviceAccount = String(argv[index + 1] || "").trim() || options.serviceAccount;
      index += 1;
      continue;
    }
    if (arg === "--limit") {
      options.limit = Math.max(0, Number(argv[index + 1] || 0));
      index += 1;
      continue;
    }
    if (arg === "--apply") options.apply = true;
  }

  return options;
}

function ensureDir(dirPath) {
  fs.mkdirSync(dirPath, { recursive: true });
}

function hashNumber(input) {
  let hash = 2166136261;
  for (const char of String(input)) {
    hash ^= char.charCodeAt(0);
    hash = Math.imul(hash, 16777619);
  }
  return hash >>> 0;
}

function xml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function initials(record) {
  const doc = record.usersDoc || {};
  const first = String(doc.firstName || doc.displayName || doc.nickname || record.uid || "")
    .trim()
    .charAt(0);
  const last = String(doc.lastName || "")
    .trim()
    .charAt(0);
  return `${first}${last}`.toLocaleUpperCase("tr-TR") || "T";
}

function pick(list, seed, salt = 0) {
  return list[(seed + salt) % list.length];
}

function hsl(seed, offset = 0, saturation = 68, lightness = 46) {
  return `hsl(${(seed * 37 + offset) % 360} ${saturation}% ${lightness}%)`;
}

function topicGlyph(topic, palette) {
  const fill = palette.accent;
  const stroke = palette.warm;
  switch (topic) {
    case "tech_ai":
      return `<path d="M22 38h20M32 18v40M22 25h20M22 51h20" stroke="${stroke}" stroke-width="5" stroke-linecap="round"/><circle cx="32" cy="38" r="8" fill="${fill}"/>`;
    case "auto_mobility":
      return `<path d="M14 42c5-14 14-22 25-22h12c8 2 14 10 18 22" fill="none" stroke="${stroke}" stroke-width="5"/><circle cx="24" cy="45" r="6" fill="${fill}"/><circle cx="58" cy="45" r="6" fill="${fill}"/>`;
    case "art_visual":
      return `<circle cx="24" cy="33" r="8" fill="${fill}"/><circle cx="42" cy="28" r="7" fill="${stroke}"/><path d="M20 54l36-36" stroke="${stroke}" stroke-width="7" stroke-linecap="round"/>`;
    case "knowledge_science":
      return `<path d="M28 16h16M32 16v18L21 55h30L40 34V16" fill="none" stroke="${stroke}" stroke-width="5" stroke-linejoin="round"/><circle cx="36" cy="48" r="5" fill="${fill}"/>`;
    case "sports":
      return `<circle cx="36" cy="36" r="20" fill="none" stroke="${stroke}" stroke-width="5"/><path d="M36 16c-5 12-5 28 0 40M18 31c11-5 25-5 36 0M18 42c11 5 25 5 36 0" stroke="${fill}" stroke-width="4" fill="none"/>`;
    case "food_cafe":
      return `<path d="M22 25h30v18c0 11-7 18-15 18s-15-7-15-18V25Z" fill="${stroke}"/><path d="M52 31h7c7 0 9 12-2 14" fill="none" stroke="${stroke}" stroke-width="5"/><path d="M30 20c-4-7 5-8 1-15M42 20c-4-7 5-8 1-15" stroke="${fill}" stroke-width="4" stroke-linecap="round"/>`;
    case "music":
      return `<path d="M42 16v32" stroke="${stroke}" stroke-width="6" stroke-linecap="round"/><path d="M42 16l17 7" stroke="${fill}" stroke-width="5" stroke-linecap="round"/><circle cx="31" cy="50" r="10" fill="${stroke}"/><path d="M41 47c-2 5-6 8-10 9" stroke="${stroke}" stroke-width="5"/>`;
    case "travel_nature":
      return `<circle cx="36" cy="36" r="22" fill="none" stroke="${stroke}" stroke-width="5"/><path d="M36 17v38M17 36h38M23 24c8 5 18 5 26 0M23 48c8-5 18-5 26 0" stroke="${fill}" stroke-width="4" fill="none"/>`;
    default:
      return `<rect x="19" y="19" width="34" height="34" rx="8" fill="none" stroke="${stroke}" stroke-width="5"/><path d="M27 32h18M27 42h14" stroke="${fill}" stroke-width="5" stroke-linecap="round"/>`;
  }
}

function loadUserTopics(mappingPath) {
  if (!mappingPath || !fs.existsSync(mappingPath)) return new Map();
  const mapping = JSON.parse(fs.readFileSync(mappingPath, "utf8"));
  const result = new Map();
  for (const pool of mapping.pools || []) {
    if (pool.userID) {
      result.set(pool.userID, {
        topic: pool.topic || "general_culture",
        sources: Array.isArray(pool.sources) ? pool.sources.map((entry) => entry.source) : [],
      });
    }
  }
  return result;
}

function drawTopicObject(topic, palette, seed) {
  const variant = seed % 5;
  const glow = `filter="url(#softShadow)"`;
  const stroke = `stroke="${palette.warm}" stroke-width="7" stroke-linecap="round" stroke-linejoin="round"`;
  const thin = `stroke="${palette.accent}" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"`;
  switch (topic) {
    case "tech_ai":
      return `
        <rect x="138" y="154" width="236" height="170" rx="24" fill="#071827" stroke="${palette.main}" stroke-width="5" ${glow}/>
        <circle cx="203" cy="225" r="22" fill="${palette.accent}"/>
        <circle cx="274" cy="225" r="18" fill="${palette.main}"/>
        <circle cx="329" cy="272" r="20" fill="${palette.warm}"/>
        <path d="M203 225H274M274 225L329 272M203 225l-43 62M329 272l42-72" ${thin}/>
        <path d="M158 358h196M180 384h152" ${stroke} opacity=".7"/>`;
    case "auto_mobility":
      return `
        <path d="M116 302c25-72 62-112 111-120h89c42 9 73 48 92 120" fill="#0B0F17" stroke="${palette.main}" stroke-width="6" ${glow}/>
        <circle cx="180" cy="319" r="35" fill="#111827" stroke="${palette.warm}" stroke-width="10"/>
        <circle cx="333" cy="319" r="35" fill="#111827" stroke="${palette.warm}" stroke-width="10"/>
        <path d="M181 232h151M143 284h250" ${thin}/>
        <path d="M226 183l-25 49M315 184l24 49" stroke="${palette.accent}" stroke-width="5" opacity=".7"/>`;
    case "art_visual":
      return `
        <ellipse cx="266" cy="286" rx="132" ry="88" fill="#F7E7CE" ${glow}/>
        <circle cx="211" cy="263" r="24" fill="#EF4444"/>
        <circle cx="268" cy="246" r="22" fill="#3B82F6"/>
        <circle cx="319" cy="280" r="23" fill="#22C55E"/>
        <path d="M166 372l184-184" stroke="${palette.warm}" stroke-width="18" stroke-linecap="round"/>
        <path d="M334 174l35-35" stroke="${palette.accent}" stroke-width="14" stroke-linecap="round"/>
        <circle cx="353" cy="333" r="19" fill="${palette.bg1}"/>`;
    case "home_style":
      return `
        <path d="M126 342h261" ${stroke}/>
        <rect x="163" y="210" width="145" height="104" rx="15" fill="${palette.main}" ${glow}/>
        <rect x="319" y="178" width="48" height="136" rx="10" fill="${palette.accent}" opacity=".9"/>
        <path d="M187 210v-55h97v55M205 155v-27h61v27" ${thin}/>
        <circle cx="357" cy="166" r="22" fill="${palette.warm}" opacity=".75"/>`;
    case "knowledge_science":
      return `
        <path d="M208 138h116M240 138v83l-62 121c-16 31 7 67 42 67h93c35 0 58-36 42-67l-63-121v-83" fill="#0B2532" stroke="${palette.main}" stroke-width="7" ${glow}/>
        <path d="M205 314h124" stroke="${palette.accent}" stroke-width="9"/>
        <circle cx="247" cy="286" r="14" fill="${palette.accent}"/>
        <circle cx="294" cy="335" r="18" fill="${palette.warm}"/>
        <circle cx="267" cy="371" r="11" fill="${palette.main}"/>`;
    case "faith_values":
      return `
        <path d="M160 365c56-53 158-53 215 0" fill="none" ${stroke}/>
        <path d="M176 343V187c57 34 122 34 179 0v156" fill="#123525" stroke="${palette.main}" stroke-width="7" ${glow}/>
        <path d="M211 224h109M211 263h109M211 302h78" ${thin}/>
        <circle cx="368" cy="153" r="42" fill="${palette.accent}" opacity=".55"/>
        <circle cx="383" cy="145" r="42" fill="${palette.bg2}"/>`;
    case "world_history_news":
      return `
        <rect x="146" y="159" width="230" height="210" rx="12" fill="#6B4B2F" ${glow}/>
        <rect x="167" y="180" width="188" height="168" rx="8" fill="#E7D4AD"/>
        <path d="M192 222h133M192 255h109M192 288h127" stroke="#7C5C35" stroke-width="7" stroke-linecap="round"/>
        <path d="M150 143l216 21" stroke="${palette.accent}" stroke-width="12" stroke-linecap="round"/>
        <circle cx="341" cy="330" r="32" fill="${palette.main}" opacity=".8"/>`;
    case "entertainment_humor":
      return `
        <rect x="133" y="169" width="245" height="168" rx="28" fill="#12111A" stroke="${palette.main}" stroke-width="7" ${glow}/>
        <path d="M204 169l-34-52M278 169l-25-58M346 169l-32-52" ${thin}/>
        <circle cx="203" cy="253" r="18" fill="${palette.accent}"/>
        <circle cx="306" cy="253" r="18" fill="${palette.accent}"/>
        <path d="M215 299c31 23 77 23 108 0" ${stroke}/>
        <path d="M163 371h184" stroke="${palette.warm}" stroke-width="11" stroke-linecap="round" opacity=".8"/>`;
    case "sports":
      return `
        <circle cx="257" cy="262" r="105" fill="#F8FAFC" stroke="${palette.main}" stroke-width="8" ${glow}/>
        <path d="M257 157c-13 43-13 166 0 210M164 226c53-22 132-22 185 0M164 300c53 22 132 22 185 0" stroke="#111827" stroke-width="8" fill="none"/>
        <path d="M125 391h267" stroke="${palette.accent}" stroke-width="15" stroke-linecap="round" opacity=".8"/>`;
    case "food_cafe":
      return `
        <ellipse cx="258" cy="339" rx="132" ry="40" fill="#F8E8C8" opacity=".9"/>
        <path d="M185 221h136v76c0 42-31 71-68 71s-68-29-68-71v-76Z" fill="${palette.main}" ${glow}/>
        <path d="M322 239h26c24 0 39 18 35 42-4 22-23 34-52 29" fill="none" stroke="${palette.main}" stroke-width="17"/>
        <path d="M217 190c-8-22 13-28 4-51M263 190c-8-22 13-28 4-51M303 190c-8-22 13-28 4-51" ${thin}/>
        <circle cx="176" cy="344" r="18" fill="${palette.accent}"/>`;
    case "music":
      return `
        <path d="M190 349c43-93 83-153 121-180 22 39 31 97 29 173" fill="#17112B" stroke="${palette.main}" stroke-width="8" ${glow}/>
        <circle cx="250" cy="307" r="38" fill="${palette.accent}"/>
        <circle cx="250" cy="307" r="16" fill="${palette.bg1}"/>
        <path d="M296 183l79-48M314 214l78-48M320 252l68-41" ${thin}/>
        <path d="M179 382h175" ${stroke} opacity=".75"/>`;
    case "travel_nature":
      return `
        <rect x="144" y="164" width="224" height="184" rx="14" fill="#E6D6A8" ${glow}/>
        <path d="M181 192c40 34 74 34 112 0s54-27 75 0M181 252c38-31 73-31 111 0s56 30 76 0M203 315l38-87 51 56 38-78" stroke="#49633B" stroke-width="8" fill="none" stroke-linecap="round"/>
        <circle cx="354" cy="347" r="46" fill="#0F172A" stroke="${palette.accent}" stroke-width="8"/>
        <path d="M354 317l13 34-38 14 25-48Z" fill="${palette.warm}"/>`;
    case "motivation_life":
      return `
        <circle cx="256" cy="242" r="100" fill="${palette.warm}" opacity=".25" ${glow}/>
        <path d="M256 142v199M178 225l78-83 78 83M171 341h170" ${stroke}/>
        <circle cx="372" cy="158" r="36" fill="${palette.accent}" opacity=".75"/>
        <path d="M144 389h223" stroke="${palette.main}" stroke-width="13" stroke-linecap="round"/>`;
    case "craft_work":
      return `
        <path d="M163 343l149-149" ${stroke}/>
        <rect x="296" y="149" width="55" height="140" rx="18" fill="${palette.main}" transform="rotate(45 323 219)" ${glow}/>
        <path d="M173 193l146 146" stroke="${palette.accent}" stroke-width="15" stroke-linecap="round"/>
        <circle cx="182" cy="189" r="27" fill="#0F172A" stroke="${palette.warm}" stroke-width="8"/>
        <path d="M143 390h221" stroke="${palette.main}" stroke-width="12" stroke-linecap="round" opacity=".8"/>`;
    case "health_people":
      return `
        <rect x="157" y="165" width="198" height="206" rx="28" fill="#ECFEFF" ${glow}/>
        <path d="M256 210v108M202 264h108" stroke="${palette.bg2}" stroke-width="24" stroke-linecap="round"/>
        <path d="M180 397h154" ${stroke}/>
        <circle cx="354" cy="166" r="34" fill="${palette.accent}" opacity=".55"/>`;
    default:
      return `
        <rect x="151" y="163" width="214" height="197" rx="20" fill="${palette.main}" opacity=".85" ${glow}/>
        <path d="M187 213h142M187 257h104M187 301h131" stroke="${palette.bg1}" stroke-width="10" stroke-linecap="round"/>
        <circle cx="353" cy="355" r="42" fill="${palette.accent}" opacity=".78"/>`;
  }
}

function avatarSvg(record, index, userTopics) {
  const doc = record.usersDoc || {};
  const topic = userTopics.get(record.uid)?.topic || "general_culture";
  const palette = TOPIC_PALETTES[topic] || TOPIC_PALETTES.general_culture;
  const seed = hashNumber(`${record.uid}:${index}:${AVATAR_VERSION}`);
  const title = `${doc.nickname || record.uid} ${topic}`;
  const mono = initials(record);
  const style = seed % 9;
  const bgA = hsl(seed, 0, 76, 30 + (seed % 14));
  const bgB = hsl(seed, 91, 72, 42 + ((seed >> 4) % 17));
  const bgC = hsl(seed, 211, 80, 52 + ((seed >> 8) % 12));
  const skin = pick(["#F5C7A9", "#E8A87C", "#D19163", "#B87550", "#8D563F", "#F1BFA5"], seed, 3);
  const hair = pick(["#1F1613", "#3A2418", "#5B3422", "#70472E", "#111827", "#2D1B48", "#6B3F24"], seed, 7);
  const shirt = hsl(seed, 151, 70, 42);
  const shirt2 = hsl(seed, 248, 70, 58);
  const object = drawTopicObject(topic, palette, seed);
  const badge = `<circle cx="386" cy="382" r="53" fill="#111827" opacity=".84" filter="url(#softShadow)"/><g transform="translate(350 346)">${topicGlyph(topic, palette)}</g>`;
  const monogram = `<circle cx="138" cy="380" r="45" fill="#0F172A" opacity=".78"/><text x="138" y="397" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="${mono.length > 1 ? 34 : 42}" font-weight="800" fill="#FFFFFF">${xml(mono)}</text>`;
  const portrait = (() => {
    const hairStyle = seed % 6;
    const face = pick(
      [
        `<path d="M171 223c0-67 37-111 88-111s88 44 88 111c0 77-42 130-88 130s-88-53-88-130Z" fill="${skin}"/>`,
        `<rect x="172" y="126" width="174" height="224" rx="82" fill="${skin}"/>`,
        `<path d="M166 232c0-70 42-116 93-116s93 46 93 116c0 68-47 119-93 119s-93-51-93-119Z" fill="${skin}"/>`,
      ],
      seed,
      13,
    );
    const hairs = [
      `<path d="M160 214c9-78 48-120 103-120 54 0 91 38 98 112-55-29-102-36-201 8Z" fill="${hair}"/>`,
      `<path d="M156 222c-5-78 41-131 104-131 75 0 112 54 96 132-45-48-98-57-200-1Z" fill="${hair}"/>`,
      `<path d="M163 199c14-70 57-103 111-98 47 5 78 40 87 92-62-23-112-25-198 6Z" fill="${hair}"/><path d="M175 201c-24 30-29 73-17 110" stroke="${hair}" stroke-width="22" stroke-linecap="round"/>`,
      `<path d="M150 228c2-83 49-136 111-136s100 49 104 130c-71-54-135-55-215 6Z" fill="${hair}"/><path d="M351 221c20 32 22 70 10 105" stroke="${hair}" stroke-width="21" stroke-linecap="round"/>`,
      `<path d="M169 183c24-66 86-91 139-65 31 15 49 46 52 89-62-35-123-43-191-24Z" fill="${hair}"/>`,
      `<path d="M154 211c13-84 66-125 128-113 47 9 79 51 78 111-72-42-132-44-206 2Z" fill="${hair}"/><circle cx="184" cy="160" r="28" fill="${hair}"/>`,
    ];
    return `<path d="M121 460c15-81 70-130 138-130s123 49 138 130H121Z" fill="${shirt}" filter="url(#softShadow)"/><path d="M183 460c14-52 42-83 76-83s62 31 76 83H183Z" fill="${shirt2}" opacity=".7"/>${face}${hairs[hairStyle]}<path d="M202 258c14-11 30-11 44 0M273 258c14-11 30-11 44 0" stroke="#111827" stroke-width="9" stroke-linecap="round"/><path d="M258 265c-9 19-9 38 9 45" stroke="#9A5C43" stroke-width="7" stroke-linecap="round" opacity=".55"/><path d="M218 322c27 20 56 20 83 0" stroke="#7C3F32" stroke-width="8" stroke-linecap="round" opacity=".65"/>`;
  })();
  const bodies = [
    `${portrait}${badge}${monogram}`,
    `<rect x="88" y="102" width="336" height="300" rx="${30 + (seed % 44)}" fill="#FFFFFF" opacity=".12" filter="url(#softShadow)"/><text x="256" y="302" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="${mono.length > 1 ? 142 : 168}" font-weight="900" fill="#FFFFFF">${xml(mono)}</text><path d="M112 372h288" stroke="${palette.accent}" stroke-width="18" stroke-linecap="round"/>${badge}`,
    `<g transform="translate(${(seed % 38) - 10} ${(seed % 26) - 5}) scale(.92)">${object}</g><text x="84" y="112" font-family="Arial, Helvetica, sans-serif" font-size="48" font-weight="900" fill="#FFFFFF" opacity=".88">${xml(mono)}</text>`,
    `<circle cx="256" cy="244" r="150" fill="#FFFFFF" opacity=".16"/><path d="M116 356c52-104 100-166 144-185 44 19 92 81 144 185-93 47-195 47-288 0Z" fill="${hsl(seed, 35, 78, 57)}" filter="url(#softShadow)"/><circle cx="256" cy="220" r="67" fill="${hsl(seed, 197, 74, 44)}"/><text x="256" y="243" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="66" font-weight="900" fill="#FFFFFF">${xml(mono.slice(0, 1))}</text>${badge}`,
    `<path d="M104 137h304v238H104Z" fill="${hsl(seed, 20, 80, 58)}" transform="rotate(${(seed % 18) - 9} 256 256)" filter="url(#softShadow)"/><path d="M134 174h244M134 234h178M134 294h222" stroke="#111827" stroke-width="18" stroke-linecap="round" opacity=".55"/><text x="374" y="354" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="70" font-weight="900" fill="#FFFFFF">${xml(mono)}</text>`,
    `<g opacity=".95">${Array.from({ length: 8 }, (_, i) => `<circle cx="${90 + ((seed >> i) % 330)}" cy="${90 + ((seed >> (i + 3)) % 330)}" r="${28 + ((seed >> (i + 7)) % 42)}" fill="${hsl(seed, i * 47, 80, 52)}" opacity=".72"/>`).join("")}</g><rect x="162" y="162" width="188" height="188" rx="${32 + (seed % 58)}" fill="#111827" opacity=".82" filter="url(#softShadow)"/><text x="256" y="291" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="${mono.length > 1 ? 82 : 104}" font-weight="900" fill="#FFFFFF">${xml(mono)}</text>`,
    `<path d="M92 415c34-128 91-222 170-282 77 60 130 154 158 282H92Z" fill="${hsl(seed, 270, 74, 45)}" filter="url(#softShadow)"/><path d="M151 376c47-84 84-143 111-177 28 35 65 94 111 177H151Z" fill="${hsl(seed, 35, 78, 60)}"/><circle cx="262" cy="187" r="48" fill="${palette.accent}"/><text x="256" y="452" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="44" font-weight="900" fill="#FFFFFF">${xml(mono)}</text>`,
    `<rect x="112" y="96" width="288" height="320" rx="144" fill="${skin}" filter="url(#softShadow)"/><path d="M114 213c20-94 74-142 152-142 70 0 119 47 134 142-99-45-189-45-286 0Z" fill="${hair}"/><path d="M190 259h38M284 259h38" stroke="#111827" stroke-width="13" stroke-linecap="round"/><path d="M208 334c31 21 68 21 99 0" stroke="#7C3F32" stroke-width="10" stroke-linecap="round"/><path d="M120 446h272" stroke="${shirt}" stroke-width="48" stroke-linecap="round"/>`,
    `<g transform="translate(54 54) scale(.78)">${portrait}</g><rect x="304" y="74" width="118" height="118" rx="30" fill="#FFFFFF" opacity=".18"/><text x="363" y="153" text-anchor="middle" font-family="Arial, Helvetica, sans-serif" font-size="58" font-weight="900" fill="#FFFFFF">${xml(mono)}</text><path d="M304 406h118" stroke="${palette.accent}" stroke-width="20" stroke-linecap="round"/>`,
  ];

  return `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512" role="img" aria-label="${xml(title)}">
  <defs>
    <linearGradient id="bg" x1="62" y1="48" x2="454" y2="464" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="${bgA}"/>
      <stop offset=".55" stop-color="${bgB}"/>
      <stop offset="1" stop-color="${bgC}"/>
    </linearGradient>
    <filter id="softShadow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="18" stdDeviation="18" flood-color="#000000" flood-opacity=".34"/>
    </filter>
    <filter id="grain">
      <feTurbulence type="fractalNoise" baseFrequency=".85" numOctaves="3" stitchTiles="stitch"/>
      <feColorMatrix type="saturate" values="0"/>
      <feComponentTransfer>
        <feFuncA type="table" tableValues="0 .16"/>
      </feComponentTransfer>
    </filter>
  </defs>
  <rect width="512" height="512" rx="${64 + (seed % 58)}" fill="url(#bg)"/>
  <circle cx="${80 + (seed % 95)}" cy="${82 + ((seed >> 3) % 78)}" r="${58 + ((seed >> 5) % 52)}" fill="#FFFFFF" opacity=".13"/>
  <circle cx="${338 + ((seed >> 4) % 80)}" cy="${312 + ((seed >> 6) % 78)}" r="${78 + ((seed >> 9) % 42)}" fill="#000000" opacity=".11"/>
  <path d="M54 ${390 + (seed % 32)}C150 ${306 + (seed % 42)} 285 ${319 + ((seed >> 4) % 38)} 458 ${272 + ((seed >> 8) % 70)}" fill="none" stroke="#FFFFFF" stroke-width="${3 + (seed % 5)}" opacity=".18"/>
  ${bodies[style]}
  <rect width="512" height="512" rx="${64 + (seed % 58)}" filter="url(#grain)" opacity=".22"/>
  <rect x="1.5" y="1.5" width="509" height="509" rx="${64 + (seed % 58)}" fill="none" stroke="#FFFFFF" stroke-opacity=".16" stroke-width="3"/>
</svg>`;
}

function initializeAdmin(serviceAccountPath) {
  if (admin.apps.length > 0) return;
  if (fs.existsSync(serviceAccountPath)) {
    admin.initializeApp({
      credential: admin.credential.cert(require(serviceAccountPath)),
      projectId: PROJECT_ID,
      storageBucket: STORAGE_BUCKET,
    });
    return;
  }
  admin.initializeApp({ projectId: PROJECT_ID, storageBucket: STORAGE_BUCKET });
}

async function writeAvatarFiles(record, index, outDir, userTopics) {
  const uid = record.uid;
  const svg = avatarSvg(record, index, userTopics);
  const svgPath = path.join(outDir, `${uid}.svg`);
  const webpPath = path.join(outDir, `${uid}.webp`);
  const thumbPath = path.join(outDir, `${uid}_thumb_150.webp`);
  fs.writeFileSync(svgPath, svg);
  await sharp(Buffer.from(svg)).resize(512, 512).webp({ quality: 88 }).toFile(webpPath);
  await sharp(Buffer.from(svg)).resize(150, 150).webp({ quality: 86 }).toFile(thumbPath);
  return { svgPath, webpPath, thumbPath };
}

async function uploadAvatar({ bucket, record, files }) {
  const uid = record.uid;
  const fullPath = `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}.webp`;
  const thumbPath = `users/${uid}/${uid}_curated_avatar_${AVATAR_VERSION}_thumb_150.webp`;
  await bucket.upload(files.webpPath, {
    destination: fullPath,
    metadata: {
      contentType: "image/webp",
      cacheControl: "public, max-age=31536000",
      metadata: {
        curatedAvatar: "true",
        avatarKind: "distinct_illustrated_profile",
        avatarVersion: AVATAR_VERSION,
        size: "512",
      },
    },
  });
  await bucket.upload(files.thumbPath, {
    destination: thumbPath,
    metadata: {
      contentType: "image/webp",
      cacheControl: "public, max-age=31536000",
      metadata: {
        curatedAvatar: "true",
        avatarKind: "distinct_illustrated_profile",
        avatarVersion: AVATAR_VERSION,
        size: "150",
      },
    },
  });
  return {
    fullStoragePath: fullPath,
    thumbStoragePath: thumbPath,
    fullUrl: `https://cdn.turqapp.com/${fullPath}`,
    avatarUrl: `https://cdn.turqapp.com/${thumbPath}`,
  };
}

function patchRecord(record, avatar) {
  for (const key of ["usersDoc", "usersPublicDoc"]) {
    record[key] = {
      ...(record[key] || {}),
      avatarUrl: avatar.avatarUrl,
      authorAvatarUrl: avatar.avatarUrl,
      avatarFullUrl: avatar.fullUrl,
      avatarType: "curated_distinct_illustration",
      avatarVersion: AVATAR_VERSION,
      avatarAsset: "",
      authorAvatarAsset: "",
      curatedAvatarStoragePath: avatar.thumbStoragePath,
      curatedAvatarFullStoragePath: avatar.fullStoragePath,
      updatedDate: Date.now(),
    };
  }
  return record;
}

async function updateFirestore(db, record, avatar) {
  const patch = {
    avatarUrl: avatar.avatarUrl,
    authorAvatarUrl: avatar.avatarUrl,
    avatarFullUrl: avatar.fullUrl,
    avatarType: "curated_distinct_illustration",
    avatarVersion: AVATAR_VERSION,
    avatarAsset: "",
    authorAvatarAsset: "",
    curatedAvatarStoragePath: avatar.thumbStoragePath,
    curatedAvatarFullStoragePath: avatar.fullStoragePath,
    updatedDate: Date.now(),
  };
  await Promise.all([
    db.collection("users").doc(record.uid).set(patch, { merge: true }),
    db.collection("usersPublic").doc(record.uid).set(patch, { merge: true }),
  ]);
}

async function run() {
  const options = parseArgs(process.argv);
  const inputJson = JSON.parse(fs.readFileSync(options.input, "utf8"));
  const records = (inputJson.records || []).slice(0, options.limit > 0 ? options.limit : undefined);
  const userTopics = loadUserTopics(options.mapping);
  ensureDir(options.outDir);
  ensureDir(path.dirname(options.manifest));

  let bucket = null;
  let db = null;
  if (options.apply) {
    initializeAdmin(options.serviceAccount);
    bucket = admin.storage().bucket();
    db = admin.firestore();
  }

  const manifest = {
    generatedAt: new Date().toISOString(),
    mode: options.apply ? "apply" : "dry-run",
    input: options.input,
    outDir: options.outDir,
    recordCount: records.length,
    topicCounts: {},
    items: [],
  };

  for (let index = 0; index < records.length; index += 1) {
    const record = records[index];
    const topic = userTopics.get(record.uid)?.topic || "general_culture";
    manifest.topicCounts[topic] = (manifest.topicCounts[topic] || 0) + 1;
    const files = await writeAvatarFiles(record, index, options.outDir, userTopics);
    const avatar = options.apply
      ? await uploadAvatar({ bucket, record, files })
      : {
          fullStoragePath: `users/${record.uid}/${record.uid}_curated_avatar_${AVATAR_VERSION}.webp`,
          thumbStoragePath: `users/${record.uid}/${record.uid}_curated_avatar_${AVATAR_VERSION}_thumb_150.webp`,
          fullUrl: `https://cdn.turqapp.com/users/${record.uid}/${record.uid}_curated_avatar_${AVATAR_VERSION}.webp`,
          avatarUrl: `https://cdn.turqapp.com/users/${record.uid}/${record.uid}_curated_avatar_${AVATAR_VERSION}_thumb_150.webp`,
        };

    patchRecord(record, avatar);
    if (options.apply) {
      await updateFirestore(db, record, avatar);
    }

    manifest.items.push({
      uid: record.uid,
      nickname: record.usersDoc?.nickname || "",
      firstName: record.usersDoc?.firstName || "",
      topic,
      avatarUrl: avatar.avatarUrl,
      fullUrl: avatar.fullUrl,
      localSvg: files.svgPath,
      localWebp: files.webpPath,
      localThumb: files.thumbPath,
    });
  }

  const outputJson = {
    ...inputJson,
    metadata: {
      ...(inputJson.metadata || {}),
      avatarsUpdatedAt: new Date().toISOString(),
      avatarMode: "curated_illustration",
      avatarVersion: AVATAR_VERSION,
    },
    records,
  };
  if (options.apply) {
    fs.writeFileSync(options.input, JSON.stringify(outputJson, null, 2));
  }
  fs.writeFileSync(options.manifest, JSON.stringify(manifest, null, 2));
  console.log(JSON.stringify({
    ok: true,
    mode: manifest.mode,
    recordCount: manifest.recordCount,
    topicCounts: manifest.topicCounts,
    outDir: options.outDir,
    manifest: options.manifest,
    first: manifest.items[0],
    last: manifest.items[manifest.items.length - 1],
  }, null, 2));
}

run().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
