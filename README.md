# Beacon - Travel App
#### Video Demo:  https://youtu.be/FeyRAbzqYxI
#### Description:

The **Beacon - Travel App** is a comprehensive mobile application designed to connect travelers, foster community interaction, and ensure safety while exploring new destinations. Often described as a "Tinder/Discord for Travelers," it combines social networking features with practical travel tools and gamification.

The project consists of two main components: a cross-platform mobile frontend built with **Flutter** and a lightweight, robust backend built with **Node.js**, **Express**, and **SQLite**.

## Project Overview

The core philosophy of the app is to make solo travel less lonely and more safe. Users can find events in their current city, join group chats to coordinate meetups, and earn "Explorer Points" by completing location-based quests. Safety is a first-class citizen with an integrated SOS feature.

### Key Features
*   **Authentication**: Secure email/password login and registration.
*   **Interactive Map**: View destination pins, other travelers (opt-in), and quest locations.
*   **Social Hub**: Create and join travel events. Each event has a dedicated group chat for coordination.
*   **Gamification**: "Quests" challenge users to visit specific landmarks or try local experiences to earn rewards.
*   **Safety Suite**: Real-time SOS alerts and emergency contact management.
*   **Premium UI**: A polished, dark-mode-first design system with smooth animations.

## File Structure and Description

### Frontend (`/lib`)
The Flutter application follows a **Feature-First Architecture** to ensure scalability and maintainability.

*   `main.dart`: The entry point of the application. It initializes the Flutter binding, sets up the **Riverpod** `ProviderScope` for state management, checks for persistent user sessions via `SharedPreferences`, and configures the `GoRouter` for navigation.
*   `core/`: Contains shared utilities, theme definitions (`PremiumTheme`), and the router configuration.
*   `features/auth/`: Handles all authentication logic.
    *   `auth_providers.dart`: Manages user state and login/signup API calls.
*   `features/social/`: The heart of the social experience. Contains screens for listing events, creating new meetups, and the chat interface.
*   `features/map/`: Logic for the interactive map, handling user location and map markers.
*   `features/discovery/`: Manages Quests and gamification logic.
*   `features/safety/`: Contains the SOS button logic and emergency contact configuration.

### Backend (`/backend`)
The backend is designed to be lightweight and easy to deploy locally for testing.

*   `server.js`: The main application entry point. It sets up the Express server, configures CORS and JSON parsing middleware, and defines all REST API endpoints (`/users`, `/events`, `/chats`, etc.).
*   `database.js`: Manages the **SQLite** database connection and schema. It automatically initializes tables for Users, Events, Chats, and Quests if they don't exist. It also handles database migrations (e.g., adding `phoneNumber` columns).
*   `seed.js` & `seed_events.js`: Utility scripts to populate the database with dummy data for demonstration purposes, allowing for a quick "out-of-the-box" test experience.
*   `package.json`: Lists dependencies, primarily `express`, `sqlite3`, and `body-parser`.

## Design Choices

### Flutter & Riverpod
I chose **Flutter** for its ability to create a high-performance, visually consistent experience across both iOS and Android from a single codebase. **Riverpod** was selected for state management over Provider or Bloc because of its compile-time safety and ability to easily handle asynchronous state (e.g., fetching events from the backend).

### Node.js & SQLite
For the hackathon/demo context, **SQLite** is the perfect database choice. It requires no external server process (like PostgreSQL or MongoDB), making the project extremely easy to run on any machine. **Node.js** allows for rapid API development using JavaScript, sharing the language concepts with the JSON data structure used throughout the app.

### REST API
A stateless **REST API** was implemented to decouple the frontend from the backend. This ensures that the mobile app handles UI concern while the server handles data validation and persistence, following standard software engineering practices.
