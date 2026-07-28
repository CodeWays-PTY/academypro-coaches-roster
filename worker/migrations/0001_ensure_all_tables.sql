-- Ensure all production D1 tables exist for AcademyPro
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE,
    phone TEXT,
    role TEXT DEFAULT 'Student',
    password_hash TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS players (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    user_id TEXT,
    parent_id TEXT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    parent_name TEXT,
    parent_phone TEXT,
    parent_contact TEXT,
    dob TEXT,
    preferred_position TEXT,
    age_group TEXT DEFAULT 'U15',
    position TEXT DEFAULT 'Athlete',
    team TEXT,
    grade INTEGER,
    age INTEGER,
    ugroups_active INTEGER DEFAULT 1,
    notes TEXT,
    status TEXT DEFAULT 'Active',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS squads (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    coach_id TEXT,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS squad_players (
    squad_id TEXT NOT NULL,
    player_id TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (squad_id, player_id)
);

CREATE TABLE IF NOT EXISTS academic_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    term INTEGER DEFAULT 1,
    grade_percentage REAL DEFAULT 0,
    discipline_score INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS test_metric_definitions (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    name TEXT NOT NULL,
    category TEXT DEFAULT 'Speed',
    unit TEXT DEFAULT 's',
    goal_direction TEXT DEFAULT 'HIGHER_IS_BETTER',
    target_benchmark REAL DEFAULT 0.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS player_test_logs (
    id TEXT PRIMARY KEY,
    player_id TEXT NOT NULL,
    metric_id TEXT NOT NULL,
    score REAL NOT NULL,
    test_date TEXT NOT NULL,
    session_name TEXT DEFAULT 'Evaluation',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fitness_baselines (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT UNIQUE NOT NULL,
    speed_40m REAL,
    speed_60m REAL,
    broad_jump REAL,
    push_ups INTEGER,
    pull_ups INTEGER,
    squats_40kg INTEGER,
    vertical_jump REAL,
    t_test REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS fitness_progression (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    week INTEGER NOT NULL,
    speed_40m REAL,
    strength_reps INTEGER,
    weight REAL,
    gym_sessions_per_week INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS match_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    match_date TEXT,
    opponent TEXT,
    tackles_made INTEGER DEFAULT 0,
    tackles_missed INTEGER DEFAULT 0,
    carries INTEGER DEFAULT 0,
    metres_gained REAL DEFAULT 0,
    errors INTEGER DEFAULT 0,
    penalties INTEGER DEFAULT 0,
    work_rate REAL DEFAULT 0,
    overall_rating REAL DEFAULT 0,
    auto_score REAL DEFAULT 0,
    tackle_percentage REAL DEFAULT 0,
    category TEXT DEFAULT 'Match',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS attendance (
    player_id TEXT NOT NULL,
    session_type TEXT NOT NULL,
    date TEXT NOT NULL,
    status TEXT DEFAULT 'Present',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (player_id, session_type, date)
);

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

CREATE TABLE IF NOT EXISTS action_plans (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    title TEXT NOT NULL,
    type TEXT DEFAULT 'Academic',
    category TEXT DEFAULT 'General',
    deadline TEXT,
    player_id TEXT,
    player_name TEXT,
    is_completed INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    is_read INTEGER DEFAULT 0,
    date_sent DATETIME DEFAULT CURRENT_TIMESTAMP,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS parent_child_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_phone TEXT,
    parent_email TEXT,
    player_id TEXT,
    player_email TEXT,
    status TEXT DEFAULT 'Pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
