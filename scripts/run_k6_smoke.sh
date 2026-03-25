#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROJECT_ID="${FIREBASE_PROJECT_ID:-turqappteknoloji}"
PROFILE="${K6_PROFILE:-smoke}"
MODE="${K6_MODE:-feed_only}"
SUMMARY_FILE="${K6_SUMMARY_FILE:-artifacts/k6/k6_summary.json}"
ID_TOKEN_VALUE="${ID_TOKEN:-}"
FIREBASE_API_KEY_VALUE="${FIREBASE_API_KEY:-AIzaSyA6I8_TtqE8iMARFZClNIxjlEnmi3-hhOI}"
SEARCH_CF_URL="${SEARCH_CF_BASE_URL:-https://us-central1-${PROJECT_ID}.cloudfunctions.net}"
INTERACTION_CF_URL="${INTERACTION_CF_BASE_URL:-https://europe-west1-${PROJECT_ID}.cloudfunctions.net}"
POST_CARDS_URL="${POST_CARDS_ENDPOINT:-${SEARCH_CF_URL}/f15_getPostCardsByIdsCallable}"
BACKFILL_FEED_URL="${BACKFILL_FEED_ENDPOINT:-${INTERACTION_CF_URL}/backfillHybridFeedForUser}"
TOGGLE_LIKE_URL="${TOGGLE_LIKE_ENDPOINT:-${INTERACTION_CF_URL}/toggleLikeBatch}"
RECORD_VIEW_URL="${RECORD_VIEW_ENDPOINT:-${INTERACTION_CF_URL}/recordViewBatch}"
FEED_USER_ID_VALUE="${FEED_USER_ID:-}"
ACTION_TOKEN_POOL_VALUE="${ACTION_ID_TOKEN_POOL:-}"
TEMP_TOKEN_PREFIX="${K6_TEMP_TOKEN_PREFIX:-k6-temp}"
CLEANUP_TOKENS_JSON="[]"
PREWARM_ENABLED="${K6_PREWARM:-1}"
FIRESTORE_BASE="https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents"

resolve_default_temp_token_count() {
  case "$MODE" in
    search_only|mixed)
      case "$PROFILE" in
        smoke) echo "4" ;;
        feed_only) echo "8" ;;
        *) echo "20" ;;
      esac
      ;;
    feed_only)
      if [[ "$PROFILE" == "full" ]]; then
        echo "20"
      else
        echo "0"
      fi
      ;;
    interaction_only)
      echo "0"
      ;;
    *)
      case "$PROFILE" in
        smoke) echo "4" ;;
        feed_only) echo "8" ;;
        *) echo "20" ;;
      esac
      ;;
  esac
}

if [[ -n "$ACTION_TOKEN_POOL_VALUE" ]]; then
  TEMP_TOKEN_COUNT="${K6_TEMP_TOKEN_COUNT:-0}"
elif [[ -n "${K6_TEMP_TOKEN_COUNT+x}" ]]; then
  TEMP_TOKEN_COUNT="${K6_TEMP_TOKEN_COUNT}"
else
  TEMP_TOKEN_COUNT="$(resolve_default_temp_token_count)"
fi

if ! command -v k6 >/dev/null 2>&1; then
  echo "[k6-smoke] k6 binary not found"
  exit 1
fi

if [[ -z "$ID_TOKEN_VALUE" ]]; then
  echo "[k6-smoke] skipped (ID_TOKEN not set)"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[k6-smoke] jq not found"
  exit 1
fi

mkdir -p "$(dirname "$SUMMARY_FILE")"

if [[ -z "$FEED_USER_ID_VALUE" || -z "$ACTION_TOKEN_POOL_VALUE" || "$TEMP_TOKEN_COUNT" != "0" ]]; then
  auth_context_json="$(
    cd "$REPO_ROOT" && \
      K6_BASE_ID_TOKEN="$ID_TOKEN_VALUE" \
      K6_TEMP_TOKEN_COUNT="$TEMP_TOKEN_COUNT" \
      K6_TEMP_TOKEN_PREFIX="$TEMP_TOKEN_PREFIX" \
      FIREBASE_API_KEY="$FIREBASE_API_KEY_VALUE" \
      node tests/load/prepare_k6_auth_context.mjs
  )"
  if [[ -z "$FEED_USER_ID_VALUE" ]]; then
    FEED_USER_ID_VALUE="$(printf '%s' "$auth_context_json" | jq -r '.feedUid // empty')"
  fi
  if [[ -z "$ACTION_TOKEN_POOL_VALUE" ]]; then
    ACTION_TOKEN_POOL_VALUE="$(printf '%s' "$auth_context_json" | jq -c '.actionTokens // []')"
  fi
  CLEANUP_TOKENS_JSON="$(printf '%s' "$auth_context_json" | jq -c '.cleanupTokens // []')"
fi

