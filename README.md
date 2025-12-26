# Morpheus

A Flutter finance companion with budgets, expenses, cards, accounts, and secure cloud sync.

## Features
- Expenses and budgets: add/edit/delete, plan future spend, set period budgets, and view analytics.
- Cards: add/edit/delete, set billing day and grace days, usage limits, and view utilization.
- Card payments: record partial/full payments and link them to accounts for clean ledgers.
- Accounts and payment sources: cash, bank accounts, wallets, or cards.
- Categories: Firestore-backed categories with optional emoji labels.
- Notifications: local testing, push reminders via Cloud Tasks + FCM, and test push in card UI when Test Mode is enabled.
- Security: app lock with device auth and encrypted storage for sensitive fields.
- Auth: Google Sign-In with silent restore (no email/password auth).
- Export: CSV export for expenses plus budget summary and future expenses.
- Forex: multi-currency handling with automatic FX rate fetch and budget conversions.
- Offline-friendly: local SQLite cache for cards and bank icon data with Firestore sync.

## Requirements
- Flutter SDK (current project built on 3.38) (see pubspec.yaml).
- Firebase project with Google Sign-In enabled.
- Android/iOS tooling (Android Studio/Xcode) and a configured emulator/device.

## Quick Start
1. Install dependencies:
   ```bash
   flutter pub get
   ```
