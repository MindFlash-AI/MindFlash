# MindFlash: Technical Documentation & Architecture Guide

## Table of Contents
1. [Overview & Core Mission](#1-overview--core-mission)
2. [Technical Architecture](#2-technical-architecture)
3. [Feature Deep-Dive](#3-feature-deep-dive)
    - [AI Tutor & Smart Generation](#31-ai-tutor--smart-generation)
    - [SRS Study Engine](#32-srs-study-engine)
    - [Study Pad (Hybrid Note-Taking)](#33-study-pad-hybrid-note-taking)
    - [Interactive Quizzes](#34-interactive-quizzes)
4. [Project Structure & Modules](#4-project-structure--modules)
5. [Data Models & Storage Strategy](#5-data-models--storage-strategy)
6. [Service Layer & API Integrations](#6-service-layer--api-integrations)
7. [UI/UX & Theming (HCI Principles)](#7-uiux--theming-hci-principles)
8. [Authentication & Security](#8-authentication--security)
9. [Economic Model & Monetization](#9-economic-model--monetization)
10. [Performance & Cost Optimization](#10-performance--cost-optimization)
11. [Error Handling & Resilience](#11-error-handling--resilience)
12. [Future Roadmap](#12-future-roadmap)
13. [Launching Marketing Strategy (Pro Version)](#13-launching-marketing-strategy-pro-version)

---

## 1. Overview & Core Mission

**MindFlash** is an intelligent, cross-platform study ecosystem designed to bridge the gap between passive reading and active recall. By leveraging Google's Gemini LLM and a scientifically grounded Spaced Repetition System (SRS), MindFlash automates the creation of high-quality study materials from any source (PDFs, images, or raw text) and manages the learner's schedule to maximize long-term retention.

---

## 2. Technical Architecture

The application follows a **Clean Architecture** inspired pattern with a focus on responsiveness and decoupled services.

- **Frontend:** Flutter (v3.9.2) targets iOS, Android, and Web from a single codebase.
- **Backend:** Firebase (Auth, Firestore, Cloud Functions).
- **AI Core:** Gemini 3.1 Flash-Lite accessed via secure Firebase Cloud Function proxies.
- **Service-Oriented Logic:** UI components never talk to the DB directly; they interact through a robust service layer in `lib/services/`.

---

## 3. Feature Deep-Dive

### 3.1. AI Tutor & Smart Generation
The AI engine (`AIService`) is the heart of MindFlash.
- **Deck Generation:** Uses prompt engineering to transform documents into structured JSON flashcards. It enforces a strict **100-card limit per deck** and **20-deck limit per user** at the service level to maintain database stability.
- **Tutor Chat:** An interactive conversation interface where students can ask for explanations of specific cards. 
- **Contextual Awareness:** The tutor is fed a **randomly sampled window of 10 cards** from the current deck to ensure it understands the specific terminology and depth of the user's study material without exceeding LLM token limits.

### 3.2. SRS Study Engine
The `SRSService` implements a modified SM-2 algorithm to manage memory decay.
- **Scoring:** Users grade themselves on a scale of 1-5.
- **Exponential Backoff:** Correct answers multiply the review interval by an `easeFactor` (capped at 3.0 to prevent "lost cards").
- **Fuzzing Logic:** To prevent "Review Spikes" (where hundreds of cards fall due on the same day), the service applies a **±5% random fuzz** to all intervals greater than 3 days.
- **Offline Persistence:** Study sessions are recorded locally and batched to Firestore to ensure progress isn't lost during poor connectivity.

### 3.3. Study Pad (Hybrid Note-Taking)
A sophisticated dual-layer interface for active synthesis.
- **Text Layer:** Powered by `flutter_quill` for rich text editing (bold, lists, etc.).
- **Drawing Layer:** A custom-built `DrawingOverlay` using `CustomPainter` for stylus/touch input.
- **Digital Ink Recognition:** Integrates `google_mlkit_digital_ink_recognition` to convert handwritten notes directly into typed text within the quill document.
- **AI Pipeline:** Users can select handwritten or typed portions of their notes and send them directly to the AI to "Convert Notes to Deck" in one click.

### 3.4. Interactive Quizzes
Transforms flashcards into multiple-choice tests.
- **Dynamic Options:** The `QuizCreator` service shuffles answers from the same deck to create realistic distractors.
- **Feedback Loop:** Features high-quality audio cues (`sounds/correct.mp3`) and immediate AI explanations for incorrect answers.

---

## 4. Project Structure & Modules

MindFlash is organized by feature-folders to allow for vertical scaling.

- **`lib/screens/`**: Contains the UI for each feature (Chat, Dashboard, Study Pad, etc.).
    - Radical layout differences between Web and Mobile are handled by splitting screens into `_mobile.dart` and `_web.dart` versions, managed by a parent `LayoutBuilder`.
- **`lib/services/`**: Stateless wrappers for Firebase, AI, and SRS logic.
- **`lib/models/`**: Strict Dart classes with Firestore serialization.
- **`lib/widgets/`**: Globally reusable atomic components (buttons, cards, dialogs).

---

## 5. Data Models & Storage Strategy

- **Atomic Writes:** All model `toMap()` methods implement **client-side truncation**. For example, a deck name is truncated to 499 characters *before* the network call, ensuring the Firestore Security Rules are never violated.
- **Batching:** `CardStorageService` chunks large operations (like adding 50 AI-generated cards) into batches of 450 to stay under the Firestore 500-limit.
- **Caching:** `DashboardScreen` caches the entire deck list in `SharedPreferences` (encrypted). This allows the UI to render in **<100ms** while the Firestore query fetches the "source of truth" in the background.

---

## 6. Service Layer & API Integrations

- **`AuthService`**: Manages Google Sign-In with distinct flows for Web (Pop-up) and Mobile (Native SDK).
- **`ProService`**: A singleton that synchronizes **RevenueCat** (Mobile) with **Firestore Entitlements** (Web). This ensures a single subscription works everywhere.
- **`EnergyService`**: Tracks the user's AI quota. Writes are disabled on the client; energy is only deducted/refilled via server-side Firestore Transactions in Cloud Functions.

---

## 7. UI/UX & Theming (HCI Principles)

MindFlash follows Human-Computer Interaction (HCI) best practices:
- **Glare Reduction:** Uses a custom "Soothing Slate" background (`0xFFE2E4E9`) in light mode instead of pure white to reduce eye strain during long study sessions.
- **Interactive Feedback:** Haptic feedback is integrated into every major button press and SRS swipe.
- **3D Physics:** The flashcard stack uses `Matrix4` transformations to provide a realistic 3D flip effect with perspective and "lift" during the transition.

---

## 8. Authentication & Security

- **App Check:** Every request to the AI backend requires a valid `X-Firebase-AppCheck` token, preventing bot spam.
- **Principle of Least Privilege:** Firestore rules strictly enforce `request.auth.uid == userId`. Users cannot even read the *existence* of another user's decks.
- **Model Truncation:** Prevents malicious users from crashing the database by sending multi-megabyte strings in flashcard fields.

---

## 9. Economic Model & Monetization

MindFlash uses a **Hybrid SaaS model**:
- **Free Tier:** Supported by AdMob (Native, Interstitial, Banner). Users get 15 AI Energy credits daily.
- **Pro Tier ($2.49/mo):** Removes all ads, doubles energy to 30, and unlocks **MindFlash Web** (Desktop access).
- **Rewarded Refills:** Free users can watch a 30-second video ad to instantly refill their energy, effectively converting user time into operational cost coverage.

---

## 10. Performance & Cost Optimization

- **StringBuffer Usage:** Extensive use of `StringBuffer` in the `AIService` prevents O(n²) string concatenation overhead during large context builds.
- **Isolate-Based Serialization:** The Study Pad offloads JSON encoding of massive notes to a background `compute()` isolate to keep the UI thread at 60 FPS.
- **Context Sampling:** AI Tutor messages only send the **last 8 messages** of history and **10 random cards**, reducing Gemini input token costs by over 70% compared to a naive implementation.

---

## 11. Error Handling & Resilience

- **AI Hiccup Mapping:** The `AIService` maps technical server errors (503, 429) to student-friendly language ("The AI is a little overwhelmed...").
- **Graceful Loading:** Uses `Shimmer` skeletons and `BackdropFilter` blurs to provide a polished feel even during slow network conditions.
- **Auto-Save Resilience:** The Study Pad implements a **2-second debounced auto-save**. If the user exits abruptly, a "Final Save" is triggered in the `dispose()` method to prevent data loss.

---

## 12. Future Roadmap

- **Collaborative Decks:** Shared study rooms with real-time peer quizzes.
- **Deep PDF Analysis:** Advanced RAG (Retrieval-Augmented Generation) to allow chatting with 500+ page textbooks.
- **Institutional Access:** B2B portal for schools and tutoring centers to manage student progress.

---

## 13. Launching Marketing Strategy (Pro Version)

This strategy outlines a practical, high-impact launch for **MindFlash Pro** using a total budget of **$300 USD (~16,800 PHP) + 20,000 PHP**, totaling approximately **36,800 PHP**. 

### 13.1. Campaign Core: The "Founder's Early Bird" Discount
To drive immediate conversion during launch week, we will leverage a **multi-tier discount structure** to create scarcity and rewarding early adopters.

*   **Standard Price:** $2.49 / month.
*   **Launch Tier 1 (First 48 Hours):** $0.99 for the first 3 months (60% discount).
*   **Launch Tier 2 (Rest of Week 1):** $1.49 for the first 3 months (40% discount).
*   **Annual Incentive:** $19.99 for the first year (33% discount vs. monthly).

### 13.2. Budget Allocation (Total: 36,800 PHP)

| Channel | Allocation | Purpose |
| :--- | :--- | :--- |
| **Meta Ads (FB/IG)** | $150 USD (8,400 PHP) | Targeted reach for "Lookalike" student audiences in PH & Global student hubs. |
| **TikTok Ads** | $100 USD (5,600 PHP) | High-engagement video ads showcasing the Study Pad and AI Deck Generation. |
| **Micro-Influencers** | 15,000 PHP | 5-7 PH-based Study-Tok/Study-Gram creators for authentic reviews. |
| **Community Giveaways** | 5,000 PHP | Sponsoring prizes in student Discord servers or Reddit communities (r/studentsph). |
| **Reserve Buffer** | $50 USD (2,800 PHP) | Emergency ad-set scaling for high-performing creatives. |

### 13.3. Phase-by-Phase Execution

#### Phase 1: Pre-Launch Teasing (7 Days Prior)
*   **Objective:** Build an email/waiting list.
*   **Activities:**
    *   Run Meta "Lead Gen" ads focused on the problem: "Tired of manual flashcards?"
    *   Influencers post "Coming Soon" snippets of the Study Pad's digital ink recognition.
    *   **Call to Action (CTA):** "Sign up for the waitlist to unlock the $0.99 Early Bird offer."

#### Phase 2: Launch Week - The Flash Sale (Days 1-7)
*   **Objective:** Convert Free users and Waitlist to Pro.
*   **Activities:**
    *   **Day 1-2:** Email blast and Push Notification to the waitlist: "Your 60% discount is LIVE. 48 hours only."
    *   **Day 3-7:** Shift messaging to Tier 2 discount ($1.49). Focus on "Ad-Free Studying" and "Desktop Web Access."
    *   Influencers release full walkthrough videos using MindFlash to study for real exams.

#### Phase 3: Post-Launch Momentum (Day 8-30)
*   **Objective:** Referral-driven growth.
*   **Activities:**
    *   Launch the "Refer a Friend" program: Give 1 week of Pro for every successful referral.
    *   Retargeting ads: Show ads to users who used the app 3+ times in launch week but didn't upgrade.

### 13.4. Key Performance Indicators (KPIs)
*   **Conversion Rate:** Target 3-5% conversion of DAU to Pro.
*   **CAC (Cost Per Acquisition):** Target < $1.00 USD per Pro subscriber.
*   **ROAS (Return on Ad Spend):** Target 2.0x within the first 60 days.

### 13.5. Practical Advice for the "Founder"
1.  **Creative is King:** Use the $300 USD for platform ads only if you have high-quality, 15-second vertical videos. Use your own phone to film the "Study Pad" in action; raw, authentic content performs better than polished studio ads on TikTok.
2.  **Focus on "Med/Law" PH Students:** Law and Med students in the Philippines have the highest need for SRS and high-volume flashcards. Target these specific interest groups in Meta Ads to maximize your 20,000 PHP budget.
