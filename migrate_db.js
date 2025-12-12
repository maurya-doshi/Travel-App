const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'backend/travel_app.db');
const db = new sqlite3.Database(dbPath);

db.serialize(() => {
    console.log('Migrating Database...');
    db.run("ALTER TABLE users ADD COLUMN password TEXT", (err) => {
        if (err) {
            if (err.message.includes('duplicate column name')) {
                console.log('Column "password" already exists.');
            } else {
                console.error('Error adding column:', err.message);
            }
        } else {
            console.log('Successfully added "password" column to users table.');
        }
    });
});

db.close();
