#!/usr/bin/env bash

load_suite_entries() {
  local manifest="$1"
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    printf '%s\n' "$line"
  done < "$manifest"
}

load_suite_pairs() {
  local manifest="$1"
  while IFS='|' read -r left right || [[ -n "$left$right" ]]; do
    [[ -z "$left" ]] && continue
    [[ "$left" == \#* ]] && continue
    printf '%s|%s\n' "$left" "$right"
  done < "$manifest"
}
