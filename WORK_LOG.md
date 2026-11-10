# Work Process Log

This file tracks planning and implementation work for `IMPLEMENTATION_PLAN.md`. Append a dated entry after each meaningful work session. Record changes, decisions, verification, and next steps. Never include credentials or secrets.

## 2026-11-09 — Initial project review and plan drafted

- **Status:** Awaiting owner approval; implementation has not started.
- **Reviewed:** Flutter app structure, entry/edit/delete screens, monthly analysis, Firebase dependencies/config references, Android release signing configuration, README, and repository status.
- **Plan created:** `IMPLEMENTATION_PLAN.md`, covering existing-flow stabilization, authentication/security and migration, dashboard/profile, categories/customers/appointments, bill tracking, reports/exports, and release readiness.
- **Key decisions proposed:** preserve legacy Firestore records; back up and plan migration before enforcing owner-scoped security; store new money values in exact minor units; target Android first while retaining configured platforms where feasible.
- **Pre-existing workspace changes observed:** `analysis_options.yaml`, `android/app/google-services.json`, generated plugin registrants, `pubspec.lock`, and untracked `.vscode/`. Preserve these during implementation.
- **Verification:** documentation and source review only. No app code changed and no tests/builds were run.
- **Next step:** wait for owner approval or requested edits to the plan. Once approved, begin Phase 0 and update this log as work proceeds.

## 2026-11-09 — Module 1: calendar month filtering

- **Status:** Complete; checked before moving on.
- **Changed:** Added `lib/month_period.dart` to calculate exclusive calendar-month boundaries, parse valid `YYYY-MM-DD` dates, discard invalid/placeholder dates, and produce unique newest-first month options. Updated the monthly analysis and both manage-entry screens to use a single month/year option drawn from real records.
- **Behavior fixed:** December filters now end on January 1 of the following year; month/year combinations with no matching records can no longer be selected; malformed or missing date values do not crash month-option extraction. Management lists open on the most recent month and report options are newest-first.
- **Tests added:** `test/month_period_test.dart` covers December rollover, a non-December boundary, invalid dates, deduplication, and newest-first ordering.
- **Verification:** Dart formatter completed with no further changes. Focused Flutter tests passed (3 tests). `git diff --check` reported no whitespace errors. Flutter analyzer reports 17 existing informational lint findings (async context usage and `print` calls); it reports no findings introduced by this module.
- **Workspace note:** Initial analyzer attempts were blocked by sandbox process/telemetry restrictions; reran the test and analyzer with the required Dart process access and analytics suppressed. No project telemetry settings were changed.
- **Next module:** amount input validation and exact money representation, while retaining compatibility with existing string-valued records.

## 2026-11-09 — Module 2: amount validation and paise storage

- **Status:** Complete; checked before moving on.
- **Scope:** Validate all required financial amount fields as non-negative rupee values with at most two decimal places; store new and edited amounts as integer paise; continue reading legacy string values as rupees in edit forms, lists, and monthly totals.
- **Changed:** Added `lib/money_amount.dart`; applied validation and paise conversion to daily and bill entry and edit forms; updated tables, delete previews, and monthly summaries to read/display legacy rupee strings and new integer-paise values consistently. Added `test/money_amount_test.dart`.
- **Verification:** Dart formatter completed. Focused date and money tests passed (7 tests). `git diff --check` reported no whitespace errors. Flutter analyzer reports the same 17 pre-existing informational lint findings; no new findings from this module.
- **Workspace note:** Flutter updated `.metadata` to match its installed SDK during verification. That generated-only change was reverted to the original project value. Other pre-existing modified files were preserved.
- **Next module:** authentication and account access. This includes checking legacy-record ownership/migration before any restrictive Firestore rules are applied.

## 2026-11-09 — Module 3: email/password and Google authentication

