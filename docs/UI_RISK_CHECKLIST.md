# UI Risk Checklist (Behavior Parity Safe)

## Purpose
- Reduce clipping and small-screen layout risk.
- Keep behavior parity (no feature flow changes).

## Device Matrix
- Small: `<=360dp`
- Medium: `361-412dp`
- Large: `>412dp`
- Text scale: `1.0`, `1.3`, `1.6`

## Pass Criteria
- No RenderFlex overflow.
- No blocked CTA/button due to keyboard.
- No critical text clipping for primary labels/actions.
- Scroll behavior remains consistent (no accidental nested-scroll lock).

## Priorities
1. Profile
2. Feed
3. Chat
4. Explore

## Safe Fix Rules
- Prefer responsive sizing over fixed pixel values.
- Keep current interactions and navigation unchanged.
- Use maxLines > 1 where content meaning is lost.
- Add expand/collapse only where current clipping hides important info.

## Release Gate
- P0 UI breaks: block release.
- P1 clipping/small-screen regressions: fix before release candidate.
- P2 visual inconsistencies: track and fix in next patch.

## Workflow
1. Run `scripts/ui_audit.sh`.
2. Inspect `docs/ui_audit_latest.md`.
3. Patch one module at a time.
4. Re-run audit and smoke test.
