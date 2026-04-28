# Project Context & Tech Stack

This document outlines the technology stack and architectural structure used in this Flutter project. It can serve as a reference for setting up or structuring new Flutter applications with a similar architecture.

## 🛠️ Tech Stack

### SDKs & Core
*   **Flutter**: Framework for building the UI and application logic.
*   **Dart**: Programming language used.

### State Management & Dependency Injection
*   **[flutter_riverpod](https://pub.dev/packages/flutter_riverpod)**: The primary state management and dependency injection solution. It's used for providing data sources, repositories, use cases, and managing UI state (e.g., `StateNotifier`, `Notifier`).

### Routing
*   **[go_router](https://pub.dev/packages/go_router)**: Used for declarative routing and deep linking. Routes are typically defined centrally (e.g., `lib/core/config/routes.dart`).

### Networking & API
*   **[dio](https://pub.dev/packages/dio)**: HTTP client for making API requests. Usually enveloped in an interceptor or customized client (`lib/core/network/api_client.dart`) to handle tokens, logging, and error catching.
*   **[flutter_dotenv](https://pub.dev/packages/flutter_dotenv)**: For managing environment variables (like Base URL) via `.env` files.

### Data Modeling & Serialization
*   **[json_serializable](https://pub.dev/packages/json_annotation)**:

### Local Storage & Caching
*   **[hive](https://pub.dev/packages/hive) & hive_flutter**: A lightweight, fast, NoSQL local database used for caching responses and storing light user data/preferences.
*   **[flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)** (implied via `secure_storage_service.dart`): Typically used for storing sensitive data like JWT tokens.

### UI & Styling
*   **Material Design 3**: Core Flutter widgets.
*   **Fonts**: Custom font implementation
*   **Icons**: [heroicons](https://pub.dev/packages/heroicons), [fluentui_system_icons](https://pub.dev/packages/fluentui_system_icons).
*   **Notifications/Toasts**: [another_flushbar](https://pub.dev/packages/another_flushbar) for custom toast notifications.

### Utility Plugins
*   **File Handling**: [file_picker](https://pub.dev/packages/file_picker), [open_file](https://pub.dev/packages/open_file).
*   **Viewing Documents**: [flutter_pdfview](https://pub.dev/packages/flutter_pdfview), [syncfusion_flutter_pdfviewer](https://pub.dev/packages/syncfusion_flutter_pdfviewer).
*   **Device Info & Permissions**: `device_info_plus`, `permission_handler`.

---

## 🏗️ Project Architecture (Feature-First Clean Architecture)

The project follows a modular, feature-based "Clean Architecture" variation. The `lib/` directory is structured to group code by feature rather than by layer, ensuring better scalability.

```text
lib/
├── core/                   # Shared utilities, configs, and base classes applicable app-wide
│   ├── config/             # App configs (routing, styling/themes)
│   ├── constants/          # App constants, API endpoints
│   ├── network/            # ApiClient, Interceptors
│   ├── storage/            # Local DB / Secure Storage setups
│   ├── ui/                 # Reusable widgets, icon mappers, colors
│   └── utils/              # Helper functions (date formatting, validators)
│
├── features/               # Contains individual domains/features
│   ├── auth/               # Example Feature: Authentication
│   │   ├── data/
│   │   │   ├── datasources/   # Remote (Dio) and Local (Hive) data sources
│   │   │   ├── models/        # DTOs (Data Transfer Objects), JSON models
│   │   │   └── repositories/  # Repository implementations calling data sources
│   │   │
│   │   ├── domain/
│   │   │   ├── entities/      # Core business objects
│   │   │   ├── repositories/  # Abstract repository interfaces contracts
│   │   │   └── usecases/      # Business logic handlers (optional but used)
│   │   │
│   │   └── presentation/   
│   │       ├── bloc/          # Riverpod State Notifiers/Providers for this feature
│   │       ├── pages/         # UI Screens/Pages
│   │       └── widgets/       # UI Widgets specific to this feature
│   │
│   ├── dashboard/          # Another Feature
│   ├── draft/              # Another Feature
│   └── ...
│
├── injection_container.dart # Centralized place defining Riverpod Providers (DI context)
└── main.dart                # App entry point, ProviderScope initialization
```

### 🔁 The Data Flow
1. **Presentation Layer (UI)** listens to **Riverpod Providers** (`StateNotifier` / `AsyncNotifier`).
2. **Provider** triggers a **Use Case** (or directly calls a Repository interface) when an action occurs.
3. **Repository Definition (Domain)** is an abstraction. Its implementation is in the Data Layer.
4. **Repository Implementation (Data)** decides whether to fetch data from the **Remote Data Source** (API) or **Local Data Source** (Hive/Cache).
5. **Data Source** returns a **Model** (JSON mapping), which the Repository maps to a Domain **Entity**.
6. The Provider updates its state with the new Entity or Error, and the UI reacts immediately.

---

## 📌 App-Specific Implementation Notes (Current)

These notes describe real, current behavior in this repository and should be treated as the default reference for future agent changes.

### Authentication Session Keys
- SharedPreferences keys used across features:
	- `auth_token`
	- `auth_user_id`
- App start decides initial route from those keys in `main.dart` (`/login` vs `/home`) and checks token expiration.

### Routing Details (go_router)
- Main route tree is in `lib/core/config/routes.dart`.
- Important auth flow paths:
	- `/login/register/profile-setup`
	- `/login/register/ml-questionnaire`
- `profile-setup` and `ml-questionnaire` expect `state.extra` map with:
	- `auth_token`
	- `auth_user_id`
	If either is missing, route falls back to `LoginPage`.

### ML Questionnaire (Dynamic + Editable)
- Core mapping source: `lib/core/data/ml_mapping.dart`.
- Form fields are rendered dynamically from `MlMapping.form_mapping`.
- Field key format is composite: `<group>_<codeId>` (example: `demog1_riagendr`).
- `MlMapping` includes helpers for parsing and validation:
	- `getGroupFromFieldKey`
	- `getCodeIdFromFieldKey`
	- `isValidFieldKey`
	- `getOptions`
- `codeMaps` contains alias `demog1` for demographic keys used by ML form.

### ML Profile API Integration
- Provider/API location: `lib/features/dashboard/presentation/providers/profile_provider.dart`.
- Existing APIs in use:
	- `fetchMlProfile(token, patientId)` → `GET /patients/{patientId}/ml-profile`
	- `submitMlProfile(token, patientId, payload)` → `PUT /patients/{patientId}/ml-profile`
- `fetchMlProfile` returns empty map on 404 so first-time users can still fill the form.

### ML Questionnaire Screen Behavior
- Screen file: `lib/features/auth/presentation/pages/ml_questionnaire_page.dart`.
- On open:
	1. Calls `fetchMlProfile`.
	2. Prefills dropdown answers from API data when valid.
	3. Shows full loading screen while initial fetch is in progress.
- On submit:
	- Validates all dynamic fields are answered.
	- Sends payload with dynamic keys from `MlMapping.form_mapping`.

### Navigation Safety Pattern (Important)
- To avoid navigator lifecycle assertion errors during modal/route transitions, some flows defer navigation using `WidgetsBinding.instance.addPostFrameCallback` (for example in profile/logout and post-submit flows).
- When adjusting modal + navigation logic, keep this safety pattern.

### Profile Area Notes
- Profile tab file: `lib/features/dashboard/presentation/pages/tabs/profil_tab.dart`.
- Includes:
	- Pull-to-refresh for profile and emergency contacts.
	- Avatar upload with `file_picker` + `image_cropper` (circle crop).
	- Logout confirmation bottom sheet.
	- Shortcut button to ML questionnaire.

### Practical Agent Guidance For This Repo
- Prefer reusing Riverpod providers/APIs from feature providers before adding local `Dio` instances in UI pages.
- Keep existing Indonesian UI copy tone and current red-pink color direction unless explicitly asked to redesign.
- Before changing ML fields/options, update `MlMapping.form_mapping` and verify group/code keys exist in `codeMaps`.
