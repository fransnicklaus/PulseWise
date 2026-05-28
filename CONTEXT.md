# PulseWise Context

This document is the working source of truth for PulseWise.

It describes:
- the real state of the codebase today
- the target architecture we want to move toward
- the rules future refactors should follow

Important: PulseWise is no longer in the old `dashboard/profile_provider.dart` phase. The patient-side refactor has already landed, and the app is now role-aware with both patient and doctor flows. This document should guide future work from that newer baseline, especially because an `admin` role is likely next.

## Current Reality

The project already uses Flutter + Riverpod + go_router and is now mostly organized by feature.

Today:
- `lib/features/auth` is a shared feature for login / registration / OTP flows.
- patient flows live under role-neutral patient-owned features such as:
  - `dashboard_shell`
  - `home_dashboard`
  - `profile`
  - `diary`
  - `medication`
  - `ml_questionnaire`
  - `ml_assessment`
  - `ml_recommendation`
  - `reports`
  - `health_connect`
  - `emergency_contacts`
  - `food_analysis`
- doctor flows now live in:
  - `lib/features/doctor_shell`
  - `lib/features/doctor`
- centralized patient legacy files like `lib/features/dashboard/presentation/providers/profile_provider.dart` are gone.

That means the codebase is no longer "fake feature-first". It now has real feature ownership for patient and doctor, but it is still early in its multi-role architecture.

## Main Architecture Problem To Solve Next

The main problem is no longer one giant provider file.

The next architectural challenge is role growth:
- patient is implemented
- doctor is implemented
- admin is likely next

So the main thing future work must protect is:
- shared auth stays shared
- each role gets its own shell
- each role gets its own role-specific feature area
- patient, doctor, and admin should not drift back into one mixed "dashboard" bucket

## Current Role Model

Right now the app behaves like this:

- shared auth decides the user role from the login response
- session stores:
  - `auth_token`
  - `auth_user_id`
  - `auth_role`
- app startup chooses home by role:
  - patient -> `/home`
  - doctor -> `/doctor/home`
- the doctor app already has its own bottom-nav shell and feature modules

This pattern should be preserved and extended for any new role.

## Target Architecture

The target is a real feature-first, role-aware architecture:

- every feature owns its own folder
- every feature owns its own providers
- every feature owns its own API/data access layer
- `core` only contains shared cross-feature infrastructure
- each app role gets its own shell and role-specific entry flow

We are not doing a big rewrite from scratch. From this point on, this is the architecture future work should move toward.

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
- `profile` owns patient profile providers
- `doctor` owns doctor patient-monitoring providers
- `diary` owns diary providers
- `medication` owns medication providers
- `ml_questionnaire` owns ML questionnaire providers
- `ml_assessment` owns ML assessment providers
- `ml_recommendation` owns patient ML recommendation providers

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

Examples already living here:
- role constants
- session storage
- shared Dio / API setup

### 4. Shells are shells, not domain dumps

Shell features should mostly contain:
- app shell
- tab scaffolding
- role home composition
- role navigation entry points

Shells should not own the data layer for unrelated business domains.

Current examples:
- `dashboard_shell` -> patient shell
- `doctor_shell` -> doctor shell

Future example:
- `admin_shell` -> admin shell

### 5. Role boundaries matter

Auth is shared, but role features are not.

Rules:
- patient-only business logic should not be placed in `doctor`
- doctor-only business logic should not be placed in patient features
- future admin logic should not be added into `doctor` or patient features just because it is "also dashboard"
- if multiple roles need the same low-level helper, move that helper to `core`

### 6. Use role shells as the scaling pattern

For new roles, follow the same structure:

- shared auth resolves the role
- session persists the role
- router sends the user to that role's shell
- that role gets its own feature root

For `admin`, the expected pattern should be:
- `/admin/home`
- `features/admin_shell`
- `features/admin`

## Recommended Target Folder Structure