- **Status:** Code implemented and checked; Firebase Console provider setup and Android build verification remain pending.
- **Scope:** Add Firebase auth-state routing, email/password sign-in and account creation, password reset, Google sign-in, user-facing auth errors, and a working sign-out action. Keep Firestore records untouched until their ownership migration is handled separately.
- **Changed:** Added `lib/auth_service.dart` and `lib/sign_in_page.dart`; routed app startup through Firebase auth state; added sign-out action; wired email sign-in, account creation, password reset, Google sign-in, and clear Firebase Auth errors. Added the iOS Google callback URL scheme. Added `FIREBASE_AUTH_SETUP.md` for required Firebase Console configuration and the existing-data limitation.
- **Dependencies/config:** Added and pinned Google Sign-In 6.2.2 to preserve the project's declared Dart SDK compatibility; updated `pubspec.lock`.
- **References checked:** Firebase Flutter documentation for email/password and federated authentication; the official `google_sign_in` package documentation and its SDK requirements.
- **Verification:** All 9 Flutter tests passed. Flutter analysis reports the same 17 pre-existing informational lint findings and no new findings. Android debug build did not reach compilation: the Gradle wrapper attempted to download its uncached Gradle 8.7 distribution, while the `.part` file remained at 0 bytes; the attempt was stopped. Firebase provider configuration/sign-in was not live-tested.
- **Workspace note:** Flutter's Android build attempt added automatic flags to `android/gradle.properties`; these generated changes were removed. `.metadata` was restored to its initial SDK revision. Initial user changes remain preserved.
- **Next module:** owner-scoped Firestore data and a safe migration for existing records. No restrictive rules will be applied until that migration path is verified.

## 2026-11-09 - Module 4: owner-scoped Firestore data and legacy migration

- **Status:** Local implementation and checks complete; live migration and rules deployment are pending owner/admin action. This module is not marked fully complete because the security rules have not been deployed and existing records have not been migrated or verified against the live Firebase project.
- **Scope:** Scope app financial reads and writes to the signed-in owner's data, restrict Firestore access by UID, and prepare a non-destructive migration for existing top-level records.
- **Changed:** Added `lib/account_data.dart` and routed financial collection access through `users/{uid}/...`; added `firestore.rules` and registered the rules file in `firebase.json`; added `scripts/migrate_legacy_records.mjs`, which defaults to dry-run, requires explicit apply and owner UID flags, avoids overwrites, verifies copied data, and retains original documents. Added Firebase Admin SDK tooling and npm migration command. Expanded `FIREBASE_AUTH_SETUP.md` with backup, migration, and rules deployment steps. Added `/node_modules/` to `.gitignore` for the local Admin SDK install.
- **Verification:** All 9 Flutter tests passed after the data-path changes. Flutter analysis reports only the same 17 pre-existing informational findings. `node --check scripts/migrate_legacy_records.mjs` passed; `firebase.json` and `package.json` parse as JSON; `git diff --check` reports no whitespace errors. Android build verification remains blocked by the uncached Gradle distribution download recorded under Module 3. npm audit has no remaining high/critical findings; 6 moderate advisories remain in transitive development tooling dependencies.
- **Safety boundary:** No Firebase data was read, copied, modified, or deleted; no rules were deployed. Before deployment, make a Firestore backup, inspect any other top-level collections and existing rules, choose the account UID that will own the legacy parlour data, run the documented dry-run, review its counts/conflicts, then explicitly apply and verify the copy. The app's security guarantee depends on deploying the reviewed rules after migration.
- **Next step at that point:** Owner/admin completes and confirms the live backup, migration, and rules review/deployment. The owner subsequently instructed continuation, so implementation proceeded with dashboard/profile code while this external security gate remains open.

## 2026-11-09 - Module 5: dashboard and profile

