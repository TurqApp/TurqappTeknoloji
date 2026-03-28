#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARTIFACT_DIR="${ARCHITECTURE_ARTIFACT_DIR:-$ROOT_DIR/artifacts/architecture}"
REPORT_PATH="$ARTIFACT_DIR/architecture_guard_report.txt"
INVENTORY_PATH="$ARTIFACT_DIR/architecture_inventory.txt"
CHANGED_PATH="$ARTIFACT_DIR/architecture_changed_files.txt"

BASE_REV=""
FILES_CSV=""

usage() {
  cat <<'EOF'
Usage:
  bash scripts/check_architecture_guards.sh [--against <git-rev>] [--files <comma-separated-paths>]

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

get_base_content() {
  local path="$1"
  if file_exists_in_base "$path"; then
    git -C "$ROOT_DIR" show "${BASE_REV}:${path}" 2>/dev/null || true
  fi
}

get_current_content() {
  local path="$1"
  if [[ -f "$ROOT_DIR/$path" ]]; then
    cat "$ROOT_DIR/$path"
  fi
}

normalize_count() {
  tr -d '[:space:]'
}

count_direct_locator_tokens() {
  local content="$1"
  if [[ -z "$content" ]]; then
    printf '0\n'
    return
  fi
  { printf '%s' "$content" | rg -o "Get\\.(find|put|lazyPut|putAsync|create|delete|isRegistered)\\b" || true; } | wc -l | normalize_count
}

count_presentation_infra_imports() {
  local path="$1"
  local content="$2"
  if [[ ! "$path" =~ ^lib/Modules/.*(view|controller|widget).*[.]dart$ ]]; then
    printf '0\n'
    return
  fi
  if [[ -z "$content" ]]; then
    printf '0\n'
    return
  fi
  { printf '%s' "$content" | rg -n "^import 'package:(cloud_firestore|firebase_auth|firebase_storage|cloud_functions)/|^import 'package:turqappv2/Core/Repositories/" || true; } | wc -l | normalize_count
}

count_cross_feature_internal_imports() {
  local path="$1"
  local content="$2"
  local import_regex="package:turqappv2/Modules/([^/]+)/([^']+)"
  if [[ ! "$path" =~ ^lib/Modules/([^/]+)/ ]]; then
    printf '0\n'
    return
  fi
  local own_feature="${BASH_REMATCH[1]}"
  local count=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" =~ $import_regex ]]; then
      local target_feature="${BASH_REMATCH[1]}"
      local target_path="${BASH_REMATCH[2]}"
      if [[ "$target_feature" != "$own_feature" ]] && [[ "$target_path" =~ (_controller|_part[.]dart$|/Common/) ]]; then
        count=$((count + 1))
      fi
    fi
  done < <(printf '%s\n' "$content" | rg "^import 'package:turqappv2/Modules/" || true)

  printf '%s\n' "$count"
}

is_locator_growth_allowed() {
  local path="$1"
  case "$path" in
    lib/main.dart|lib/Modules/Splash/*|*_facade_part.dart|*_binding.dart|*_bindings.dart|*_binding_part.dart|*_bindings_part.dart)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

write_inventory() {
  local total_dart direct_locator_total helper_locator_total module_import_total
  total_dart="$(find "$ROOT_DIR/lib" -type f -name '*.dart' | wc -l | normalize_count)"
  direct_locator_total="$({ rg -o "Get\\.(find|put|lazyPut|putAsync|create|delete|isRegistered)\\b" "$ROOT_DIR/lib" -g '*.dart' || true; } | wc -l | normalize_count)"
  helper_locator_total="$({ rg -o "\\b(maybeFind[A-Za-z0-9_]*|ensure[A-Za-z0-9_]*Controller)\\b" "$ROOT_DIR/lib" -g '*.dart' || true; } | wc -l | normalize_count)"
  module_import_total="$({ rg -n "^import 'package:turqappv2/Modules/" "$ROOT_DIR/lib" -g '*.dart' || true; } | wc -l | normalize_count)"

  {
    printf 'Architecture inventory generated at: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    printf 'Base revision: %s\n' "$BASE_REV"
    printf 'Total lib Dart files: %s\n' "$total_dart"
    printf 'Direct GetX locator tokens: %s\n' "$direct_locator_total"
    printf 'Helper locator tokens: %s\n' "$helper_locator_total"
    printf 'Feature-to-feature package imports: %s\n' "$module_import_total"
    printf '\nTop 15 largest Dart files in lib:\n'
    find "$ROOT_DIR/lib" -type f -name '*.dart' -print0 \
      | xargs -0 wc -l \
      | sort -nr \
      | sed -n '1,15p'
  } >"$INVENTORY_PATH"
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

write_inventory

CHANGED_FILES=()
while IFS= read -r line; do
  CHANGED_FILES+=("$line")
done < <(load_changed_files)
printf '%s\n' "${CHANGED_FILES[@]:-}" >"$CHANGED_PATH"

violations=0

{
  printf 'Architecture guard report generated at: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'Base revision: %s\n' "$BASE_REV"
  printf 'Changed file count: %s\n' "${#CHANGED_FILES[@]}"
  printf 'Report path: %s\n' "$REPORT_PATH"
  printf 'Inventory path: %s\n' "$INVENTORY_PATH"
  printf '\n'
} >"$REPORT_PATH"

report_violation() {
  local rule="$1"
  local path="$2"
  local detail="$3"
  {
    printf '[FAIL] %s :: %s\n' "$rule" "$path"
    printf '  %s\n' "$detail"
  } >>"$REPORT_PATH"
  violations=$((violations + 1))
}

if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
  printf 'No changed files detected. Inventory only.\n' >>"$REPORT_PATH"
fi

for path in "${CHANGED_FILES[@]}"; do
  [[ -z "$path" ]] && continue

  if [[ "$path" =~ ^lib/(Core|Services|Models)/.+[.]dart$ ]] && ! file_exists_in_base "$path"; then
    report_violation \
      "legacy_folder_freeze" \
      "$path" \
      "Yeni Dart dosyasi legacy klasor altina eklenemez."
  fi

  if [[ "$path" =~ (_facade_part|_fields_part|_class_part)[.]dart$ ]] && ! file_exists_in_base "$path"; then
    report_violation \
      "no_new_part_sprawl" \
      "$path" \
      "Yeni facade/fields/class part dosyasi olusturulamaz."
  fi

  if [[ ! "$path" =~ [.]dart$ ]]; then
    continue
  fi

  current_content="$(get_current_content "$path")"
  base_content="$(get_base_content "$path")"

  current_locator_count="$(count_direct_locator_tokens "$current_content")"
  base_locator_count="$(count_direct_locator_tokens "$base_content")"
  if (( current_locator_count > base_locator_count )) && ! is_locator_growth_allowed "$path"; then
    report_violation \
      "no_service_locator_outside_root" \
      "$path" \
      "Direct GetX locator kullanimi artis gosterdi (${base_locator_count} -> ${current_locator_count})."
  fi

  current_presentation_infra_count="$(count_presentation_infra_imports "$path" "$current_content")"
  base_presentation_infra_count="$(count_presentation_infra_imports "$path" "$base_content")"
  if (( current_presentation_infra_count > base_presentation_infra_count )); then
    report_violation \
      "presentation_cannot_touch_infra" \
      "$path" \
      "Presentation katmaninda Firebase veya Core/Repositories importu artis gosterdi (${base_presentation_infra_count} -> ${current_presentation_infra_count})."
  fi

  current_cross_feature_count="$(count_cross_feature_internal_imports "$path" "$current_content")"
  base_cross_feature_count="$(count_cross_feature_internal_imports "$path" "$base_content")"
  if (( current_cross_feature_count > base_cross_feature_count )); then
    report_violation \
      "no_cross_feature_internal_imports" \
      "$path" \
      "Baska feature'in ic controller/part importu artis gosterdi (${base_cross_feature_count} -> ${current_cross_feature_count})."
  fi
done

if (( violations == 0 )); then
  {
    printf '\n[PASS] Architecture guards passed.\n'
    printf 'Scanned files:\n'
    sed 's/^/  - /' "$CHANGED_PATH"
  } >>"$REPORT_PATH"
else
  {
    printf '\nArchitecture guards failed with %s violation(s).\n' "$violations"
    printf 'Scanned files:\n'
    sed 's/^/  - /' "$CHANGED_PATH"
  } >>"$REPORT_PATH"
fi

cat "$REPORT_PATH"

if (( violations > 0 )); then
  exit 1
fi
