const db = require('./database');

setTimeout(() => {
    db.all('SELECT * FROM quests', [], (err, rows) => {
        if (err) console.error(err);
        else {
            console.log('Quests Count:', rows.length);
            console.log(JSON.stringify(rows, null, 2));
        }
    });

    db.all('SELECT * FROM quest_steps LIMIT 5', [], (err, rows) => {
        if (err) console.error(err);
        else {
            console.log('Sample Steps:', rows.length);
            console.log(JSON.stringify(rows, null, 2));
        }
    });
}, 2000); // Wait for db init