cleanup_temp_k6_users() {
  local cleanup_token
  if [[ "$CLEANUP_TOKENS_JSON" == "[]" ]]; then
    return
  fi
  while IFS= read -r cleanup_token; do
    [[ -z "$cleanup_token" ]] && continue
    curl -sS -X POST \
      "https://identitytoolkit.googleapis.com/v1/accounts:delete?key=${FIREBASE_API_KEY_VALUE}" \
      -H "Content-Type: application/json" \
      --data "{\"idToken\":\"${cleanup_token}\"}" >/dev/null || true
  done < <(printf '%s' "$CLEANUP_TOKENS_JSON" | jq -r '.[]')
}

trap cleanup_temp_k6_users EXIT

call_callable() {
  local url="$1"
  local token="$2"
  local payload="$3"
  curl -sS -X POST \
    "$url" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${token}" \
    --data "$payload"
}

load_feed_post_ids() {
  local url response
  url="${FIRESTORE_BASE}/userFeeds/${FEED_USER_ID_VALUE}/items?orderBy=timeStamp%20desc&pageSize=20"
  response="$(curl -sS -H "Authorization: Bearer ${ID_TOKEN_VALUE}" "$url")"
  if [[ "$(printf '%s' "$response" | jq -r '.documents | length // 0')" == "0" ]]; then
    call_callable \
      "$BACKFILL_FEED_URL" \
      "$ID_TOKEN_VALUE" \
      "$(jq -nc --arg uid "$FEED_USER_ID_VALUE" '{data:{uid:$uid,perAuthorLimit:4}}')" >/dev/null || true
    response="$(curl -sS -H "Authorization: Bearer ${ID_TOKEN_VALUE}" "$url")"
  fi
  printf '%s' "$response" | jq -r '.documents[]?.fields.postId.stringValue // empty'
}

prewarm_k6_paths() {
  local warm_token post_ids_json first_post
  local -a post_ids=()
  local -a warm_tokens=()

  [[ "$PREWARM_ENABLED" == "0" ]] && return
  [[ -z "$ID_TOKEN_VALUE" || -z "$FEED_USER_ID_VALUE" ]] && return

  while IFS= read -r first_post; do
    post_ids+=("$first_post")
  done < <(load_feed_post_ids | sed -n '1,5p')
  [[ "${#post_ids[@]}" -eq 0 ]] && return

  while IFS= read -r warm_token; do
    [[ -z "$warm_token" ]] && continue
    warm_tokens+=("$warm_token")
  done < <(printf '%s' "$ACTION_TOKEN_POOL_VALUE" | jq -r '.[]? // empty' 2>/dev/null || true)

  if [[ "${#warm_tokens[@]}" -eq 0 ]]; then
    warm_tokens+=("$ID_TOKEN_VALUE")
  fi

  post_ids_json="$(printf '%s\n' "${post_ids[@]}" | jq -R . | jq -sc .)"
  first_post="${post_ids[0]}"
  for warm_token in "${warm_tokens[@]}"; do
    call_callable \
      "$POST_CARDS_URL" \
      "$warm_token" \
      "$(jq -nc --argjson ids "$post_ids_json" '{data:{ids:$ids}}')" >/dev/null || true

    if [[ "$MODE" == "interaction_only" || "$MODE" == "mixed" ]]; then
      call_callable \
        "$TOGGLE_LIKE_URL" \
        "$warm_token" \
        "$(jq -nc --arg postId "$first_post" '{data:{items:[{postId:$postId,value:true}]}}')" >/dev/null || true
      call_callable \
        "$TOGGLE_LIKE_URL" \
        "$warm_token" \
        "$(jq -nc --arg postId "$first_post" '{data:{items:[{postId:$postId,value:false}]}}')" >/dev/null || true
    fi
  done
}

echo "[k6-smoke] profile=${PROFILE} mode=${MODE} project=${PROJECT_ID}"
prewarm_k6_paths

k6 run \
  --summary-export "${SUMMARY_FILE}" \
  --env FIREBASE_PROJECT_ID="${PROJECT_ID}" \
  --env SEARCH_CF_BASE_URL="${SEARCH_CF_URL}" \
  --env INTERACTION_CF_BASE_URL="${INTERACTION_CF_URL}" \
  --env ID_TOKEN="${ID_TOKEN_VALUE}" \
  --env POST_CARDS_ENDPOINT="${POST_CARDS_URL}" \
  --env BACKFILL_FEED_ENDPOINT="${BACKFILL_FEED_URL}" \
  --env TOGGLE_LIKE_ENDPOINT="${TOGGLE_LIKE_URL}" \
  --env RECORD_VIEW_ENDPOINT="${RECORD_VIEW_URL}" \
  --env FEED_USER_ID="${FEED_USER_ID_VALUE}" \
  --env ACTION_ID_TOKEN_POOL="${ACTION_TOKEN_POOL_VALUE}" \
  --env K6_PROFILE="${PROFILE}" \
  --env K6_MODE="${MODE}" \
  tests/load/k6_turqapp_load_test.js

echo "[k6-smoke] summary=${SUMMARY_FILE}"
