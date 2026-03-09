import { test } from "node:test";
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const sourcePath = path.resolve(__dirname, "../src/index.ts");
const source = fs.readFileSync(sourcePath, "utf8");

test("worker source contains route parser for all short link kinds", () => {
  assert.match(source, /\/\(p\|s\|u\|e\|i\)\//);
  assert.match(source, /type LinkType = "p" \| "s" \| "u" \| "e" \| "i"/);
});

test("worker source contains OG and well-known handlers", () => {
  assert.match(source, /\/og-image/);
  assert.match(source, /\/\.well-known\/apple-app-site-association/);
  assert.match(source, /\/\.well-known\/assetlinks\.json/);
});

test("worker source keeps bot fallback detection", () => {
  assert.match(source, /function isBot\(ua: string\)/);
  assert.match(source, /"whatsapp"/);
  assert.match(source, /"telegram"/);
});
