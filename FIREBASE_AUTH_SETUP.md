# Firebase Authentication Setup

The app now supports Firebase email/password sign-in and Google sign-in. Provider configuration is managed in the Firebase console and cannot be enabled by Flutter code alone.

## Enable the providers

1. Open Firebase Console → Authentication → Sign-in method.
2. Enable **Email/Password** and **Google**, then save.
3. For Android, add the debug and release SHA-1 fingerprints for the registered Android app in Firebase project settings. The Android package name must match `applicationId` in `android/app/build.gradle`.
4. For web, add each deployed host name to Authentication → Settings → Authorized domains.
5. For iOS, confirm the registered bundle ID matches the Xcode Runner target. The Google callback URL scheme is configured in `ios/Runner/Info.plist` from the iOS OAuth client ID in `lib/firebase_options.dart`.

## Existing Firestore records

The app now reads and writes financial records under `users/{uid}/DailyDataEntry` and `users/{uid}/BillPaymentEntry`. Existing root-level records need to be copied to the intended owner's UID before deploying the restrictive rules. This repository does not include Node.js migration tooling.

Before changing deployed rules:

1. Confirm the intended parlour-owner account and sign in once. Get that account's Firebase Auth UID from Firebase Console → Authentication → Users.
2. Back up Firestore. The managed export feature uses a Cloud Storage bucket and requires Blaze billing; see the [Firestore export and import guide](https://firebase.google.com/docs/firestore/manage-data/export-import).
3. Use an approved Firebase Admin migration process to copy the records without overwriting destination documents. Do not put administrator credentials in this repository.
4. Review record counts and conflicts. Sign into the app using the owner account and verify the migrated entries and totals. Check any additional Firestore collections before deploying `firestore.rules`, because the rules deny access to every path other than the signed-in user's `users/{uid}/...` path.
5. Once migration and review are complete, deploy the rules from the repository root with `firebase deploy --only firestore:rules`.

The rules are not deployed by this project change. Until an administrator migrates the existing records and deploys the rules, account-level Firestore isolation is not active in the live Firebase project.

## Profile photo storage

Profile photos are stored at `users/{uid}/profile/avatar.<extension>`. Enable Firebase Storage and confirm the project's default bucket is configured before using photo upload. The repository includes `storage.rules`; deploy them with:

```powershell
firebase deploy --only storage
```

The rules allow signed-in users to read and write only their own profile photo, and limit uploads to images smaller than 5 MB. The iOS photo-library usage description is included in `ios/Runner/Info.plist`.
