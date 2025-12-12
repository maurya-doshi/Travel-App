const { v4: uuidv4 } = require('uuid');
const db = require('./database');

const runQuery = (query, params = []) => {
    return new Promise((resolve, reject) => {
        db.run(query, params, function (err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

const seed = async () => {
    console.log('Seeding database...');

    try {
        // 1. Create User
        const userId = "test-user-1";
        await runQuery(`INSERT OR REPLACE INTO users (uid, email, displayName, explorerPoints) VALUES (?, ?, ?, ?)`,
            [userId, "demo@travelapp.com", "Demo Traveler", 100]);
        console.log('User created');

        // 2. Create Destination Pin
        const pinId = uuidv4();
        await runQuery(`INSERT OR REPLACE INTO destination_pins (id, city, type, activeVisitorCount) VALUES (?, ?, ?, ?)`,
            [pinId, "Paris", "destination", 12]);
        console.log('Pin created');

        // 3. Create Event
        const eventId = uuidv4();
        await runQuery(`INSERT OR REPLACE INTO travel_events (id, city, title, eventDate, isDateFlexible, creatorId, requiresApproval) VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [eventId, "Paris", "Sunset at Eiffel Tower", new Date().toISOString(), 0, userId, 0]);
        console.log('Event created');

        // 4. Create Chat
        const chatId = uuidv4();
        await runQuery(`INSERT OR REPLACE INTO group_chats (id, eventId) VALUES (?, ?)`,
            [chatId, eventId]);
        console.log('Chat created');

        // 5. Add Participant
        await runQuery(`INSERT OR REPLACE INTO event_participants (eventId, userId) VALUES (?, ?)`,
            [eventId, userId]);

    } catch (err) {
        console.error('Error seeding:', err);
    } finally {
        console.log('Seeding complete.');
        // Keep connection open or close? Script usually exits.
        // db.close(); // db.js doesn't export close cleanly but process exit will handle it
    }
};

// Wait for DB init in database.js (serialized)
setTimeout(seed, 1000);
