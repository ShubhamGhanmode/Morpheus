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
- Expenses, budgets, accounts, and credit card management.
- Bills calendar and recurring transaction tracking.
- Subscriptions and planned expenses management.
- Firestore + Firebase Auth cloud sync.
- Local SQLite cache for credit cards and bank icon data.
- Encrypted storage for sensitive fields before upload.
- App lock using device authentication (biometric/PIN).
- Push notifications for card reminders using Cloud Tasks + FCM.
- Monthly snapshots for per-card utilization summaries.
- Optional secondary currency display (base/secondary defined in config).
- Error reporting via Sentry and Firebase Crashlytics.

## Tech Stack
- Flutter (Dart 3.38+), Material 3 UI.
- State management: `bloc` / `flutter_bloc` with `equatable`.
- Firebase: Auth, Firestore, Messaging, Cloud Functions Gen 2, Crashlytics.
- Local storage: SQLite via `sqflite` / `sqflite_common_ffi`.
- Notifications: `flutter_local_notifications`, FCM.
- Cloud Tasks for scheduled pushes.
- Data models: `freezed` + `json_serializable` with code generation.
- Charts: `fl_chart` for expense visualizations.
- Error reporting: `sentry_flutter` + Firebase Crashlytics.
- Security: `flutter_secure_storage`, `local_auth`, `crypto`, `encrypt`.
- Networking: `http` for REST calls, `connectivity_plus` for status.

## Directory Structure
```
lib/
  main.dart                  # App entry, Firebase init, providers
  navigation_bar.dart        # Bottom nav with IndexedStack tabs
  accounts.dart              # Accounts list page
  creditcard_management_page.dart  # Cards list page
  bills_calendar_page.dart   # Bills calendar view
  accounts/                  # Account feature module
    accounts_cubit.dart
    accounts_repository.dart
    account_form_sheet.dart
    account_ledger_page.dart
    models/
  auth/                      # Authentication (Bloc pattern)
    auth_bloc.dart, auth_event.dart, auth_state.dart
    auth_repository.dart
  banks/                     # Bank data & search
    bank_repository.dart
    bank_search_cubit.dart
  bills/                     # Bills module
    models/bill_item.dart
  cards/                     # Credit cards feature
    card_cubit.dart
    card_repository.dart
    card_ledger_page.dart
    models/credit_card.dart, card_spend_stats.dart
  categories/                # Expense categories
    category_cubit.dart
    category_repository.dart
    expense_category.dart
  config/                    # App configuration
    app_config.dart          # Currencies, defaults, seeded categories
  data/                      # Platform-specific DB access
    banks_db.dart            # Abstract interface
    banks_db_io.dart         # Mobile implementation
    banks_db_web.dart        # Web stub
  database/                  # SQLite helpers
    database_helper.dart
  expenses/                  # Expenses feature (full module)
    bloc/                    # ExpenseBloc with events/states
    constants/
    models/                  # Expense, Budget, PlannedExpense, Subscription
    repositories/
    services/
    utils/
    view/                    # Dashboard, widgets, sheets
  lock/                      # App lock gate
    app_lock_gate.dart
  models/                    # Shared model utilities
    json_converters.dart
  services/                  # Core services
    app_lock_service.dart
    auth_service.dart
    encryption_service.dart
    error_reporter.dart      # Abstract + Crashlytics impl
    export_service.dart      # Platform-conditional exports
    forex_service.dart
    notification_service.dart
  settings/                  # User settings
    settings_page.dart
    settings_cubit.dart
  theme/                     # Theming
    app_theme.dart
    color_schemes.dart
    typography.dart
  utils/                     # Shared utilities
    card_balances.dart
    statement_dates.dart
    error_mapper.dart
  widgets/                   # Reusable widgets
    color_picker.dart
functions/                   # Cloud Functions (Node.js)
  index.js
```

