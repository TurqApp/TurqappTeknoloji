#!/usr/bin/env node
import fs from 'fs';
import path from 'path';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const admin = require('../functions/node_modules/firebase-admin');

const args = process.argv.slice(2);

function hasFlag(flag) {
  return args.includes(`--${flag}`);
}

function readArg(name, fallback = '') {
  const prefix = `--${name}=`;
  const match = args.find((arg) => arg.startsWith(prefix));
  if (!match) return fallback;
  return match.slice(prefix.length).trim();
}

function readIntArg(name, fallback) {
  const raw = readArg(name, '');
  const parsed = Number.parseInt(raw, 10);
  return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
}

function printUsage() {
  console.log(`Usage:
  node scripts/fetch_latest_qa_remote_report.mjs [options]

Options:
  --collection=qa              Remote collection name. Default: qa
  --scope=live                 Remote scope doc. Default: live
  --project-id=<id>            Firebase project id override
  --service-account=<path>     Service account JSON path override
  --session-id=<id>            Fetch a specific session instead of lastSessionId
  --occurrence-limit=<n>       Max occurrence count to include. Default: 50
  --out=<path>                 Output file path. Default: artifacts/qa_lab/qa_remote_<scope>_<sessionId>.json
  --stdout                     Print fetched JSON to stdout
  --session-only               Skip collectionGroup occurrence fetch
  --compact                    Compact JSON output
  --help                       Show this help

Examples:
  node scripts/fetch_latest_qa_remote_report.mjs
  node scripts/fetch_latest_qa_remote_report.mjs --session-id=1774652072508
  node scripts/fetch_latest_qa_remote_report.mjs --project-id=turqappteknoloji --service-account=/abs/key.json
  node scripts/fetch_latest_qa_remote_report.mjs --scope=staging --stdout
`);
}

function sanitize(value) {
  if (
    value == null ||
    typeof value === 'string' ||
    typeof value === 'number' ||
    typeof value === 'boolean'
  ) {
    return value;
  }
  if (value instanceof Date) return value.toISOString();
  if (typeof value.toDate === 'function') {
    return value.toDate().toISOString();
  }
  if (typeof value.path === 'string' && typeof value.id === 'string') {
    return { id: value.id, path: value.path };
  }
  if (Array.isArray(value)) {
    return value.map((item) => sanitize(item));
  }
  if (typeof value === 'object') {
    return Object.fromEntries(
      Object.entries(value).map(([key, nested]) => [key, sanitize(nested)]),
    );
  }
  return String(value);
}

const collection = readArg('collection', 'qa');
const scope = readArg('scope', 'live');
const explicitSessionId = readArg('session-id', '');
const occurrenceLimit = readIntArg('occurrence-limit', 50);
const outputPathArg = readArg('out', '');
const explicitProjectId = readArg(
  'project-id',
  process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT || '',
);
const serviceAccountPath = readArg(
  'service-account',
  process.env.GOOGLE_APPLICATION_CREDENTIALS || '',
);
const printToStdout = hasFlag('stdout');
const sessionOnly = hasFlag('session-only');
const compact = hasFlag('compact');

if (hasFlag('help')) {
  printUsage();
  process.exit(0);
}

function resolveProjectId() {
  if (explicitProjectId) return explicitProjectId;
  if (!serviceAccountPath || !fs.existsSync(serviceAccountPath)) return '';
  try {
    const raw = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    return String(raw.project_id ?? '').trim();
  } catch (_) {
    return '';
  }
}

const projectId = resolveProjectId();

if (!admin.apps.length) {
  if (serviceAccountPath && fs.existsSync(serviceAccountPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: projectId || serviceAccount.project_id || undefined,
    });
  } else {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      ...(projectId ? { projectId } : {}),
    });
  }
}

const db = admin.firestore();
const scopeRef = db.collection(collection).doc(scope);

function sortByIsoTimestampDesc(items, fieldName) {
  return [...items].sort((left, right) => {
    const a = String(left?.[fieldName] ?? '');
    const b = String(right?.[fieldName] ?? '');
    return b.localeCompare(a);
  });
}

async function resolveSessionId() {
  if (explicitSessionId) return explicitSessionId;
  const scopeSnap = await scopeRef.get();
  if (!scopeSnap.exists) {
    throw new Error(`Scope document not found: ${scopeRef.path}`);
  }
  const lastSessionId = String(scopeSnap.get('lastSessionId') ?? '').trim();
  if (!lastSessionId) {
    throw new Error(`Scope document ${scopeRef.path} has no lastSessionId`);
  }
  return lastSessionId;
}

