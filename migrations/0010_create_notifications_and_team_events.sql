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

INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
VALUES 
  ('USR-10928', '⚠️ Academic Risk Alert: Liam Venter', 'Term 2 Grade dropped to 64.0%. Academic warning triggered.', 'academic_flag', 0, '2026-07-22 10:00:00'),
  ('USR-10928', '🏉 Match Strategy Ready vs Menlopark', 'Auto-Score breakdown generated for U15 A Team match.', 'match_update', 0, '2026-07-22 11:30:00'),
  ('USR-10928', '🏋️ Field Session Scheduled', 'High intensity tackle session set for Thursday 16:30 at Overkruin Main Field.', 'event_schedule', 1, '2026-07-21 09:00:00');

ALTER TABLE events ADD COLUMN team TEXT DEFAULT 'U15 Academy Elite';
