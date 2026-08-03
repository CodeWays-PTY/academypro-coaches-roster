CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    age_group TEXT,
    team TEXT,
    title TEXT NOT NULL,
    event_type TEXT DEFAULT 'Field Session',
    start_time TEXT NOT NULL,
    date TEXT NOT NULL,
    duration_mins INTEGER DEFAULT 60,
    location TEXT DEFAULT 'Grounds',
    is_important INTEGER DEFAULT 0,
    completion_count INTEGER DEFAULT 0,
    workout_image_path TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