- **Status:** Feature code complete and checked locally. Live profile photo upload depends on Firebase Storage being enabled and `storage.rules` being deployed; that external configuration has not been performed.
- **Dashboard:** Replaced the button-only landing screen with today's income, expenses, bill/payment outflow, and net after bills. Queries filter each signed-in user's collections to today's date. Added refresh/retry behavior and shortcuts for adding, managing, and reporting entries.
- **Profile:** Added persistent display name and theme color settings under `users/{uid}/profile/settings`, gallery-based photo selection/upload at a UID-scoped Storage path, a 5 MB upload limit, progress/error feedback, and sign-out. Added owner-only Storage rules and Firebase CLI configuration. Added iOS photo-library usage text. Existing `image_picker`, Firebase Storage, and MIME dependencies were already declared.
- **Verification:** Dart formatter completed. Flutter analyzer reports the same 17 existing informational findings and no new warnings/errors. All 9 Flutter tests pass. Existing Android build limitation and Firebase external configuration gates remain as logged above.
- **Definition:** Dashboard net is calculated as daily income minus daily expenses minus bill/payment amounts, which are displayed separately so the assumed treatment of bills is visible.
- **Next module:** Categories and customer/appointment records. Firebase migration, Firestore rules, Auth provider setup, and Storage rules still need live project configuration before release.

## 2026-11-09 - Module 6: categories, customers, and appointments

- **Status:** Complete and locally checked.
- **Planned:** Owner-scoped category CRUD and category assignment to financial records; customer records; appointment scheduling and status management. Keep entry forms compatible with records that predate categories.
- **Category slice:** Implemented starter categories, create/rename/archive/restore, optional assignment on create/edit forms, and category labels in monthly tables. Archived categories remain available in existing records by ID/name.
- **Category verification:** Formatter completed; Flutter analysis reported no new findings (same 17 existing informational findings); all 9 Flutter tests passed.
- **Customer and appointment slice:** Added customer create/edit/archive/restore and appointment history; appointments support customer, service, date/time, status, and notes, with booked/completed/cancelled updates. Upcoming appointments are queried by start time with a 100-record bound; customer history is bounded to 200 entries.
- **Verification:** Formatter completed. Flutter analysis reports no new findings (same 17 existing informational findings). All 9 Flutter tests passed after the category, customer, and appointment changes.

## 2026-11-09 - Module 7: bill and payment status tracking

- **Status:** Complete and locally checked.
- **Planned:** Add payee, bill purpose, due date, payment date and status, plus partial payment amounts and outstanding balance. Preserve historical records by treating legacy bill amounts as paid when no status/payment fields exist. Update dashboard and monthly totals so unpaid amounts are not counted as cash paid.
- **Changed:** Added payee and required bill-purpose fields; due date, last payment date, paid/unpaid/part-paid status, cash/online paid amounts, live outstanding preview, and validation preventing zero totals, overpayment, or a remaining balance without a due date. Edit/manage/monthly views show payee, status, paid amount and outstanding balance.
- **Compatibility:** `BillPaymentModel` treats legacy records with no paid fields as fully paid; editing such a record initializes the paid amounts to its existing total. Dashboard subtracts payments made today from net and shows due/overdue balance separately. Monthly summaries show invoiced, paid, and outstanding totals.
- **Tests:** Added 3 model tests for legacy records, partial payments, outstanding balances, and status classification.
- **Verification:** Formatter completed; Flutter analysis has the same 17 pre-existing informational findings and no new findings. All 12 Flutter tests passed.
- **Definition:** Net cash for the dashboard uses today's income minus today's daily expenses minus bill payments recorded as paid today; remaining invoice balances are shown separately.

## 2026-11-09 - Module 8: reports and exports

