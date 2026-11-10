# Parlour Account App: Implementation Plan

## Goal

Evolve the current Flutter and Firebase app into a reliable parlour management app with secure sign-in, a useful dashboard, financial records and reports, customer appointments, and user profile preferences.

## Sequencing boundary

The owner authorized implementation on 2026-11-09 with the instruction to complete and check one module before starting the next. Work follows that sequence; each module is verified and recorded in `WORK_LOG.md` before the next begins. Any scope change that affects stored data, access rules, or user-visible behavior will be recorded and brought back for approval if it materially changes this plan.

## Current project baseline

- Flutter app with Firebase Core and Cloud Firestore.
- Existing collections: `DailyDataEntry` and `BillPaymentEntry`.
- Existing flows: daily income/expense entry, bill/payment entry, edit/delete, and a monthly summary.
- Firebase Auth is listed as a dependency but there is no sign-in flow in the app.
- No Firestore rules or data migration files were found in the repository during the initial review.
- Existing amount fields are strings and dates are `YYYY-MM-DD` strings.
- Initial repository status showed user changes in `analysis_options.yaml`, `android/app/google-services.json`, generated plugin registrants, `pubspec.lock`, and an untracked `.vscode/` directory. These are pre-existing and must be preserved.

## Proposed product assumptions

- The first release is for one parlour owner, with the data owned by that signed-in account. The data model should leave room for multiple staff accounts later.
- Android is the first-class delivery target. Keep existing iOS and web builds working where Firebase configuration supports them; do not promise desktop Firebase support without verifying its configuration.
- Keep the existing records accessible. Back up and plan migration before enforcing authenticated-only access or changing record formats.
- Use Firebase Authentication for Google sign-in and email/password sign-in. Provider enablement, OAuth setup, and production credentials may require configuration in the Firebase console outside the repository.
- Store money in integer paise (or another exact minor-unit representation) and store dates in a queryable, consistently typed form. Keep compatibility/migration logic for legacy string values.

## Delivery phases

### Phase 0 — Confirm scope and inspect environment

- Wait for approval of this plan.
- Inspect the full Flutter target/configuration, current Firebase project setup, Firestore data shape, and existing builds before code changes.
- Confirm the existing records can be backed up and decide the migration path before enabling restrictive rules.
- Identify Firebase console actions required for Google and email/password providers; document them separately from code changes.

**Exit criteria:** approved scope recorded; implementation prerequisites and data migration path are understood; no existing user changes are overwritten.

### Phase 1 — Stabilize existing accounting flows

- Fix month boundaries, including December-to-January rollover, and prevent invalid month/year combinations in report and management filters.
- Add shared amount parsing and validation: valid non-negative monetary values, clear zero/optional-field behavior, and exact minor-unit storage for new data.
- Normalize date handling and sort records chronologically.
- Improve save/update/delete loading, success, and error states; prevent duplicate submissions and unsafe context use after async work.
- Correct rupee display encoding and add basic empty/loading/error states consistently.
- Define shared transaction models and a Firestore data-access layer to reduce duplicated logic.

**Exit criteria:** existing entry/edit/delete and monthly filtering work across year boundaries; malformed amounts are rejected; old records remain readable; the data layer handles legacy strings and new normalized values.

### Phase 2 — Authentication and data security

- Add an auth entry flow with Google sign-in and email/password registration, login, logout, and password reset.
- Add signed-in/signed-out routing and useful auth error messages.
- Associate new records with the signed-in owner and scope reads/writes to that owner.
- Decide and implement a safe migration for old top-level collection records. Back up first; do not silently hide or delete unowned records.
- Add Firestore security rules and rule tests so users can only read/write their own data.
- Document Firebase console provider setup, authorized domains, OAuth configuration, and any required platform settings.

**Exit criteria:** both requested login methods work on supported configured platforms; signed-out users cannot reach account data; rules enforce ownership; legacy data has an explicit, verified migration path.

### Phase 3 — Dashboard and profile

- Replace the button-only landing screen with a dashboard showing today’s income, expenses, net amount, and shortcuts to add records or open reports.
- Add a profile page with display name editing, profile image selection/upload, theme color selection, and logout.
- Store profile preferences under the authenticated user and restore them on next launch.
- Include sensible image upload/loading/error behavior and handle storage permissions/configuration.

**Exit criteria:** dashboard values match the underlying records; profile changes persist across app restarts; logout returns to signed-out flow and clears account-specific in-memory state.

### Phase 4 — Categories and parlour records

- Add income/expense categories, including editable category labels and a safe default for migrated records.
- Add customer records with name and optional phone/contact notes.
- Add appointments with customer, service, date/time, status, and optional notes.
- Add appointment list/calendar views and basic create/edit/cancel flows.
- Keep customer and appointment data owner-scoped and include validation for required fields and past/future dates.