2. Configure Firebase (see setup below):
   ```bash
   flutterfire configure
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Project Overview
Morpheus is a personal finance companion built with Flutter. It combines a local-first UX
(SQLite caching, fast UI) with Firebase cloud sync for accounts, cards, and expenses.
Sensitive fields are encrypted in-app before they are written to Firestore. The app also
supports card payment reminders, device app lock, and dashboard summaries.

Highlights:
- Local + cloud sync with offline-friendly reads.
- Encrypted storage for sensitive card/account data.
- Push notifications for card reminders using Cloud Tasks + FCM.
- Monthly per-card spend/utilization snapshots generated on the server.

## Data Model (Firestore)
User-scoped documents:
- users/{uid}/cards/{cardId}
  - encrypted fields: bankName, holderName, cardNumber, expiryDate, cvv
  - reminders: reminderEnabled, reminderOffsets, billingDay, graceDays
- users/{uid}/accounts/{accountId} (encrypted fields)
- users/{uid}/expenses/{expenseId}
- users/{uid}/expense_categories/{categoryId} with fields: name, emoji
- users/{uid}/deviceTokens/{token}
- users/{uid}: timezone, timezoneUpdatedAt
- users/{uid}/reminderLogs/{cardId_offset_dueDate}
- users/{uid}/cardReminderTasks/{cardId}
- users/{uid}/cardSnapshots/{YYYY-MM}

## Local Storage (SQLite)
- File: morpheus.db (sqflite).
- Table: credit_cards (local cache).
- Cache is scoped per user; when uid changes, the local card cache is cleared and reloaded.
- Bank icons come from assets/tables/banks.sqlite.

## Transactions and Ledgers
- paymentSourceType: cash, card, account, wallet.
- transactionType: spend or transfer.
- Card payments are recorded as two expenses (account debit + card credit).
- Ledger pages exist for both accounts and cards.

## Configuration
- Currency settings live in lib/config/app_config.dart:
  - baseCurrency
  - secondaryCurrency
  - enableSecondaryCurrency
- Encryption keys are in lib/services/encryption_service.dart.
  Keep secrets out of the repo and sync the values to Cloud Functions.

## Firebase Setup Guide (Personal Use)
This repo intentionally does NOT include:
- android/app/google-services.json
- ios/Runner/GoogleService-Info.plist
- any private encryption keys or function secrets

Follow these steps to bootstrap your own Firebase project.

### 0) Quick checklist for using your own Firebase project
- Replace android/app/google-services.json and ios/Runner/GoogleService-Info.plist with your own.
- Update .firebaserc or run firebase use --add to point to your project.
- Run flutterfire configure to generate lib/firebase_options.dart.
- Update functions/.env.<projectId> with your secrets.
- If you change regions, update REGION in functions/index.js and the callable region in lib/services/notification_service.dart.

### 1) Create a Firebase project
1. Go to the Firebase Console and create a new project.
2. Enable Google Analytics only if you want it.

### 2) Register app targets
Register each platform you plan to run:
- Android: package name from android/app/src/main/AndroidManifest.xml
- iOS: bundle ID from ios/Runner.xcodeproj

Download:
- google-services.json -> place at android/app/google-services.json
- GoogleService-Info.plist -> place at ios/Runner/GoogleService-Info.plist

These files should stay local; do not commit them.

### 3) Enable Firebase products
In Firebase Console:
- Authentication: enable Google Sign-In
- Firestore: create a database (production or test mode)
- Cloud Messaging: keep defaults (used by FCM)

### 3b) Deploy security rules
This repo includes firestore.rules and storage.rules:
```bash
firebase deploy --only firestore,storage
```

### 4) Configure Google Sign-In (Android)
Add SHA-1 and SHA-256 to your Android app in Firebase Console:
```bash
cd android
./gradlew signingReport
```
Copy the SHA-1/SHA-256 for your debug keystore and add them under the Android app settings in Firebase Console.

### 5) Configure iOS push (optional but recommended)
If you want push notifications on iOS:
- Create an APNs key in Apple Developer portal
- Upload the .p8 key to Firebase -> Project Settings -> Cloud Messaging

### 6) Secrets and encryption
This project uses EncryptionService for sensitive data. Replace the default key/IV in:
- lib/services/encryption_service.dart

For Cloud Functions, set env params in functions/.env.<projectId>:
```
CARD_ENCRYPTION_KEY=your-32-char-key
CARD_ENCRYPTION_IV=your-16-char-iv
TASKS_WEBHOOK_SECRET=your-long-random-secret
```

### 7) Deploy functions (for push reminders)
```bash
cd functions
npm install
firebase deploy --only functions
```
This deploys:
- reminder scheduler and task handler (Cloud Tasks)
- test push function
- monthly snapshot job

Note: Firebase Functions require the Blaze (pay-as-you-go) plan.

## Cloud Tasks (Card Reminder Push)
This app uses a Cloud Tasks pipeline to send timezone-aware card reminder push notifications.

### Why Cloud Tasks
- Accurate timing: schedule reminders per user timezone instead of a single UTC sweep.
- Lower cost: tasks run only when needed; no hourly scans across all cards.
- Resilient: tasks are retried by Cloud Tasks, and a daily reconcile fixes drift.

### Architecture (Step-by-step)
1. App startup stores timezone at users/{uid}.timezone.
2. Card writes (users/{uid}/cards/{cardId}) trigger syncCardReminders.
3. syncCardReminders deletes old tasks and schedules new ones for each offset.
4. Each task hits sendCardReminderTask, which:
   - validates the payload and card config
   - sends FCM push to users/{uid}/deviceTokens
   - logs the send in users/{uid}/reminderLogs/{cardId_offset_dueDate}
   - enqueues the next task for the same offset
5. sendCardReminders runs daily at 03:00 UTC to reconcile missing/expired tasks.

### Key resources
- Queue: card-reminders (region europe-west1)
- Task handler: sendCardReminderTask (HTTP)
- Resync triggers: syncCardReminders (card writes), syncUserTimezone (timezone changes)
- Task registry: users/{uid}/cardReminderTasks/{cardId}
- Logs: users/{uid}/reminderLogs/{cardId_offset_dueDate}

### Setup guide
1. Install functions dependencies:
   ```bash
   cd functions
   npm install
   ```
2. Configure env params (recommended):
   - TASKS_WEBHOOK_SECRET (required for securing the task endpoint)
   - CARD_ENCRYPTION_KEY, CARD_ENCRYPTION_IV (if you are not using defaults)
   You can set them in .env.<projectId> or via:
   ```bash
   firebase functions:config:set TASKS_WEBHOOK_SECRET="..." CARD_ENCRYPTION_KEY="..." CARD_ENCRYPTION_IV="..."
   ```
3. Ensure the queue exists (auto-created at runtime, or create once):
   ```bash
   gcloud tasks queues create card-reminders --location=europe-west1
   ```
4. Deploy:
   ```bash
   firebase deploy --only functions
   ```
5. Launch the app once so it stores timezone and registers FCM tokens.

### Testing
- Enable Test Mode in Settings and tap "Test push" on a card.
- Verify logs appear under users/{uid}/reminderLogs.
- Check Cloud Tasks queue for scheduled tasks in europe-west1.

### Troubleshooting
- 500 errors during deploy: ensure Cloud Run, Eventarc, Tasks APIs are enabled.
- Tasks not firing: verify the queue exists in europe-west1 and the task handler is deployed.
- 403 from task handler: set TASKS_WEBHOOK_SECRET and confirm the header is sent.

### Cost controls
- The reconcile job runs once per day instead of hourly.
- The monthly snapshot job uses maxInstances: 1 and runs only once per month.
- Task queue rate limits are capped to avoid spikes.

### Security
- TASKS_WEBHOOK_SECRET protects the task handler from public abuse.
- Functions are deployed in europe-west1 for EU latency.

### Required APIs
- Cloud Tasks, Cloud Scheduler, Cloud Run, Eventarc, Pub/Sub

## Notes
- Permissions: exports request storage access on Android; files land in Download/morpheus_exports/ (or Documents on other platforms).
- Encryption: cards/accounts are encrypted before Firestore writes; decryption happens on fetch. Existing unencrypted docs should be re-saved to apply encryption.
- Bank icons: the bundled banks.sqlite supplies bank icons; these are stored with cards and shown beside bank names.
- Customization: card color picker supports presets and custom hues; theming lives under lib/theme/.

## Scripts
- Format code: dart format lib
- Run app: flutter run
- Run tests: flutter test

## License
MIT license.
