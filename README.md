# 🧠 MindFlash AI

## 📖 Overview
MindFlash AI is a smart, interactive study assistant and flashcard application built with Flutter. It leverages the power of Google's Gemini AI to automatically generate study decks from notes and documents, provides a context-aware conversational AI tutor, and features robust local study tools including interactive flashcard reviews and dynamically generated multiple-choice quizzes.

Designed to be a high-performance and accessible alternative to traditional study platforms, MindFlash seamlessly bridges the gap between powerful cloud-based AI generation and rapid, offline-first review mechanisms.

---

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    match /users/{userId} {
      
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // 1. CREATE: Prevent malicious users from injecting Pro fields
      allow create: if request.auth != null && request.auth.uid == userId
                    && !request.resource.data.keys().hasAny(['entitlements', 'subscriptions']);
      
      // 2. UPDATE: Protect existing subscription fields
      allow update: if request.auth != null && request.auth.uid == userId
                    && !request.resource.data.diff(resource.data).affectedKeys().hasAny(['entitlements', 'subscriptions']);
      
      // 3. DELETE: GDPR wipe
      allow delete: if request.auth != null && request.auth.uid == userId;
      
      // --- ENHANCED SCHEMA VALIDATION ---

      match /decks/{deckId} {
        allow read, delete: if request.auth != null && request.auth.uid == userId;
        // Require name and subject, prevent massive text spam (limit to ~500 chars)
        allow create, update: if request.auth != null && request.auth.uid == userId
                              && request.resource.data.name is string 
                              && request.resource.data.name.size() < 500
                              && request.resource.data.subject is string
                              && request.resource.data.subject.size() < 500;
      }

      match /cards/{cardId} {
        allow read, delete: if request.auth != null && request.auth.uid == userId;
        // Prevent massive card content (limit to ~3000 chars per question/answer)
        allow create, update: if request.auth != null && request.auth.uid == userId
                              && request.resource.data.question is string 
                              && request.resource.data.question.size() < 3000
                              && request.resource.data.answer is string
                              && request.resource.data.answer.size() < 3000;
      }

      match /chat/{deckId} {
        allow read, delete: if request.auth != null && request.auth.uid == userId;
        allow create, update: if request.auth != null && request.auth.uid == userId;
      }
      
      match /notes/{noteId} {
        allow read, delete: if request.auth != null && request.auth.uid == userId;
        // Notes can be larger, but still cap them to prevent 1MB payload attacks
        allow create, update: if request.auth != null && request.auth.uid == userId
                              && request.resource.data.title is string
                              && request.resource.data.content is string
                              && request.resource.data.content.size() < 100000; // ~100kb limit
      }
      
      match /stats/subscription { 
        allow read: if request.auth != null && request.auth.uid == userId;
        allow delete: if request.auth != null && request.auth.uid == userId;
        allow create, update: if false; 
      }

      match /stats/energy {
        allow read: if request.auth != null && request.auth.uid == userId;
        allow delete: if request.auth != null && request.auth.uid == userId;
        allow create, update: if false;
      }
    }
  }
}