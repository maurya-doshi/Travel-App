const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.resolve(__dirname, 'travel_app.db');
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database ' + dbPath + ': ' + err.message);
        process.exit(1);
    }
});

const fs = require('fs');

db.all("SELECT * FROM users", [], (err, rows) => {
    if (err) {
        throw err;
    }
    console.log("Found " + rows.length + " users. Writing to passwords.json");
    fs.writeFileSync(path.resolve(__dirname, 'passwords.json'), JSON.stringify(rows, null, 2));
    db.close();
});