## Platform-Specific Pattern
For platform-conditional code, use the barrel + conditional export pattern:
- `service.dart` - exports `_io.dart` or `_web.dart` based on platform
- `service_io.dart` - mobile/desktop implementation
- `service_web.dart` - web stub or alternative

Examples: `notification_service.dart`, `banks_db.dart`, `export_service.dart`

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

**Core Navigation**
- App shell / nav: `lib/navigation_bar.dart` (IndexedStack tabs)
- App entry: `lib/main.dart`
- Splash: `lib/splash_page.dart`
- Auth flow: `lib/signup_page.dart`

**Cards Module**
- Cards UI: `lib/creditcard_management_page.dart`
- Card ledger: `lib/cards/card_ledger_page.dart`
- Add/Edit Card dialog: `lib/add_card_dialog.dart`
- Card Cubit: `lib/cards/card_cubit.dart`
- Card Repository: `lib/cards/card_repository.dart`
- Card models: `lib/cards/models/credit_card.dart`, `card_spend_stats.dart`

**Accounts Module**
- Accounts UI: `lib/accounts.dart`
- Account ledger: `lib/accounts/account_ledger_page.dart`
- Account form: `lib/accounts/account_form_sheet.dart`
- Accounts Cubit: `lib/accounts/accounts_cubit.dart`

**Expenses Module**
- Expenses dashboard: `lib/expenses/view/expense_dashboard_page.dart`
- Expense form: `lib/expenses/view/widgets/expense_form_sheet.dart`
- Planned expenses: `lib/expenses/view/widgets/planned_expense_sheet.dart`
- Expense Bloc: `lib/expenses/bloc/expense_bloc.dart`
- Expense models: `lib/expenses/models/` (expense, budget, subscription, planned_expense)

**Bills & Subscriptions**
- Bills calendar: `lib/bills_calendar_page.dart`
- Bill models: `lib/bills/models/bill_item.dart`
- Subscription model: `lib/expenses/models/subscription.dart`
- Recurring transactions: `lib/expenses/models/recurring_transaction.dart`

**Categories**
- Categories: `lib/categories/`
- Category Cubit: `lib/categories/category_cubit.dart`

**Auth & Security**
- Auth Bloc: `lib/auth/auth_bloc.dart`
- Auth Repository: `lib/auth/auth_repository.dart`
- App lock: `lib/lock/app_lock_gate.dart`
- App lock service: `lib/services/app_lock_service.dart`

**Services**
- Notification pipeline: `lib/services/notification_service.dart`
- Encryption: `lib/services/encryption_service.dart`
- FX rates: `lib/services/forex_service.dart`
- Error reporting: `lib/services/error_reporter.dart`
- Export: `lib/services/export_service.dart`

**Utilities & Config**
- Card balances: `lib/utils/card_balances.dart`, `lib/utils/statement_dates.dart`
- Config: `lib/config/app_config.dart`
- Theme: `lib/theme/app_theme.dart`
- Database helper: `lib/database/database_helper.dart`
- Banks DB: `lib/data/banks_db.dart`

**Backend**
- Cloud Functions: `functions/index.js`

## Decision Tree for Common Tasks

```
Adding a new feature?
  -> Does it need server state? -> Add Firestore collection under users/{uid}/
  -> Does it need local cache? -> Add SQLite table in database_helper.dart
  -> Does it need scheduled work? -> Add Cloud Function + Cloud Tasks

Adding a new expense-related model?
  -> Create Freezed model in lib/expenses/models/
  -> Add toJson/fromJson with json_serializable
  -> Run: dart run build_runner build --delete-conflicting-outputs
  -> Update ExpenseRepository if persistence needed

Adding a new UI page?
  -> Stateful with server data? -> Create Cubit + Repository
  -> Pure display? -> StatelessWidget with data from parent Cubit
  -> Modal/Sheet? -> Ensure parent provides required Cubits via BlocProvider

Adding a new card/account field?
  -> Is it sensitive? -> Add to encrypted fields list
  -> Update Firestore schema doc below
  -> Update card_repository.dart or accounts_repository.dart
  -> Update UI form and display

Adding a new notification type?
  -> Local only? -> Use NotificationService.showInstantNotification
  -> Scheduled push? -> Add Cloud Tasks scheduling in functions/index.js
  -> Update syncCardReminders or create new trigger

Modifying currency logic?
  -> Check lib/config/app_config.dart for baseCurrency/secondaryCurrency
  -> Update forex_service.dart if new conversion needed
  -> Ensure Expense model fields are populated correctly

Fixing a platform-specific bug?
  -> Check for _io.dart / _web.dart variants
  -> Use conditional imports in the barrel file
```

