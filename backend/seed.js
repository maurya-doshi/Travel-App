const db = require('./database');
const { v4: uuidv4 } = require('uuid');

const run = (query, params = []) => {
    return new Promise((resolve, reject) => {
        db.run(query, params, function (err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

const seed = async () => {
    try {
        console.log("🌱 Starting Seeding...");

        // 1. Clear Tables
        await run("DELETE FROM chat_messages");
        await run("DELETE FROM group_chats");
        await run("DELETE FROM event_participants");
        await run("DELETE FROM travel_events");
        await run("DELETE FROM destination_pins");
        await run("DELETE FROM users");

        // 2. Create Users
        const aliceId = 'user_alice';
        const bobId = 'user_bob';

        await run("INSERT INTO users (uid, email, displayName, explorerPoints) VALUES (?, ?, ?, ?)",
            [aliceId, 'alice@example.com', 'Alice Explorer', 120]);

        await run("INSERT INTO users (uid, email, displayName, explorerPoints) VALUES (?, ?, ?, ?)",
            [bobId, 'bob@example.com', 'Bob The Builder', 50]);

        console.log("✅ Users Created");

        // 3. Create Pins
        // Bangalore
        await run("INSERT INTO destination_pins (id, city, type, latitude, longitude, activeVisitorCount) VALUES (?, ?, ?, ?, ?, ?)",
            [uuidv4(), 'Bangalore', 'point_of_interest', 12.9716, 77.5946, 5]);

        // Paris
        await run("INSERT INTO destination_pins (id, city, type, latitude, longitude, activeVisitorCount) VALUES (?, ?, ?, ?, ?, ?)",
            [uuidv4(), 'Paris', 'point_of_interest', 48.8566, 2.3522, 120]);

        console.log("✅ Pins Created");

        // 4. Create Events
        const event1Id = uuidv4();
        await run(`INSERT INTO travel_events (id, city, title, eventDate, isDateFlexible, creatorId, requiresApproval) 
            VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [event1Id, 'Bangalore', 'Weekend Tech Meetup', new Date().toISOString(), 0, aliceId, 0]);

        const event2Id = uuidv4();
        await run(`INSERT INTO travel_events (id, city, title, eventDate, isDateFlexible, creatorId, requiresApproval) 
            VALUES (?, ?, ?, ?, ?, ?, ?)`,
            [event2Id, 'Bangalore', 'Nandi Hills Sunrise', new Date(Date.now() + 86400000).toISOString(), 1, bobId, 1]);

        console.log("✅ Events Created");

        // 5. Participants & Chats
        const chat1Id = uuidv4();
        await run("INSERT INTO group_chats (id, eventId) VALUES (?, ?)", [chat1Id, event1Id]);

        // Alice matches Event1
        await run("INSERT INTO event_participants (eventId, userId) VALUES (?, ?)", [event1Id, aliceId]);

        // Chat Messages
        await run("INSERT INTO chat_messages (id, chatId, senderId, text, timestamp) VALUES (?, ?, ?, ?, ?)",
            [uuidv4(), chat1Id, aliceId, 'Hey everyone! Excited for the meetup.', new Date().toISOString()]);

        console.log("✅ Chats & Participants Created");
        console.log("🎉 Seeding Complete!");

    } catch (e) {
        console.error("❌ Seeding Failed:", e);
    }
};

// Wait for DB connection
setTimeout(seed, 1000);
