const db = require('./database');

setTimeout(() => {
    db.all('SELECT * FROM travel_events', [], (err, rows) => {
        if (err) console.error(err);
        else {
            console.log('Events Count:', rows.length);
            if (rows.length > 0) console.log(rows[0]);
        }
    });
}, 2000);
