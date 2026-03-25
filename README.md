🧠 MindFlash AI

MindFlash AI is a smart, interactive study assistant and flashcard application built with Flutter. It leverages the power of Google's Gemini AI to automatically generate study decks from notes and documents, provides a context-aware conversational AI tutor, and features robust local study tools including interactive flashcard reviews and dynamically generated multiple-choice quizzes.

✨ Key Features

🤖 AI-Powered Study Tools

Generate Decks from Documents: Upload notes or text, and the Firebase-hosted Gemini AI backend will automatically extract key concepts and generate a comprehensive flashcard deck.

Context-Aware AI Chat: Chat directly with the MindFlash AI tutor. The AI is aware of all your locally saved decks and can quiz you, explain concepts, or help you add new cards to existing decks dynamically.

Smart Deck Updates: Ask the AI to expand an existing deck on a specific topic, and it will append new cards seamlessly.

📚 Study & Review Modes

Interactive Review Mode: A clean, gesture-based flashcard stack view for studying terms. Tracks session stats (cards reviewed, remaining) in real-time.

Dynamic Multiple-Choice Quizzes: The app features a custom LocalQuizEngine that intelligently generates multiple-choice questions from your flashcards. It uses a custom scoring algorithm to select the trickiest "distractor" answers from other cards in the same deck.

Persistent Quiz Progress: Quiz progress is automatically saved locally. You can close the app mid-quiz and resume exactly where you left off. Includes intuitive "Previous" and "Next" navigation.

🗂️ Deck Management

Full CRUD Capabilities: Create, read, update, and delete decks and individual flashcards manually.

Local Storage: All decks, cards, and user progress are stored securely on the device using SharedPreferences.

🛠️ Technology Stack

Frontend (Mobile App)

Framework: Flutter (Dart)

Local Storage: shared_preferences

Environment Management: flutter_dotenv

Networking: http package for communicating with the AI backend.

Backend (AI Service)

Infrastructure: Firebase Cloud Functions (v2)

Environment: Node.js & Express.js

AI Integration: @google/generative-ai SDK (Gemini 3.1 Flash-Lite / Gemini 1.5 Flash)

📁 Project Structure

```text
.
├── functions/                     # Firebase Cloud Functions Backend
│   ├── index.js                   # Express app & Gemini API integration
│   ├── package.json               # Backend dependencies
│   └── .env                       # Backend environment variables (GEMINI_API_KEY)
│
└── lib/                           # Flutter Frontend App
├── main.dart                  # App entry point
├── constants.dart             # App-wide UI/UX constants
├── models/                    # Data models (Deck, Flashcard, QuizQuestion)
├── screens/                   # UI Screens
│   ├── chat/                  # AI Conversational interface
│   ├── dashboard/             # Main library and deck overview
│   ├── deck_view/             # Deck details and management
│   ├── loading_screen/        # App loading states
│   ├── quiz/                  # Dynamic multiple-choice quiz UI
│   └── review/                # Flashcard swipe/review UI
├── services/                  # Business Logic & API Calls
│   ├── ai_service.dart        # Communicates with Firebase backend
│   ├── card_storage_service.dart # Local DB operations for cards
│   ├── deck_storage_service.dart # Local DB operations for decks
│   └── quiz_creator.dart      # Local MCQ generation algorithm
└── widgets/                   # Reusable UI components & Dialogs
```

🚀 Setup & Installation

Prerequisites

Flutter SDK installed.

Node.js installed (for Firebase backend).

Firebase CLI installed and authenticated (firebase login).

A Gemini API Key from Google AI Studio.

1. Backend Setup (Firebase Functions)

Navigate to the functions directory:

```bash
cd functions
```

Install dependencies:

```bash
npm install
```

Create a .env file in the functions folder and add your Gemini API Key:

```env
GEMINI_API_KEY=your_actual_api_key_here
```

Deploy the function to Firebase:

```bash
firebase deploy --only functions
```

After deployment, the CLI will output a URL for your function (e.g., https://<region>-<project-id>.cloudfunctions.net/api). Save this URL.

2. Frontend Setup (Flutter)

Navigate to the root of the Flutter project.

Install dependencies:

```bash
flutter pub get
```

Create a .env file in the root of the Flutter project and add your backend URL (append /generate-deck to the URL provided by Firebase):

```env
BACKEND_URL=https://<region>-<project-id>.cloudfunctions.net/api/generate-deck
```

Note: Ensure .env is declared in your pubspec.yaml under assets:.

Run the app:

```bash
flutter run
```

🧠 How the Local Quiz Engine Works

MindFlash AI doesn't rely on the cloud for everything. To save API costs and reduce latency, the multiple-choice quizzes are generated locally on your device using the LocalQuizEngine (lib/services/quiz_creator.dart).

When you start a quiz, the engine:

Takes the correct answer for a flashcard.

Scans every other card in the deck and generates an _AnswerProfile (analyzing word count, length, and presence of numbers).

Uses a custom heuristic scoring algorithm (_calculateFastScore) to rank how "plausible" other answers are as distractors (e.g., prioritizing numbers vs numbers, or similar length answers).

Selects the top 3 trickiest distractors to formulate a 4-option multiple-choice question.

🛡️ Error Handling

The app features robust error handling for AI generation. If the Gemini model experiences high demand (e.g., a 503 Service Unavailable error), the backend passes the exact error trace to the frontend, which gracefully intercepts it and displays a user-friendly dialogue, preventing app crashes.