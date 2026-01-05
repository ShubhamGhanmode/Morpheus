<div align="center">

# 💰 Morpheus

### A Modern Personal Finance Companion

[![Flutter](https://img.shields.io/badge/Flutter-3.38+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.8+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)

**Track expenses • Manage credit cards • Set budgets • Stay on top of your finances**

[Features](#-features) • [Screenshots](#-screenshots) • [Architecture](#-architecture) • [Getting Started](#-getting-started) • [Tech Stack](#-tech-stack)

</div>

---

## 🎯 What is Morpheus?

Morpheus is a **full-featured personal finance app** built with Flutter that demonstrates industry-standard mobile development practices. It combines a **local-first architecture** with **real-time cloud sync**, providing a seamless experience whether you're online or offline.

### Why This Project Stands Out

| Aspect | Implementation |
|--------|----------------|
| **Architecture** | Clean separation with BLoC/Cubit pattern, repository layer, and service abstraction |
| **Security** | AES-256 encryption for sensitive data before cloud storage |
| **Cloud Infrastructure** | Firebase Auth, Firestore, Cloud Functions (Gen 2), Cloud Tasks, FCM |
| **Offline Support** | SQLite caching with automatic Firestore synchronization |
| **Code Quality** | Freezed models, type-safe JSON serialization, comprehensive error handling |
| **Notifications** | Timezone-aware push reminders via Cloud Tasks pipeline |

---

## ✨ Features

### 💳 Credit Card Management
- Track multiple credit cards with billing cycles
- Set usage limits and monitor utilization
- **Smart payment reminders** with configurable offsets (e.g., 3 days before due date)
- Record partial/full payments linked to accounts
- Per-card spending analytics and monthly snapshots

### 📊 Expense Tracking
- Log expenses with categories, notes, and payment sources
- Smart expense search with filters and query syntax
- **Multi-currency support** with automatic FX rate conversion
- Receipt scanning via Document AI (default) or Cloud Vision (preview, date extraction, category suggestions; toggle in AppConfig/settings)
- Receipt scans create a grouped entry (merchant + timestamp) with stored receipt metadata (image path, totals, receipt date)
- Category labels fall back to default emojis when stored emojis are missing or invalid
- Plan future expenses and recurring transactions
- Dashboard with spending analytics and charts
- All expenses list view is modularized for easier customization
- Default category seeds are consolidated (produce/dairy under Groceries)
- Rule-based category suggestions map produce/dairy keywords to Groceries

### 💰 Budget Management
- Set period-based budgets (weekly, monthly, yearly)
- Category-specific budget tracking
- Real-time budget utilization alerts
- Cross-currency budget calculations

### 🏦 Accounts & Payment Sources
- Track bank accounts, wallets, and cash
- Complete ledger history per account
- Balance tracking across payment sources

### 🔐 Security & Privacy
- **Biometric/PIN app lock** using device authentication
- **Client-side encryption** for sensitive card data (card numbers, CVV, etc.)
- User-scoped data isolation in Firestore
- No third-party analytics or tracking

### 📱 User Experience
- Material 3 design with customizable themes
- Offline-first with instant UI responses
- CSV export for expenses, budget summary, and planned expenses (separate files)
- Google Sign-In with silent session restore

---

## 📸 Screenshots

<!-- Add your screenshots here -->
<div align="center">
<i>Screenshots coming soon</i>

<!-- Example format when you add screenshots:
<img src="screenshots/dashboard.png" width="200" alt="Dashboard" />
<img src="screenshots/cards.png" width="200" alt="Cards" />
<img src="screenshots/expenses.png" width="200" alt="Expenses" />
<img src="screenshots/budgets.png" width="200" alt="Budgets" />
-->
</div>

---

## 🏗 Architecture

Morpheus follows a **clean, layered architecture** designed for maintainability and testability:

```
┌─────────────────────────────────────────────────────────┐
│                        UI Layer                         │
│         (Pages, Widgets, Sheets, Dialogs)               │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                    State Management                     │
│              (BLoC / Cubit + Equatable)                 │
└─────────────────────────┬───────────────────────────────┘
                          │
┌─────────────────────────▼───────────────────────────────┐
│                   Repository Layer                      │
│        (Firestore sync + SQLite cache logic)            │
└──────────────┬──────────────────────────┬───────────────┘
               │                          │
┌──────────────▼──────────┐  ┌────────────▼───────────────┐
│     Cloud Services      │  │      Local Storage         │
│  (Firestore, FCM, Auth) │  │   (SQLite, SecureStorage)  │
└─────────────────────────┘  └────────────────────────────┘
```

### Key Design Decisions

- **Offline-First**: SQLite cache ensures fast reads; Firestore streams handle real-time sync
- **Encrypted at Rest**: Sensitive fields (card numbers, CVV) are AES-encrypted before upload
- **Server-Side Scheduling**: Cloud Tasks enable per-user timezone-aware reminder delivery
- **Platform Abstraction**: Conditional exports (`_io.dart` / `_web.dart`) for platform-specific code

---

## 🛠 Tech Stack

### Frontend
| Technology | Purpose |
|------------|---------|
| **Flutter 3.38+** | Cross-platform UI framework |
| **Dart 3.8+** | Programming language with null safety |
| **flutter_bloc** | State management (BLoC/Cubit pattern) |
| **freezed** | Immutable data classes with code generation |
| **fl_chart** | Beautiful expense visualization charts |
| **sqflite** | Local SQLite database for offline caching |

### Backend (Firebase)
| Technology | Purpose |
|------------|---------|
| **Firebase Auth** | Google Sign-In authentication |
| **Cloud Firestore** | Real-time NoSQL database |
| **Cloud Functions (Gen 2)** | Serverless backend logic |
| **Document AI / Vision API** | Receipt OCR parsing |
| **Cloud Tasks** | Scheduled reminder delivery |
| **Cloud Messaging (FCM)** | Push notifications |
| **Crashlytics** | Crash reporting and analytics |

### Security
| Technology | Purpose |
|------------|---------|
| **flutter_secure_storage** | Encrypted key-value storage |
| **local_auth** | Biometric/PIN authentication |
| **crypto / encrypt** | AES-256 encryption for sensitive data |
| **Sentry** | Error monitoring and reporting |

---

## 🚀 Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

| Tool | Version | Installation Guide |
|------|---------|-------------------|
| **Flutter SDK** | 3.38+ | [flutter.dev/docs/get-started](https://flutter.dev/docs/get-started/install) |
| **Dart SDK** | 3.8+ | Included with Flutter |
| **Android Studio** | Latest | [developer.android.com](https://developer.android.com/studio) |
| **Xcode** (macOS only) | 14+ | Mac App Store |
| **Node.js** | 18+ | [nodejs.org](https://nodejs.org) (for Cloud Functions) |
| **Firebase CLI** | Latest | `npm install -g firebase-tools` |

### Step 1: Clone the Repository

```bash
git clone https://github.com/ShubhamGhanmode/Morpheus.git
cd morpheus
```

### Step 2: Install Flutter Dependencies

```bash
flutter pub get
```

### Step 3: Set Up Firebase (Required)

This project requires your own Firebase project. Follow these steps:

#### 3.1 Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click **"Create a project"** or **"Add project"**
3. Name your project (e.g., "morpheus-finance")
4. Enable/disable Google Analytics (optional)
5. Click **"Create project"**

#### 3.2 Register Your App

**For Android:**
1. In Firebase Console, click **"Add app"** → Android
2. Package name: `com.example.morpheus` (or check `android/app/build.gradle.kts`)
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

**For iOS:**
1. Click **"Add app"** → iOS
2. Bundle ID: Check `ios/Runner.xcodeproj/project.pbxproj`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/GoogleService-Info.plist`

#### 3.3 Enable Firebase Services

In Firebase Console, enable these services:

| Service | Location | Settings |
|---------|----------|----------|
| **Authentication** | Build → Authentication → Sign-in method | Enable **Google** provider |
| **Cloud Firestore** | Build → Firestore Database | Create database (start in **test mode** for development) |
| **Cloud Messaging** | Engage → Messaging | Enabled by default |

#### 3.4 Configure Android SHA Keys (Required for Google Sign-In)

```bash
cd android
./gradlew signingReport
```

Copy the **SHA-1** and **SHA-256** fingerprints and add them in:
- Firebase Console → Project Settings → Your Android app → Add fingerprint

#### 3.5 Generate Firebase Options

```bash
# Install FlutterFire CLI if not installed
dart pub global activate flutterfire_cli

# Configure (select your project and platforms)
flutterfire configure
```

This generates `lib/firebase_options.dart`.

### Step 4: Deploy Firestore Security Rules

```bash
firebase login
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore,storage
```

### Step 5: Run the App

```bash
# For Android
flutter run

# For iOS (macOS only)
cd ios && pod install && cd ..
flutter run
```

🎉 **Congratulations!** The app should now be running on your device/emulator.

---

## ⚡ Advanced Setup (Optional)

### Push Notifications with Cloud Tasks

For timezone-aware card payment reminders, you need to deploy Cloud Functions:

> **Note**: Cloud Functions require the Firebase **Blaze (pay-as-you-go)** plan.

#### 1. Set Up Secrets

```bash
# Navigate to functions directory
cd functions
npm install

# Set required secrets
firebase functions:secrets:set TASKS_WEBHOOK_SECRET
firebase functions:secrets:set CARD_ENCRYPTION_KEY
firebase functions:secrets:set CARD_ENCRYPTION_IV
```

| Secret | Description | Example |
|--------|-------------|---------|
| `TASKS_WEBHOOK_SECRET` | Protects task endpoint from abuse | Any long random string |
| `CARD_ENCRYPTION_KEY` | 32-character AES key | Must match `encryption_service.dart` |
| `CARD_ENCRYPTION_IV` | 16-character IV | Must match `encryption_service.dart` |

#### 2. Create Cloud Tasks Queue

```bash
gcloud tasks queues create card-reminders --location=europe-west1
```

#### 3. Deploy Functions

```bash
firebase deploy --only functions
```

This deploys:
- `syncCardReminders` - Firestore trigger for card changes
- `sendCardReminderTask` - HTTP handler for Cloud Tasks
- `sendCardReminders` - Daily reconciliation job
- `scanReceipt` - Receipt OCR (Google Vision)
- `scanReceiptDocumentAi` - Receipt OCR (Document AI via Cloud Functions)
- `computeMonthlyCardSnapshots` - Monthly summary generator

#### 4. Enable Required APIs

In [Google Cloud Console](https://console.cloud.google.com/apis/library), enable:
- Cloud Tasks API
- Cloud Scheduler API
- Cloud Run API
- Eventarc API
- Document AI API
- Vision API

### Receipt Scanning (Document AI / Vision)
1. Document AI: enable the API and configure Cloud Functions with
   `DOC_AI_PROJECT_ID`, `DOC_AI_LOCATION`, `DOC_AI_PROCESSOR_ID`
   (optional `DOC_AI_ENDPOINT`), then deploy Functions.
2. Cloud Vision: enable the Vision API and deploy Cloud Functions after installing
   dependencies in `functions/`.
3. Set `AppConfig.enableReceiptScanning = true` to show the scan UI and choose
   the provider in settings.

### iOS Push Notifications

1. Create an APNs key in [Apple Developer Portal](https://developer.apple.com)
2. Upload the `.p8` key to Firebase Console → Project Settings → Cloud Messaging

---

## 📁 Project Structure

```
morpheus/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── navigation_bar.dart       # Bottom navigation shell
│   ├── accounts/                 # Accounts feature module
│   ├── auth/                     # Authentication (BLoC pattern)
│   ├── bills/                    # Bills calendar feature
│   ├── cards/                    # Credit cards feature
│   ├── categories/               # Expense categories
│   ├── config/                   # App configuration
│   ├── expenses/                 # Expenses feature (full module)
│   │   ├── bloc/                 # ExpenseBloc + events/states
│   │   ├── models/               # Freezed data models
│   │   ├── repositories/         # Firestore + cache logic
│   │   └── view/                 # UI pages and widgets
│   ├── services/                 # Core services
│   │   ├── encryption_service.dart
│   │   ├── notification_service.dart
│   │   └── forex_service.dart
│   ├── theme/                    # Material 3 theming
│   └── utils/                    # Shared utilities
├── functions/                    # Firebase Cloud Functions (Node.js)
│   └── index.js
├── firestore.rules               # Firestore security rules
└── pubspec.yaml
```

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/

# Format code
dart format lib

# Analyze code
flutter analyze
```

### Test Files
- `test/expense_service_test.dart` - Expense service unit tests
- `test/statement_dates_test.dart` - Statement date calculations
- `integration_test/expense_form_sheet_test.dart` - Expense form integration
- `integration_test/bills_calendar_page_test.dart` - Bills calendar integration

---

## 🔧 Configuration

### Currency Settings
Edit `lib/config/app_config.dart`:
```dart
static const String baseCurrency = 'EUR';
static const String secondaryCurrency = 'USD';
static const bool enableSecondaryCurrency = true;
```

### Receipt Scanning
Receipt OCR is disabled by default. Enable it in `lib/config/app_config.dart`:
```dart
static const bool enableReceiptScanning = true;
```
Choose the provider in settings (Document AI default, Cloud Vision optional). The selection is
stored in app settings and drives the scan flow. For Document AI,
configure Cloud Functions with `DOC_AI_PROJECT_ID`, `DOC_AI_LOCATION`,
`DOC_AI_PROCESSOR_ID` (optional `DOC_AI_ENDPOINT`) and deploy Functions. When using
Cloud Vision, deploy Cloud Functions and turn on the Vision API in your GCP project.
The client parser normalizes Document AI response maps to avoid Dart key-cast issues.
Receipt scans upload the image to Storage under `users/{uid}/receipt_scans/` and store the
`receiptImageUri`, `currency`, `totalAmount`, and `receiptDate` on the group doc for later review.

### Encryption Keys
Edit `lib/services/encryption_service.dart`:
```dart
// Replace with your own 32-char key and 16-char IV
static const String _key = 'YOUR_32_CHARACTER_KEY_HERE_____';
static const String _iv = 'YOUR_16_CHAR_IV_';
```

> ⚠️ **Important**: Never commit real encryption keys to version control!

---

## 🤝 Contributing

Contributions are welcome! Please read the [AGENTS.md](AGENTS.md) file for:
- Architecture guidelines
- Code conventions
- State management patterns
- Testing requirements

### Development Workflow
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes
4. Run tests: `flutter test`
5. Commit: `git commit -m 'Add amazing feature'`
6. Push: `git push origin feature/amazing-feature`
7. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - Beautiful native apps in record time
- [Firebase](https://firebase.google.com) - Backend infrastructure
- [flutter_bloc](https://bloclibrary.dev) - State management
- [freezed](https://pub.dev/packages/freezed) - Immutable data classes
- [fl_chart](https://pub.dev/packages/fl_chart) - Charts and graphs

---

<div align="center">

**Built with ❤️ using Flutter**

If you found this project helpful, please consider giving it a ⭐

</div>
