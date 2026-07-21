const { DatabaseSync } = require('node:sqlite');
const path = require('path');

const dbPath = path.join(__dirname, '../usport.db');
const db = new DatabaseSync(dbPath);

console.log("Existing tables:");
const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all();
console.log(tables);

// Create notifications table if not exists
db.exec(`
CREATE TABLE IF NOT EXISTS notifications (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT NOT NULL DEFAULT 'general',
    is_read INTEGER DEFAULT 0,
    action_route TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
`);

console.log("Notifications table ensured.");

// Check if any notifications exist, if empty insert seed notifications
const count = db.prepare("SELECT COUNT(*) as cnt FROM notifications").get();
if (count.cnt === 0) {
  console.log("Seeding sample notifications...");
  const insert = db.prepare(`
    INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
    VALUES (?, ?, ?, ?, ?, ?)
  `);

  insert.run("USR-10928", "⚠️ Academic Risk Alert: Liam Venter", "Term 2 Grade dropped to 64.0%. Academic warning triggered.", "academic_flag", 0, "2026-07-21 16:30:00");
  insert.run("USR-10928", "🏉 Match Strategy Ready vs Menlopark", "Auto-Score breakdown generated for U15 A Team match.", "match_update", 0, "2026-07-21 14:15:00");
  insert.run("USR-10928", "🏋️ Field Session Scheduled", "High intensity tackle session set for Thursday 16:30 at Overkruin Main Field.", "event_schedule", 1, "2026-07-20 09:00:00");
  insert.run("USR-10928", "📲 Push Notification Active", "Your device is registered for Overkruin Academy push alerts.", "system", 1, "2026-07-19 11:00:00");
  
  // Also seed for student/parent generic IDs if needed
  insert.run("PAR-OVK-001", "📢 U15 Parent Update", "Coach Ross posted updated fitness baselines for July.", "general", 0, "2026-07-21 15:00:00");
  insert.run("STUD-001", "🏆 New Tackle Rating Logged", "Auto-score generated for your latest match performance: 3.7/5", "match_update", 0, "2026-07-21 14:15:00");

  console.log("Sample notifications seeded successfully.");
} else {
  console.log(`Notifications count: ${count.cnt}`);
}
