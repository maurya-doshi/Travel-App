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

// --- EMAIL CONFIG (NODEMAILER) ---
const nodemailer = require('nodemailer');
require('dotenv').config();

let transporter;

async function initEmail() {
    if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
        console.log("Using Real Email Account:", process.env.EMAIL_USER);

        // Check if we are using a specific service or generic SMTP
        if (process.env.EMAIL_SERVICE) {
            transporter = nodemailer.createTransport({
                service: process.env.EMAIL_SERVICE,
                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS,
                }
            });
        } else {
            // Generic SMTP (Brevo, Outlook, etc.)
            transporter = nodemailer.createTransport({
                host: process.env.EMAIL_HOST || 'smtp-relay.brevo.com',
                port: parseInt(process.env.EMAIL_PORT || '587'),
                secure: false, // true for 465
                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS,
                }
            });
        }
    } else {
        console.log("No Real Email Configured. Generating Ethereal Test Account...");
        try {
            const testAccount = await nodemailer.createTestAccount();
            console.log("Ethereal Account Created:", testAccount.user);
            transporter = nodemailer.createTransport({
                host: "smtp.ethereal.email",
                port: 587,
                secure: false, // true for 465, false for other ports
                auth: {
                    user: testAccount.user,
                    pass: testAccount.pass,
                },
            });
        } catch (e) {
            console.error("Failed to create Ethereal account:", e);
        }
    }
}
initEmail(); // Start initialization

// Helper to send email
const sendEmail = async (to, code) => {
    if (!transporter) await initEmail(); // Retry init if failed previously

    const mailOptions = {
        from: process.env.EMAIL_FROM || process.env.EMAIL_USER || '"Travel App" <no-reply@example.com>',
        to: to,
        subject: 'Your Travel App Login Code',
        text: `Welcome Back! 🌍\n\nYour verification code is: ${code}\n\nThis code expires in 10 minutes.`,
        html: `<h3>Welcome Back! 🌍</h3><p>Your verification code is: <strong>${code}</strong></p><p>This code expires in 10 minutes.</p>`
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log(`Email sent to ${to}`);

        // Log Preview URL for Ethereal
        const previewUrl = nodemailer.getTestMessageUrl(info);
        if (previewUrl) {
            console.log("---------------------------------------------------");
            console.log("✉️  EMAIL PREVIEW URL (Click to see OTP):");
            console.log(previewUrl);
            console.log("---------------------------------------------------");
        }
    } catch (error) {
        console.error('Error sending email:', error);
        throw error;
    }
};

// --- AUTH / USER ENDPOINTS ---

// 1. Request OTP (Send Real Email)
app.post('/auth/otp/request', async (req, res) => {
    const { email, isLogin } = req.body;
    if (!email) return res.status(400).json({ error: 'Email required' });

    try {
        // If Login Flow: Check if user exists first
        // if (isLogin) {
        //     const user = await getQuery('SELECT * FROM users WHERE email = ?', [email]);
        //     if (!user) {
        //         return res.status(404).json({ error: 'User not found. Please sign up first.' });
        //     }
        // }

        // Generate 6-digit code
        const code = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = Date.now() + 10 * 60 * 1000; // 10 mins

        // Save to DB (Upsert)
        await runQuery(`INSERT OR REPLACE INTO otp_codes (email, code, expiresAt) VALUES (?, ?, ?)`,
            [email, code, expiresAt]);

        await sendEmail(email, code);
        res.json({ message: 'OTP sent to email' });

    } catch (err) {
        console.error("OTP Error:", err);
        res.status(500).json({ error: err.message });
    }
});

