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
12. [Economic Projections & Cost Analysis](#12-economic-projections--cost-analysis)
13. [Revenue, Income, and Profit Analysis](#13-revenue-income-and-profit-analysis)
14. [Future Recommendations & Roadmap](#14-future-recommendations--roadmap)

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

---

## 12. Economic Projections & Cost Analysis

This section outlines a structured economic model forecasting the operational costs of MindFlash, evaluating Gemini 3.1 Flash-Lite Preview, Firebase Firestore, Cloud Functions, and Firebase Hosting.

### 12.1. Methodology & Pricing Assumptions

Calculations rely on current Google Cloud and Firebase pricing tiers, utilizing the specific architecture constraints of the app.

**Pricing Formulas Used:**
*   **Gemini 3.1 Flash-Lite Preview:**
    *   Cost = (Input Tokens / 1,000,000) × $0.25 + (Output Tokens / 1,000,000) × $1.50
*   **Firestore (assuming `us-central1` standard tier):**
    *   Reads Cost = (Total Reads - 50,000 free/day) / 100,000 × $0.036
    *   Writes Cost = (Total Writes - 20,000 free/day) / 100,000 × $0.108
    *   Deletes Cost = (Total Deletes - 20,000 free/day) / 100,000 × $0.012
    *   Storage Cost = (GB Stored - 1 GB free) × $0.108 / month
*   **Cloud Functions (Gen 2 / Tier 1 base):**
    *   Invocations Cost = (Invocations - 2,000,000 free/month) / 1,000,000 × $0.40
    *   *Note: Compute time (GB-seconds) is assumed negligible due to fast Gemini response times and low-memory allocations (256MB).*
*   **Firebase Hosting:**
    *   Cost = (Bandwidth GB - 10 GB free/month) × $0.15 + (Storage GB) × $0.026

**Daily Active User (DAU) Usage Modeling:**
Based on the application's workflow and limits (max 20 decks, 100 cards/deck, energy limits), an "Average Active User" is modeled per day as:
1.  **AI Deck Generation:** 0.2 times/day (1 generation every 5 days).
    *   Gemini: ~2,000 Input Tokens, ~2,000 Output Tokens.
    *   Firestore: ~25 writes (1 deck + 24 cards).
2.  **AI Tutor Chats:** 2 messages/day.
    *   Gemini: ~1,500 Input Tokens, ~200 Output Tokens (thanks to the 10-card sampling optimization).
    *   Firestore: 1 write (chat history array update).
3.  **Energy Refill:** 0.5 times/day.
    *   Firestore: 1 read, 1 write.
4.  **Standard Study/Review Session:** 1 session/day.
    *   Firestore: ~10 reads (Dashboard cache check) + ~30 reads (Fetch cards) = ~40 reads.
    *   Firestore: ~20 writes (Batched review updates).

**Totals per Average DAU per Day:**
*   **Gemini Tokens:** 3,400 Input | 800 Output
*   **Firestore:** 42 Reads | 28 Writes | 1 Delete (occasional)
*   **Cloud Functions:** 2.7 Invocations

### 12.2. Monthly Projection by Scale (30 Days)

The following matrix extrapolates the "Average Active User" profile across three growth stages: 1K, 10K, and 100K DAU.

| Metric (Monthly) | 1,000 DAU | 10,000 DAU | 100,000 DAU |
| :--- | :--- | :--- | :--- |
| **Gemini Input Tokens** | 102 Million | 1.02 Billion | 10.2 Billion |
| **Gemini Output Tokens** | 24 Million | 240 Million | 2.4 Billion |
| **Firestore Reads** | 1.26 Million | 12.6 Million | 126 Million |
| **Firestore Writes** | 840,000 | 8.4 Million | 84 Million |
| **Function Invocations** | 81,000 | 810,000 | 8.1 Million |
| **Hosting Bandwidth (Est)** | 50 GB | 500 GB | 5,000 GB |

### 12.3. Monthly Cost Breakdown

*Assuming all free tiers are exhausted at the 100K DAU scale for conservative, worst-case paid modeling.*

| Service | Cost Formula | 1,000 DAU | 10,000 DAU | 100,000 DAU |
| :--- | :--- | :--- | :--- | :--- |
| **Gemini Input** | (Tokens/1M) × $0.25 | $25.50 | $255.00 | $2,550.00 |
| **Gemini Output** | (Tokens/1M) × $1.50 | $36.00 | $360.00 | $3,600.00 |
| **Firestore Reads** | (Reads/100K) × $0.036 | Free | $4.54 | $45.36 |
| **Firestore Writes** | (Writes/100K) × $0.108 | Free | $9.07 | $90.72 |
| **Cloud Functions** | (Invokes/1M) × $0.40 | Free | Free | $3.24 |
| **Firebase Hosting** | (GB) × $0.15 | $6.00 | $73.50 | $748.50 |
| **Total Monthly Cost** | | **~$67.50** | **~$698.11** | **~$7,037.82** |

*Note: Per-user cost per month drops significantly at scale but averages incredibly low at **$0.06 - $0.07 per MAU**, largely due to the highly aggressive caching optimizations implemented in `DashboardScreen` and `AIChatScreen`.*

### 12.4. Cost Bottlenecks & Risks

While the projected unit economics are excellent, several bottlenecks present overrun risks if unchecked:

1.  **Image Uploads vs. Token Costs:** The Gemini API converts base64 image strings into token representations. If users frequently upload highly complex, text-dense PDFs or images for the "Quick Scan" feature, the input token count could safely triple, shifting the cost curve drastically. *Risk Level: Medium.*
2.  **Firestore Read Spikes:** The application relies on `SharedPreferences` to cache decks on the dashboard. If users frequently uninstall/reinstall the app or clear cache, it bypasses the offline cache, directly hitting Firestore. *Risk Level: Low (Mitigated by offline persistence).*
3.  **Malicious Energy Depletion:** If bad actors attempt to bypass the client-side energy block, they could spam the Cloud Function. *Risk Level: Low (Mitigated by Server-Side App Check, Auth requirements, and secure transaction-based energy deduction in `functions/index.js`).*

### 12.5. Economic Optimization Strategies

To further compress the cost profile and maximize profit margins (via the Pro subscription and AdMob), the following strategies are actively utilized or recommended:

*   **Token Optimization (Active):** The `processTutorChat` method intentionally shuffles and slices the flashcard context down to exactly 10 cards. This prevents sending 100+ cards (thousands of tokens) as context for a simple chat question, single-handedly reducing Gemini costs by ~60%.
*   **Batched Firestore Writes (Active):** SRS updates are batched locally and sent to Firestore using `WriteBatch` chunks of 450 documents, compressing thousands of potential network calls into unified, efficient writes.
*   **Recommendation - Caching AI Responses:** A significant percentage of users will ask the AI Tutor the exact same questions ("Explain Photosynthesis"). Implementing a Redis cache or Firestore lookup for frequent semantic queries could bypass the Gemini API entirely for common questions.
*   **Recommendation - Hosting CDN:** Ensure rigorous HTTP Cache-Control headers on Flutter Web build artifacts to ensure the aggressive 5TB bandwidth projection at 100k DAU is absorbed mostly by global CDNs and edge caching rather than raw Firebase egress.

---

## 13. Revenue, Income, and Profit Analysis

This section analyzes the revenue potential of MindFlash based on a **$2.49 USD/month** subscription model and AdMob integration, balanced against the operational costs detailed in Section 12.

### 13.1. Revenue Streams

MindFlash utilizes a dual-revenue model:

1.  **Direct Subscription (Pro):** $2.49 USD / Month.
    *   **Platform Fees:** 15% - 30% (Apple/Google). For this model, an average of **20%** is assumed.
    *   **Net Revenue per Sub:** ~$1.99 USD.
2.  **Advertising (Free Tier):**
    *   **Assumed eCPM (Effective Cost Per Mille):** $2.00 (Hybrid of Native, Banner, and Interstitial).
    *   **Impressions per DAU:** 5 (1 Banner session, 1 Native view, 1 Interstitial post-quiz, 2 Rewarded refills).
    *   **Ad Revenue per DAU/Day:** (5 / 1000) × $2.00 = **$0.01 USD / day**.
    *   **Ad Revenue per DAU/Month:** **$0.30 USD / month**.

### 13.2. Financial Projections by Stage

This model assumes a conservative **3% conversion rate** from Free to Pro.

| Stage | DAU | Free Users (97%) | Pro Users (3%) | Monthly OpEx | Monthly Revenue | Net Profit | Margin |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Starter** | 1,000 | 970 | 30 | ~$67.50 | $350.70 | **$283.20** | 80.7% |
| **Growth** | 10,000 | 9,700 | 300 | ~$698.11 | $3,507.00 | **$2,808.89** | 80.1% |
| **Scale** | 100,000 | 97,000 | 3,000 | ~$7,037.82 | $35,070.00 | **$28,032.18** | 79.9% |

**Revenue Breakdown Calculation (Scale Stage):**
*   **Ad Revenue (Free):** 97,000 users × $0.30/mo = $29,100.00
*   **Subscription Revenue (Pro):** 3,000 users × $1.99 (Net) = $5,970.00
*   **Total Gross Monthly Revenue:** **$35,070.00**

### 13.3. Profitability Key Performance Indicators (KPIs)

*   **LTV (Lifetime Value) per Free User:** Assuming 6-month retention, $1.80.
*   **LTV per Pro User:** Assuming 6-month retention, $11.94 (Net).
*   **Average Cost Per User (OpEx):** ~$0.07 / month.
*   **Profit Per User (Weighted Average):** ~$0.28 / month.

### 13.4. Income Risks & Mitigation

1.  **High Churn Rate:** If retention drops below 3 months, the LTV may not cover customer acquisition costs (CAC). *Mitigation:* Focus on the SRS system and streak notifications to build daily habits.
2.  **Ad-Blocking:** If a significant portion of the web landing traffic uses ad-blockers, the $0.30/mo estimate may drop. *Mitigation:* The `WebProGate` already incentivizes Pro for web usage, where ad-blocking is most prevalent.
3.  **App Store Rejections:** RevenueCat integration must be flawless to avoid payment processing interruptions. *Mitigation:* Regular auditing of the `ProService` and RevenueCat webhooks.

### 13.5. Financial Summary

The MindFlash economic model is highly robust. Because Gemini 3.1 Flash-Lite costs are so low and the application implements aggressive client-side caching, the **Operational Margin remains near 80%** even at massive scale. The primary driver of income is the high-volume AdMob revenue from the Free tier, while the $2.49 Pro subscription provides a stable, high-margin baseline for power users.

---

## 14. Future Recommendations & Roadmap

To ensure continued growth, scalability, and long-term maintainability, the following strategic recommendations are proposed for the MindFlash engineering and product teams.

### 14.1. Technical Debt & Architecture Refinement
- **State Management Migration:** Transition from the current `setState`/`ChangeNotifier` hybrid to a more robust, unidirectional state management library like **Riverpod** or **Bloc**. This will facilitate easier unit testing and prevent state-leakage in complex screens like the Study Pad.
- **Unit & Widget Testing:** Implement a comprehensive test suite targeting core business logic (specifically the `SRSService` algorithm) and critical user flows (Auth, Deck Creation, Quiz completion).
- **Centralized API Wrapper:** Standardize the HTTP/Firebase Function call logic into a base `ApiService` class to handle common headers, logging, and error parsing in one location.

### 14.2. Feature Roadmap & User Value
- **Collaborative Study Groups:** Allow users to share decks via public links or join "Study Rooms" for competitive quizzes.
- **Offline-First SRS:** Enhance the mobile app's offline capabilities to allow studying even with 0 network connectivity, syncing SRS progress only when the user returns online.
- **Advanced LaTeX Support:** Expand the `MathBuilder` to support more complex mathematical notations and chemical formulas to appeal to STEM students.
- **Semantic Search:** Implement AI-powered semantic search across all decks and notes, allowing users to find specific concepts across their entire study library.

### 14.3. Cost & Performance Optimization
- **Gemini Cache:** Implement server-side caching for common AI Tutor questions to reduce Gemini API costs.
- **Image Compression Pipeline:** Integrate a client-side image compression library (like `flutter_image_compress`) for the "Quick Scan" feature to significantly reduce token costs associated with high-resolution document uploads.
- **Dynamic Context Loading:** Instead of pre-fetching all cards for AI chat, implement a paginated or "proximity-based" context loader that only sends relevant cards to the AI based on the user's current query.

### 14.4. Monetization & Growth
- **Annual Subscription Discount:** Offer an annual Pro plan at a discounted rate (e.g., $19.99/year) to improve user retention and provide immediate cash flow.
- **Referral Program:** Implement a "Refer a Friend" system where users gain 5 bonus energy credits for every successful signup they refer.
- **Institutional Enterprise Plan:** Create a dashboard for teachers or schools to manage decks for entire classrooms, opening a high-ticket B2B revenue stream.
