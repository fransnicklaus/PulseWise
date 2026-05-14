# PulseWise FCM Setup

This project now includes the client-side wiring for Firebase Cloud Messaging on Flutter/Android.

Recommended official setup from Firebase is still to run:

`flutterfire configure`

after creating your Firebase project. This repo currently initializes Firebase from the native platform config files, so the minimum Android requirement is still `android/app/google-services.json`.

## 1. Firebase Console

1. Create or open your Firebase project.
2. Add an Android app with this application ID:
   `com.rdib.pulsewise`
3. Download `google-services.json`.
4. Place it at:
   `android/app/google-services.json`

If you also want iOS later:

1. Add an iOS app in the same Firebase project.
2. Download `GoogleService-Info.plist`.
3. Place it at:
   `ios/Runner/GoogleService-Info.plist`
4. In Apple Developer, enable Push Notifications and Background Modes.
5. Upload your APNs key/certificate in Firebase Console.

## 2. What you need in Firebase for testing

For a quick device-token test:

1. A Firebase project
2. The Android app registered as `com.rdib.pulsewise`
3. `google-services.json` downloaded into `android/app/`
4. A physical device running the app
5. The FCM device token from the `FCM Device Token` page in the app

For the included Node.js sender script:

1. Go to `Project settings`
2. Open the `Service accounts` tab
3. Click `Generate new private key`
4. Save the JSON file somewhere safe outside source control

## 3. What is already wired in the repo

- Firebase initialization on app startup
- FCM token retrieval and persistence
- Foreground notification display via `flutter_local_notifications`
- Background message logging
- A debug page to view/copy/print the FCM token

## 4. Reminder feature note

FCM only gets the push to the device.
Your reminder backend still needs to:

1. Save each user's FCM token
2. Decide when a reminder should fire
3. Send the push payload to that token

## 5. Test flow

1. Add `google-services.json`
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run the app on a real Android device
5. Open `Profil` -> `FCM Device Token`
6. Copy the token
7. Use `scripts/send_fcm_test.js` to send a test push
