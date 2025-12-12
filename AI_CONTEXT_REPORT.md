# 🧠 AGENT SYSTEM INSTRUCTION: Travel Hackathon Project Context

**IMPORTANT FOR AI AGENT:**
You are joining a 4-person Hackathon Team building a "Social Travel App".
The User you are pair-programming with is one of the team members.
**You must ALIGN STRICTLY with the context below.** DO NOT deviate from the Architecture, Data Models, or Tech Stack defined here. This project is being built in parallel, and deviations will cause Merge Conflicts.

---

## 🏗️ PART 1: THE CORE VISION (The "Why" & "What")

### 1.1 The Problem
Solo traveling is lonely. Existing apps (Booking.com, TripAdvisor) are transactional. They help you find *places*, but not *people*.
**We are building the "Tinder/Discord for Travelers" layer on top of a Map.**

### 1.2 The "Pivot" (Key Decision)
*   *Initial Idea:* A global chat room for every city.
*   *Why we rejected it:* Too noisy, spammy, unfocused.
*   *The Pivot:* **"Bulletin Board" Model.**
    *   The Map is just the entry point.
    *   Users post specific **TravelEvents** (e.g., "Dinner at 8PM", "Hike tomorrow").
    *   Users join these *specific, temporary* events.
    *   Chat only exists *inside* an Event.

### 1.3 The "Twist" Features (Differentiation)
1.  **Social Hotels:** We don't just list hotels. We show, "3 other Explorers are staying at The Grand Hotel". Goal: Force users to book where the community is.
2.  **Co-op Quests:** Gamification. standard quests are "Go here, get points". OUR quests are "Find a partner and scan this QR code together". (Forces IRL interaction).

---

## 🏛️ PART 2: ARCHITECTURE & TECH STACK (Non-Negotiable)

**Technology:**
*   **Flutter** (Latest Stable)
*   **Riverpod** (State Management - STRICTLY use `@riverpod` or `Provider`. No `Bloc`, no `GetX`).
*   **GoRouter** (Navigation - STRICTLY use URI-based routing `/chat/123`, not `Navigator.push`).
*   **Flutter Map** (OpenStreetMap - Free, no Google API Keys needed for MVP).
*   **Backend:** Node.js (Express) + SQLite (Local).

**Folder Structure (Feature-First Clean Architecture):**
*   **Rule:** Code MUST be inside its specific feature folder.
*   **Rule:** Features cannot import each other's Widgets. They interact only via `AppRouter`.

```
lib/
├── core/                   # Shared logic (Theme, Router, Extensions)
├── features/
├── auth/               # User Authentication (Member 1)
├── map/                # Pins, User Location, displaying the Map (Member 2)
├── social/             # Events, Bulletin Board, Chat Logic (Member 3)
└── discovery/          # Hotels, Quests, Gamification (Member 4)
    ├── data/           # Repositories (Impl), Data Sources
    ├── domain/         # Models (Pure Dart), Abstract Interfaces
    └── presentation/   # Widgets, Riverpod Providers
```

---

## 📜 PART 3: THE "BIBLE" (Data Contracts)

**CRITICAL:** Do not change field names. The entire team relies on these exact JSON structures.

### 3.1 User Model (`lib/features/auth/domain/user_model.dart`)
```dart
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final int explorerPoints;   // Gamification Score
  // Note: Password is stored in DB but NOT in this model
}
```

### 3.2 Destination Pin (`lib/features/map/domain/destination_pin_model.dart`)
*Concept:* A permanent marker on the map (City or Major Landmark).
```dart
class DestinationPin {
  final String id;
  final String city;          // "Paris" (Used availability grouping)
  final String type;          // 'destination' | 'hotel'
  final double latitude;
  final double longitude;
  final int activeVisitorCount; // "12 people here now"
}
```

### 3.3 Travel Event (`lib/features/social/domain/travel_event_model.dart`)
*Concept:* A temporary activity posted on the Bulletin Board.
```dart
class TravelEvent {
  final String id;
  final String city;              // "Paris" (Matches Pin.city)
  final String title;             // "Louvre Visit"
  final DateTime eventDate;
  final bool isDateFlexible;      // Logic: "I can move this if needed"
  final String creatorId;         // ADMIN of the event
  final bool requiresApproval;    // Logic: If true, User sits in pendingRequests
  final List<String> pendingRequestIds;
  final List<String> participantIds; // Accepted members
}
```

### 3.4 Chat (`lib/features/social/domain/chat_model.dart`)
*Concept:* Created AUTOMATICALLY when an Event is created.
```dart
class GroupChat {
  final String id;
  final String eventId;           // Links back to TravelEvent
  final List<String> memberIds;   // SYNCED with TravelEvent.participantIds
}
```

---

## 🚦 PART 4: USER FLOW IMPLEMENTATION

**Step 1: The Map (Map Team)**
*   User opens app -> Sees `MapScreen`.
*   User taps a "City Pin" (e.g., Paris).
*   **Action:** App navigates to `/events?city=Paris`. (Do NOT open a modal. Navigate to a new screen).

**Step 2: The Bulletin Board (Social Team)**
*   User sees `EventsScreen` (List of cards).
*   User filters: "Today", "Flexible Dates".
*   User taps "Join" on an event.

**Step 3: The Connection (Social Team)**
*   *Case A (Open Event):* User is added to `participantIds` immediately. Navigates to `/chat/:eventId`.
*   *Case B (Approval Required):* User is added to `pendingRequestIds`. Button changes to "Pending". Creator must accept them.

---

## 🔄 PART 6: LATEST STATE (Real Backend & Hybrid Auth - 2025-12-12 Part 3)

**Summary:** The application is now fully powered by a local Node.js + SQLite backend. Firebase has been sidelined for Authentication in favor of a custom Hybrid Auth system.

### 6.1 Authentication System (`features/auth`)
*   **Hybrid Auth:**
    *   **Signup:** User provides Email, Password, Name -> OTP Sent -> OTP Verified -> User Created (Password stored).
    *   **Login (Password):** User provides Email/Password -> Verified -> Session Created.
    *   **Login (Password):** User provides Email/Password -> Verified -> Session Created.
    *   **Login (OTP):** User requests OTP -> Verified -> Session Created.
    *   **Event Management:** Creators can view, accept, or reject pending join requests (real-time).
*   **Repository:** `ApiAuthRepository` is the active implementation.
*   **Security:** Passwords currently stored as plaintext (Hackathon MVP).

### 6.2 Backend Architecture (`backend/`)
*   **Stack:** Node.js (Express) + SQLite (`travel_app.db`).
*   **Startup:** `cd backend && node server.js`.
*   **Environment:** Requires `.env` file with email credentials (Brevo/SMTP).

### 6.3 Schema Updates
1.  `users`: Added `password` (TEXT).
2.  `otp_codes`: Tracks email verification codes.
3.  `user_sessions`: Manages active login sessions (expiry, tokens).

### 6.4 Teammate Setup Guide
1.  **Backend:**
    *   Navigate to `backend/`.
    *   Create `.env` file (copy from snippet/team chat).
    *   Run `npm install`.
    *   Run `node server.js` (Ensure it says "Connected to SQLite database").
2.  **Frontend:**
    *   Run `flutter pub get`.
    *   Run `flutter run -d chrome`.