```text
lib/
|-- core/
|   |-- config/
|   |-- constants/
|   |-- data/
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
|   |-- dashboard_shell/        # patient shell
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- home_dashboard/         # patient home composition
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- profile/
|   |-- emergency_contacts/
|   |-- diary/
|   |-- medication/
|   |-- ml_questionnaire/
|   |-- ml_assessment/
|   |-- ml_recommendation/
|   |-- reports/
|   |-- health_connect/
|   |-- food_analysis/
|   |
|   |-- doctor_shell/
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   |-- doctor/
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
|   |-- admin_shell/            # planned next
|   |   |-- data/
|   |   |-- domain/
|   |   `-- presentation/
|   |       |-- pages/
|   |       |-- providers/
|   |       `-- widgets/
|   |
|   `-- admin/                  # planned next
|       |-- data/
|       |-- domain/
|       `-- presentation/
|           |-- pages/
|           |-- providers/
|           `-- widgets/
|
`-- main.dart
```

Notes:
- patient features are not wrapped inside `features/patient/` right now
- that is acceptable as long as ownership remains clear
- doctor and future admin should follow the explicit `role_shell + role` pattern

## How Current Code Maps To Role Boundaries

### Shared

- auth / login / OTP / register -> `features/auth`
- routing -> `core/config/routes.dart`
- role/session/bootstrap -> `core/constants`, `core/storage`, `main.dart`

### Patient-owned

- patient tab shell / app shell -> `features/dashboard_shell`
- patient home dashboard -> `features/home_dashboard`
- patient profile -> `features/profile`
- emergency contacts -> `features/emergency_contacts`
- diary -> `features/diary`
- food analysis -> `features/food_analysis`
- medication reminder pages/providers -> `features/medication`
- ML questionnaire flow -> `features/ml_questionnaire`
- ML assessment flow -> `features/ml_assessment`
- ML recommendation history/detail -> `features/ml_recommendation`
- report / print pages -> `features/reports`
- Health Connect integration -> `features/health_connect`

### Doctor-owned

- doctor bottom-nav shell -> `features/doctor_shell`
- doctor profile -> `features/doctor`
- doctor QR scan / patient selection -> `features/doctor`
- doctor patient dashboard -> `features/doctor`
- doctor prediction + recommendation history -> `features/doctor`

### Planned admin-owned

When admin starts, it should not be mixed into `doctor_shell` or patient shells.

Expected ownership:
- admin app shell -> `features/admin_shell`
- admin business pages/providers -> `features/admin`

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

`random role page -> some unrelated feature provider -> everything`

## Current App Notes That Still Matter

These are real implementation details that still matter right now.

### Session keys

SharedPreferences keys currently used across the app:
- `auth_token`
- `auth_user_id`
- `auth_role`

App start logic in `lib/main.dart` uses those keys to choose:
- `/login`
- `/home`
- `/doctor/home`

Future expectation:
- `/admin/home`

It also clears the session if the JWT is expired.

### Routing

Routing is currently centralized in:
- `lib/core/config/routes.dart`

Important current role entry paths:
- patient -> `/home`
- doctor -> `/doctor/home`

Important auth flow paths:
- `/login/register/profile-setup`
- `/login/register/ml-questionnaire`

Centralized routing is still acceptable. The main thing to protect is ownership by feature and by role.

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
- fl_chart
- mobile_scanner

## Refactor Guidance For Future Work

When future role work continues, follow this order:

1. keep shared auth and shared infra in `core` / `auth`
2. add a new role shell before adding lots of role pages
3. add a role root feature for that role's domain pages/providers
4. keep feature ownership incremental and working at every step
5. do not collapse patient, doctor, and admin into one dashboard layer

## Rules For Future Agents

- do not reintroduce a giant shared provider for unrelated domains
- prefer creating or using a provider inside the correct feature instead
- if a new role is introduced, give it:
  - a role shell
  - a role feature root
  - a route namespace
- if something is truly shared, move it to `core`, not to patient or doctor features
- preserve existing app behavior unless the task explicitly asks for product changes

## Summary

PulseWise is now:
- feature-first for patient flows
- role-aware for patient and doctor
- ready to scale to more roles if we stay disciplined

What it should become next:
- patient remains stable
- doctor continues inside `doctor_shell` + `doctor`
- admin should follow the same role-shell pattern
- shared infra stays in `core`
- one feature boundary per domain
- one shell boundary per role
