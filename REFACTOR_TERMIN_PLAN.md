# PulseWise Full Refactor Termin Plan

This file is the practical roadmap for splitting PulseWise into the feature
structure described in `CONTEXT.md`.

Important clarification:

This plan is **not only** about breaking up
`lib/features/dashboard/presentation/providers/profile_provider.dart`.

This plan is about refactoring the **entire current dashboard-heavy structure**
so pages, widgets, providers, models, and API access move into proper feature
folders.

## Goal

Move the app from this current reality:

- `features/dashboard` owns too many unrelated domains
- many features still live physically inside the dashboard folder
- `profile_provider.dart` is the biggest bottleneck, but not the only one

To this target direction:

- `dashboard_shell` becomes shell/navigation only
- real features live in their own folders
- each feature owns its pages, widgets, providers, models, and API access
- `core` only holds truly shared infrastructure

## Current Codebase Snapshot

Current feature folders:

- `features/auth`
- `features/dashboard`
- `features/food_analysis`
- `features/medication`

Current dashboard load:

- `26` page files under `lib/features/dashboard/presentation/pages`
- `3` widget files under `lib/features/dashboard/presentation/widgets`
- `8` provider files under `lib/features/dashboard/presentation/providers`

Current provider bottleneck:

- `profile_provider.dart` is about `2621` lines
- it currently exposes about `40` async methods
- it is still imported by `25` files in `lib/`

So the real problem is two layers at once:

1. API/data ownership is too centralized in `profile_provider.dart`
2. physical folder ownership is still too centralized in `features/dashboard`

## What Needs To Be Split

The current `dashboard` feature is still acting like all of these at once:

- dashboard shell
- home composition
- profile
- emergency contacts
- diary
- medication/reminders
- health connect
- ML assessment
- ML recommendation history
- reports/print

That means the refactor needs to move both:

- **logic ownership**
- **file ownership**

## Current To Target Ownership Map

This is the recommended direction for the current files.

### Dashboard Shell

Target folder:
- `features/dashboard_shell`

Likely current files:
- `dashboard_page.dart`
- `home_page.dart`
- `dashboard_provider.dart`

Responsibility after refactor:
- tab shell
- app-level patient navigation entry points
- no domain API ownership

### Home Dashboard / Composition

Target folder:
- `features/home_dashboard`

Likely current files:
- `tabs/beranda_tab.dart`
- `patient_dashboard_page.dart`
- `patient_flutter.dart`
- possibly `tabs/edukasi_tab.dart` if it remains just a home-facing section

Responsibility after refactor:
- compose data from other features
- no direct ownership of profile/diary/medication/ML APIs

### Profile

Target folder:
- `features/profile`

Likely current files:
- `update_profile_page.dart`
- `tabs/profil_tab.dart`
- profile-specific parts of `profile_provider.dart`
- profile-related models now defined in `profile_provider.dart`

Responsibility after refactor:
- patient profile
- auth-me display data if still profile-owned
- avatar upload/save

### Health Connect

Target folder:
- `features/health_connect`

Likely current files:
- `health_connect_page.dart`
- health-connect-specific parts of profile/update flows

Responsibility after refactor:
- Health Connect preference/status
- sync setup UI

### Emergency Contacts

Target folder:
- `features/emergency_contacts`

Likely current files:
- `contacts_page.dart`
- `emergency_contacts_provider.dart`

Responsibility after refactor:
- contacts list
- add/edit/delete/primary contact

### Diary

Target folder:
- `features/diary`

Likely current files:
- `add_diary_page.dart`
- `detail_diari_page.dart`
- `riwayat_diari_page.dart`
- `tabs/diari_tab.dart`
- `diary_section_bottom_sheet.dart`
- `current_diary_provider.dart`
- `diary_history_provider.dart`
- diary models now defined inside `profile_provider.dart`

Possibly diary-owned too:
- `diary_qr_page.dart`
- `qr_scanner_page.dart`

Responsibility after refactor:
- diary history
- diary detail
- body metrics
- symptoms
- activities
- sleep
- consumption save flows

### Food Analysis

Target folder:
- `features/food_analysis`

Current files already here:
- `food_nutrition_estimate_api.dart`
- `food_macro_analysis.dart`
- `food_macro_camera_page.dart`
- `manual_food_macro_entry_page.dart`
- `food_nutrition_estimate_api_provider.dart`

Open decision:
- keep this as a standalone feature
- or treat it as a diary-consumption sub-feature with its own module

### Medication

Target folder:
- `features/medication`

