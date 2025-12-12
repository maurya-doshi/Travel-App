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

**Folder Structure (Feature-First Clean Architecture):**
*   **Rule:** Code MUST be inside its specific feature folder.
*   **Rule:** Features cannot import each other's Widgets. They interact only via `AppRouter`.

```
lib/
├── core/                   # Shared logic (Theme, Router, Extensions)
├── features/
│   ├── auth/               # User Authentication (Member 1)
│   ├── map/                # Pins, User Location, displaying the Map (Member 2)
│   ├── social/             # Events, Bulletin Board, Chat Logic (Member 3)
│   └── discovery/          # Hotels, Quests, Gamification (Member 4)
│       ├── data/           # Repositories (Impl), Data Sources
│       ├── domain/         # Models (Pure Dart), Abstract Interfaces
│       └── presentation/   # Widgets, Riverpod Providers
```

---

## 📜 PART 3: THE "BIBLE" (Data Contracts)

**CRITICAL:** Do not change field names. The entire team relies on these exact JSON structures.

### 3.1 User Model (`lib/features/auth/domain/user_model.dart`)
```dart
class UserModel {
  final String uid;           // Firebase UID
  final String email;
  final String displayName;
  final int explorerPoints;   // Gamification Score
}
```

### 3.2 Destination Pin (`lib/features/map/domain/destination_pin_model.dart`)
*Concept:* A permanent marker on the map (City or Major Landmark).
```dart
class DestinationPin {
  final String id;
  final String city;          // "Paris" (Used availability grouping)
  final String type;          // 'destination' | 'hotel'
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

**Step 4: The Discovery (Discovery Team)**
*   User navigates to `/discovery`.
*   **Hotels:** Display List. *Logic:* Sort by "Most Travelers Staying".
*   **Quests:** Display List. *Logic:* If Type == 'co-op', show "Find Partner" button.

---

## 🛠️ PART 5: DEVELOPMENT STRATEGY

**Current Status:**
*   The project uses **MOCK REPOSITORIES** (`MockMapRepository`, `MockSocialRepository`).
*   **Rule:** Maintain the Mocks until the backend is fully ready. This allows the UI team to work without being blocked by Firebase bugs.

**Your Role (Agent):**
1.  Read the `lib/` folder to understand existing patterns.
// ... existing content ...

## 🔄 PART 6: RECENT CHANGES (Backend Connection - 2025-12-12)

**Summary:** The frontend has been connected to the Node.js backend. Mocks are replaced with real API calls.

### 6.1 Backend Updates (`backend/`)
*   **Schema Changes:**
    *   `destination_pins`: Added `latitude` (REAL), `longitude` (REAL).
    *   `chat_messages`: New table for chat history.
*   **Endpoints:**
    *   `POST /pins`: Now accepts lat/lng.
    *   `GET /chats/:chatId/messages`: Fetch message history.
    *   `POST /chats/:chatId/messages`: Send a message.
*   **Database:** Accessing `Travel-App/backend/travel_app.db` (SQLite). *Note: DB was reset to apply schema changes.*

### 6.2 Frontend Updates (`lib/`)
*   **Dependencies:** Added `http` package.
*   **Core:** Created `ApiService` (`lib/core/services/api_service.dart`) pointing to `http://10.0.2.2:3000` (Android Emulator Localhost).
*   **Repositories:**
    *   `ApiMapRepository` (Implemented): Fetches pins from backend. Maps JSON to `DestinationPin`.
    *   `ApiSocialRepository` (Implemented): Fetches events, joins events, and polls for chat messages.
    *   `ApiAuthRepository` (Implemented): Handles "Login" via deterministic UUIDv5 generation from email (Hackathon shortcut).
*   **Providers:**
    *   `mapProvider` & `socialProvider` now use the `Api*Repository` implementations.
    *   Added `authRepositoryProvider`.

### 6.3 Action Items for Teammates
*   **Run Backend:** `cd backend && npm install && npm start`.
*   **Run Frontend:** `flutter pub get && flutter run`.
*   **Note:** If testing on iOS Simulator, update `api_service.dart` baseUrl to `http://localhost:3000`.

### 6.4 Schema alignment & Demo Decisions (2025-12-12)
*   **Resolved Schema Mismatches:**
    *   `DestinationPin`: Removed `creatorId` (Backend does not store it).
    *   `TravelEvent`: Removed `description` and `maxParticipants` ( Backend does not support them yet). Frontend updated to avoid crashes.
*   **Demo Strategy (Hackathon Focus):**
    *   **Map:** `activeVisitorCount` is currently **MOCKED/STATIC** in the database. Dynamic aggregation is postponed.
    *   **Locations:** Shifting focus to **Bangalore** and **Mumbai** for the demo.
    *   **Features:** Prioritizing "Join Event" flow over complex backend validation.
