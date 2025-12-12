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
    explorerPoints INTEGER DEFAULT 0
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

  console.log('Database tables initialized.');
});

module.exports = db;
