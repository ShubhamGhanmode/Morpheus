# AI Agent Guide (Morpheus)

This guide helps AI coding agents understand the project, architecture, and workflows. Read before making changes.

## Goal
Build an industry-standard finance app with modular, maintainable code and a clean directory structure.

## Quick Start for Agents
- Read this file end-to-end before edits.
- Prefer `rg` for search and `apply_patch` for single-file edits.
- Keep edits ASCII unless a file already uses Unicode.
- Avoid removing unrelated changes in a dirty worktree.

## Project Overview
Morpheus is a Flutter finance companion with:
- Expenses, budgets, accounts, and card management.
- Firestore + Firebase Auth cloud sync.
- Local SQLite cache for credit cards and bank icon data.
- Encrypted storage for sensitive fields before upload.
- App lock using device authentication.
- Push notifications for card reminders using Cloud Tasks + FCM.
- Monthly snapshots for per-card utilization summaries.
- Optional secondary currency display (base/secondary defined in config).

## Tech Stack
- Flutter (Dart), Material 3 UI.
- State management: `bloc` / `flutter_bloc`.
- Firebase: Auth, Firestore, Messaging, Cloud Functions Gen 2.
- Local storage: SQLite via `sqflite`.
- Notifications: `flutter_local_notifications`, FCM.
- Cloud Tasks for scheduled pushes.

## Architecture Principles
- User data never leaves user scope (privacy-first).
- Offline-first for critical reads via SQLite cache.
- Server-side source of truth: Firestore for persistence.
- Client-side computed: UI state, derived balances, and totals.
- Server-side computed: reminders and monthly snapshots.

## State Management Conventions
- Prefer Cubits for feature state: `CardsCubit`, `AccountsCubit`, `ExpenseCubit`.
- Keep Cubit files as `snake_case`: `cards_cubit.dart`, `cards_state.dart`.
- Class names use PascalCase: `CardsState`, `AccountLedgerEntry`.
- If Bloc is used, events are `PascalCase` with `Event` suffix and verbs:
  `LoadCardsEvent`, `RefreshLedgerEvent`, `SaveExpenseEvent`.
- Emit error states with user-visible messages; do not swallow exceptions.
- Provide cubits above sheets/routes that read them to avoid scope errors.


## Debugging Quick Reference
- Enable Firestore debug logs: `flutter run --dart-define=FIREBASE_DEBUG=true`.
- Check Cloud Tasks queue: `gcloud tasks queues describe card-reminders --location=europe-west1`.
- View function logs: `firebase functions:log --only sendCardReminders`.

## Repo Map (Key Paths)
- App shell / nav: `lib/navigation_bar.dart` (IndexedStack tabs).
- Cards UI: `lib/creditcard_management_page.dart`
- Card ledger: `lib/cards/card_ledger_page.dart`
- Add/Edit Card dialog: `lib/add_card_dialog.dart`
- Accounts UI: `lib/accounts.dart`
- Account ledger: `lib/accounts/account_ledger_page.dart`
- Expenses dashboard: `lib/expenses/view/expense_dashboard_page.dart`
- Expense form: `lib/expenses/view/widgets/expense_form_sheet.dart`
- Planned expenses: `lib/expenses/view/widgets/planned_expense_sheet.dart`
- Categories: `lib/categories/`
- Settings: `lib/settings/settings_page.dart`, `lib/settings/settings_cubit.dart`
- Notification pipeline: `lib/services/notification_service.dart`
- Encryption: `lib/services/encryption_service.dart`
- FX rates: `lib/services/forex_service.dart`
- Card balances: `lib/utils/card_balances.dart`, `lib/utils/statement_dates.dart`
- Config: `lib/config/app_config.dart`
- Cloud Functions: `functions/index.js`

## Decision Tree for Common Tasks


## Core Data Model (Firestore)
User-scoped documents:
- `users/{uid}/cards/{cardId}`
  - encrypted fields: bankName, holderName, cardNumber, expiryDate, cvv
  - reminders: reminderEnabled, reminderOffsets, billingDay, graceDays
- `users/{uid}/accounts/{accountId}` (encrypted fields)
- `users/{uid}/expenses/{expenseId}`
- `users/{uid}/expense_categories/{categoryId}` with fields: name, emoji
- `users/{uid}/deviceTokens/{token}`
- `users/{uid}`: timezone, timezoneUpdatedAt
- `users/{uid}/reminderLogs/{cardId_offset_dueDate}`
- `users/{uid}/cardReminderTasks/{cardId}`
- `users/{uid}/cardSnapshots/{YYYY-MM}`

## Firestore Security Rules
- Location: `firestore.rules` (Firestore) and `storage.rules` (Storage).
- Approach: user-scoped access with `request.auth.uid == uid` on `users/{uid}/...`.
- When adding collections, update rules and required indexes.

## Local Storage (SQLite)
- File: `morpheus.db` via `sqflite`.
- Table: `credit_cards` caches card data for offline use.
- Bank icons come from bundled SQLite: `assets/tables/banks.sqlite`.
- Cache scope: cards are cached per-user. On uid change, the local card cache is cleared and refilled from Firestore.

## Expense and Ledger Semantics
- Expense fields include: amount, currency, category, date, note.
- Conversion fields: amountEur, baseCurrency, baseRate, amountInBaseCurrency,
  budgetCurrency, budgetRate, amountInBudgetCurrency.
