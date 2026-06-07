# Developer Context & Refactoring Instructions: Medical to Wellness Re-scoping

## Context & Background
We are preparing an undergraduate thesis (S1 Information Systems) mobile health application for publication on the Google Play Store. Due to policy constraints, the app must be published using a **Personal Developer Account**. 

Google Play Store strictly regulates health applications on personal accounts. Apps that claim to diagnose, treat, or manage specific medical conditions (especially chronic or clinical conditions like cardiovascular diseases) are heavily scrutinized and routinely rejected unless published by a verified healthcare organization. 

To ensure successful publication, we are **re-scoping the application from a clinical medical utility into a general wellness and lifestyle tracking application**. Your task is to refactor the Flutter codebase, UI text, and configurations to reflect this change completely.

---

## 1. Contextual Terminology & Copywriting Refactoring
You must scan the entire codebase (Dart files, JSON localization files, UI strings, asset names, and `pubspec.yaml`) to replace clinical or disease-specific language with neutral lifestyle language.

| High-Risk Clinical Context (BANNED) | Safe Wellness Context (APPROVED) |
| :--- | :--- |
| Cardiovascular, CVD, Heart Disease | Wellness, General Health, Fitness |
| Patient | User, Member |
| Treatment, Therapy, Prescription | Routine, Daily Habits, Lifestyle Plan |
| Diagnosis, Medical Record | Health Diary, Personal Logs, Progress Tracker |
| Symptom Management, Clinical Data | Activity Logs, Daily Well-being |
| Prevent, Cure, Mitigate | Track, Maintain, Improve |

**Agent Action:** Update all text widgets, tooltips, hints, and descriptions. Ensure the app name and metadata contain absolutely no references to managing a specific chronic illness.

---

## 2. UI & Interaction Logic Adjustments
The app's interface must not look like a diagnostic tool or a clinical monitoring system. 

* **Remove Warning Thresholds:** If the current code contains logic that highlights data in red or triggers alerts when readings look abnormal (e.g., flagging high blood pressure or abnormal heart rates as "Dangerous" or prompting "Seek Medical Attention"), remove or refactor this logic.
* **Neutral Data Presentation:** Instead of assessing the user's health state, the UI should simply display the recorded numbers neutrally (e.g., "Logged Value: 120/80"). Let the user view their data without the system interpreting it for them.

---

## 3. Implementation of Mandatory Medical Disclaimers
To legally and policy-wise protect the personal account status, the app must explicitly state it is not a medical tool.

* **Agent Action:** Create or modify an onboarding screen, a prominent section on the Home Dashboard, and the "About App" settings page to display a mandatory disclaimer.
* **Disclaimer Text:** 
  > "This application is designed for informational and lifestyle tracking purposes only. It is not intended for medical use, diagnosis, or treatment, and should not replace professional medical advice."

---

## 4. Verification Checklist Before Compilation
Before completing the task, verify the following files do not leak clinical context:
1. `pubspec.yaml` (Check the `description:` field)
2. `android/app/src/main/AndroidManifest.xml` (Ensure labels and package names don't conflict with the wellness scope)
3. All localization or string constants files.