**Exit criteria:** users can maintain categories, customers, and appointments; records are isolated by owner; existing financial records continue to work.

### Phase 5 — Bills and payment tracking

- Clarify bill/payment transaction types and record counterparty/payee, category, amount, due date, paid date, status, and notes as applicable.
- Support unpaid/part-paid/paid status and payment method, with clear totals for outstanding amounts.
- Preserve current bill/payment records through migration and provide edit/history handling.

**Exit criteria:** users can identify who is owed or paid, distinguish due from paid amounts, and see correct outstanding totals without double-counting in reports.

### Phase 6 — Reports and exports

- Add date-range and monthly reports with gross income, operating expenses, bill totals, outstanding amounts, and net result clearly defined.
- Add category breakdowns and transaction drill-down.
- Export reports/transactions to CSV and a shareable PDF with parlour name, selected range, currency, and totals.
- Use bounded/paginated queries and avoid loading every Firestore document just to populate filters.

**Exit criteria:** report totals reconcile with source records; date ranges include their intended endpoints; CSV/PDF exports match on-screen totals and can be shared/saved on supported platforms.

### Phase 7 — Release readiness

- Add automated tests for money/date/model logic, auth/data ownership, and report totals; run Flutter analysis and relevant platform builds.
- Review Firestore rules, failure states, accessibility, small-screen layouts, and upload/export behavior.
- Replace Android debug release signing with a production signing setup provided by the owner; do not commit signing secrets.
- Update README with setup, Firebase configuration, migration/backup procedure, and release steps.

**Exit criteria:** analysis and tests pass; release configuration has no debug signing; setup and recovery steps are documented; remaining Firebase console actions are explicitly listed.

## Acceptance checklist

Checkboxes mean the acceptance item is verified for release, including required Firebase Console and platform setup. Locally implemented items whose external steps remain open are listed in `WORK_LOG.md`.

- [ ] Google and email/password sign-in, registration, password reset, and logout (code is implemented; provider configuration/live sign-in pending).
- [ ] Secure owner-scoped Firestore access, including legacy migration and deployed rules (implementation is ready; migration and deployment pending).
- [x] Dashboard with today’s income, expenses, net amount, and shortcuts (locally checked).
- [x] Income/expense categories (locally checked).
- [x] Customer profiles and appointment scheduling/history (locally checked).
- [x] Bill/payment records with due/paid status and outstanding totals (locally checked).
- [x] Correct month/year and custom date-range reporting (locally checked).
- [x] CSV and PDF exports (locally checked; Unicode font support remains a known PDF limitation).
- [x] Profile name, image, theme color, and logout (locally checked; Firebase Storage setup/deployment pending for live photo upload).
- [ ] Existing records preserved in the live project; migration/backup and verification pending.
- [x] Automated unit verification and analysis completed; Android build/release verification pending.

## Risks and dependencies

- Authentication and access rules can make legacy records inaccessible if ownership migration is incomplete. Backup and migration verification must precede restrictive rules.
- Google sign-in requires Firebase provider and platform OAuth configuration; code alone cannot enable it in the Firebase console.
- Image upload and exports depend on Firebase Storage/platform configuration and storage/share APIs.
- Historical data may contain malformed amount/date strings; migration should report records it cannot safely convert instead of guessing.
- Deployment requires production signing credentials supplied through a secure local process, never committed to the repository.

## Work log process

Maintain `WORK_LOG.md` throughout implementation. At the start of each approved phase, record its status and intended work. After each meaningful work session, record changed files, decisions, verification performed and results, blockers, and the next step. Keep entries factual and append dated updates rather than rewriting history. Do not record passwords, signing secrets, tokens, or other credentials.

## Current execution status

- Module 1, **calendar month filtering**, is complete and verified.
- Module 2, **amount validation and paise storage**, is complete and verified.
- Module 3, **email/password and Google authentication**, is implemented and code-checked; Firebase Console provider setup and Android build verification remain pending.
- Module 4, **owner-scoped Firestore data and legacy-record migration**, is implemented and locally checked. A backed-up, owner-confirmed migration and rules review/deployment are still required before the security exit criteria can be met.
- Module 5, **dashboard and profile**, is implemented and locally checked. Firebase Storage setup and Storage Rules deployment remain required for live photo uploads.
- Module 6, **categories, customers, and appointments**, is implemented and locally checked.
- Module 7, **bill and payment status tracking**, is implemented and locally checked.
- Module 8, **reports and exports**, is implemented and locally checked.
- Module 9, **release readiness**, has its local documentation and signing safeguards complete. Firebase project setup/data migration, production signing values, and an Android build remain unverified owner-side release gates.
- Continue module-by-module and record verification and external configuration gates in `WORK_LOG.md`.
