PRAGMA foreign_keys = OFF;

CREATE TABLE IF NOT EXISTS schools (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    logo_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT CHECK(role IN ('SuperAdmin', 'SchoolAdmin', 'Coach', 'Student', 'Parent')) NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sports (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    config_json TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS players (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    user_id TEXT UNIQUE,
    age_group TEXT NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    grade INTEGER,
    age INTEGER,
    position TEXT,
    team TEXT,
    status TEXT CHECK(status IN ('Active', 'Injured', 'Inactive')) DEFAULT 'Active',
    parent_name TEXT,
    parent_contact TEXT,
    parent_id TEXT UNIQUE,
    ugroups_active INTEGER CHECK(ugroups_active IN (0, 1)) DEFAULT 0,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS academic_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    term INTEGER CHECK(term IN (1, 2, 3, 4)) NOT NULL,
    grade_percentage REAL,
    discipline_score INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, term)
);

CREATE TABLE IF NOT EXISTS fitness_baselines (
    player_id TEXT PRIMARY KEY,
    speed_40m REAL,
    speed_60m REAL,
    broad_jump REAL,
    push_ups INTEGER,
    pull_ups INTEGER,
    squats_40kg INTEGER,
    vertical_jump REAL,
    t_test REAL,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS fitness_progression (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    week INTEGER CHECK(week IN (0, 8, 16)) NOT NULL,
    speed_40m REAL,
    strength_reps INTEGER,
    weight REAL,
    gym_sessions_per_week INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, week)
);

CREATE TABLE IF NOT EXISTS match_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    match_date TEXT NOT NULL,
    opponent TEXT,
    tackles_made INTEGER DEFAULT 0,
    tackles_missed INTEGER DEFAULT 0,
    carries INTEGER DEFAULT 0,
    metres_gained REAL DEFAULT 0.0,
    errors INTEGER DEFAULT 0,
    penalties INTEGER DEFAULT 0,
    work_rate INTEGER CHECK(work_rate BETWEEN 0 AND 5) DEFAULT 0,
    overall_rating INTEGER CHECK(overall_rating BETWEEN 0 AND 5) DEFAULT 0,
    extra_stats_json TEXT,
    auto_score REAL,
    tackle_percentage REAL,
    category TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS attendance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    session_type TEXT CHECK(session_type IN ('Gym', 'Field', 'uGroup')) NOT NULL,
    date TEXT NOT NULL,
    status TEXT CHECK(status IN ('Present', 'Absent', 'Excused')) DEFAULT 'Present',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, session_type, date)
);

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

CREATE INDEX IF NOT EXISTS idx_players_school ON players(school_id);
CREATE INDEX IF NOT EXISTS idx_players_age_group ON players(age_group);
CREATE INDEX IF NOT EXISTS idx_match_stats_player_date ON match_stats(player_id, match_date);
CREATE INDEX IF NOT EXISTS idx_attendance_player_date ON attendance(player_id, date);
CREATE INDEX IF NOT EXISTS idx_academic_logs_player ON academic_logs(player_id);
CREATE INDEX IF NOT EXISTS idx_events_school_date ON events(school_id, date);

PRAGMA foreign_keys = ON;
