#!/usr/bin/env node
import fs from 'fs';
import fsp from 'fs/promises';
import os from 'os';
import path from 'path';
import { execFile } from 'child_process';
import { promisify } from 'util';
import { randomUUID } from 'crypto';

const execFileAsync = promisify(execFile);

const PROJECT_ID = 'turqappteknoloji';
const BUCKET = 'turqappteknoloji.firebasestorage.app';
const FIRESTORE_BASE =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const FOLDER = '/Users/turqapp/Desktop/adsız klasör';
const START_TRACK_NUMBER = 61;
const PLACEHOLDER_COVER =
  '/Users/turqapp/Desktop/TurqApp/ios/Runner/Assets.xcassets/AppIcon.appiconset/1024.png';
const TMP_ROOT = path.join(os.tmpdir(), `story-music-upload-${Date.now()}`);
const FIREBASE_TOOLS_CONFIG = path.join(
  os.homedir(),
  '.config/configstore/firebase-tools.json',
);
const ALLOWED_EXTENSIONS = new Set(['.mp3', '.m4a']);
const args = new Set(process.argv.slice(2));
const isDryRun = args.has('--dry-run');

function padTrackNumber(n) {
  return String(n).padStart(3, '0');
}

function trackIdFromIndex(n) {
  return `track_${padTrackNumber(n)}`;
}

function normalizeText(value) {
  return String(value ?? '')
    .normalize('NFC')
    .replace(/\s+/g, ' ')
    .trim();
}

function stripExtension(fileName) {
  return fileName.replace(/\.[^.]+$/, '');
}

function inferMetadataFromFilename(fileName) {
  const base = normalizeText(stripExtension(fileName).replace(/[_]+/g, ' '));
  if (!base) {
    return { title: '', artist: '' };
  }
  const delimiter = base.includes(' - ') ? ' - ' : null;
  if (delimiter) {
    const [artist, ...rest] = base.split(delimiter);
    const title = rest.join(delimiter).trim();
    if (title) {
      return {
        title: normalizeText(title),
        artist: normalizeText(artist),
      };
    }
  }
  return { title: base, artist: '' };
}

function contentTypeForFile(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (ext === '.m4a') return 'audio/mp4';
  return 'audio/mpeg';
}

function integerField(value) {
  return { integerValue: String(Math.max(0, Math.round(value))) };
}

function stringField(value) {
  return { stringValue: normalizeText(value) };
}

function booleanField(value) {
  return { booleanValue: Boolean(value) };
}

function makeFirestoreFields(track) {
  return {
    title: stringField(track.title),
    artist: stringField(track.artist),
    audioUrl: stringField(track.audioUrl),
    coverUrl: stringField(track.coverUrl),
    durationMs: integerField(track.durationMs),
    useCount: integerField(0),
    shareCount: integerField(0),
    storyCount: integerField(0),
    order: integerField(track.order),
    lastUsedAt: integerField(0),
    createdAt: integerField(track.createdAt),
    updatedAt: integerField(track.updatedAt),
    isActive: booleanField(true),
    category: stringField(''),
  };
}

function encodeStorageObjectPath(storagePath) {
  return encodeURIComponent(storagePath).replace(/%2F/g, '%2F');
}

async function ensureTempRoot() {
  await fsp.mkdir(TMP_ROOT, { recursive: true });
}

function loadFirebaseToolsConfig() {
  return JSON.parse(fs.readFileSync(FIREBASE_TOOLS_CONFIG, 'utf8'));
}

class TokenProvider {
  constructor() {
    this.config = loadFirebaseToolsConfig();
  }

  getAccessToken() {
    const token = this.config?.tokens?.access_token;
    if (!token) {
      throw new Error('firebase-tools access token bulunamadı.');
    }
    return token;
  }
}

async function authorizedFetch(url, options = {}, tokenProvider) {
  const token = tokenProvider.getAccessToken();
  const headers = new Headers(options.headers || {});
  headers.set('Authorization', `Bearer ${token}`);
  const res = await fetch(url, { ...options, headers });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`${options.method || 'GET'} ${url} -> ${res.status} ${text}`);
  }
  return res;
}

async function listAudioFiles(folderPath) {
  const entries = await fsp.readdir(folderPath, { withFileTypes: true });
  return entries
    .filter((entry) => entry.isFile())
    .map((entry) => entry.name)
    .filter((name) => ALLOWED_EXTENSIONS.has(path.extname(name).toLowerCase()))
    .sort((a, b) => a.localeCompare(b, 'tr', { numeric: true, sensitivity: 'base' }))
    .map((name) => path.join(folderPath, name));
}

async function ffprobeJson(filePath) {
  const { stdout } = await execFileAsync('/opt/homebrew/bin/ffprobe', [
    '-v',
    'error',
    '-show_entries',
    'format=duration:format_tags=title,artist',
    '-show_entries',
    'stream=index,codec_type:stream_tags=comment',
    '-of',
    'json',
    filePath,
  ]);
  return JSON.parse(stdout);
}

async function extractCoverJpeg(inputPath, outputPath) {
  await execFileAsync('/opt/homebrew/bin/ffmpeg', [
    '-y',
    '-i',
    inputPath,
    '-an',
    '-vf',
    'scale=1024:1024:force_original_aspect_ratio=decrease,pad=1024:1024:(ow-iw)/2:(oh-ih)/2:black',
    '-frames:v',
    '1',
    '-q:v',
    '2',
    outputPath,
  ]);
}