async function fetchSessionDocument(sessionId) {
  const sessionRef = scopeRef.collection('sessions').doc(sessionId);
  const sessionSnap = await sessionRef.get();
  if (!sessionSnap.exists) {
    throw new Error(`Session document not found: ${sessionRef.path}`);
  }
  return {
    ref: sessionRef.path,
    data: sanitize(sessionSnap.data() ?? {}),
  };
}

async function fetchOccurrenceDocuments(sessionId) {
  if (sessionOnly) return [];
  const snap = await db
    .collectionGroup('occurrences')
    .where('sessionId', '==', sessionId)
    .get();
  const items = snap.docs.map((doc) => ({
    id: doc.id,
    ref: doc.ref.path,
    ...sanitize(doc.data() ?? {}),
  }));
  return sortByIsoTimestampDesc(items, 'timestamp').slice(0, occurrenceLimit);
}

async function fetchIssueAggregates(signatures) {
  const unique = [...new Set(signatures.map((item) => String(item ?? '').trim()).filter(Boolean))];
  if (unique.length === 0) return [];
  const refs = unique.map((signature) => scopeRef.collection('issues').doc(signature));
  const snaps = await db.getAll(...refs);
  return snaps
    .filter((snap) => snap.exists)
    .map((snap) => ({
      id: snap.id,
      ref: snap.ref.path,
      ...sanitize(snap.data() ?? {}),
    }));
}

function buildDefaultOutputPath(sessionId) {
  return path.join(
    process.cwd(),
    'artifacts',
    'qa_lab',
    `qa_remote_${scope}_${sessionId}.json`,
  );
}

async function main() {
  const sessionId = await resolveSessionId();
  const scopeSnap = await scopeRef.get();
  const session = await fetchSessionDocument(sessionId);
  const occurrences = await fetchOccurrenceDocuments(sessionId);
  const issueAggregates = await fetchIssueAggregates(
    occurrences.map((item) => item.signature),
  );

  const payload = {
    fetchedAt: new Date().toISOString(),
    source: {
      collection,
      scope,
      sessionId,
      projectId: projectId || '',
      scopeRef: scopeRef.path,
      usedLastSessionPointer: !explicitSessionId,
    },
    scopeState: {
      ref: scopeRef.path,
      exists: scopeSnap.exists,
      data: sanitize(scopeSnap.data() ?? {}),
    },
    summary: {
      healthScore: session.data.healthScore ?? null,
      topSurfaceAlertCount: Array.isArray(session.data.topSurfaceAlerts)
        ? session.data.topSurfaceAlerts.length
        : 0,
      highlightedFindingCount: Array.isArray(session.data.highlightedFindings)
        ? session.data.highlightedFindings.length
        : 0,
      occurrenceCount: occurrences.length,
      issueAggregateCount: issueAggregates.length,
    },
    session,
    issueAggregates,
    occurrences,
  };

  const outputPath = outputPathArg || buildDefaultOutputPath(sessionId);
  const json = compact
    ? JSON.stringify(payload)
    : JSON.stringify(payload, null, 2);

  fs.mkdirSync(path.dirname(outputPath), { recursive: true });
  fs.writeFileSync(outputPath, json);

  console.log(
    `[qa-remote-fetch] scope=${scope} session=${sessionId} health=${payload.summary.healthScore ?? '-'} occurrences=${occurrences.length} issues=${issueAggregates.length} output=${outputPath}`,
  );

  if (printToStdout) {
    console.log(json);
  }
}

main().catch((error) => {
  const missingProjectId = String(error?.message ?? '').includes(
    'Unable to detect a Project Id',
  );
  const missingDefaultCredentials = String(error?.message ?? '').includes(
    'Could not load the default credentials',
  );
  if (missingProjectId) {
    console.error(
      'fetch_latest_qa_remote_report failed: Project ID not resolved. ' +
        'Pass --project-id=<firebase-project> or --service-account=/abs/path/key.json ' +
        'or set GOOGLE_APPLICATION_CREDENTIALS.',
    );
  } else if (missingDefaultCredentials) {
    console.error(
      'fetch_latest_qa_remote_report failed: Default credentials missing. ' +
        'Pass --service-account=/abs/path/key.json or set GOOGLE_APPLICATION_CREDENTIALS.',
    );
  } else {
    console.error('fetch_latest_qa_remote_report failed:', error);
  }
  process.exit(1);
});
