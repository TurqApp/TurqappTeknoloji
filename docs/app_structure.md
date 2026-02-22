# Flutter Social App Project Layout

**Objective**: keep the codebase modular, testable, and ready for rapid iteration against Instagram/Twitter-class expectations while integrating Firebase services.

```
turqapp/
├── analysis_options.yaml       <- lints, formatter, custom rules
├── pubspec.yaml                <- dependencies, assets, scripts
├── lib/
│   ├── app/                    <- top-level composition
│   │   ├── app.dart            <- `MaterialApp.router` / DI root
│   │   ├── bootstrap.dart      <- async init, Firebase, Sentry, env
│   │   └── router/             <- go_router or beamer definitions
│   ├── core/                   <- cross-cutting concerns
│   │   ├── config/             <- env, flavor, remote config adapters
│   │   ├── constants/          <- colors, typography, spacing tokens
│   │   ├── analytics/          <- telemetry facade (Firebase, Amplitude)
│   │   ├── error/              <- failure models, crash reporting
│   │   ├── localization/       <- arb, string keys, intl delegates
│   │   ├── network/            <- connectivity, retry, interceptors
│   │   └── theme/              <- theme extensions, responsive breakpoints
│   ├── features/               <- feature-first slices (DDD-ish)
│   │   ├── auth/
│   │   │   ├── data/           <- FirebaseAuth datasource, DTOs
│   │   │   ├── domain/         <- entities, repos, use cases
│   │   │   └── presentation/   <- controllers, pages, widgets
│   │   ├── onboarding/
│   │   ├── feed/
│   │   ├── profile/
│   │   ├── messaging/
│   │   ├── search/
│   │   └── settings/
│   ├── shared/                 <- reusable UI components & utils
│   │   ├── widgets/            <- buttons, cards, skeletons
│   │   ├── mixins/
│   │   └── extensions/
│   ├── services/               <- Firebase services behind interfaces
│   │   ├── firestore_service.dart
│   │   ├── storage_service.dart
│   │   ├── remote_config_service.dart
│   │   └── push_notifications_service.dart
│   └── state/                  <- application-level state management setup
│       ├── observers/          <- logging, analytics observers
│       ├── dependencies.dart   <- di container (get_it/riverpod)
│       └── app_state.dart
├── test/                       <- unit & widget tests (mirrors lib/)
├── integration_test/           <- e2e flows (login, post, follow, DM)
├── assets/                     <- fonts, icons, localization data
├── android/                    <- native setup (firebase_options.dart)
├── ios/
├── web/                        <- web target
└── scripts/                    <- CI helpers, code-gen triggers
```

## Folder Strategy Highlights
- **Feature-first**: Each feature holds its data/domain/presentation stack, enabling squads to iterate independently.
- **Core vs Shared**: `core/` contains opinionated, app-wide services; `shared/` keeps stateless UI and helpers to avoid feature coupling.
- **State boundary**: `state/` wires the global provider/container to bootstrap the app while features manage their own scoped controllers.
- **Generated code** (Freezed, JsonSerializable, Firebase Options) stored alongside sources; CI enforces `dart run build_runner build --delete-conflicting-outputs`.
- **Testing symmetry**: Mirror folder tree inside `test/` to simplify coverage automation.

## Firebase Integration Touchpoints
- `bootstrap.dart` initialises Firebase, Crashlytics, Remote Config, Cloud Messaging.
- `services/` exposes typed repositories for Firestore, Storage, Cloud Functions.
- Feature data layers depend on service abstractions to keep swapability (e.g., local mocks, REST fallback).

## Tooling & Automation
- Add `melos` or `very_good_cli` for scriptable tasks (formatting, analyzer, tests).
- CI pipelines: format → analyze → unit tests → integration tests (Firebase emulator suite) → build.
- Configure `fastlane` or `shorebird` for release automation.

