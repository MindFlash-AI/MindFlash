# MindFlash: Technical Documentation & Architecture Guide

## Table of Contents
1. [Overview & Architecture](#1-overview--architecture)
2. [Project Structure](#2-project-structure)
3. [Core Dependencies](#3-core-dependencies)
4. [Data Models & Firestore Schema](#4-data-models--firestore-schema)
5. [Services & Business Logic](#5-services--business-logic)
6. [State Management & Data Flow](#6-state-management--data-flow)
7. [UI Components & Navigation](#7-ui-components--navigation)
8. [Authentication Flow](#8-authentication-flow)
9. [Firebase Integration & Security](#9-firebase-integration--security)
10. [Performance & Cost Optimization](#10-performance--cost-optimization)
11. [Error Handling](#11-error-handling)

---

## 1. Overview & Architecture

**MindFlash** is a cross-platform (Mobile & Web) AI-powered study application built with Flutter, Firebase, and Google's Gemini API. It allows users to generate, manage, and study flashcards using a Spaced Repetition System (SRS), take AI-generated quizzes, chat with an interactive AI Tutor, and take rich notes in a "Study Pad".

### Architectural Paradigms
- **Cross-Platform Responsive Design:** The app utilizes `LayoutBuilder` extensively at the screen level (e.g., `DashboardScreen` delegating to `DashboardMobile` or `DashboardWeb`) to provide tailored experiences for mobile and desktop web browsers without duplicating core business logic.
- **Service-Oriented Architecture (SOA):** Business logic, external API calls, and database operations are decoupled from the UI and housed in Singleton or instanced service classes within `lib/services/`.
- **Offline-Capable (Partial):** By utilizing local `SharedPreferences` caching (e.g., in `DashboardScreen`) and Firestore's native caching, the app provides a snappy initial load while syncing in the background.
- **Secure Backend Hand-offs:** Sensitive operations like AI generation, prompt engineering, and energy refilling are entirely offloaded to Firebase Cloud Functions to protect API keys and prevent client-side manipulation.

---

## 2. Project Structure

The codebase follows a feature-by-folder and layer-separated organization.

```text
lib/
├── constants/         # Global constants, colors, theming (AppTheme), and legal texts
├── models/            # Core Dart data models (Deck, Flashcard, Note, QuizQuestion)
├── screens/           # UI Screens grouped by feature
│   ├── chat/          # AI Tutor chat interface
│   ├── dashboard/     # Main user dashboard and deck listing
│   ├── deck_view/     # Detailed view of a single deck and its cards
│   ├── loading_screen/# Initial splash/loading animations
│   ├── login/         # Authentication UI
│   ├── quiz/          # Multiple-choice quiz interface
│   ├── review/        # Flashcard swiping / SRS study session
│   ├── settings/      # User preferences and account management
│   ├── study_pad/     # Rich text and drawing note-taking interface
│   └── web_landing/   # Public-facing marketing page for web
├── services/          # Business logic, Firebase wrappers, and API clients
├── utils/             # Helper functions (e.g., math_markdown.dart)
└── widgets/           # Globally shared UI components and Dialogs
functions/             # Firebase Cloud Functions (Node.js)
```

---

## 3. Core Dependencies

Defined in `pubspec.yaml`, the project relies on several key packages:

- **Framework:** `flutter` (SDK ^3.9.2)
- **Firebase:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_app_check`
- **Monetization:** `purchases_flutter`, `purchases_ui_flutter` (RevenueCat)
- **Ads:** `google_mobile_ads`
- **AI/ML:** `google_mlkit_digital_ink_recognition` (for Study Pad drawing)
- **UI/UX:** 
  - `flutter_markdown`, `flutter_math_fork` (LaTeX rendering)
  - `shimmer` (Loading skeletons)
  - `audioplayers` (Quiz feedback sounds)
  - `flutter_quill` (Rich text editing in Study Pad)
- **Utility:** `shared_preferences`, `uuid`, `http`

---

## 4. Data Models & Firestore Schema

Models reside in `lib/models/` and include robust `toMap` and `fromMap` serialization tailored for Firestore.

### 4.1. Firestore Schema & Security Truncation
All models strictly enforce Firestore payload limits during the `toMap()` serialization phase to guarantee compliance with security rules and prevent silent network failures.

*   **Deck (`decks/{deckId}`)**
    *   `id` (String)
    *   `name` (String, truncated to < 500 chars)
    *   `subject` (String)
    *   `cardCount` (Int)
    *   `cardOrder` (List<String>)
    *   `createdAt` (Timestamp)
*   **Flashcard (`cards/{cardId}`)**
    *   `id`, `deckId` (String)
    *   `question`, `answer` (String, truncated to < 3000 chars)
    *   `isMastered`, `isFlagged` (Bool)
    *   `repetitions`, `interval` (Int)
    *   `easeFactor` (Double)
    *   `nextReviewDate` (Timestamp)
    *   `lastScore` (Int?)
*   **Note (`notes/{noteId}`)**
    *   `id`, `title` (String)
    *   `content` (String, truncated to < 100,000 chars)
    *   `drawingData` (String)
    *   `updatedAt` (Timestamp)
    *   `isTrashed` (Bool) - Implements soft-delete logic.
*   **Stats (`users/{userId}/stats/energy`)**
    *   `energy` (Int)
    *   `lastResetDate` (Timestamp)
    *   *Note: Client cannot write to this document; read-only.*

---

## 5. Services & Business Logic

The `lib/services/` directory isolates side effects and external dependencies.

### 5.1. Storage Services (`deck_storage_service.dart`, `card_storage_service.dart`, `note_storage_service.dart`)
- **Responsibility:** Act as repositories wrapping `FirebaseFirestore`.
- **Optimizations:** 
  - **Array Chunking:** Methods like `addCards`, `updateCards`, and `deleteCards` automatically split requests into chunks of 450 to avoid exceeding Firestore's 500-write batch limit.
  - **Count Aggregation:** `NoteStorageService` uses `collection.count().get()` instead of fetching documents to determine limits.
  - **Soft Deletion:** Notes are marked `isTrashed` rather than immediately deleted, allowing for a 30-day recovery window.

### 5.2. AI Service (`ai_service.dart`)
- **Responsibility:** Communicates with the Firebase Cloud Function (`/generate-deck`).
- **Features:** 
  - Generates new decks or appends cards to existing decks via prompt engineering.
  - Manages the AI Tutor chat context window.
- **Cost Reduction:** Before sending chat history to the backend, it samples a maximum of 10 random cards from the deck (down from 25) to provide context without burning excessive LLM tokens. It strictly limits the length of base64 image strings.

### 5.3. SRS Service (`srs_service.dart`)
- **Responsibility:** Pure Dart logic calculating Spaced Repetition intervals.
- **Algorithm:** Inspired by SuperMemo-2 (SM-2). Takes a `Flashcard` and a user `quality` score (1-5) to calculate the next `easeFactor`, `interval`, and `nextReviewDate`. 

### 5.4. Pro Service (`pro_service.dart`)
- **Responsibility:** Manages RevenueCat integration (`Purchases`) and Firestore entitlement syncing.
- **Architecture:** Subscribes to RevenueCat listeners on mobile AND listens to the `entitlements` map on the user's Firestore document. This ensures that if a user upgrades on the web, their mobile app instantly unlocks premium features.

### 5.5. Energy Service (`energy_service.dart`)
- **Responsibility:** Tracks the user's daily AI usage quota.
- **Architecture:** Establishes a `Stream` to the user's `/stats/energy` document. Refills are executed via a secure HTTP POST to a Firebase Cloud Function, preventing client-side hacking of the energy value.

---

## 6. State Management & Data Flow

MindFlash relies primarily on standard Flutter state management primitives combined with reactive Streams, avoiding heavy third-party boilerplate where possible.

- **Local UI State:** Managed via `StatefulWidget` and `setState`.
- **Global Reactive State:**
  - `ValueNotifier<ThemeMode>`: Controls dark/light mode toggling instantly across the app.
  - `StreamBuilder`: Used extensively to listen to `FirebaseAuth.instance.authStateChanges()` (for routing) and `EnergyService().energyStream` (for updating the energy UI badge in real-time).
  - `ChangeNotifier`: Used by `ProService` to notify the UI when subscription status changes.
- **Data Fetching & Caching:** 
  - `DashboardScreen` utilizes `SharedPreferences` to cache the user's list of decks as an encrypted JSON string (using `SecureCacheService`). This ensures the dashboard paints instantly while a background Firestore query fetches updates.

---

## 7. UI Components & Navigation

The UI is built using Material Design 3 guidelines with extensive custom theming defined in `AppTheme`.

### 7.1. Splitting Web and Mobile
To handle radical layout differences, complex screens utilize a structural pattern:
1.  **Stateful Wrapper:** (e.g., `QuizScreen`) Handles initState, dispose, DB fetching, and heavy business logic.
2.  **Layout Builder:** Returns either a Mobile or Web widget based on constraints.
3.  **Dumb UI Widgets:** `QuizMobile` and `QuizWeb` accept state variables and callback functions, focusing entirely on layout.

### 7.2. Extracted Reusable Widgets
Located in `lib/widgets/` and deeply nested folders (e.g., `lib/screens/quiz/widgets/`):
- `ConfirmationDialog`: Standardized alert dialog for destructive actions (deletions).
- `FeedbackDialog`: Standardized success/error modal.
- `WebProGate`: A wrapper widget that blocks access to mobile-only or premium features on the web.
- `UniversalSidebar`: Persistent navigation drawer used on desktop layouts.

---

## 8. Authentication Flow

Managed by `AuthService` (`auth_service.dart`).

1.  **Provider:** Google Sign-In via `google_sign_in` and `firebase_auth`.
2.  **Web Support:** On the web, it uses `signInWithPopup(GoogleAuthProvider())`.
3.  **Mobile Support:** On mobile, it uses the native Google Sign-In SDK to obtain an `idToken` and `accessToken`, which are then passed to `signInWithCredential`.
4.  **Routing:** The `main.dart` root uses a `StreamBuilder` on `authStateChanges`. If user is null, it displays `LoginScreen`; otherwise, it routes to `DashboardScreen`.

---

## 9. Firebase Integration & Security

### 9.1. Cloud Functions (`functions/index.js`)
Acts as a secure proxy between the Flutter app and Google's Gemini API.
- **Middleware:** Enforces Firebase App Check (`requireAppCheck`) and User Authentication (`requireAuth`) on every request.
- **Endpoint `/generate-deck`:** Validates user energy, deducts energy via a Firestore Transaction, contacts Gemini, and returns structured JSON flashcards.
- **Endpoint `/refill-energy`:** Securely resets a user's energy to max (15 or 30 based on Pro status).

### 9.2. Firestore Security Rules
The rules (`firestore.rules`) are the ultimate source of truth, heavily restricting operations:
- Users can only read/write documents where `request.auth.uid == userId`.
- **Anti-Privilege Escalation:** `allow create, update: ... && !request.resource.data.keys().hasAny(['entitlements', 'subscriptions']);` prevents users from hacking their Pro status.
- **Data Validation:** Strict type and size limits are enforced (e.g., `request.resource.data.name is string && request.resource.data.name.size() < 500`).
- **Read-Only Stats:** `/stats/energy` and `/stats/subscription` strictly deny `create` and `update` from the client.

---

## 10. Performance & Cost Optimization

MindFlash implements several critical optimizations to protect UI frame rates and reduce cloud billing:

1.  **Reduced Firestore Reads (AI Chat):** The AI Chat screen caches the deck's flashcards in memory upon initialization rather than querying Firestore on every single message sent. This saves thousands of redundant read operations per user session.
2.  **Debounced Writes (Quiz Screen):** In `QuizScreen`, writing progress to `SharedPreferences` is debounced by 800ms. Rapidly clicking through questions results in only a single disk write instead of dozens.
3.  **Batched Operations:** Deleting a deck triggers `deleteCardsByDeck`, which chunks up to 450 delete operations into a single Firestore `WriteBatch`, turning hundreds of network requests into one.
4.  **Payload Truncation:** The `AIService` truncates overly large strings (like massive pasted documents) *before* sending the HTTP request, saving client egress bandwidth.
5.  **Count Aggregation:** `getNotesCount()` utilizes the server-side `count()` function, costing exactly 1 read, avoiding the bandwidth and cost of downloading a massive collection to the client.

---

## 11. Error Handling

- **Graceful Degradation:** When Firestore fetches fail, repositories catch the exception, log it, and return empty lists `[]` rather than crashing the UI.
- **AI Fallbacks:** If the Gemini API fails (e.g., rate limits, safety blocks), the Cloud Function returns standardized error JSON. `AIService` parses this and maps it to user-friendly messages (e.g., "The AI is a little overwhelmed...").
- **Energy Interception:** If an AI action is triggered but the user has 0 energy, the UI preempts the API call entirely, immediately showing the `Energy Empty` dialog to prompt a rewarded ad or wait period.