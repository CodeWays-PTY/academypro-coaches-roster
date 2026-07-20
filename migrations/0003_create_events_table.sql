PRAGMA foreign_keys = OFF;

CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    school_id TEXT NOT NULL,
    title TEXT NOT NULL,
    event_type TEXT CHECK(event_type IN ('Field Session', 'Match Day', 'Development', 'Gym Session')) NOT NULL,
    start_time TEXT NOT NULL,
    date TEXT NOT NULL,
    duration_mins INTEGER,
    location TEXT NOT NULL,
    intensity TEXT CHECK(intensity IN ('High', 'Medium', 'Low')),
    is_important INTEGER DEFAULT 0,
    completion_count INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_events_school_date ON events(school_id, date);

-- Seed Events
INSERT INTO events (school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, completion_count) VALUES ('OVK', 'Tactical Periodization', 'Field Session', '16:30', '2026-07-20', 90, 'Pitch 4', 'High', 0, NULL);
INSERT INTO events (school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, completion_count) VALUES ('OVK', 'vs. Pretoria Boys High', 'Match Day', '10:00', '2026-07-25', NULL, 'West Field Complex', NULL, 1, NULL);
INSERT INTO events (school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, completion_count) VALUES ('OVK', 'Spiritual Character Dev', 'Development', '18:00', '2026-07-22', NULL, 'Youth Hall', NULL, 0, NULL);
INSERT INTO events (school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, completion_count) VALUES ('OVK', 'Strength Baselines Check', 'Gym Session', '06:00', '2026-07-27', NULL, 'High Performance Gym', NULL, 0, 2);

PRAGMA foreign_keys = ON;
