# PulseWise Context

This document is the working source of truth for PulseWise.

It describes:
- the real state of the codebase today
- the target architecture we want to move toward
- the rules future refactors should follow

Important: PulseWise is not fully clean architecture yet. This repository is in a transitional state. We are documenting the target architecture now so future refactors can move toward it feature by feature instead of doing one risky rewrite.

## Current Reality

The project already uses Flutter + Riverpod + go_router and is partially organized by feature, but most non-auth business logic is still concentrated inside the `dashboard` area.

Today:
- `lib/features/auth` is already a real feature module.
- `lib/features/dashboard` is overloaded and currently contains many unrelated concerns.
- `lib/features/dashboard/presentation/providers/profile_provider.dart` acts as a large shared API/provider hub.
- many screens outside "profile" still import `profile_provider.dart`
- shared Dio setup is also currently defined inside `profile_provider.dart`

That means the current structure looks feature-first on the surface, but in practice it is still too centralized.

## Main Problem To Fix Later

The biggest architectural issue right now is this:

- almost every patient-facing API call is routed through `lib/features/dashboard/presentation/providers/profile_provider.dart`

That file currently mixes responsibilities such as:
- profile
- avatar upload
- auth-me
- dashboard vitals / quick dashboard
- ML profile questionnaire
- ML assessment
- ML recommendations and recommendation history
- diary
- medications / reminders / logs / calendar

This is exactly what we do not want going forward.

## Target Architecture

The target is a real feature-first clean architecture:

- every feature owns its own folder
- every feature owns its own providers
- every feature owns its own API/data access layer
- `dashboard` stops being a catch-all folder
- `core` only contains shared cross-feature infrastructure

We are not doing the full refactor yet. From this point on, this is the architecture future work should move toward.

## Architecture Rules

### 1. Feature ownership

Each feature should be self-contained.

A feature should own:
- its pages
- its widgets
- its providers
- its models / entities
- its repositories
- its datasources / API layer

Another feature should not depend on that feature's presentation provider just to make an API call.

### 2. Provider ownership

Each feature must have its own provider layer.

Examples:
- `profile` owns profile providers
- `diary` owns diary providers
- `medication` owns medication providers
- `ml_questionnaire` owns ML questionnaire providers
- `ml_assessment` owns ML assessment providers
- `ml_recommendation` owns ML recommendation providers

Rule:
- do not put unrelated API methods into one giant provider file

### 3. Shared infrastructure stays in `core`

Only truly shared code belongs in `core`, such as:
- API client / Dio base configuration
- interceptors / logging
- storage helpers
- app-wide constants
- routing config
- shared UI primitives
- generic utilities

Important:
- `dioProvider` should eventually live in `core`, not inside a feature provider file

### 4. Dashboard is a shell, not a domain dump

The `dashboard` feature should eventually become mostly:
- app shell
- tab scaffolding
- home composition
- navigation entry points

It should not own the data layer for profile, diary, medication, ML, and other unrelated domains.

## Recommended Target Folder Structure