## Core Data Model (Firestore)
User-scoped documents:
- `users/{uid}/cards/{cardId}`
  - encrypted fields: bankName, holderName, cardNumber, expiryDate, cvv
  - reminders: reminderEnabled, reminderOffsets, billingDay, graceDays
- `users/{uid}/accounts/{accountId}` (encrypted fields)
- `users/{uid}/expenses/{expenseId}`
- `users/{uid}/expense_categories/{categoryId}` with fields: name, emoji
- `users/{uid}/budgets/{budgetId}` with fields: name, amount, currency, categoryId, period
- `users/{uid}/subscriptions/{subscriptionId}` with fields: name, amount, frequency, nextDate
- `users/{uid}/plannedExpenses/{id}` for future scheduled expenses
- `users/{uid}/bills/{billId}` for recurring bills
- `users/{uid}/deviceTokens/{token}`
- `users/{uid}`: timezone, timezoneUpdatedAt
- `users/{uid}/reminderLogs/{cardId_offset_dueDate}`
- `users/{uid}/cardReminderTasks/{cardId}`
- `users/{uid}/cardSnapshots/{YYYY-MM}`

## Freezed Models Reference
Key models using `@freezed`:
- `Expense` - core expense with currency conversion fields
- `Budget` - spending limits per category/period
- `PlannedExpense` - future scheduled expenses
- `Subscription` - recurring subscriptions
- `RecurringTransaction` - templated recurring items
- `CreditCard` - card with encrypted fields
- `ExpenseCategory` - category with emoji
- `BillItem` - calendar bill entries
- `AccountCredential` - account with credentials
- `CardSpendStats` - computed spend statistics

After modifying any Freezed model:
```bash
dart run build_runner build --delete-conflicting-outputs
```

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

## Data Flow Architecture
```
[UI Widget]
    |
    v
[Cubit/Bloc] <-- emits state updates
    |
    v
[Repository] <-- handles Firestore + cache sync
    |         \-- calls Services for business logic
    v
[Firestore] <--> [SQLite Cache]
```

Typical read flow:
1. UI subscribes to Cubit state
2. Cubit calls Repository.fetchAll()
3. Repository reads from SQLite cache first (offline-first)
4. Repository streams Firestore for updates
5. Cubit emits new state, UI rebuilds

Typical write flow:
1. UI triggers Cubit.add/update/delete
2. Cubit calls Repository.save()
3. Repository writes to Firestore
4. Firestore triggers update -> Repository updates SQLite cache
5. Cubit emits success state

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

## Environment Variables & Secrets

**Flutter (compile-time defines)**
- `FIREBASE_DEBUG=true` - Enable Firestore debug logs

**Cloud Functions (runtime secrets via Firebase)**
- `TASKS_WEBHOOK_SECRET` - Protects Cloud Tasks HTTP endpoint
- `CARD_ENCRYPTION_KEY` - 32-char AES key for card field encryption
- `CARD_ENCRYPTION_IV` - 16-char IV for encryption

Set secrets:
```bash
firebase functions:secrets:set TASKS_WEBHOOK_SECRET
firebase functions:secrets:set CARD_ENCRYPTION_KEY
firebase functions:secrets:set CARD_ENCRYPTION_IV
```

