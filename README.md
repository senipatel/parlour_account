# Parlour Account

A Flutter app for parlour income and expenses, bills and payments, customers, appointments, and financial reports. Firebase Authentication and Cloud Firestore provide account sign-in and owner-scoped records.

## Features

- Email/password and Google sign-in, account creation, password reset, and sign-out.
- Daily income and expense entries with exact paise storage.
- Bill/vendor records with cash/online partial payments, due dates, and outstanding balances.
- Customer contacts and appointment booking, history, and status updates.
- Dashboard totals and monthly/custom date-range reports.
- CSV and PDF report sharing.
- Profile display name and photo, with a fixed navy and slate app theme.

## Requirements

- Flutter and Dart matching the SDK constraints in `pubspec.yaml`.
- A Firebase project configured for the desired platforms.
- Firebase Authentication providers enabled in Firebase Console.
- Firebase Storage enabled for profile-photo uploads.
- Firebase CLI for deploying Firestore and Storage rules.

## Local setup

1. Install Flutter and configure the target platform toolchain.
2. Confirm `lib/firebase_options.dart` and `android/app/google-services.json` point to the intended Firebase project. Do not replace owner-provided Firebase configuration without checking the project and app IDs.
3. In Firebase Console, enable Email/Password and Google under Authentication. Configure Android SHA fingerprints, iOS OAuth settings, and web authorized domains as applicable. See `FIREBASE_AUTH_SETUP.md`.
4. From the project root, run:

   ```powershell
   flutter pub get
   flutter run
   ```

5. Run local checks with:

   ```powershell
   flutter analyze
   flutter test
   ```

The Dart source is organized into `lib/screens`, `lib/providers`, `lib/services`, `lib/models`, and `lib/utils`. Shared widgets and formatters live under `lib/utils`.

## Demo data

Use a dedicated test Firebase project and test account. The seeder uses Firebase Authentication and the signed-in user's Firestore rules; it does not require Node.js or administrator credentials. First run a dry run:

```powershell
dart run tool/seed_demo_data.dart
```

Set `FIREBASE_PROJECT_ID`, `FIREBASE_WEB_API_KEY`, `FIREBASE_SEED_EMAIL`, and `FIREBASE_SEED_PASSWORD` in your local shell, then explicitly write the sample records:

```powershell
dart run tool/seed_demo_data.dart --apply --confirm-project your-test-project-id
```

The script creates 30 daily entries and three sample bills with a `demoSeedId` marker. Remove only those records with:

```powershell
dart run tool/seed_demo_data.dart --apply --cleanup --confirm-project your-test-project-id
```

## Firebase data and security

Financial data is stored under `users/{uid}/DailyDataEntry` and `users/{uid}/BillPaymentEntry`. Profile preferences, categories, customers, and appointments are stored under the same signed-in UID. Firestore and Storage rules are in `firestore.rules` and `storage.rules`.

Existing root-level `DailyDataEntry` and `BillPaymentEntry` documents must be backed up and copied to the selected owner's UID before deploying the restrictive Firestore rules. This repository does not include Node.js migration tooling; use an approved Firebase Admin migration process and verify the copied counts before deployment. Never commit administrator credentials. Inspect other existing Firestore collections and current rules before deployment.

After the migration and project review, deploy rules from the repository root:

```powershell
firebase deploy --only firestore:rules,storage
```

Until Firebase Console setup, the legacy data migration, and rules deployment are complete, live account isolation and profile-photo uploads are not confirmed.

## Release signing

Android release builds must use a production keystore. The release signing configuration reads the following environment variables:

- `PARLOUR_RELEASE_STORE_FILE`
- `PARLOUR_RELEASE_STORE_PASSWORD`
- `PARLOUR_RELEASE_KEY_ALIAS`
- `PARLOUR_RELEASE_KEY_PASSWORD`

Provide these through a protected local or CI secret store. Do not commit keystores, passwords, or signing properties. A release built without these values will not use the debug signing key and is not ready for distribution.

For local Android release builds, `android/app/build.gradle` also reads `android/key.properties` when the `PARLOUR_RELEASE_*` environment variables are unset. Keep the referenced keystore and this properties file private and backed up securely; losing the upload key can prevent future app updates. The local signing files are excluded by `.gitignore`.

## Work log

Implementation decisions, verification results, and external setup gates are tracked in `IMPLEMENTATION_PLAN.md` and `WORK_LOG.md`.