```text
lib/
|-- core/
|   |-- config/
|   |-- constants/
|   |-- network/
|   |-- storage/
|   |-- ui/
|   |-- utils/
|   `-- widgets/
|
|-- features/
|   |-- auth/
|   |   |-- data/
|   |   |   |-- datasources/
|   |   |   |-- models/
|   |   |   `-- repositories/
|   |   |-- domain/
|   |   |   |-- entities/
|   |   |   |-- repositories/
|   |   |   `-- usecases/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- dashboard_shell/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- home_dashboard/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- profile/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- emergency_contacts/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- diary/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- medication/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- ml_questionnaire/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- ml_assessment/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- ml_recommendation/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- reports/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   `-- health_connect/
|       |-- data/
|       |-- domain/
|       `-- presentation/
|           |-- pages/
|           |-- providers/
|           `-- widgets/
|
|-- injection_container.dart
`-- main.dart
```

This structure is the target direction. We can adjust feature names slightly during the refactor if a better boundary becomes obvious, but the rule stays the same: one feature, one ownership boundary.

## How Current Code Maps To Future Features

The current `dashboard` folder should eventually be split roughly like this:

- profile-related pages/providers -> `features/profile`
- emergency contact pages/providers -> `features/emergency_contacts`
- diary pages/providers -> `features/diary`
- medication reminder pages/providers -> `features/medication`
- ML questionnaire flow -> `features/ml_questionnaire`
- ML assessment flow -> `features/ml_assessment`
- ML recommendation history/detail -> `features/ml_recommendation`
- report / print pages -> `features/reports`
- Health Connect integration -> `features/health_connect`
- tab shell / home shell -> `features/dashboard_shell`

If a screen mostly exists to compose data from multiple features, it can stay in a shell/composition feature, but the underlying providers should still live with their own domains.

## Data Flow We Want

The intended flow for each feature is:

1. UI listens to feature providers in `presentation/providers/`
2. provider calls a feature use case or repository contract
3. repository implementation lives in the feature `data/` layer
4. datasource talks to API / storage
5. models map raw data
6. domain entities move back up to presentation

Short version:

`page -> provider -> usecase/repository -> datasource -> API/storage`

Not this:

`random page -> dashboard/profile_provider.dart -> everything`

## Current App Notes That Still Matter

These are real implementation details that still matter right now, even before the refactor.

### Session keys

SharedPreferences keys currently used across the app:
- `auth_token`
- `auth_user_id`

App start logic in `lib/main.dart` uses those keys to choose:
- `/login`
- `/home`

It also clears the session if the JWT is expired.

### Routing

Routing is currently centralized in:
- `lib/core/config/routes.dart`

Important auth flow paths:
- `/login/register/profile-setup`
- `/login/register/ml-questionnaire`

For now, centralized routing is acceptable. The main architectural problem is provider/data ownership, not the route file itself.

### ML questionnaire mapping

The dynamic questionnaire mapping currently lives in:
- `lib/core/data/ml_mapping.dart`

Important behavior:
- fields are generated from `MlMapping.form_mapping`
- field keys use `<group>_<codeId>`
- `demog1` is used as an alias group for demographic keys

If ML questionnaire fields change in the future, this mapping must stay in sync.

### Navigation safety

Some flows already use:
- `WidgetsBinding.instance.addPostFrameCallback`

This is important for modal-dismiss + navigation flows to avoid lifecycle assertion issues. Keep that pattern where needed during future refactors.

### Audience and UX tone

PulseWise is a health app for older adults, so UI changes should favor clarity over novelty.

Design guidance:
- prefer calm, readable layouts over flashy or high-stimulation UI
- keep contrast clear, spacing generous, and text hierarchy obvious
- avoid overly eye-popping colors, dense information walls, or clever interactions that reduce usability
- prioritize larger touch targets and easy scanning, especially on health-related screens

### Local quality workflow

After every code edit:
- run `dart analyze`
- report whether the edit introduced any new issues
- if unrelated analyzer warnings already exist elsewhere in the repo, do not silently ignore them; mention that they are pre-existing

## Tech Stack

Current core stack in this repository:

- Flutter
- Dart
- flutter_riverpod
- go_router
- dio
- flutter_dotenv
- hive / hive_flutter
- shared_preferences
- another_flushbar
- file_picker
- open_file
- flutter_pdfview
- syncfusion_flutter_pdfviewer
- permission_handler
- device_info_plus
- google_sign_in
- image_cropper
- jwt_decoder

## Refactor Guidance For Future Work

When we start the actual refactor later, follow this order:

1. move shared networking setup out of `profile_provider.dart` into `core`
2. split `profile_provider.dart` by domain responsibility
3. move pages/widgets/providers into their feature folders
4. keep refactors incremental and working at every step
5. do not rewrite the whole app in one pass

## Rules For Future Agents

- do not add new unrelated API methods into `features/dashboard/presentation/providers/profile_provider.dart`
- prefer creating or using a provider inside the correct feature instead
- if a new feature is introduced, give it its own folder with its own layers
- if something is truly shared, move it to `core`, not to `dashboard`
- preserve existing app behavior unless the task explicitly asks for product changes

## Summary

PulseWise is currently in a transitional architecture.

What it is now:
- partially feature-based
- still too centralized around `dashboard/profile_provider.dart`

What it should become:
- truly feature-first
- clean provider ownership
- clean data ownership
- shared infra in `core`
- one feature folder per domain