Likely current files still trapped in dashboard:
- `add_pengingat_page.dart`
- `detail_pengingat_page.dart`
- `edit_pengingat_page.dart`
- `manage_pengingat_page.dart`
- `tabs/pengingat_tab.dart`
- `medication_calendar_provider.dart`
- `medication_history_provider.dart`
- `medication_consumption_tracking_card.dart`
- `medication_status_bottom_sheet.dart`

Current files already here:
- `manual_medication_reminder_notification_api.dart`
- related manual reminder response/provider files

Responsibility after refactor:
- reminder CRUD
- medication list/detail/history
- medication logs/calendar
- take medication / status updates
- reminder-related notification helpers if medication-specific

### ML Questionnaire

Target folder:
- `features/ml_questionnaire`

Likely current files:
- `auth/presentation/pages/ml_questionnaire_page.dart`
- ML questionnaire methods now inside `profile_provider.dart`

Responsibility after refactor:
- fetch/submit ML profile questionnaire
- preserve `MlMapping` contract

### ML Assessment

Target folder:
- `features/ml_assessment`

Likely current files:
- `patient_ml_assessment_page.dart`
- readiness/prediction/assessment parts of `patient_flutter.dart`
- ML assessment methods now inside `profile_provider.dart`
- `core/data/ml_readiness_mapping.dart` may stay shared or move here later

Responsibility after refactor:
- assessment CRUD
- readiness checks
- prediction request orchestration if owned by assessment flow

### ML Recommendation

Target folder:
- `features/ml_recommendation`

Likely current files:
- `ml_recommendation_history_page.dart`
- `recommendation_history_provider.dart`
- recommendation parts of `patient_flutter.dart`
- recommendation methods now inside `profile_provider.dart`

Responsibility after refactor:
- latest recommendation
- recommendation history
- recommendation detail

### Reports

Target folder:
- `features/reports`

Likely current files:
- `print_page.dart`
- `report_generator_flutter.dart`

Responsibility after refactor:
- patient report generation
- printable report flows

### Temporary / Ambiguous Cases

These need explicit decisions during refactor:

- `fcm_token_page.dart`
  - likely move to a debug/devtools area or profile/settings area
- `diary_qr_page.dart` and `qr_scanner_page.dart`
  - likely diary-owned unless product direction changes
- `patient_flutter.dart`
  - likely becomes a composition page in `home_dashboard`
- `tabs/edukasi_tab.dart`
  - may stay home-dashboard-owned or become its own education feature later

## Refactor Principles

- refactor by ownership boundary, not by random file batches
- move API/datasource ownership before deep UI cleanup
- keep routes stable at first unless route changes are the actual goal
- keep each termin releasable
- avoid one giant “dashboard to everything” branch

## Recommended Termin Sequence

The sequence below is designed for minimal breakage and clearer review.

## Termin 1 - Shared Foundations and Folder Skeletons

Goal:
- prepare the repo for full feature extraction

Scope:
- finish consolidating on `core/network`
- remove the need for future features to depend on dashboard-owned Dio setup
- extract shared session helpers for `auth_token` and `auth_user_id`
- create missing feature folders from `CONTEXT.md` with basic structure
  - `dashboard_shell`
  - `home_dashboard`
  - `profile`
  - `emergency_contacts`
  - `diary`
  - `ml_questionnaire`
  - `ml_assessment`
  - `ml_recommendation`
  - `reports`
  - `health_connect`

Done when:
- new features have a place to move into
- `core` owns shared networking/session plumbing

## Termin 2 - Dashboard Shell and Home Composition Split

Goal:
- make `dashboard` stop being the default place for everything

Scope:
- move shell-only pieces into `features/dashboard_shell`
- move composition/home pages into `features/home_dashboard`
- keep domain logic out of these moved pages as much as possible
- likely touch:
  - `dashboard_page.dart`
  - `home_page.dart`
  - `dashboard_provider.dart`
  - `tabs/beranda_tab.dart`
  - `patient_dashboard_page.dart`
  - `patient_flutter.dart`
  - `tabs/edukasi_tab.dart`

Done when:
- shell/composition files are separated from domain feature files
- `features/dashboard` is no longer the default home for unrelated pages

## Termin 3 - Profile and Health Connect

Goal:
- extract user profile ownership first

Scope:
- create feature-owned profile datasource/provider/model flow
- move avatar flows
- move profile UI files
- move health connect into its own feature
- likely touch:
  - `update_profile_page.dart`
  - `tabs/profil_tab.dart`
  - `health_connect_page.dart`
  - profile/health-connect methods from `profile_provider.dart`

Done when:
- profile and health connect are no longer dashboard-owned

## Termin 4 - Emergency Contacts

