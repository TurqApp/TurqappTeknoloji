# Widget Test Strategy

This document defines the advanced widget testing shape for TurqApp.

## Goals

- Keep `test/widget` fast and deterministic.
- Use a shared harness for platform, size, and text-scale variation.
- Track every widget class in `lib/` with an explicit matrix entry.
- Separate direct widget verification from integration and smoke coverage.

## Layers

1. Render contract
- Widget builds without exception.
- Critical keys and labels are present.

2. Interaction contract
- Taps, text entry, focus, and sheet actions behave correctly.

3. Accessibility contract
- Semantics labels and tap actions are preserved.
- Large text scale does not break critical UI.

4. Platform contract
- Android and iOS visual/runtime assumptions are verified through the same harness.

5. Matrix governance
- Every widget class is inventoried.
- Coverage status is generated into `docs/testing/widget_test_matrix.md`.

## Shared Harness

Use:

- `test/helpers/pump_app.dart`
- `test/helpers/widget_test_harness.dart`

Available variants:

- `WidgetHarnessVariants.phoneAndroid`
- `WidgetHarnessVariants.phoneIos`
- `WidgetHarnessVariants.phoneLargeText`
- `WidgetHarnessVariants.tabletAndroid`

## Coverage Tiers

- `P0`: main user surfaces and critical app widgets
  - Required: render, interaction, semantics, textScale, platform
- `P1`: important secondary surfaces and reusable UI containers
  - Required: render, interaction, semantics
- `P2`: support widgets and lower-risk leaf components
  - Required: render, semantics

## Execution Order

1. `dart run tool/generate_widget_test_matrix.dart`
2. `flutter test test/widget`
3. Expand `P0` gaps first
4. Expand `P1` and `P2` after critical surfaces stabilize

## Commands

```bash
dart run tool/generate_widget_test_matrix.dart
flutter test test/widget
```

## Output

- Human-readable matrix: `docs/testing/widget_test_matrix.md`
- Machine-readable matrix: `docs/testing/widget_test_matrix.json`
