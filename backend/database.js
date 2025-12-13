const sqlite3 = require('sqlite3').verbose();
const path = require('path');

// Connect to SQLite database
const dbPath = path.resolve(__dirname, 'travel_app.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) {
    console.error('Error opening database ' + dbPath + ': ' + err.message);
  } else {
    console.log('Connected to the SQLite database.');
  }
});

// Serialize queries to ensure sequential execution for table creation
db.serialize(() => {
  // 1. Users Table
  db.run(`CREATE TABLE IF NOT EXISTS users (
    uid TEXT PRIMARY KEY,
    email TEXT,
    displayName TEXT,
    explorerPoints INTEGER DEFAULT 0,
    password TEXT
  )`);

  // 2. Destination Pins Table
  db.run(`CREATE TABLE IF NOT EXISTS destination_pins (
    id TEXT PRIMARY KEY,
    city TEXT NOT NULL,
    type TEXT NOT NULL,
    latitude REAL,
    longitude REAL,
    activeVisitorCount INTEGER DEFAULT 0
  )`);

  // 3. Travel Events Table
  // Note: Storing eventDate as INTEGER (Unix Timestamp in milliseconds or seconds? 
  // Context says DateTime. We'll stick to ISO8601 TEXT for robustness or INTEGER millis. 
  // Let's use TEXT ISO8601 for easier debugging, or INTEGER if performance needed. 
  // 'isDateFlexible' and 'requiresApproval' are BOOLEANs -> INTEGER 0/1
  db.run(`CREATE TABLE IF NOT EXISTS travel_events (
    id TEXT PRIMARY KEY,
    city TEXT NOT NULL,
    title TEXT NOT NULL,
    eventDate TEXT NOT NULL,
    isDateFlexible INTEGER DEFAULT 0,
    creatorId TEXT NOT NULL,
    requiresApproval INTEGER DEFAULT 0,
    FOREIGN KEY(creatorId) REFERENCES users(uid)
  )`);

  // Migration: Add category column (Safe to run multiple times, will error if exists but won't crash app if handled)
  db.run("ALTER TABLE travel_events ADD COLUMN category TEXT DEFAULT 'General'", (err) => {
    if (!err) console.log("Migrated: Added category column to travel_events");
  });

  // 4. Group Chats Table
  db.run(`CREATE TABLE IF NOT EXISTS group_chats (
    id TEXT PRIMARY KEY,
    eventId TEXT NOT NULL,
    FOREIGN KEY(eventId) REFERENCES travel_events(id) ON DELETE CASCADE
  )`);

  // 4a. Chat Messages Table
  db.run(`CREATE TABLE IF NOT EXISTS chat_messages (
    id TEXT PRIMARY KEY,
    chatId TEXT NOT NULL,
    senderId TEXT NOT NULL,
    text TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY(chatId) REFERENCES group_chats(id) ON DELETE CASCADE,
    FOREIGN KEY(senderId) REFERENCES users(uid)
  )`);


  // 5. Relations Tables (Many-to-Many)

  // Pending Requests for Events
  db.run(`CREATE TABLE IF NOT EXISTS event_requests (
    eventId TEXT,
    userId TEXT,
    PRIMARY KEY (eventId, userId),
    FOREIGN KEY(eventId) REFERENCES travel_events(id) ON DELETE CASCADE,
    FOREIGN KEY(userId) REFERENCES users(uid) ON DELETE CASCADE
  )`);

  // Participants in Events (and by extension, Chat Members)
  db.run(`CREATE TABLE IF NOT EXISTS event_participants (
    eventId TEXT,
    userId TEXT,
    PRIMARY KEY (eventId, userId),
    FOREIGN KEY(eventId) REFERENCES travel_events(id) ON DELETE CASCADE,
    FOREIGN KEY(userId) REFERENCES users(uid) ON DELETE CASCADE
  )`);

  // 6. Safety Alerts Table (SOS)
  db.run(`CREATE TABLE IF NOT EXISTS safety_alerts (
    id TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    type TEXT NOT NULL, /* 'emergency' or 'uncomfortable' */
    timestamp TEXT NOT NULL,
    status TEXT DEFAULT 'active'
  )`);

  // 7. OTP Codes (Updated for Server Logic)
  db.run(`CREATE TABLE IF NOT EXISTS otp_codes (
    id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    code TEXT NOT NULL,
    expiresAt INTEGER NOT NULL,
    verified INTEGER DEFAULT 0,
    createdAt TEXT
  )`);

  // 8. User Sessions (For Persisted Login)
  db.run(`CREATE TABLE IF NOT EXISTS user_sessions (
    sessionId TEXT PRIMARY KEY,
    userId TEXT NOT NULL,
    createdAt TEXT,
    expiresAt TEXT,
    isActive INTEGER DEFAULT 1,
    FOREIGN KEY(userId) REFERENCES users(uid) ON DELETE CASCADE
  )`);

  // 8a. Direct Chats Table (1-on-1)
  db.run(`CREATE TABLE IF NOT EXISTS direct_chats (
    id TEXT PRIMARY KEY,
    user1Id TEXT NOT NULL,
    user2Id TEXT NOT NULL,
    lastMessage TEXT,
    lastMessageTime TEXT,
    FOREIGN KEY(user1Id) REFERENCES users(uid),
    FOREIGN KEY(user2Id) REFERENCES users(uid)
  )`);

  // 8b. Direct Messages Table
  db.run(`CREATE TABLE IF NOT EXISTS direct_messages (
    id TEXT PRIMARY KEY,
    chatId TEXT NOT NULL,
    senderId TEXT NOT NULL,
    text TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    FOREIGN KEY(chatId) REFERENCES direct_chats(id) ON DELETE CASCADE,
    FOREIGN KEY(senderId) REFERENCES users(uid)
  )`);

  // --- QUESTS ---
  // New Schema for Dynamic Quests
  db.run(`CREATE TABLE IF NOT EXISTS quests (
      id TEXT PRIMARY KEY,
      city TEXT UNIQUE,
      title TEXT,
      description TEXT,
      reward TEXT
  )`);

  db.run(`CREATE TABLE IF NOT EXISTS quest_steps (
      id TEXT PRIMARY KEY,
      questId TEXT,
      title TEXT,
      description TEXT,
      latitude REAL,
      longitude REAL,
      type TEXT,
      clue TEXT,
      mustTry TEXT,
      points INTEGER DEFAULT 50,
      FOREIGN KEY(questId) REFERENCES quests(id)
  )`);

  // Progress tracking
  db.run(`CREATE TABLE IF NOT EXISTS user_quest_progress (
      userId TEXT,
      questId TEXT,
      stepId TEXT,
      completedAt TEXT,
      PRIMARY KEY (userId, stepId)
  )`);

  // Active Quests (User opt-in)
  db.run(`CREATE TABLE IF NOT EXISTS user_active_quests (
      userId TEXT,
      questId TEXT,
      startedAt TEXT,
      completedAt TEXT,
      PRIMARY KEY (userId, questId)
  )`);

  // Seed Quests from JSON
  try {
    const questData = require('./quests_data.json');

    const insertQuest = db.prepare("INSERT OR REPLACE INTO quests (id, city, title, description, reward) VALUES (?, ?, ?, ?, ?)");
    const insertStep = db.prepare("INSERT OR REPLACE INTO quest_steps (id, questId, title, description, latitude, longitude, type, clue, mustTry) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");

    questData.forEach(q => {
      const questId = q.city.toLowerCase() + '_main_quest';
      insertQuest.run(questId, q.city, q.title, q.description, q.reward, (err) => {
        if (err) console.error("Insert Quest Error:", err);
      });

      q.steps.forEach(s => {
        const stepId = questId + '_step_' + s.id;
        // Normalize lat/lng if string
        const lat = parseFloat(s.latitude);
        const lng = parseFloat(s.longitude);
        insertStep.run(stepId, questId, s.title, s.description, lat, lng, s.type, s.clue, s.mustTry, (err) => {
          if (err) console.error("Insert Step Error:", err);
        });
      });
    });
    insertQuest.finalize();
    insertStep.finalize();
    console.log('Quests seeded from JSON.');

  } catch (e) {
    console.warn('Skipping quest seeding (quests_data.json not found or invalid):', e.message);
  }

  console.log('Database tables initialized.');
});

module.exports = db;
