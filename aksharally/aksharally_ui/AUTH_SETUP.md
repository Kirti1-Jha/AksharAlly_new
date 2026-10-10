# Authentication setup

The app now uses Firebase Auth for email/password, Google, and Apple
authentication. Provider credentials and platform registration must be supplied
in the Firebase and Apple developer consoles; they are intentionally not
hard-coded in the repository.

## Firebase

1. In Firebase Authentication, enable **Email/Password**, **Google**, and
   **Apple** under Sign-in providers.
2. Register the Android application with package name
   `com.example.aksharally_ui` and add its SHA-1/SHA-256 fingerprints.
3. Download the Android Firebase configuration as
   `android/app/google-services.json`.
4. Configure the iOS bundle identifier in Firebase and run FlutterFire
   configuration to generate the iOS section of `lib/firebase_options.dart`
   and add `ios/Runner/GoogleService-Info.plist`.

The current repository includes Android and web Firebase options, but does not
include iOS Firebase configuration. iOS startup/authentication will remain
unavailable until that platform configuration is added.

## Apple

For iOS, enable the **Sign in with Apple** capability for the Runner target and
configure the matching App ID and Firebase Apple provider (Team ID, Key ID, and
private key) in the consoles.

For Android or web, Apple requires an Apple Service ID and HTTPS redirect URI.
Pass them as build-time values:

```text
flutter run \
  --dart-define=APPLE_SERVICE_ID=your.service.id \
  --dart-define=APPLE_REDIRECT_URI=https://your-domain.example/callback
```

The redirect URI must be registered with Apple and match the value used by the
sign-in flow. These values are configuration, not secrets, but the Apple
private key must stay in Firebase/provider configuration and never be committed.