- **Status:** Complete and locally checked.
- **Planned:** Add custom date-range reporting with clear gross income, operating expenses, bill paid/outstanding totals, category breakdowns and transaction detail, then CSV and PDF export/share that matches the selected report.
- **Changed:** Added an inclusive custom date-range report with bounded Firestore queries (500 results per query), income, daily expenses, bill invoices, payments received, current outstanding balances on invoices issued in range, category breakdown, transaction rows, and a visible truncation warning. Added shareable CSV and PDF outputs; CSV includes summary totals, status, due dates, a UTF-8 BOM, quoted fields, and formula-leading text protection. PDF includes summary totals, transaction details, and payment status/balance. Monthly analysis now shows net cash after bill payments.
- **Dependencies:** Added PDF generation/printing and CSV share packages pinned to versions compatible with the project's declared Dart 3.5.3 SDK and Android Gradle 8.7 constraints: `pdf`, `printing 5.14.3`, and `share_plus 10.1.4`. Verified package APIs and SDK/platform constraints against their pub.dev package documentation.
- **Tests:** Added reconciliation, legacy bill, outstanding balance, CSV escaping, and PDF file-header checks.
- **Verification:** Formatter completed; Flutter analysis reports the same 17 existing informational findings and no new findings; all 14 Flutter tests pass; `git diff --check` reports no whitespace errors. PDF generation passes; the PDF library logs that its built-in Helvetica fonts do not support arbitrary Unicode, so non-Latin customer/payee text may not render correctly.
- **Report limit:** If a query returns more than 500 documents, the report and exports clearly warn that the date range must be narrowed to get complete totals. Bill outstanding is explicitly the current balance on invoices issued inside the selected range; cash net counts payments made inside the selected range.

## 2026-11-09 - Module 9: release readiness

- **Status:** Local preparation complete; full release readiness remains pending owner-side Firebase setup, migration/rules deployment, production signing values, and a successful platform build.
- **Changed:** Replaced the empty README with setup, Firebase migration/rules, run/test, and release-signing instructions. Removed Android release's debug-key fallback and added optional production signing via four `PARLOUR_RELEASE_*` environment variables; partial configuration fails early. Added Firebase Storage rules deployment instructions.
- **Final local verification:** `flutter analyze` completes with the same 17 pre-existing informational findings and no warnings/errors; all 14 Flutter tests pass; migration script syntax check passes; `firebase.json` and `package.json` parse; `git diff --check` reports no whitespace errors.
- **Unverified gates:** Android build remains unverified because Gradle 8.7 was not cached and its earlier download could not complete. Google/Email providers, Storage, migration, and Firestore/Storage rules have not been configured or deployed in Firebase Console. Production keystore values were not provided, so no signed release build was produced. Do not release until these steps are complete.
- **Output note:** The generated PDF passes its file-header test. The library warns that built-in Helvetica fonts lack general Unicode support; use a bundled Unicode font before relying on PDF reports for non-ASCII customer/payee names.

## 2026-11-10 - Dashboard, reports, fixed theme, and screen architecture

- **Status:** UI/provider implementation complete in the workspace. Live Firebase project replacement, analysis, and platform build verification remain blocked.
- **Changed:** Reorganized application code into `screens/`, `providers/`, `services/`, `models/`, and `utils/`; registered dashboard, daily-entry, and monthly-report providers above auth routing; removed the profile theme-color control and fixed the app palette to the five requested colors. Rebuilt dashboard with a seven-day income/expense chart and refreshed summary cards; rebuilt monthly report with an animated circular breakdown. Removed categories from daily create/edit screens and their report table, improved form spacing, app bars, typography, icons, and route transitions. Fixed refresh handling that returned a Future from `setState`.
- **Demo records:** Added `tool/seed_demo_data.dart`, which defaults to dry-run, requires explicit project confirmation for writes, uses signed-in user Firestore rules, and can clean up only its tagged documents. Added README usage instructions; no Node tooling was added.
- **Verification:** `git diff --check` passed. Searches confirmed no profile theme controller/color references and no daily-entry category controls. No tests were run. Dart format and analysis processes stalled in this workspace, so formatter/analyzer results are unavailable for this session.
- **External setup:** Firebase CLI project listing could not refresh the expired login because network access is unavailable. No Firebase project was created or replaced, and Firebase config was not intentionally changed; live project setup requires valid Firebase CLI authentication and network access.
