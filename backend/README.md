# Travel App Backend

A Node.js + Express + SQLite backend for the Social Travel App.

## Setup

1.  Navigate to `backend/`:
    ```bash
    cd backend
    ```
2.  Install dependencies:
    ```bash
    npm install
    ```
3.  Seed the database (Optional, for demo data):
    ```bash
    node seed.js
    ```
4.  Start the server:
    ```bash
    npm start
    ```

## API Endpoints

Base URL: `http://localhost:3000`

-   **GET /users/:uid**: Get user details.
-   **POST /users**: Create/Update user (`uid`, `email`, `displayName`).
-   **GET /pins**: Get all map pins.
-   **GET /events**: Get all travel events.
-   **POST /events**: Create a new event.
-   **POST /events/:id/join**: Join an event.
-   **GET /chats/:eventId**: Get chat details for an event.

## Database

Uses `sqlite3`. Database file is `travel_app.db`.