Goal:
- fully extract a relatively isolated domain

Scope:
- move contacts page/provider/API ownership into `features/emergency_contacts`
- replace dashboard/provider dependencies with feature-owned plumbing

Done when:
- emergency contacts are fully out of `dashboard`

## Termin 5 - Diary Core

Goal:
- extract diary as a real feature before dealing with nutrition/photo extras

Scope:
- move diary read/history/detail ownership
- move body metrics, symptoms, activities, and sleep
- move diary models out of `profile_provider.dart`
- move diary pages/providers/widgets into `features/diary`
- likely touch:
  - `add_diary_page.dart`
  - `detail_diari_page.dart`
  - `riwayat_diari_page.dart`
  - `tabs/diari_tab.dart`
  - `current_diary_provider.dart`
  - `diary_history_provider.dart`

Done when:
- diary core no longer depends on dashboard-owned profile API logic

## Termin 6 - Consumption and Food Analysis Boundary

Goal:
- finish the diary split by cleaning up consumption ownership

Scope:
- separate diary consumption save flow from generic dashboard glue
- decide permanent boundary between `diary` and `food_analysis`
- move any remaining consumption-specific logic out of dashboard widgets
- likely touch:
  - `diary_section_bottom_sheet.dart`
  - food analysis pages/providers/models
  - consumption methods currently inside `profile_provider.dart`

Done when:
- consumption capture is clearly owned
- food analysis is either standalone-by-choice or clearly nested by design

## Termin 7 - Medication and Reminder Feature Extraction

Goal:
- move the full reminder domain into `features/medication`

Scope:
- move all medication/reminder pages out of dashboard
- move calendar/list/detail/history providers and API logic
- move reminder widgets and bottom sheets
- likely touch:
  - `add_pengingat_page.dart`
  - `detail_pengingat_page.dart`
  - `edit_pengingat_page.dart`
  - `manage_pengingat_page.dart`
  - `tabs/pengingat_tab.dart`
  - `medication_calendar_provider.dart`
  - `medication_history_provider.dart`
  - medication widgets under dashboard

Done when:
- medication flows are feature-owned end to end

## Termin 8 - ML Questionnaire

Goal:
- remove ML questionnaire ownership from dashboard/profile code

Scope:
- move ML questionnaire API/provider logic into `features/ml_questionnaire`
- keep auth route entry points stable
- keep `MlMapping` compatibility intact

Done when:
- questionnaire flow is feature-owned even if entered from auth routes

## Termin 9 - ML Assessment, Readiness, and Prediction

Goal:
- isolate assessment and prediction responsibilities

Scope:
- move ML assessment submit/update/save logic
- move readiness and prediction request orchestration
- reduce assessment-related complexity inside `patient_flutter.dart`
- likely touch:
  - `patient_ml_assessment_page.dart`
  - readiness/prediction methods in `profile_provider.dart`
  - parts of `patient_flutter.dart`

Done when:
- ML assessment is its own feature

## Termin 10 - ML Recommendation and Reports

Goal:
- extract patient decision-support and reporting

Scope:
- move latest recommendation/history/detail ownership
- move report/print ownership
- likely touch:
  - `ml_recommendation_history_page.dart`
  - `recommendation_history_provider.dart`
  - `print_page.dart`
  - `report_generator_flutter.dart`

Done when:
- recommendation and report flows are not dashboard-owned

## Termin 11 - Final Dashboard Cleanup

Goal:
- leave `dashboard` as a shell-only area or remove it entirely in favor of
  `dashboard_shell` and `home_dashboard`

Scope:
- remove leftover compatibility imports
- remove any remaining domain files from dashboard
- delete `profile_provider.dart` once all consumers are gone
- update routes/imports to final locations

Done when:
- domain features live in their own folders
- dashboard is shell/composition only
- `profile_provider.dart` no longer exists

## Suggested Output Per Termin

Each termin should ideally produce:

- folder moves
- feature-owned datasource(s)
- feature-owned provider(s)
- feature-owned model/entity placement
- updated page/widget imports
- `dart analyze` result

## Things Already Going In The Right Direction

These are good bases to keep building on:

- `features/auth`
- `features/food_analysis`
- `features/medication` partial slice
- `core/network/api_dio_provider.dart`
- `core/network/api_logger.dart`
- `core/network/app_connectivity_provider.dart`

## Things To Avoid

- do not treat this as only a `profile_provider.dart` cleanup
- do not move files physically without also moving ownership boundaries
- do not mix multiple big features into one unreviewable branch
- do not let new work keep landing inside `features/dashboard` unless it is
  truly shell/composition-only
