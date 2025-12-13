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

            // Get Creator Name
            const creator = await getQuery('SELECT displayName FROM users WHERE uid = ?', [event.creatorId]);

            return {
                ...event,
                // Boolean conversion for SQLite integers
                isDateFlexible: !!event.isDateFlexible,
                requiresApproval: !!event.requiresApproval,
                participantIds: participants.map(p => p.userId),
                pendingRequestIds: pending.map(p => p.userId),
                creatorName: creator ? creator.displayName : 'Unknown Traveler'
            };
        }));
        res.json(enrichedEvents);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Create Event
app.post('/events', async (req, res) => {
    const { city, title, eventDate, isDateFlexible, creatorId, requiresApproval, category } = req.body;
    const id = uuidv4();
    try {
        await runQuery(`
      INSERT INTO travel_events (id, city, title, eventDate, isDateFlexible, creatorId, requiresApproval, category)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `, [id, city, title, eventDate, isDateFlexible ? 1 : 0, creatorId, requiresApproval ? 1 : 0, category || 'General']);

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

// --- CHAT DETAILS (Event info + Members) ---
app.get('/chats/:chatId/details', async (req, res) => {
    const { chatId } = req.params;
    console.log('🔍 Chat details requested for chatId:', chatId);
    try {
        // Try to get the linked event from group_chats
        let chat = await getQuery('SELECT eventId FROM group_chats WHERE id = ?', [chatId]);
        console.log('  group_chats lookup result:', chat);

        // If not found, derive eventId from chatId (strip 'chat_' prefix)
        let eventId;
        if (!chat) {
            // chatId format is "chat_<eventId>", extract eventId
            eventId = chatId.startsWith('chat_') ? chatId.substring(5) : chatId;

            // Check if event exists
            const eventExists = await getQuery('SELECT id FROM travel_events WHERE id = ?', [eventId]);
            if (!eventExists) {
                return res.status(404).json({ error: 'Chat not found' });
            }

            // Auto-create the group_chat entry for this event
            await runQuery('INSERT INTO group_chats (id, eventId) VALUES (?, ?)', [chatId, eventId]);
            console.log(`Auto-created group_chat: ${chatId} -> ${eventId}`);
        } else {
            eventId = chat.eventId;
        }

        // Get event details
        const event = await getQuery('SELECT * FROM travel_events WHERE id = ?', [eventId]);
        if (!event) {
            return res.status(404).json({ error: 'Event not found' });
        }

        // Get participants (excluding creator to avoid duplication)
        const participants = await allQuery(
            'SELECT u.uid, u.displayName FROM event_participants ep JOIN users u ON ep.userId = u.uid WHERE ep.eventId = ? AND ep.userId != ?',
            [eventId, event.creatorId]
        );

        // Add creator to members list first
        const creator = await getQuery('SELECT uid, displayName FROM users WHERE uid = ?', [event.creatorId]);
        const members = creator ? [{ ...creator, isCreator: true }, ...participants] : participants;

        res.json({
            eventId: event.id,
            eventTitle: event.title,
            city: event.city,
            creatorId: event.creatorId,
            status: event.status || 'open',
            members: members
        });
    } catch (err) {
        console.error('Chat details error:', err);
        res.status(500).json({ error: err.message });
    }
});

// --- LEAVE EVENT (with ownership transfer) ---
app.post('/events/:eventId/leave', async (req, res) => {
    const { eventId } = req.params;
    const { userId } = req.body;
    console.log(`User ${userId} leaving event ${eventId}`);

    try {
        const event = await getQuery('SELECT * FROM travel_events WHERE id = ?', [eventId]);
        if (!event) {
            return res.status(404).json({ error: 'Event not found' });
        }

        const isCreator = event.creatorId === userId;

        if (isCreator) {
            // Find earliest joined member to transfer ownership
            const earliestMember = await getQuery(
                'SELECT userId FROM event_participants WHERE eventId = ? ORDER BY rowid ASC LIMIT 1',
                [eventId]
            );

            if (earliestMember) {
                // Transfer ownership
                await runQuery('UPDATE travel_events SET creatorId = ? WHERE id = ?', [earliestMember.userId, eventId]);
                console.log(`Ownership transferred to ${earliestMember.userId}`);
            } else {
                // No other members, delete the event entirely
                await runQuery('DELETE FROM travel_events WHERE id = ?', [eventId]);
                await runQuery('DELETE FROM group_chats WHERE eventId = ?', [eventId]);
                console.log(`Event ${eventId} deleted (no members left)`);
                return res.json({ success: true, eventDeleted: true });
            }
        }

        // Remove user from participants
        await runQuery('DELETE FROM event_participants WHERE eventId = ? AND userId = ?', [eventId, userId]);

        res.json({ success: true, ownershipTransferred: isCreator });
    } catch (err) {
        console.error('Leave event error:', err);
        res.status(500).json({ error: err.message });
    }
});

// --- CLOSE EVENT (Hide from Bulletin Board, keep GC) ---
app.post('/events/:eventId/close', async (req, res) => {
    const { eventId } = req.params;
    const { userId } = req.body;
    console.log(`User ${userId} closing event ${eventId}`);

    try {
        const event = await getQuery('SELECT creatorId FROM travel_events WHERE id = ?', [eventId]);
        if (!event) {
            return res.status(404).json({ error: 'Event not found' });
        }

        if (event.creatorId !== userId) {
            return res.status(403).json({ error: 'Only the creator can close this event' });
        }

        await runQuery("UPDATE travel_events SET status = 'closed' WHERE id = ?", [eventId]);
        console.log(`Event ${eventId} closed`);

        res.json({ success: true });
    } catch (err) {
        console.error('Close event error:', err);
        res.status(500).json({ error: err.message });
    }
});

// --- GET USER'S GROUP CHATS ---
app.get('/chats/groups/:userId', async (req, res) => {
    const { userId } = req.params;
    console.log(`Fetching group chats for user: ${userId}`);

    try {
        // Get events where user is creator OR participant
        const events = await allQuery(`
            SELECT DISTINCT e.id, e.title, e.city, e.status, e.creatorId,
                   gc.id as chatId
            FROM travel_events e
            LEFT JOIN group_chats gc ON gc.eventId = e.id
            WHERE e.creatorId = ?
               OR e.id IN (SELECT eventId FROM event_participants WHERE userId = ?)
        `, [userId, userId]);

        // Format response
        const groupChats = events.map(e => ({
            chatId: e.chatId || `chat_${e.id}`,
            eventId: e.id,
            eventTitle: e.title,
            city: e.city,
            status: e.status || 'open',
            isCreator: e.creatorId === userId
        }));

        res.json(groupChats);
    } catch (err) {
        console.error('Get user group chats error:', err);
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
// Legacy route removed

// LEGACY: Complete a Quest (Triggered by Proximity) - DISABLED: conflicts with /quests/step/complete
// This route pattern /quests/:id/complete was catching /quests/step/complete requests
/*
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
*/

// --- DIRECT MESSAGES (DMs) ---

// 1. Get or Create Direct Chat
app.post('/chats/direct', async (req, res) => {
    const { user1Id, user2Id } = req.body;
    if (!user1Id || !user2Id) return res.status(400).json({ error: 'Missing user IDs' });

    try {
        // Check if chat exists (in either direction)
        const existing = await getQuery(
            `SELECT * FROM direct_chats WHERE (user1Id = ? AND user2Id = ?) OR (user1Id = ? AND user2Id = ?)`,
            [user1Id, user2Id, user2Id, user1Id]
        );

        if (existing) {
            return res.json(existing);
        }

        // Create new
        const id = uuidv4();
        const now = new Date().toISOString();
        await runQuery(
            `INSERT INTO direct_chats (id, user1Id, user2Id, lastMessage, lastMessageTime) VALUES (?, ?, ?, ?, ?)`,
            [id, user1Id, user2Id, '', now]
        );
        res.json({ id, user1Id, user2Id, lastMessage: '', lastMessageTime: now });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// 2. Get All Direct Chats for a User
app.get('/chats/direct/user/:userId', async (req, res) => {
    const { userId } = req.params;
    try {
        const chats = await allQuery(
            `SELECT * FROM direct_chats WHERE user1Id = ? OR user2Id = ? ORDER BY lastMessageTime DESC`,
            [userId, userId]
        );

        // Enrich with other user's name
        const enriched = await Promise.all(chats.map(async (chat) => {
            const otherId = chat.user1Id === userId ? chat.user2Id : chat.user1Id;
            const otherUser = await getQuery(`SELECT displayName, email FROM users WHERE uid = ?`, [otherId]);
            return {
                ...chat,
                otherUser: otherUser || { displayName: 'Unknown', email: '' }
            };
        }));

        res.json(enriched);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// 3. Get Messages for a Direct Chat
app.get('/chats/direct/:chatId/messages', async (req, res) => {
    try {
        const msgs = await allQuery(
            `SELECT * FROM direct_messages WHERE chatId = ? ORDER BY timestamp ASC`,
            [req.params.chatId]
        );

        // Enrich with sender name
        const enriched = await Promise.all(msgs.map(async (m) => {
            const sender = await getQuery('SELECT displayName FROM users WHERE uid = ?', [m.senderId]);
            return {
                ...m,
                senderName: sender ? sender.displayName : 'Unknown'
            };
        }));

        res.json(enriched);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// 4. Send Direct Message
app.post('/chats/direct/:chatId/messages', async (req, res) => {
    const { senderId, text } = req.body;
    const { chatId } = req.params;
    const id = uuidv4();
    const timestamp = new Date().toISOString();

    try {
        await runQuery(
            `INSERT INTO direct_messages (id, chatId, senderId, text, timestamp) VALUES (?, ?, ?, ?, ?)`,
            [id, chatId, senderId, text, timestamp]
        );

        // Update last message in chat
        await runQuery(
            `UPDATE direct_chats SET lastMessage = ?, lastMessageTime = ? WHERE id = ?`,
            [text, timestamp, chatId]
        );

        res.json({ success: true, id, timestamp });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// --- QUESTS API ---
app.get('/quests', async (req, res) => {
    try {
        const quests = await allQuery('SELECT * FROM quests');

        // Enrich with steps
        const enriched = await Promise.all(quests.map(async (q) => {
            const steps = await allQuery('SELECT * FROM quest_steps WHERE questId = ?', [q.id]);
            return { ...q, steps };
        }));

        res.json(enriched);
    } catch (e) { res.status(500).json({ error: e.message }); }
});

app.get('/quests/city/:city', async (req, res) => {
    try {
        const { city } = req.params;
        const quest = await getQuery('SELECT * FROM quests WHERE city = ? COLLATE NOCASE', [city]); // Case insensitive
        if (!quest) return res.status(404).json({ error: 'No quest found for this city' });

        const steps = await allQuery('SELECT * FROM quest_steps WHERE questId = ? ORDER BY points ASC', [quest.id]); // Just verifying sort order if needed
        res.json({ ...quest, steps });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

// --- QUEST PROGRESS APIs ---

// Join a quest (opt-in)
app.post('/quests/join', async (req, res) => {
    const { userId, questId } = req.body;
    console.log('JOIN quest request:', { userId, questId });
    try {
        const result = await runQuery(
            'INSERT OR IGNORE INTO user_active_quests (userId, questId, startedAt) VALUES (?, ?, ?)',
            [userId, questId, new Date().toISOString()]
        );
        console.log('JOIN result:', result);
        res.json({ success: true, message: 'Quest joined!' });
    } catch (e) {
        console.error('JOIN error:', e);
        res.status(500).json({ error: e.message });
    }
});

// Quit a quest (resets progress)
app.post('/quests/quit', async (req, res) => {
    const { userId, questId } = req.body;
    console.log('QUIT quest request:', { userId, questId });
    try {
        // Remove from active quests
        await runQuery('DELETE FROM user_active_quests WHERE userId = ? AND questId = ?', [userId, questId]);
        // Reset progress for this quest
        await runQuery('DELETE FROM user_quest_progress WHERE userId = ? AND questId = ?', [userId, questId]);
        console.log('QUIT completed for:', { userId, questId });
        res.json({ success: true, message: 'Quest quit, progress reset.' });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

// Get user's active quests
app.get('/quests/active/:userId', async (req, res) => {
    try {
        const activeQuests = await allQuery(
            `SELECT uaq.*, q.title, q.city, q.description, q.reward 
             FROM user_active_quests uaq 
             JOIN quests q ON uaq.questId = q.id 
             WHERE uaq.userId = ?`,
            [req.params.userId]
        );

        // Enrich with steps and progress
        const enriched = await Promise.all(activeQuests.map(async (aq) => {
            const steps = await allQuery('SELECT * FROM quest_steps WHERE questId = ?', [aq.questId]);
            const progress = await allQuery(
                'SELECT stepId FROM user_quest_progress WHERE userId = ? AND questId = ?',
                [req.params.userId, aq.questId]
            );
            const completedStepIds = progress.map(p => p.stepId);
            return {
                ...aq,
                steps: steps.map(s => ({ ...s, isCompleted: completedStepIds.includes(s.id) })),
                completedCount: completedStepIds.length,
                totalSteps: steps.length
            };
        }));

        res.json(enriched);
    } catch (e) { res.status(500).json({ error: e.message }); }
});

// Mark a step as completed
app.post('/quests/step/complete', async (req, res) => {
    const { userId, questId, stepId } = req.body;
    console.log('Step completion request:', { userId, questId, stepId });
    try {
        const result = await runQuery(
            'INSERT OR IGNORE INTO user_quest_progress (userId, questId, stepId, completedAt) VALUES (?, ?, ?, ?)',
            [userId, questId, stepId, new Date().toISOString()]
        );
        console.log('Insert result:', result);

        // Check if all steps are now complete
        const totalSteps = await getQuery('SELECT COUNT(*) as count FROM quest_steps WHERE questId = ?', [questId]);
        const completedSteps = await getQuery(
            'SELECT COUNT(*) as count FROM user_quest_progress WHERE userId = ? AND questId = ?',
            [userId, questId]
        );

        const isQuestComplete = completedSteps.count >= totalSteps.count;

        if (isQuestComplete) {
            // Mark quest as completed
            await runQuery(
                'UPDATE user_active_quests SET completedAt = ? WHERE userId = ? AND questId = ?',
                [new Date().toISOString(), userId, questId]
            );

            // Get quest reward and update user XP
            const quest = await getQuery('SELECT reward FROM quests WHERE id = ?', [questId]);
            if (quest && quest.reward) {
                // Extract number from reward string (e.g., "500 XP" -> 500)
                const xpMatch = quest.reward.match(/(\d+)/);
                if (xpMatch) {
                    const xpAmount = parseInt(xpMatch[1]);
                    await runQuery(
                        'UPDATE users SET explorerPoints = explorerPoints + ? WHERE uid = ?',
                        [xpAmount, userId]
                    );
                }
            }
        }

        res.json({
            success: true,
            isQuestComplete,
            completedCount: completedSteps.count,
            totalSteps: totalSteps.count
        });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

// Get progress for a specific quest
app.get('/quests/progress/:userId/:questId', async (req, res) => {
    try {
        const { userId, questId } = req.params;
        const progress = await allQuery(
            'SELECT stepId, completedAt FROM user_quest_progress WHERE userId = ? AND questId = ?',
            [userId, questId]
        );
        const activeQuest = await getQuery(
            'SELECT * FROM user_active_quests WHERE userId = ? AND questId = ?',
            [userId, questId]
        );
        res.json({
            isJoined: !!activeQuest,
            isCompleted: activeQuest?.completedAt != null,
            completedSteps: progress
        });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

// Legacy endpoint (keep for compatibility)
app.get('/quests/progress/:userId', async (req, res) => {
    try {
        const progress = await allQuery('SELECT * FROM user_quest_progress WHERE userId = ?', [req.params.userId]);
        res.json(progress);
    } catch (e) { res.status(500).json({ error: e.message }); }
});

// =====================================================
// ============ SAFETY & PROFILE ENDPOINTS =============
// =====================================================

// --- Update User Profile ---
app.put('/users/:uid', async (req, res) => {
    const { uid } = req.params;
    const { displayName, phoneNumber } = req.body;
    try {
        await runQuery(
            'UPDATE users SET displayName = COALESCE(?, displayName), phoneNumber = COALESCE(?, phoneNumber) WHERE uid = ?',
            [displayName, phoneNumber, uid]
        );
        const updatedUser = await getQuery('SELECT * FROM users WHERE uid = ?', [uid]);
        res.json({ success: true, user: updatedUser });
    } catch (e) {
        console.error('Error updating user profile:', e);
        res.status(500).json({ error: e.message });
    }
});

// --- Emergency Contacts CRUD ---
app.get('/safety/contacts/:userId', async (req, res) => {
    try {
        const contacts = await allQuery('SELECT * FROM emergency_contacts WHERE userId = ?', [req.params.userId]);
        res.json(contacts);
    } catch (e) { res.status(500).json({ error: e.message }); }
});

app.post('/safety/contacts', async (req, res) => {
    const { userId, name, phone, email } = req.body;
    const id = uuidv4();
    try {
        await runQuery(
            'INSERT INTO emergency_contacts (id, userId, name, phone, email) VALUES (?, ?, ?, ?, ?)',
            [id, userId, name, phone, email]
        );
        res.json({ success: true, id });
    } catch (e) {
        console.error('Error adding emergency contact:', e);
        res.status(500).json({ error: e.message });
    }
});

app.delete('/safety/contacts/:id', async (req, res) => {
    try {
        await runQuery('DELETE FROM emergency_contacts WHERE id = ?', [req.params.id]);
        res.json({ success: true });
    } catch (e) { res.status(500).json({ error: e.message }); }
});

// --- SOS Alert Trigger ---
app.post('/safety/sos', async (req, res) => {
    const { userId, latitude, longitude, type } = req.body;
    const id = uuidv4();
    const timestamp = new Date().toISOString();
    console.log('🚨 SOS ALERT RECEIVED:', { userId, latitude, longitude, type });

    try {
        // 1. Log the alert in the database
        await runQuery(
            'INSERT INTO safety_alerts (id, userId, latitude, longitude, type, timestamp) VALUES (?, ?, ?, ?, ?, ?)',
            [id, userId, latitude, longitude, type || 'emergency', timestamp]
        );

        // 2. Fetch emergency contacts for this user
        const contacts = await allQuery('SELECT * FROM emergency_contacts WHERE userId = ?', [userId]);
        const user = await getQuery('SELECT displayName, email FROM users WHERE uid = ?', [userId]);

        // 3. Send email to all emergency contacts
        const mapLink = `https://www.google.com/maps/search/?api=1&query=${latitude},${longitude}`;

        if (transporter && contacts.length > 0) {
            for (const contact of contacts) {
                if (contact.email) {
                    try {
                        await transporter.sendMail({
                            from: process.env.EMAIL_FROM || process.env.EMAIL_USER || '"Travel App Safety" <sos@travelapp.com>',
                            to: contact.email,
                            subject: `🚨 EMERGENCY ALERT from ${user?.displayName || 'A User'}`,
                            html: `
                                <h1 style="color: red;">⚠️ EMERGENCY ALERT</h1>
                                <p><strong>${user?.displayName || 'A user'}</strong> has triggered an SOS alert!</p>
                                <p><strong>Time:</strong> ${timestamp}</p>
                                <p><strong>Location:</strong> <a href="${mapLink}">View on Google Maps</a></p>
                                <p style="color: red;">Please check on them immediately or contact local authorities.</p>
                            `
                        });
                        console.log(`SOS email sent to: ${contact.email}`);
                    } catch (emailErr) {
                        console.error(`Failed to send SOS email to ${contact.email}:`, emailErr);
                    }
                }
            }
        }

        res.json({ success: true, alertId: id, contactsNotified: contacts.length });
    } catch (e) {
        console.error('Error triggering SOS:', e);
        res.status(500).json({ error: e.message });
    }
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
