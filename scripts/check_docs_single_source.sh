#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="${DOC_GUARD_ARTIFACT_DIR:-$ROOT_DIR/artifacts/docs_guard}"
REPORT_PATH="$ARTIFACT_DIR/docs_single_source_report.txt"
INVENTORY_PATH="$ARTIFACT_DIR/docs_single_source_inventory.txt"
CHANGED_PATH="$ARTIFACT_DIR/docs_changed_files.txt"

BASE_REV=""
FILES_CSV=""
CANONICAL_PLAN_PATH="docs/TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28.md"
README_PATH="docs/README.md"

usage() {
  cat <<'EOF'
Usage:
  bash scripts/check_docs_single_source.sh [--against <git-rev>] [--files <comma-separated-paths>]

Options:
  --against   Guard karsilastirmasi icin base revision. Varsayilan:
              - PR ise merge-base(HEAD, origin/$GITHUB_BASE_REF)
              - aksi halde HEAD^ varsa HEAD^
              - degilse HEAD
  --files     Yalniz verilen dosyalari denetle. Relative repo path bekler.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --against)
      BASE_REV="${2:-}"
      shift 2
      ;;
    --files)
      FILES_CSV="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

mkdir -p "$ARTIFACT_DIR"

resolve_base_rev() {
  if [[ -n "$BASE_REV" ]]; then
    printf '%s\n' "$BASE_REV"
    return
  fi

  if [[ -n "${GITHUB_BASE_REF:-}" ]]; then
    git -C "$ROOT_DIR" fetch --no-tags --depth=1 origin "${GITHUB_BASE_REF}" >/dev/null 2>&1 || true
    local merge_base=""
    merge_base="$(git -C "$ROOT_DIR" merge-base HEAD "origin/${GITHUB_BASE_REF}" 2>/dev/null || true)"
    if [[ -n "$merge_base" ]]; then
      printf '%s\n' "$merge_base"
      return
    fi
  fi

  if git -C "$ROOT_DIR" rev-parse --verify HEAD^ >/dev/null 2>&1; then
    printf 'HEAD^\n'
    return
  fi

  printf 'HEAD\n'
}

BASE_REV="$(resolve_base_rev)"

file_exists_in_base() {
  local path="$1"
  git -C "$ROOT_DIR" cat-file -e "${BASE_REV}:${path}" >/dev/null 2>&1
}

load_changed_files() {
  if [[ -n "$FILES_CSV" ]]; then
    printf '%s\n' "$FILES_CSV" | tr ',' '\n' | sed '/^[[:space:]]*$/d' | sed 's#^\./##' | sort -u
    return
  fi

  {
    git -C "$ROOT_DIR" diff --name-only --diff-filter=ACMR "$BASE_REV" --
    git -C "$ROOT_DIR" ls-files --others --exclude-standard
  } | sed '/^[[:space:]]*$/d' | sort -u
}

is_ignored_docs_path() {
  local path="$1"
  case "$path" in
    docs/.DS_Store|docs/**/.DS_Store)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

