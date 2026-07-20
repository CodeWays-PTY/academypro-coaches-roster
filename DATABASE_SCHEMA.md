# uSPORT Player Development Tracker — D1 SQL Database Schema

This database is designed for Cloudflare D1 (SQLite compatible). It uses a **Multi-Tenant Architecture** isolating data by `school_id` across all primary entities.

---

## 1. Relational Database Schema (D1 SQL)

Below is the clean, production-ready SQL script to initialize the D1 database.

```sql
-- Disable foreign key constraints temporarily for safe rebuild
PRAGMA foreign_keys = OFF;

-- ==========================================
-- 1. SCHOOLS (Tenants)
-- ==========================================
CREATE TABLE IF NOT EXISTS schools (
    id TEXT PRIMARY KEY, -- e.g., "OVK" (Hoërskool Overkruin)
    name TEXT NOT NULL,
    logo_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. USERS (Staff, Coaches, Admins)
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    role TEXT CHECK(role IN ('SuperAdmin', 'SchoolAdmin', 'Coach', 'Student')) NOT NULL,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

-- ==========================================
-- 3. SPORTS & TEMPLATES
-- ==========================================
CREATE TABLE IF NOT EXISTS sports (
    id TEXT PRIMARY KEY, -- e.g., "rugby", "netball", "soccer"
    name TEXT NOT NULL,
    -- JSON structure defining custom metrics, buttons, and calculations
    config_json TEXT NOT NULL 
);

-- ==========================================
-- 4. PLAYER REGISTER
-- ==========================================
CREATE TABLE IF NOT EXISTS players (
    id TEXT PRIMARY KEY, -- e.g., "OVK-U15-001"
    school_id TEXT NOT NULL,
    user_id TEXT UNIQUE, -- Link to user table if student has portal access
    age_group TEXT NOT NULL, -- e.g., "U14", "U15", "U16"
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    grade INTEGER,
    age INTEGER,
    position TEXT,
    team TEXT, -- e.g., "A Team", "B Team"
    status TEXT CHECK(status IN ('Active', 'Injured', 'Inactive')) DEFAULT 'Active',
    parent_name TEXT,
    parent_contact TEXT,
    parent_id TEXT UNIQUE, -- e.g., "PAR-OVK-001"
    ugroups_active INTEGER CHECK(ugroups_active IN (0, 1)) DEFAULT 0,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ==========================================
-- 5. ACADEMIC & LIFE LOGS
-- ==========================================
CREATE TABLE IF NOT EXISTS academic_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    term INTEGER CHECK(term IN (1, 2, 3, 4)) NOT NULL,
    grade_percentage REAL, -- Nullable if not yet entered
    discipline_score INTEGER DEFAULT 0, -- Count of infractions/demerits
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, term) -- One record per student per term
);

-- ==========================================
-- 6. FITNESS BASELINE TESTS (June Baselines)
-- ==========================================
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

-- ==========================================
-- 7. Gym & Fitness Logs (Progression Weeks)
-- ==========================================
CREATE TABLE IF NOT EXISTS fitness_progression (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    week INTEGER CHECK(week IN (0, 8, 16)) NOT NULL,
    speed_40m REAL,
    strength_reps INTEGER, -- E.g. benchpress or squats
    weight REAL,
    gym_sessions_per_week INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, week) -- One entry per student per milestone week
);

-- ==========================================
-- 8. MATCH DAY STATISTICS
-- ==========================================
CREATE TABLE IF NOT EXISTS match_stats (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    match_date TEXT NOT NULL, -- YYYY-MM-DD
    opponent TEXT,
    
    -- Structured core stats (Rugby focus)
    tackles_made INTEGER DEFAULT 0,
    tackles_missed INTEGER DEFAULT 0,
    carries INTEGER DEFAULT 0,
    metres_gained REAL DEFAULT 0.0,
    errors INTEGER DEFAULT 0,
    penalties INTEGER DEFAULT 0,
    work_rate INTEGER CHECK(work_rate BETWEEN 0 AND 5) DEFAULT 0,
    overall_rating INTEGER CHECK(overall_rating BETWEEN 0 AND 5) DEFAULT 0,
    
    -- Dynamic extensions for other sports (JSON)
    extra_stats_json TEXT, 
    
    -- Calculated outputs
    auto_score REAL,
    tackle_percentage REAL,
    category TEXT,
    
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

-- ==========================================
-- 9. ATTENDANCE LOGS
-- ==========================================
CREATE TABLE IF NOT EXISTS attendance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    session_type TEXT CHECK(session_type IN ('Gym', 'Field', 'uGroup')) NOT NULL,
    date TEXT NOT NULL, -- YYYY-MM-DD
    status TEXT CHECK(status IN ('Present', 'Absent', 'Excused')) DEFAULT 'Present',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, session_type, date) -- Protects against double-logging
);

-- ==========================================
-- 10. COMMAND EVENTS (Calendar / Schedule)
-- ==========================================
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    school_id TEXT NOT NULL,
    title TEXT NOT NULL,
    event_type TEXT CHECK(event_type IN ('Field Session', 'Match Day', 'Development', 'Gym Session')) NOT NULL,
    start_time TEXT NOT NULL, -- e.g., "16:30"
    date TEXT NOT NULL, -- YYYY-MM-DD
    duration_mins INTEGER, -- e.g., 90
    location TEXT NOT NULL,
    intensity TEXT CHECK(intensity IN ('High', 'Medium', 'Low')),
    is_important INTEGER DEFAULT 0, -- 0 or 1
    completion_count INTEGER, -- e.g. 2 for gym check
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

-- ==========================================
-- INDEXES FOR INSTANT RETRIEVAL
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_players_school ON players(school_id);
CREATE INDEX IF NOT EXISTS idx_players_age_group ON players(age_group);
CREATE INDEX IF NOT EXISTS idx_match_stats_player_date ON match_stats(player_id, match_date);
CREATE INDEX IF NOT EXISTS idx_attendance_player_date ON attendance(player_id, date);
CREATE INDEX IF NOT EXISTS idx_academic_logs_player ON academic_logs(player_id);
CREATE INDEX IF NOT EXISTS idx_events_school_date ON events(school_id, date);

PRAGMA foreign_keys = ON;
```