**Local files (not in git)**
- `android/app/google-services.json` - Firebase Android config
- `ios/Runner/GoogleService-Info.plist` - Firebase iOS config
- `lib/firebase_options.dart` - Generated Firebase options

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

**Existing test files:**
- `test/expense_service_test.dart` - Expense service unit tests
- `test/statement_dates_test.dart` - Statement date calculation tests
- `test/widget_test.dart` - Basic widget tests
- `integration_test/expense_form_sheet_test.dart` - Expense form integration
- `integration_test/bills_calendar_page_test.dart` - Bills calendar integration

**Running tests:**
```bash
flutter test                           # Unit tests
flutter test integration_test/         # Integration tests
```

**Manual validation checklist:**
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
- Bills calendar shows upcoming and past bills correctly.
- Subscriptions are tracked and due dates are accurate.

## Common Pitfalls
- Missing `FlutterFragmentActivity` causes biometric auth to fail.
- Missing Google Services files breaks Android/iOS builds.
- Missing Eventarc permissions can block Gen 2 Firestore triggers.
- Region mismatch: callable functions must be called with `region: europe-west1`.
- Encryption key/IV mismatch: server cannot decrypt card data.
- Provider scope issues when opening sheets/routes (ensure required cubits are in scope).
- Forgetting to run `build_runner` after Freezed model changes.
- Web platform: some services have stub implementations (_web.dart).
- SQLite not available on web: use conditional imports.
- Sentry/Crashlytics: ensure DSN and config are set for production.
- DateTime timezone: use `flutter_timezone` for user's local zone.
- Firestore indexes: new queries may require composite indexes (check console errors).

## Conventions
- Keep edits ASCII unless a file already contains Unicode.
- Prefer `rg` for searching.
- Use `apply_patch` for small single-file edits.
- Avoid removing unrelated changes.
- Favor modular changes and keep logic close to the feature area.

## Freezed and Json Serializable
- Use `@freezed abstract class` for models and add a private constructor
  (`const ClassName._();`) when defining helpers/getters.
- Always include the correct `part` files (`.freezed.dart` and `.g.dart` if
  using JSON).
- After changing model fields or constructors, run
  `dart run build_runner build --delete-conflicting-outputs` and keep the
  generated files in sync.
- If you see "missing implementations" errors, verify the `part` filenames
  match and re-run build_runner.

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
- **Cards**: `lib/creditcard_management_page.dart`
- **Card ledger**: `lib/cards/card_ledger_page.dart`
- **Accounts**: `lib/accounts.dart`
- **Expenses**: `lib/expenses/view/expense_dashboard_page.dart`
- **Bills calendar**: `lib/bills_calendar_page.dart`
- **Categories**: `lib/categories/category_cubit.dart`
- **Auth flow**: `lib/auth/auth_bloc.dart`
- **App lock**: `lib/lock/app_lock_gate.dart`
- **Notifications**: `lib/services/notification_service.dart`
- **Encryption**: `lib/services/encryption_service.dart`
- **FX rates**: `lib/services/forex_service.dart`
- **Theme**: `lib/theme/app_theme.dart`
- **Config**: `lib/config/app_config.dart`
- **Functions**: `functions/index.js`
- **Settings**: `lib/settings/settings_page.dart`

## Code Style Quick Reference
- File names: `snake_case.dart`
- Class names: `PascalCase`
- Cubits: `feature_cubit.dart` with `FeatureCubit` class
- Blocs: `feature_bloc.dart`, `feature_event.dart`, `feature_state.dart`
- Freezed models: include `part 'model.freezed.dart';` and `part 'model.g.dart';`
- Private constructor for Freezed helpers: `const ClassName._();`
- Repository methods: `Future<T>` for writes, `Stream<List<T>>` for reads
- Error handling: emit error state with user message, log full details
