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

  // --- QUESTS ---
  db.run(`CREATE TABLE IF NOT EXISTS quest_locations (
      id TEXT PRIMARY KEY,
      city TEXT,
      name TEXT,
      description TEXT,
      latitude REAL,
      longitude REAL,
      points INTEGER
  )`); // Points of Interest

  db.run(`CREATE TABLE IF NOT EXISTS user_quests (
      userId TEXT,
      questId TEXT,
      completedAt TEXT,
      PRIMARY KEY (userId, questId)
  )`);

  // Seed Quests (Bangalore)
  const quests = [
    { id: 'q1', city: 'Bangalore', name: 'Cubbon Park', desc: 'The lung of the city.', lat: 12.9763, lng: 77.5929, pts: 100 },
    { id: 'q2', city: 'Bangalore', name: 'Lalbagh', desc: 'Famous botanical garden.', lat: 12.9507, lng: 77.5848, pts: 150 },
    { id: 'q3', city: 'Bangalore', name: 'Bangalore Palace', desc: 'Tudor-style architecture.', lat: 12.9988, lng: 77.5921, pts: 200 },
    { id: 'q4', city: 'Bangalore', name: 'Vidhana Soudha', desc: 'Legislative building.', lat: 12.9797, lng: 77.5912, pts: 100 },
    { id: 'q5', city: 'Bangalore', name: 'Tipu Sultan Palace', desc: 'Summer residence.', lat: 12.9594, lng: 77.5737, pts: 120 },
    { id: 'q6', city: 'Bangalore', name: 'ISKCON Temple', desc: 'Krishna temple on hill.', lat: 13.0098, lng: 77.5511, pts: 150 },
    { id: 'q7', city: 'Bangalore', name: 'UB City', desc: 'Luxury mall and skyline.', lat: 12.9719, lng: 77.5960, pts: 80 },
    { id: 'q8', city: 'Bangalore', name: 'Commercial Street', desc: 'Shopping hub.', lat: 12.9822, lng: 77.6083, pts: 50 },
    { id: 'q9', city: 'Bangalore', name: 'Ulsoor Lake', desc: 'Boating and islands.', lat: 12.9830, lng: 77.6200, pts: 90 },
    { id: 'q10', city: 'Bangalore', name: 'Nandi Hills', desc: 'Sunrise view point.', lat: 13.3702, lng: 77.6835, pts: 300 }
  ];

  const insertQuest = db.prepare("INSERT OR IGNORE INTO quest_locations (id, city, name, description, latitude, longitude, points) VALUES (?, ?, ?, ?, ?, ?, ?)");
  quests.forEach(q => insertQuest.run(q.id, q.city, q.name, q.desc, q.lat, q.lng, q.pts));
  insertQuest.finalize();

  console.log('Database tables initialized.');
});

module.exports = db;
