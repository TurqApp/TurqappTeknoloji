#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository: $ROOT_DIR" >&2
  exit 1
fi

policy_path="${PART_SPRAWL_BUDGET_POLICY:-config/quality/part_sprawl_budget_targets.txt}"
artifact_dir="${PART_SPRAWL_BUDGET_ARTIFACT_DIR:-artifacts/part_sprawl_budget}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --policy)
      policy_path="${2:-}"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      echo "Usage:" >&2
      echo "  bash scripts/check_part_sprawl_budget.sh [--policy <relative-or-absolute-policy-path>]" >&2
      exit 64
      ;;
  esac
done

if [[ ! -f "$policy_path" ]]; then
  echo "Policy file not found: $policy_path" >&2
  exit 66
fi

mkdir -p "$artifact_dir"

report_path="$artifact_dir/part_sprawl_budget_report.txt"
inventory_path="$artifact_dir/part_sprawl_budget_inventory.txt"

python3 - "$ROOT_DIR" "$policy_path" "$report_path" "$inventory_path" <<'PY'
from __future__ import annotations

import fnmatch
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

MICRO_SUFFIXES = (
    "_facade_part.dart",
    "_fields_part.dart",
    "_class_part.dart",
    "_base_part.dart",
    "_members_part.dart",
)


@dataclass
class Cluster:
    name: str
    mode: str
    max_count: int
    patterns: list[str]
    note: str


def load_policy(path: Path) -> list[Cluster]:
    clusters: list[Cluster] = []
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        parts = [part.strip() for part in line.split("|")]
        if len(parts) != 5:
            raise SystemExit(f"Invalid policy line: {raw_line}")
        name, mode, max_count, pattern_csv, note = parts
        if mode not in {"guard", "watch"}:
            raise SystemExit(f"Invalid mode for {name}: {mode}")
        patterns = [pattern.strip() for pattern in pattern_csv.split(",") if pattern.strip()]
        if not patterns:
            raise SystemExit(f"No patterns configured for {name}")
        clusters.append(
            Cluster(
                name=name,
                mode=mode,
                max_count=int(max_count),
                patterns=patterns,
                note=note,
            )
        )
    if not clusters:
        raise SystemExit("Policy file does not define any clusters")
    return clusters


def tracked_micro_parts(root_dir: Path) -> list[str]:
    output = subprocess.check_output(
        ["git", "-C", str(root_dir), "ls-files", "lib/**/*_part.dart"],
        text=True,
    )
    files = [line.strip() for line in output.splitlines() if line.strip()]
    return [file_path for file_path in files if file_path.endswith(MICRO_SUFFIXES)]


def match_count(files: list[str], patterns: list[str]) -> tuple[int, list[str]]:
    matched: list[str] = []
    seen: set[str] = set()
    for file_path in files:
      if any(fnmatch.fnmatch(file_path, pattern) for pattern in patterns):
          if file_path not in seen:
              seen.add(file_path)
              matched.append(file_path)
    matched.sort()
    return len(matched), matched


def main() -> int:
    root_dir = Path(sys.argv[1])
    policy_path = Path(sys.argv[2])
    report_path = Path(sys.argv[3])
    inventory_path = Path(sys.argv[4])

    clusters = load_policy(policy_path)
    files = tracked_micro_parts(root_dir)

    results = []
    guard_failures = []
    watch_exceeded = []

    suffix_counts = {
        suffix: sum(1 for file_path in files if file_path.endswith(suffix))
        for suffix in MICRO_SUFFIXES
    }

    for cluster in clusters:
        count, matched = match_count(files, cluster.patterns)
        status = "PASS"
        if count > cluster.max_count:
            if cluster.mode == "guard":
                status = "FAIL"
                guard_failures.append(cluster.name)
            else:
                status = "WATCH-OVER"
                watch_exceeded.append(cluster.name)
        results.append((cluster, count, status, matched))

    lines = []
    lines.append("Micro part suffix totals:")
    for suffix, count in suffix_counts.items():
        lines.append(f"  - {suffix}: {count}")
    lines.append("")
    for cluster, count, status, matched in results:
        lines.append(f"[{cluster.name}]")
        lines.append(f"mode={cluster.mode}")
        lines.append(f"max={cluster.max_count}")
        lines.append(f"count={count}")
        lines.append(f"status={status}")
        lines.append(f"note={cluster.note}")
        lines.append("patterns:")
        for pattern in cluster.patterns:
            lines.append(f"  - {pattern}")
        lines.append("tracked micro parts:")
        if matched:
            for file_path in matched:
                lines.append(f"  - {file_path}")
        else:
            lines.append("  - (none)")
        lines.append("")
    inventory_path.write_text("\n".join(lines).rstrip() + "\n", encoding="utf-8")

    generated_at = subprocess.check_output(
        ["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"],
        text=True,
    ).strip()
    report = [
        f"Part sprawl budget report generated at: {generated_at}",
        f"Repository root: {root_dir}",
        f"Policy path: {policy_path}",
        f"Tracked micro part count: {len(files)}",
        f"Cluster count: {len(results)}",
        f"Guard failure count: {len(guard_failures)}",
        f"Watch-over count: {len(watch_exceeded)}",
        "",
        "Micro part suffix totals:",
    ]
    for suffix, count in suffix_counts.items():
        report.append(f"  - {suffix}: {count}")
    report.append("")
    report.append("Cluster summary:")
    for cluster, count, status, _matched in results:
        report.append(
            f"  - {cluster.name}: mode={cluster.mode}, count={count}, max={cluster.max_count}, status={status}"
        )
    report.append("")
    if guard_failures:
        report.append("Guard failures:")
        for name in guard_failures:
            report.append(f"  - {name}")
        report.append("")
    if watch_exceeded:
        report.append("Watch clusters over target:")
        for name in watch_exceeded:
            report.append(f"  - {name}")
        report.append("")
    report.append(f"Inventory path: {inventory_path}")
    report_path.write_text("\n".join(report).rstrip() + "\n", encoding="utf-8")

    print(f"Part sprawl budget report generated at: {generated_at}")
    print(f"Policy path: {policy_path}")
    print(f"Tracked micro part count: {len(files)}")
    print(f"Report path: {report_path}")
    print(f"Inventory path: {inventory_path}")

    if guard_failures:
        print()
        print("[FAIL] Part sprawl budget guard exceeded guarded budgets.")
        return 3

    print()
    print("[PASS] Part sprawl budget guard passed.")
    if watch_exceeded:
        print("Watch clusters over target:")
        for name in watch_exceeded:
            print(f"  - {name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
PY