- paymentSourceType: cash | card | account | wallet.
- paymentSourceId: card/account id (or wallet handle).
- transactionType: spend | transfer.
- Transfers often use negative amounts to represent credits.
- Card payment is recorded as two expenses: account debit + card credit.

## Flow Diagrams (ASCII)
Expense creation
[ExpenseFormSheet]
  -> validate input
  -> build Expense model
  -> write Firestore (users/{uid}/expenses/{expenseId})
  -> update local state/caches
  -> refresh dashboard and ledger

Card payment (record payment)
[Record Payment]
  -> create expense (account debit)
  -> create expense (card credit)
  -> ledger queries show both entries
  -> card balance updates from expenses

Card reminder pipeline
[Card write] -> [syncCardReminders trigger]
  -> [Cloud Tasks enqueue]
  -> [sendCardReminderTask HTTP]
  -> [FCM push]
  -> [device receives notification]

## Card Balances and Availability
- Statement windows computed in `lib/utils/statement_dates.dart`.
- Balances computed in `lib/utils/card_balances.dart`.
- Expenses match cards by paymentSourceId or card number digits.
- Available limit = card usageLimit - totalBalance (can be negative).

## Categories
- Firestore source of truth: `users/{uid}/expense_categories`.
- Default categories seeded from `lib/config/app_config.dart`.
- Emoji is optional but stored as empty string, not null.
- UI shows categories as "emoji + space + name".

## Config and Currency
- Single source for currencies and defaults: `lib/config/app_config.dart`.
  - baseCurrency
  - secondaryCurrency
  - enableSecondaryCurrency
- Settings has a base currency toggle which is commented out for now; currently only affects some UI/flows.
  Consider consolidating to a single source of truth if you extend currency logic.

## Error Handling Conventions
- Wrap repository writes in try/catch for `FirebaseException` and `PlatformException`.
- Emit failure states with context (operation + message) for UI surfacing.
- Use user-friendly messages in snackbars/dialogs; log full error details via `debugPrint`.
- Validate required fields early and return fast with inline errors.
- Avoid silent catches; every failure should be visible in logs or UI.

## Notifications and Reminders
- Local notifications: `NotificationService.showInstantNotification`.
- Push notifications: Cloud Tasks + FCM (server-side send).
- Test push button in card UI calls `sendTestPush` callable function.

## Cloud Functions (Gen 2)
Region: `europe-west1`
- sendCardReminders: daily reconcile for missing tasks.
- syncCardReminders: Firestore onWrite trigger for cards.
- syncUserTimezone: Firestore onWrite trigger for user timezone changes.
- sendCardReminderTask: HTTP handler invoked by Cloud Tasks.
- sendTestPush: Callable function for UI test button.
- computeMonthlyCardSnapshots: monthly server-side summary.

Cloud Tasks queue:
- `card-reminders` in `europe-west1`

Security:
- `TASKS_WEBHOOK_SECRET` protects the Cloud Tasks endpoint via header.
- If not set, the task endpoint is public.

## Build and Run (App)
Common commands:
- `flutter pub get`
- `flutter run`
- `dart format lib`

Android notes:
- `MainActivity` uses `FlutterFragmentActivity` for biometric auth.
- Android Gradle plugin is set in `android/settings.gradle.kts`.

## Build and Deploy (Functions)
From `functions/`:
- `npm install`
- `firebase deploy --only functions`

If Cloud Tasks queue is missing:
- `gcloud tasks queues create card-reminders --location=europe-west1`

## Required Firebase APIs
- Cloud Functions, Cloud Run, Eventarc, Cloud Tasks, Cloud Scheduler, Pub/Sub

## Testing and QA
There are no automated tests by default.
Manual validation checklist:
- Auth: login, logout, and account switch resets local caches.
- App lock toggle and biometric prompt behavior.
- Card add/edit, reminder offsets, and network logo rendering.
- Test notification (local) and test push (server) from UI.
- Reminder scheduling in Firestore and Cloud Tasks queue.
- Monthly snapshot writes in Firestore (runs on 1st each month).
- Expense add/edit with each payment source and category.
- Account ledger reflects expenses and credits correctly.
- Currency conversion shows base and secondary values consistently.
- Offline mode: cached cards/expenses render without crash.

## Common Pitfalls
- Missing `FlutterFragmentActivity` causes biometric auth to fail.
- Missing Google Services files breaks Android/iOS builds.
- Missing Eventarc permissions can block Gen 2 Firestore triggers.
- Region mismatch: callable functions must be called with `region: europe-west1`.
- Encryption key/IV mismatch: server cannot decrypt card data.
- Provider scope issues when opening sheets/routes (ensure required cubits are in scope).

## Conventions
- Keep edits ASCII unless a file already contains Unicode.
- Prefer `rg` for searching.
- Use `apply_patch` for small single-file edits.
- Avoid removing unrelated changes.
- Favor modular changes and keep logic close to the feature area.

## How to Extend
To add a new reminder type:
- Add fields to card schema.
- Update scheduling logic in `functions/index.js`.
- Update UI and storage models.

To add a new dashboard summary:
- Decide whether it should be client-computed or server-computed.
- For server summaries, add a scheduled Gen 2 function and write into `users/{uid}/...`.

## Contact Points in Code
Start here if you are unsure where to change something:
- Cards: `lib/creditcard_management_page.dart`
- Card ledger: `lib/cards/card_ledger_page.dart`
- Accounts: `lib/accounts.dart`
- Notifications: `lib/services/notification_service.dart`
- Functions: `functions/index.js`
- Settings: `lib/settings/settings_page.dart`