// 2. Verify OTP
app.post('/auth/otp/verify', async (req, res) => {
    const { email, code, displayName, password } = req.body;
    try {
        // Fetch the LATEST OTP for this email
        const record = await getQuery('SELECT * FROM otp_codes WHERE email = ? ORDER BY rowid DESC LIMIT 1', [email]);

        if (!record) return res.status(400).json({ error: 'No OTP found for this email' });
        if (record.code !== code) return res.status(400).json({ error: 'Invalid Code' });
        if (Date.now() > record.expiresAt) return res.status(400).json({ error: 'Code Expired' });

        // Valid! Create/Update User
        const uid = 'user_' + email.split('@')[0]; // Simple UID derivation

        // Check if user exists to preserve existing data
        const existingUser = await getQuery('SELECT * FROM users WHERE email = ?', [email]);

        let explorerPoints = 0;
        if (existingUser) explorerPoints = existingUser.explorerPoints;

        // Upsert User with Password
        await runQuery(`
            INSERT OR REPLACE INTO users (uid, email, displayName, explorerPoints, password)
            VALUES (?, ?, ?, ?, ?)
        `, [uid, email, displayName || (existingUser ? existingUser.displayName : email.split('@')[0]), explorerPoints, password || (existingUser ? existingUser.password : null)]);

        // Clean up OTP
        await runQuery('DELETE FROM otp_codes WHERE email = ?', [email]);

        res.json({ uid, email, displayName: displayName || (existingUser ? existingUser.displayName : email.split('@')[0]), token: 'session_token_' + uid });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

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

// Create/Update User (Managed by OTP flow usually, but keeping for direct profile updates)
app.post('/users', async (req, res) => {
    const { uid, email, displayName, explorerPoints } = req.body;
    try {
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

// Delete Event
app.delete('/events/:id', async (req, res) => {
    const eventId = req.params.id;
    const userId = req.headers['x-user-id']; // Authorization check

    try {
        const event = await getQuery('SELECT creatorId FROM travel_events WHERE id = ?', [eventId]);
        if (!event) return res.status(404).json({ error: 'Event not found' });

        if (event.creatorId !== userId) {
            return res.status(403).json({ error: 'Unauthorized: Only the creator can delete this event' });
        }

        await runQuery('DELETE FROM travel_events WHERE id = ?', [eventId]);
        res.json({ success: true, message: 'Event deleted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Get Pending Requests
app.get('/events/:id/requests', async (req, res) => {
    try {
        const requests = await allQuery('SELECT r.userId, u.displayName, u.email FROM event_requests r JOIN users u ON r.userId = u.uid WHERE r.eventId = ?', [req.params.id]);
        res.json(requests);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Accept Request
app.post('/events/:id/accept', async (req, res) => {
    const eventId = req.params.id;
    const { userId } = req.body; // User to accept

    // In a real app, verify req.headers['x-user-id'] is the creator

    try {
        // Move from requests to participants
        await runQuery('INSERT OR IGNORE INTO event_participants (eventId, userId) VALUES (?, ?)', [eventId, userId]);
        await runQuery('DELETE FROM event_requests WHERE eventId = ? AND userId = ?', [eventId, userId]);

        res.json({ success: true, status: 'accepted' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Reject Request
app.post('/events/:id/reject', async (req, res) => {
    const eventId = req.params.id;
    const { userId } = req.body;

    try {
        await runQuery('DELETE FROM event_requests WHERE eventId = ? AND userId = ?', [eventId, userId]);
        res.json({ success: true, status: 'rejected' });
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

// --- OTP AUTHENTICATION ---

// Generate OTP (6-digit code)
const generateOTP = () => Math.floor(100000 + Math.random() * 900000).toString();

// Send OTP to Email
app.post('/auth/send-otp', async (req, res) => {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: 'Email is required' });

    const otp = generateOTP();
    const id = uuidv4();
    const createdAt = new Date().toISOString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString(); // 5 minutes

    try {
        // Invalidate old OTPs for this email
        await runQuery('UPDATE otp_codes SET verified = 1 WHERE email = ? AND verified = 0', [email]);

        // Create new OTP
        await runQuery(
            'INSERT INTO otp_codes (id, email, code, expiresAt, verified, createdAt) VALUES (?, ?, ?, ?, 0, ?)',
            [id, email, otp, expiresAt, createdAt]
        );

        // In production, send email here. For hackathon, we return it.
        console.log(`OTP for ${email}: ${otp}`);

        res.json({
            success: true,
            message: 'OTP sent successfully',
            // HACKATHON ONLY: Return OTP for testing (remove in production!)
            otp: otp
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Verify OTP and Create Session
app.post('/auth/verify-otp', async (req, res) => {
    const { email, otp, displayName } = req.body;
    if (!email || !otp) return res.status(400).json({ error: 'Email and OTP are required' });

    try {
        // Find valid OTP
        const otpRecord = await getQuery(
            'SELECT * FROM otp_codes WHERE email = ? AND code = ? AND verified = 0 AND expiresAt > datetime("now")',
            [email, otp]
        );

        if (!otpRecord) {
            return res.status(401).json({ error: 'Invalid or expired OTP' });
        }

        // Mark OTP as used
        await runQuery('UPDATE otp_codes SET verified = 1 WHERE id = ?', [otpRecord.id]);

        // Create or get user
        let user = await getQuery('SELECT * FROM users WHERE email = ?', [email]);

        if (!user) {
            // Create new user
            const uid = uuidv4();
            await runQuery(
                'INSERT INTO users (uid, email, displayName, explorerPoints) VALUES (?, ?, ?, 0)',
                [uid, email, displayName || email.split('@')[0]]
            );
            user = { uid, email, displayName: displayName || email.split('@')[0], explorerPoints: 0 };
        }

        // Create session
        const sessionId = uuidv4();
        const createdAt = new Date().toISOString();
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(); // 7 days

        await runQuery(
            'INSERT INTO user_sessions (sessionId, userId, createdAt, expiresAt, isActive) VALUES (?, ?, ?, ?, 1)',
            [sessionId, user.uid, createdAt, expiresAt]
        );

        res.json({
            success: true,
            session: {
                sessionId,
                expiresAt
            },
            user: {
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                explorerPoints: user.explorerPoints
            }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Validate Session
app.get('/auth/session/:sessionId', async (req, res) => {
    try {
        const session = await getQuery(
            'SELECT s.*, u.email, u.displayName, u.explorerPoints FROM user_sessions s JOIN users u ON s.userId = u.uid WHERE s.sessionId = ? AND s.isActive = 1 AND s.expiresAt > datetime("now")',
            [req.params.sessionId]
        );

        if (!session) {
            return res.status(401).json({ error: 'Invalid or expired session' });
        }

        res.json({
            valid: true,
            user: {
                uid: session.userId,
                email: session.email,
                displayName: session.displayName,
                explorerPoints: session.explorerPoints
            }
        });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Logout (Invalidate Session)
app.post('/auth/logout', async (req, res) => {
    const { sessionId } = req.body;
    try {
        await runQuery('UPDATE user_sessions SET isActive = 0 WHERE sessionId = ?', [sessionId]);
        res.json({ success: true });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Login with Password
app.post('/auth/login', async (req, res) => {
    const { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and Password required' });

    try {
        const user = await getQuery('SELECT * FROM users WHERE email = ?', [email]);
        if (!user) return res.status(404).json({ error: 'User not found' });

        // Simple password check
        if (user.password !== password) {
            return res.status(401).json({ error: 'Invalid Credentials' });
        }

        // Create Session
        const sessionId = uuidv4();
        const createdAt = new Date().toISOString();
        const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(); // 7 days

        await runQuery(
            'INSERT INTO user_sessions (sessionId, userId, createdAt, expiresAt, isActive) VALUES (?, ?, ?, ?, 1)',
            [sessionId, user.uid, createdAt, expiresAt]
        );

        res.json({
            success: true,
            session: { sessionId, expiresAt },
            user: {
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                explorerPoints: user.explorerPoints
            }
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- QUESTS ---

// Get API for Quests in a City (Unordered, Proximity Logic on Client)
app.get('/quests', async (req, res) => {
    const { city, userId } = req.query;
    try {
        const quests = await allQuery('SELECT * FROM quest_locations WHERE city = ?', [city]);

        let completedIds = [];
        if (userId) {
            const completed = await allQuery('SELECT questId FROM user_quests WHERE userId = ?', [userId]);
            completedIds = completed.map(c => c.questId);
        }

        const enriched = quests.map(q => ({
            ...q,
            isCompleted: completedIds.includes(q.id)
        }));

        res.json(enriched);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Complete a Quest (Triggered by Proximity)
app.post('/quests/:id/complete', async (req, res) => {
    const { userId } = req.body;
    const questId = req.params.id;
    const timestamp = new Date().toISOString();

    try {
        // 1. Mark as completed
        await runQuery('INSERT OR IGNORE INTO user_quests (userId, questId, completedAt) VALUES (?, ?, ?)', [userId, questId, timestamp]);

        // 2. Award Points
        const quest = await getQuery('SELECT points FROM quest_locations WHERE id = ?', [questId]);
        if (quest) {
            await runQuery('UPDATE users SET explorerPoints = explorerPoints + ? WHERE uid = ?', [quest.points, userId]);
        }

        res.json({ success: true, pointsAwarded: quest ? quest.points : 0 });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
