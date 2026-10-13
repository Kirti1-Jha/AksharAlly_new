# aksharally_ui

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Account onboarding sync

Onboarding completion and reading preferences are stored in the signed-in
user's Cloud Firestore document at `userProfiles/{uid}`. Enable Cloud Firestore
in the Firebase project used by this app, then deploy the included rules from
this directory:

```sh
firebase deploy --only firestore:rules --project YOUR_FIREBASE_PROJECT_ID
```

The rules allow a signed-in user to read or update only their own profile and
deny profile listing and deletion. If Firestore is unavailable or its rules
have not been deployed, the app will show a retry state instead of treating a
device-local completion flag as the account's source of truth.
