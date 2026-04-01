#!/usr/bin/env node
import crypto from 'crypto';
import fs from 'fs';

const defaultServiceAccountPath =
  '/Users/turqapp/Desktop/TurqApp/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json';

const payload = {
  ios: {
    kare: [
      'ca-app-pub-4558422035199571/8122867409',
      'ca-app-pub-4558422035199571/8962191459',
      'ca-app-pub-4558422035199571/3881293152',
      'ca-app-pub-4558422035199571/9209603468',
      'ca-app-pub-4558422035199571/9672675885',
    ],
    gecis: [
      'ca-app-pub-4558422035199571/5999655265',
      'ca-app-pub-4558422035199571/8523207750',
      'ca-app-pub-4558422035199571/2987562624',
      'ca-app-pub-4558422035199571/1674480958',
      'ca-app-pub-4558422035199571/3877385732',
    ],
  },
  android: {
    kare: [
      'ca-app-pub-4558422035199571/2790203845',
      'ca-app-pub-4558422035199571/9097922825',
      'ca-app-pub-4558422035199571/9648587166',
      'ca-app-pub-4558422035199571/2340942782',
      'ca-app-pub-4558422035199571/3689721460',
    ],
    gecis: [
      'ca-app-pub-4558422035199571/8183250889',
      'ca-app-pub-4558422035199571/6503549079',
      'ca-app-pub-4558422035199571/9552970979',
      'ca-app-pub-4558422035199571/8359594210',
      'ca-app-pub-4558422035199571/6926807632',
    ],
  },
};

const serviceAccountPath =
  process.env.GOOGLE_APPLICATION_CREDENTIALS || defaultServiceAccountPath;

if (!fs.existsSync(serviceAccountPath)) {
  throw new Error(`service account missing: ${serviceAccountPath}`);
}

const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));

function base64UrlEncode(value) {
  return Buffer.from(value)
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/g, '');
}

function buildJwtAssertion() {
  const now = Math.floor(Date.now() / 1000);
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  };
  const claimSet = {
    iss: serviceAccount.client_email,
    sub: serviceAccount.client_email,
    aud: serviceAccount.token_uri,
    scope: 'https://www.googleapis.com/auth/datastore',
    iat: now,
    exp: now + 3600,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedClaimSet = base64UrlEncode(JSON.stringify(claimSet));
  const unsignedToken = `${encodedHeader}.${encodedClaimSet}`;

  const signer = crypto.createSign('RSA-SHA256');
  signer.update(unsignedToken);
  signer.end();

  const signature = signer
      .sign(serviceAccount.private_key)
      .toString('base64')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/g, '');

  return `${unsignedToken}.${signature}`;
}

async function getAccessToken() {
  const response = await fetch(serviceAccount.token_uri, {
    method: 'POST',
    headers: {
      'content-type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: buildJwtAssertion(),
    }),
  });

  if (!response.ok) {
    throw new Error(`token request failed: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  const accessToken = String(data.access_token || '').trim();
  if (!accessToken) {
    throw new Error('access token missing');
  }
  return accessToken;
}

function toFirestoreArray(values) {
  return {
    arrayValue: {
      values: values.map((value) => ({
        stringValue: value,
      })),
    },
  };
}

function toFirestoreDocument() {
  return {
    fields: {
      ios: {
        mapValue: {
          fields: {
            kare: toFirestoreArray(payload.ios.kare),
            gecis: toFirestoreArray(payload.ios.gecis),
          },
        },
      },
      android: {
        mapValue: {
          fields: {
            kare: toFirestoreArray(payload.android.kare),
            gecis: toFirestoreArray(payload.android.gecis),
          },
        },
      },
    },
  };
}

function decodeStringArray(field) {
  const values = field?.arrayValue?.values;
  if (!Array.isArray(values)) return [];
  return values
      .map((item) => String(item?.stringValue || '').trim())
      .filter((item) => item.length > 0);
}

function decodeDocument(document) {
  const fields = document?.fields || {};
  const iosFields = fields.ios?.mapValue?.fields || {};
  const androidFields = fields.android?.mapValue?.fields || {};
  return {
    ios: {
      kare: decodeStringArray(iosFields.kare),
      gecis: decodeStringArray(iosFields.gecis),
    },
    android: {
      kare: decodeStringArray(androidFields.kare),
      gecis: decodeStringArray(androidFields.gecis),
    },
  };
}

async function writeConfig(accessToken) {
  const baseUrl =
    `https://firestore.googleapis.com/v1/projects/${serviceAccount.project_id}` +
    '/databases/(default)/documents/adminConfig/reklam';

  const writeResponse = await fetch(
    `${baseUrl}?updateMask.fieldPaths=ios&updateMask.fieldPaths=android`,
    {
      method: 'PATCH',
      headers: {
        authorization: `Bearer ${accessToken}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify(toFirestoreDocument()),
    },
  );

  if (!writeResponse.ok) {
    throw new Error(`firestore write failed: ${writeResponse.status} ${await writeResponse.text()}`);
  }

  const readResponse = await fetch(baseUrl, {
    headers: {
      authorization: `Bearer ${accessToken}`,
    },
  });

  if (!readResponse.ok) {
    throw new Error(`firestore read failed: ${readResponse.status} ${await readResponse.text()}`);
  }

  const document = await readResponse.json();
  console.log(
    JSON.stringify(
      {
        path: 'adminConfig/reklam',
        projectId: serviceAccount.project_id,
        data: decodeDocument(document),
      },
      null,
      2,
    ),
  );
}

const accessToken = await getAccessToken();
await writeConfig(accessToken);