async function buildCoverFile(sourceAudioPath, trackId, hasEmbeddedCover) {
  const outputPath = path.join(TMP_ROOT, `${trackId}-cover.jpg`);
  if (hasEmbeddedCover) {
    await extractCoverJpeg(sourceAudioPath, outputPath);
    return outputPath;
  }
  await extractCoverJpeg(PLACEHOLDER_COVER, outputPath);
  return outputPath;
}

async function buildTrackPayload(filePath, order, docId) {
  const fileName = path.basename(filePath);
  const probe = await ffprobeJson(filePath);
  const tags = probe.format?.tags || {};
  const inferred = inferMetadataFromFilename(fileName);
  const title = normalizeText(tags.title) || inferred.title;
  const artist = normalizeText(tags.artist) || inferred.artist;
  const durationSeconds = Number(probe.format?.duration || 0);
  const durationMs = Number.isFinite(durationSeconds)
    ? Math.round(durationSeconds * 1000)
    : 0;
  const hasEmbeddedCover = (probe.streams || []).some(
    (stream) => stream.codec_type === 'video',
  );
  const coverFilePath = await buildCoverFile(filePath, docId, hasEmbeddedCover);

  return {
    docId,
    filePath,
    fileName,
    title,
    artist,
    durationMs,
    hasEmbeddedCover,
    coverFilePath,
    order,
  };
}

async function uploadMultipartObject({
  storagePath,
  contentType,
  bytes,
  tokenProvider,
  cacheControl = 'public, max-age=31536000, immutable',
}) {
  const downloadToken = randomUUID();
  const boundary = `----codex-${randomUUID()}`;
  const metadata = {
    name: storagePath,
    contentType,
    cacheControl,
    metadata: {
      firebaseStorageDownloadTokens: downloadToken,
    },
  };
  const preamble =
    `--${boundary}\r\n` +
    'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
    `${JSON.stringify(metadata)}\r\n` +
    `--${boundary}\r\n` +
    `Content-Type: ${contentType}\r\n\r\n`;
  const closing = `\r\n--${boundary}--`;
  const body = Buffer.concat([
    Buffer.from(preamble, 'utf8'),
    bytes,
    Buffer.from(closing, 'utf8'),
  ]);

  await authorizedFetch(
    `https://storage.googleapis.com/upload/storage/v1/b/${BUCKET}/o?uploadType=multipart`,
    {
      method: 'POST',
      headers: {
        'Content-Type': `multipart/related; boundary=${boundary}`,
      },
      body,
    },
    tokenProvider,
  );

  return `https://firebasestorage.googleapis.com/v0/b/${BUCKET}/o/${encodeStorageObjectPath(
    storagePath,
  )}?alt=media&token=${downloadToken}`;
}

async function saveFirestoreTrack(track, tokenProvider) {
  const url = `${FIRESTORE_BASE}/storyMusic/${track.docId}`;
  await authorizedFetch(
    url,
    {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        fields: makeFirestoreFields(track),
      }),
    },
    tokenProvider,
  );
}

async function fetchExistingDocument(docId, tokenProvider) {
  const url = `${FIRESTORE_BASE}/storyMusic/${docId}`;
  const token = tokenProvider.getAccessToken();
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (res.status === 404) return null;
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`GET ${url} -> ${res.status} ${text}`);
  }
  return res.json();
}

async function main() {
  await ensureTempRoot();
  const tokenProvider = new TokenProvider();
  const files = await listAudioFiles(FOLDER);
  if (files.length === 0) {
    throw new Error('Yüklenecek audio dosyası bulunamadı.');
  }

  const existing060 = await fetchExistingDocument('track_060', tokenProvider);
  if (!existing060) {
    throw new Error('track_060 bulunamadı. Başlangıç noktası doğrulanamadı.');
  }

  let nextOrder = START_TRACK_NUMBER;
  let uploaded = 0;

  for (const filePath of files) {
    const docId = trackIdFromIndex(nextOrder);
    const payload = await buildTrackPayload(filePath, nextOrder, docId);

    console.log(
      `[${docId}] ${payload.title}${payload.artist ? ` • ${payload.artist}` : ''} ` +
        `(cover=${payload.hasEmbeddedCover ? 'embedded' : 'fallback'})`,
    );

    if (!isDryRun) {
      const audioStoragePath = `storyMusic/${docId}/audio${path
        .extname(filePath)
        .toLowerCase()}`;
      const coverStoragePath = `storyMusic/${docId}/cover.jpg`;

      const [audioBytes, coverBytes] = await Promise.all([
        fsp.readFile(filePath),
        fsp.readFile(payload.coverFilePath),
      ]);

      const audioUrl = await uploadMultipartObject({
        storagePath: audioStoragePath,
        contentType: contentTypeForFile(filePath),
        bytes: audioBytes,
        tokenProvider,
      });

      const coverUrl = await uploadMultipartObject({
        storagePath: coverStoragePath,
        contentType: 'image/jpeg',
        bytes: coverBytes,
        tokenProvider,
      });

      await saveFirestoreTrack(
        {
          ...payload,
          audioUrl,
          coverUrl,
          createdAt: Date.now(),
          updatedAt: Date.now(),
        },
        tokenProvider,
      );
    }

    uploaded += 1;
    nextOrder += 1;
  }

  console.log(
    isDryRun
      ? `Dry run tamamlandı. ${uploaded} parça işlendi. Başlangıç: track_${padTrackNumber(
          START_TRACK_NUMBER,
        )}`
      : `Yükleme tamamlandı. ${uploaded} parça yüklendi. Son ID: ${trackIdFromIndex(
          nextOrder - 1,
        )}`,
  );
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