is_allowed_docs_path() {
  local path="$1"
  case "$path" in
    "$README_PATH"|"$CANONICAL_PLAN_PATH")
      return 0
      ;;
    docs/architecture/T-*.md)
      return 0
      ;;
    docs/policies/*|docs/observability/*|docs/testing/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

contains_disallowed_doc_label() {
  local path="$1"
  local basename_upper=""
  basename_upper="$(basename "$path" | tr '[:lower:]' '[:upper:]')"
  if [[ "$path" == "$CANONICAL_PLAN_PATH" ]]; then
    return 1
  fi
  if [[ "$path" =~ ^docs/architecture/T-.*[.]md$ ]]; then
    return 1
  fi
  [[ "$basename_upper" =~ (PLAN|PLANI|MIGRATION|HANDOFF|ANALIZ|ANALYSIS|ANALYSE) ]]
}

write_inventory() {
  {
    printf 'Docs single-source inventory generated at: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'Base revision: %s\n' "$BASE_REV"
    printf 'Canonical root files:\n'
    printf '  - %s\n' "$README_PATH"
    printf '  - %s\n' "$CANONICAL_PLAN_PATH"
    printf '\nCurrent docs root files:\n'
    find "$ROOT_DIR/docs" -maxdepth 1 -type f | sed "s#${ROOT_DIR}/##" | sort
    printf '\nCurrent docs subdirectories:\n'
    find "$ROOT_DIR/docs" -maxdepth 1 -mindepth 1 -type d | sed "s#${ROOT_DIR}/##" | sort
  } >"$INVENTORY_PATH"
}

report_failure() {
  local rule="$1"
  local path="$2"
  local detail="$3"
  {
    printf '[FAIL] %s :: %s\n' "$rule" "$path"
    printf '  %s\n' "$detail"
  } >>"$REPORT_PATH"
}

violations=0
write_inventory

CHANGED_FILES=()
while IFS= read -r line; do
  CHANGED_FILES+=("$line")
done < <(load_changed_files)
printf '%s\n' "${CHANGED_FILES[@]:-}" >"$CHANGED_PATH"

{
  printf 'Docs single-source guard report generated at: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'Base revision: %s\n' "$BASE_REV"
  printf 'Changed file count: %s\n' "${#CHANGED_FILES[@]}"
  printf 'Report path: %s\n' "$REPORT_PATH"
  printf 'Inventory path: %s\n' "$INVENTORY_PATH"
  printf '\n'
} >"$REPORT_PATH"

if [[ ! -f "$ROOT_DIR/$README_PATH" ]]; then
  report_failure "docs_policy_missing" "$README_PATH" "README bulunamadi."
  violations=$((violations + 1))
else
  if ! rg -q "Kanonik belgeler:" "$ROOT_DIR/$README_PATH"; then
    report_failure "docs_policy_missing" "$README_PATH" "README icinde 'Kanonik belgeler' bolumu yok."
    violations=$((violations + 1))
  fi
  if ! rg -q "Tarihli plan, migration, handoff ve analiz belgeleri tutulmaz\\." "$ROOT_DIR/$README_PATH"; then
    report_failure "docs_policy_missing" "$README_PATH" "README icinde tarihli plan/doc yigini yasagi yok."
    violations=$((violations + 1))
  fi
  if ! rg -q "\\./TURQAPP_30_GUNLUK_ODAK_PLANI_2026-03-28\\.md" "$ROOT_DIR/$README_PATH"; then
    report_failure "docs_policy_missing" "$README_PATH" "README kanonik plan dosyasini isaret etmiyor."
    violations=$((violations + 1))
  fi
fi

for path in "${CHANGED_FILES[@]}"; do
  [[ -z "$path" ]] && continue
  [[ "$path" != docs/* ]] && continue

  if is_ignored_docs_path "$path"; then
    continue
  fi

  if ! is_allowed_docs_path "$path"; then
    report_failure \
      "docs_single_source_surface" \
      "$path" \
      "Docs altinda izinli yuzey disinda yeni veya degisen dosya var."
    violations=$((violations + 1))
    continue
  fi

  if contains_disallowed_doc_label "$path"; then
    report_failure \
      "docs_single_source_naming" \
      "$path" \
      "Tarihli plan/migration/handoff/analiz isimlendirmesi kanonik plan disinda yasak."
    violations=$((violations + 1))
  fi
done

if (( violations == 0 )); then
  {
    printf '\n[PASS] Docs single-source guard passed.\n'
    printf 'Scanned files:\n'
    sed 's/^/  - /' "$CHANGED_PATH"
  } >>"$REPORT_PATH"
else
  {
    printf '\nDocs single-source guard failed with %s violation(s).\n' "$violations"
    printf 'Scanned files:\n'
    sed 's/^/  - /' "$CHANGED_PATH"
  } >>"$REPORT_PATH"
fi

cat "$REPORT_PATH"

if (( violations > 0 )); then
  exit 1
fi
