const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const db = require('./database');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// --- Helper Functions ---
const runQuery = (query, params = []) => {
    return new Promise((resolve, reject) => {
        db.run(query, params, function (err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

const getQuery = (query, params = []) => {
    return new Promise((resolve, reject) => {
        db.get(query, params, (err, row) => {
            if (err) reject(err);
            else resolve(row);
        });
    });
};

const allQuery = (query, params = []) => {
    return new Promise((resolve, reject) => {
        db.all(query, params, (err, rows) => {
            if (err) reject(err);
            else resolve(rows);
        });
    });
};

// --- AUTH / USER ENDPOINTS ---

// Get User
app.get('/users/:uid', async (req, res) => {
    try {
        const user = await getQuery('SELECT * FROM users WHERE uid = ?', [req.params.uid]);
        if (!user) return res.status(404).json({ error: 'User not found' });
        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create/Update User (Sync)
app.post('/users', async (req, res) => {
    const { uid, email, displayName, explorerPoints } = req.body;
    try {
        // Upsert logic
        await runQuery(`
      INSERT OR REPLACE INTO users (uid, email, displayName, explorerPoints)
      VALUES (?, ?, ?, ?)
    `, [uid, email, displayName, explorerPoints || 0]);
        res.json({ uid, email, displayName, explorerPoints: explorerPoints || 0 });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- MAP / DESTINATIONS ---

// Get All Pins
app.get('/pins', async (req, res) => {
    try {
        const pins = await allQuery('SELECT * FROM destination_pins');
        // Ensure activeVisitorCount is int
        res.json(pins);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create Pin (Helper for seeding)
app.post('/pins', async (req, res) => {
    const { city, type, activeVisitorCount, latitude, longitude } = req.body;
    const id = uuidv4();
    try {
        await runQuery('INSERT INTO destination_pins (id, city, type, activeVisitorCount, latitude, longitude) VALUES (?, ?, ?, ?, ?, ?)',
            [id, city, type, activeVisitorCount || 0, latitude || 0, longitude || 0]);
        res.json({ id, city, type, activeVisitorCount, latitude, longitude });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- SOCIAL / EVENTS ---

// Get Events (with participants)
app.get('/events', async (req, res) => {
    try {
        const events = await allQuery('SELECT * FROM travel_events');
        const enrichedEvents = await Promise.all(events.map(async (event) => {
            // Get participants
            const participants = await allQuery('SELECT userId FROM event_participants WHERE eventId = ?', [event.id]);
            const pending = await allQuery('SELECT userId FROM event_requests WHERE eventId = ?', [event.id]);

            return {
                ...event,
                // Boolean conversion for SQLite integers
                isDateFlexible: !!event.isDateFlexible,
                requiresApproval: !!event.requiresApproval,
                participantIds: participants.map(p => p.userId),
                pendingRequestIds: pending.map(p => p.userId)
            };
        }));
        res.json(enrichedEvents);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create Event
app.post('/events', async (req, res) => {
    const { city, title, eventDate, isDateFlexible, creatorId, requiresApproval } = req.body;
    const id = uuidv4();
    try {
        await runQuery(`
      INSERT INTO travel_events (id, city, title, eventDate, isDateFlexible, creatorId, requiresApproval)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [id, city, title, eventDate, isDateFlexible ? 1 : 0, creatorId, requiresApproval ? 1 : 0]);

        // Add creator as participant
        await runQuery('INSERT INTO event_participants (eventId, userId) VALUES (?, ?)', [id, creatorId]);

        // Create Chat automatically
        const chatId = uuidv4();
        await runQuery('INSERT INTO group_chats (id, eventId) VALUES (?, ?)', [chatId, id]);

        res.json({ id, city, title, eventDate, isDateFlexible, creatorId, requiresApproval, participantIds: [creatorId], pendingRequestIds: [] });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Join Event
app.post('/events/:id/join', async (req, res) => {
    const eventId = req.params.id;
    const { userId } = req.body;
    try {
        const event = await getQuery('SELECT requiresApproval FROM travel_events WHERE id = ?', [eventId]);
        if (!event) return res.status(404).json({ error: 'Event not found' });

        if (event.requiresApproval) {
            await runQuery('INSERT OR IGNORE INTO event_requests (eventId, userId) VALUES (?, ?)', [eventId, userId]);
            res.json({ status: 'pending' });
        } else {
            await runQuery('INSERT OR IGNORE INTO event_participants (eventId, userId) VALUES (?, ?)', [eventId, userId]);
            res.json({ status: 'accepted' });
        }
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- CHAT ---

// Get Chat for Event
app.get('/chats/:eventId', async (req, res) => {
    try {
        const chat = await getQuery('SELECT * FROM group_chats WHERE eventId = ?', [req.params.eventId]);
        if (!chat) return res.status(404).json({ error: 'Chat not found' });

        const participants = await allQuery('SELECT userId FROM event_participants WHERE eventId = ?', [req.params.eventId]);

        // BIBLE: "memberIds" -> SYNCED with TravelEvent.participantIds
        res.json({
            id: chat.id,
            eventId: chat.eventId,
            memberIds: participants.map(p => p.userId)
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get Messages
app.get('/chats/:chatId/messages', async (req, res) => {
    try {
        const messages = await allQuery('SELECT * FROM chat_messages WHERE chatId = ? ORDER BY timestamp ASC', [req.params.chatId]);
        // Enhance with sender name? For now just return raw. Frontend might need to fetch user names.
        // Or we join with users table.
        const enriched = await Promise.all(messages.map(async (msg) => {
            const user = await getQuery('SELECT displayName FROM users WHERE uid = ?', [msg.senderId]);
            return { ...msg, senderName: user ? user.displayName : 'Unknown' };
        }));
        res.json(enriched);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Send Message
app.post('/chats/:chatId/messages', async (req, res) => {
    const { senderId, text } = req.body;
    const id = uuidv4();
    const timestamp = new Date().toISOString();
    try {
        await runQuery('INSERT INTO chat_messages (id, chatId, senderId, text, timestamp) VALUES (?, ?, ?, ?, ?)',
            [id, req.params.chatId, senderId, text, timestamp]);

        // Fetch sender name for response
        const user = await getQuery('SELECT displayName FROM users WHERE uid = ?', [senderId]);

        res.json({ id, chatId: req.params.chatId, senderId, text, timestamp, senderName: user ? user.displayName : 'Unknown' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- SAFETY ---

// Create Safety Alert
app.post('/safety/alert', async (req, res) => {
    const { userId, latitude, longitude, type } = req.body;
    const id = uuidv4();
    const timestamp = new Date().toISOString();
    try {
        await runQuery('INSERT INTO safety_alerts (id, userId, latitude, longitude, type, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
            [id, userId, latitude, longitude, type, timestamp]);
        res.json({ id, status: 'alert_sent' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
