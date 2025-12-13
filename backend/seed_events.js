// Seed Script for Demo Events
// Run with: node seed_events.js

const db = require('./database');

const USERS = {
    alice: 'user_alice',
    bob: 'user_bob',
    maurya: 'user_mauryadoshi',
    vishal: 'user_josephvishal9',
};

// Helper functions
const runQuery = (query, params = []) => {
    return new Promise((resolve, reject) => {
        db.run(query, params, function (err) {
            if (err) reject(err);
            else resolve(this);
        });
    });
};

const tomorrow = new Date();
tomorrow.setDate(tomorrow.getDate() + 1);

const dayAfter = new Date();
dayAfter.setDate(dayAfter.getDate() + 2);

const nextWeek = new Date();
nextWeek.setDate(nextWeek.getDate() + 7);

async function seedEvents() {
    console.log('🌱 Seeding demo events...');

    // Clear existing events for clean demo
    await runQuery('DELETE FROM travel_events');
    await runQuery('DELETE FROM event_participants');
    await runQuery('DELETE FROM event_requests');
    await runQuery('DELETE FROM group_chats');
    await runQuery('DELETE FROM chat_messages');

    const events = [
        // --- BANGALORE EVENTS ---
        {
            id: 'event_blr_1',
            city: 'Bangalore',
            title: '☕ Koramangala Cafe Hopping',
            eventDate: tomorrow.toISOString(),
            isDateFlexible: 0,
            creatorId: USERS.alice,
            requiresApproval: 0,
            category: 'Food & Drinks',
        },
        {
            id: 'event_blr_2',
            city: 'Bangalore',
            title: '🏃 Cubbon Park Morning Run',
            eventDate: tomorrow.toISOString(),
            isDateFlexible: 1,
            creatorId: USERS.bob,
            requiresApproval: 1, // REQUIRES APPROVAL
            category: 'Adventure',
        },
        {
            id: 'event_blr_3',
            city: 'Bangalore',
            title: '🎨 Nandi Hills Sunrise Trip',
            eventDate: dayAfter.toISOString(),
            isDateFlexible: 0,
            creatorId: USERS.maurya,
            requiresApproval: 0,
            category: 'Adventure',
        },

        // --- MUMBAI EVENTS ---
        {
            id: 'event_mum_1',
            city: 'Mumbai',
            title: '🌊 Marine Drive Evening Walk',
            eventDate: tomorrow.toISOString(),
            isDateFlexible: 1,
            creatorId: USERS.vishal,
            requiresApproval: 0,
            category: 'Tours',
        },
        {
            id: 'event_mum_2',
            city: 'Mumbai',
            title: '🍜 Street Food Tour - Juhu Beach',
            eventDate: dayAfter.toISOString(),
            isDateFlexible: 0,
            creatorId: USERS.alice,
            requiresApproval: 1, // REQUIRES APPROVAL
            category: 'Food & Drinks',
        },
        {
            id: 'event_mum_3',
            city: 'Mumbai',
            title: '🎬 Bollywood Studio Visit',
            eventDate: nextWeek.toISOString(),
            isDateFlexible: 1,
            creatorId: USERS.bob,
            requiresApproval: 0,
            category: 'Tours',
        },

        // --- DELHI EVENTS ---
        {
            id: 'event_del_1',
            city: 'Delhi',
            title: '🏛️ Red Fort Heritage Walk',
            eventDate: tomorrow.toISOString(),
            isDateFlexible: 0,
            creatorId: USERS.maurya,
            requiresApproval: 0,
            category: 'Tours',
        },
        {
            id: 'event_del_2',
            city: 'Delhi',
            title: '🍗 Old Delhi Food Crawl',
            eventDate: dayAfter.toISOString(),
            isDateFlexible: 1,
            creatorId: USERS.vishal,
            requiresApproval: 1, // REQUIRES APPROVAL
            category: 'Food & Drinks',
        },

        // --- GOA EVENTS ---
        {
            id: 'event_goa_1',
            city: 'Goa',
            title: '🏖️ Beach Hopping - North Goa',
            eventDate: nextWeek.toISOString(),
            isDateFlexible: 1,
            creatorId: USERS.alice,
            requiresApproval: 0,
            category: 'Adventure',
        },
        {
            id: 'event_goa_2',
            city: 'Goa',
            title: '🎉 Saturday Night Party',
            eventDate: nextWeek.toISOString(),
            isDateFlexible: 0,
            creatorId: USERS.bob,
            requiresApproval: 1, // REQUIRES APPROVAL
            category: 'Nightlife',
        },
    ];

    // Insert events
    for (const event of events) {
        await runQuery(
            `INSERT INTO travel_events (id, city, title, eventDate, isDateFlexible, creatorId, requiresApproval, category)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
            [event.id, event.city, event.title, event.eventDate, event.isDateFlexible, event.creatorId, event.requiresApproval, event.category]
        );
        console.log(`  ✅ Created: ${event.title}`);

        // Create group chat for each event
        await runQuery(
            `INSERT INTO group_chats (id, eventId) VALUES (?, ?)`,
            [`chat_${event.id}`, event.id]
        );
    }

    // --- ADD PARTICIPANTS ---
    // Alice's cafe event: Bob and Maurya joined
    await runQuery('INSERT INTO event_participants (eventId, userId) VALUES (?, ?)', ['event_blr_1', USERS.bob]);
    await runQuery('INSERT INTO event_participants (eventId, userId) VALUES (?, ?)', ['event_blr_1', USERS.maurya]);

    // Marine Drive: Alice joined
    await runQuery('INSERT INTO event_participants (eventId, userId) VALUES (?, ?)', ['event_mum_1', USERS.alice]);

    // --- ADD PENDING REQUESTS (for approval-required events) ---
    // Bob's run event: Vishal REQUESTED to join
    await runQuery('INSERT INTO event_requests (eventId, userId) VALUES (?, ?)', ['event_blr_2', USERS.vishal]);

    // Alice's food tour: Maurya REQUESTED to join
    await runQuery('INSERT INTO event_requests (eventId, userId) VALUES (?, ?)', ['event_mum_2', USERS.maurya]);

    // Delhi food crawl: Alice REQUESTED
    await runQuery('INSERT INTO event_requests (eventId, userId) VALUES (?, ?)', ['event_del_2', USERS.alice]);

    // --- ADD SAMPLE CHAT MESSAGES ---
    const now = new Date().toISOString();
    await runQuery(
        `INSERT INTO chat_messages (id, chatId, senderId, text, timestamp) VALUES (?, ?, ?, ?, ?)`,
        ['msg_1', 'chat_event_blr_1', USERS.bob, 'Hey! Excited for tomorrow! ☕', now]
    );
    await runQuery(
        `INSERT INTO chat_messages (id, chatId, senderId, text, timestamp) VALUES (?, ?, ?, ?, ?)`,
        ['msg_2', 'chat_event_blr_1', USERS.maurya, 'Same here! Should we meet at Third Wave?', now]
    );
    await runQuery(
        `INSERT INTO chat_messages (id, chatId, senderId, text, timestamp) VALUES (?, ?, ?, ?, ?)`,
        ['msg_3', 'chat_event_blr_1', USERS.alice, 'Sounds good! Let\'s finalize the route.', now]
    );

    console.log('\n🎉 Demo events seeded successfully!');
    console.log('\n📊 Summary:');
    console.log('  - 10 events across Bangalore, Mumbai, Delhi, Goa');
    console.log('  - 4 events REQUIRE APPROVAL (for demo)');
    console.log('  - 3 pending join requests');
    console.log('  - Sample chat messages in Cafe Hopping event');

    process.exit(0);
}

seedEvents().catch(err => {
    console.error('Seed error:', err);
    process.exit(1);
});
