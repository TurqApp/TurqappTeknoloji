#!/usr/bin/env node
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const args = process.argv.slice(2);
const verifyOnly = readBoolArg('verify-only', false);

function readArg(name, fallback = '') {
  const prefix = `--${name}=`;
  const match = args.find((arg) => arg.startsWith(prefix));
  if (!match) return fallback;
  return match.slice(prefix.length).trim();
}

function readBoolArg(name, fallback) {
  const raw = readArg(name, '');
  if (!raw) return fallback;
  return raw.toLowerCase() == 'true';
}

function readIntArg(name, fallback) {
  const raw = readArg(name, '');
  const value = Number.parseInt(raw, 10);
  if (Number.isFinite(value) && value > 0) return value;
  return fallback;
}

const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
if (!serviceAccountPath) {
  throw new Error('GOOGLE_APPLICATION_CREDENTIALS missing');
}

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}

const payload = {
  androidMinVersion: readArg('android-min', '1.1.4'),
  iosMinVersion: readArg('ios-min', '1.1.4'),
  updateTitle: readArg('update-title', 'Yeni Güncelleme Mevcut'),
  updateBody: readArg(
    'update-body',
    "TurqApp'in yeni versiyonu mevcut. Daha iyi performans ve yeni özellikler için lütfen uygulamanızı güncelleyin."
  ),
  androidStoreUrl: readArg(
    'android-store-url',
    'https://play.google.com/store/apps/details?id=com.turqapp.app'
  ),
  iosStoreUrl: readArg(
    'ios-store-url',
    'https://apps.apple.com/tr/app/turqapp/id6740809479?l=tr'
  ),
  ratingPromptEnabled: readBoolArg('rating-enabled', true),
  ratingPromptInitialDelayDays: readIntArg('rating-initial-days', 7),
  ratingPromptRepeatDays: readIntArg('rating-repeat-days', 7),
  ratingPromptStoreCooldownDays: readIntArg('rating-store-cooldown-days', 90),
  updatedAt: Date.now(),
};

function requireNonEmptyString(data, key) {
  const value = `${data?.[key] ?? ''}`.trim();
  if (!value) {
    throw new Error(`adminConfig/appVersion missing required field: ${key}`);
  }
  return value;
}

async function main() {
  const db = admin.firestore();
  if (verifyOnly) {
    const snapshot = await db.doc('adminConfig/appVersion').get();
    if (!snapshot.exists) {
      throw new Error('adminConfig/appVersion document is missing');
    }
    const data = snapshot.data() ?? {};
    const verifiedPayload = {
      androidMinVersion: requireNonEmptyString(data, 'androidMinVersion'),
      iosMinVersion: requireNonEmptyString(data, 'iosMinVersion'),
      androidStoreUrl: requireNonEmptyString(data, 'androidStoreUrl'),
      iosStoreUrl: requireNonEmptyString(data, 'iosStoreUrl'),
      updateTitle: requireNonEmptyString(data, 'updateTitle'),
      updateBody: requireNonEmptyString(data, 'updateBody'),
    };
    console.log('adminConfig/appVersion verified');
    console.log(JSON.stringify(verifiedPayload, null, 2));
    return;
  }
  await db.doc('adminConfig/appVersion').set(payload, { merge: true });
  console.log('adminConfig/appVersion updated');
  console.log(JSON.stringify(payload, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