---

## 2. Dynamic Sport Template Configuration (SaaS Extensibility)

To support Netball, Soccer, and other sports, the `sports.config_json` field contains UI layout and rules configurations.

### Rugby Config Example
```json
{
  "sport": "Rugby",
  "fields": [
    {"key": "tackles_made", "label": "Tackles Made", "type": "counter"},
    {"key": "tackles_missed", "label": "Tackles Missed", "type": "counter"},
    {"key": "carries", "label": "Carries", "type": "counter"},
    {"key": "metres_gained", "label": "Metres Gained", "type": "numeric"},
    {"key": "errors", "label": "Errors", "type": "counter"},
    {"key": "penalties", "label": "Penalties", "type": "counter"},
    {"key": "work_rate", "label": "Work Rate", "type": "rating_1_5"},
    {"key": "overall_rating", "label": "Overall Rating", "type": "rating_1_5"}
  ]
}
```

### Netball Config Example
```json
{
  "sport": "Netball",
  "fields": [
    {"key": "goals_scored", "label": "Goals Scored", "type": "counter"},
    {"key": "intercepts", "label": "Intercepts", "type": "counter"},
    {"key": "turnovers", "label": "Turnovers", "type": "counter"},
    {"key": "penalties", "label": "Penalties", "type": "counter"},
    {"key": "work_rate", "label": "Work Rate", "type": "rating_1_5"},
    {"key": "overall_rating", "label": "Overall Rating", "type": "rating_1_5"}
  ]
}
```

---

## 3. Workers KV Caching Strategy

Workers KV handles fast-access data to bypass database requests during heavy mobile traffic.

### A. Active Team Rosters Cache
- **Key:** `roster:{school_id}:{age_group}:{team}`
- **Value:** JSON array containing player objects for immediate mobile display:
```json
[
  {
    "id": "OVK-U15-001",
    "name": "Liam",
    "position": "Flanker",
    "status": "Active"
  }
]
```
- **TTL:** 24 Hours. Evicted/refreshed automatically when a player register updates.

### B. Session Authorization Cache
- **Key:** `session:{user_id}`
- **Value:** Role and active access token (used for token validation).
- **TTL:** 12 Hours.
