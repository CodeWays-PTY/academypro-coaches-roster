# uSPORT Player Development Tracker — D1 SQL Database Schema

This database is designed for Cloudflare D1 (SQLite compatible). It uses a **Multi-Tenant Architecture** isolating data by `school_id` across all primary entities.

---

## 1. Relational Database Schema (D1 SQL)

Below is the clean, production-ready D1 SQL database schema covering all active database tables.

```sql
PRAGMA foreign_keys = OFF;

-- ==========================================
-- 1. SCHOOLS (Tenants)
-- ==========================================
CREATE TABLE IF NOT EXISTS schools (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 2. USERS (Staff, Coaches, Admins, Students, Parents)
-- ==========================================
CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    school_id INTEGER NOT NULL DEFAULT 1,
    email TEXT UNIQUE,
    phone TEXT,
    password_hash TEXT,
    role TEXT CHECK(role IN ('SuperAdmin', 'SchoolAdmin', 'Coach', 'Student', 'Parent')) DEFAULT 'Student',
    first_name TEXT,
    last_name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

-- ==========================================
-- 3. SPORTS & TEMPLATES
-- ==========================================
CREATE TABLE IF NOT EXISTS sports (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    config_json TEXT NOT NULL
);

-- ==========================================
-- 4. PLAYERS (Athlete Register)
-- ==========================================
CREATE TABLE IF NOT EXISTS players (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    user_id TEXT,
    parent_id TEXT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    parent_name TEXT,
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- ==========================================
-- 5. SQUADS (Team Squads)
-- ==========================================
CREATE TABLE IF NOT EXISTS squads (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    coach_id TEXT,
    name TEXT NOT NULL,
    code TEXT NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    FOREIGN KEY (coach_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ==========================================
-- 6. SQUAD PLAYERS (Junction Table)
-- ==========================================
CREATE TABLE IF NOT EXISTS squad_players (
    squad_id TEXT NOT NULL,
    player_id TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (squad_id, player_id),
    FOREIGN KEY (squad_id) REFERENCES squads(id) ON DELETE CASCADE,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

-- ==========================================
-- 7. TEST METRIC DEFINITIONS (Dynamic Metrics)
-- ==========================================
CREATE TABLE IF NOT EXISTS test_metric_definitions (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK',
    name TEXT NOT NULL,
    category TEXT DEFAULT 'Speed',
    unit TEXT DEFAULT 's',
    goal_direction TEXT DEFAULT 'HIGHER_IS_BETTER',
    target_benchmark REAL DEFAULT 0.0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

-- ==========================================
-- 8. PLAYER TEST LOGS (Fitness Metric Evaluations)
-- ==========================================
CREATE TABLE IF NOT EXISTS player_test_logs (
    id TEXT PRIMARY KEY,
    player_id TEXT NOT NULL,
    metric_id TEXT NOT NULL,
    score REAL NOT NULL,
    test_date TEXT NOT NULL,
    session_name TEXT DEFAULT 'Evaluation',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    FOREIGN KEY (metric_id) REFERENCES test_metric_definitions(id) ON DELETE CASCADE
);

-- ==========================================
-- 9. ACADEMIC RECORDS & LOGS
-- ==========================================
CREATE TABLE IF NOT EXISTS academic_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    term INTEGER DEFAULT 1,
    grade_percentage REAL DEFAULT 0,
    discipline_score INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, term)
);

-- ==========================================
-- 10. FITNESS RECORDS & BASELINES
-- ==========================================
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

-- ==========================================
-- 11. FITNESS PROGRESSION (Milestone Weeks)
-- ==========================================
CREATE TABLE IF NOT EXISTS fitness_progression (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    week INTEGER NOT NULL,
    speed_40m REAL,
    strength_reps INTEGER,
    weight REAL,
    gym_sessions_per_week INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    UNIQUE(player_id, week)
);

-- ==========================================
-- 12. MATCH DAY STATISTICS
-- ==========================================
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

-- ==========================================
-- 13. ATTENDANCE LOGS
-- ==========================================
CREATE TABLE IF NOT EXISTS attendance (
    player_id TEXT NOT NULL,
    session_type TEXT NOT NULL,
    date TEXT NOT NULL,
    event_id TEXT,
    status TEXT DEFAULT 'Present',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (player_id, session_type, date),
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

-- ==========================================
-- 14. EVENTS (Schedule / Calendar)
-- ==========================================
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
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

-- ==========================================
-- 15. ACTION PLANS (Interventions)
-- ==========================================
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

-- ==========================================
-- 16. NOTIFICATIONS
-- ==========================================
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

-- ==========================================
-- 17. PARENT CHILD LINKS (Link Requests)
-- ==========================================
CREATE TABLE IF NOT EXISTS parent_child_links (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    parent_phone TEXT,
    parent_email TEXT,
    player_id TEXT,
    player_email TEXT,
    status TEXT DEFAULT 'Pending',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- 18. MEDICAL RECORDS
-- ==========================================
CREATE TABLE IF NOT EXISTS medical_records (
    id TEXT PRIMARY KEY,
    player_id TEXT NOT NULL,
    condition_type TEXT,
    description TEXT,
    clearance_status TEXT DEFAULT 'Cleared',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
);

-- ==========================================
-- INDEXES FOR RETRIEVAL OPTIMIZATION
-- ==========================================
CREATE INDEX IF NOT EXISTS idx_players_school ON players(school_id);
CREATE INDEX IF NOT EXISTS idx_players_age_group ON players(age_group);
CREATE INDEX IF NOT EXISTS idx_match_stats_player_date ON match_stats(player_id, match_date);
CREATE INDEX IF NOT EXISTS idx_attendance_player_date ON attendance(player_id, date);
CREATE INDEX IF NOT EXISTS idx_attendance_player_event ON attendance(player_id, event_id);
CREATE INDEX IF NOT EXISTS idx_academic_logs_player ON academic_logs(player_id);
CREATE INDEX IF NOT EXISTS idx_events_school_date ON events(school_id, date);

PRAGMA foreign_keys = ON;
```

---

## 2. Active Cloudflare D1 Database Tables Summary

| # | Table Name | Alias / Functional Category | Description | Primary Key | Key Foreign Keys |
|---|---|---|---|---|---|
| 1 | `schools` | Multi-Tenant Schools | School tenant registry | `id` (TEXT) | None |
| 2 | `users` | User Accounts | Staff, coaches, admins, student accounts, parents | `id` (TEXT) | `school_id -> schools.id` |
| 3 | `sports` | Sport Definitions | Dynamic sport metric definitions & JSON layouts | `id` (TEXT) | None |
| 4 | `players` | Athlete Register | Player roster (`parent_contact` dropped) | `id` (TEXT) | `school_id -> schools.id`, `user_id -> users.id` |
| 5 | `squads` | Squad Management | Team squads assigned to coaches | `id` (TEXT) | `school_id -> schools.id`, `coach_id -> users.id` |
| 6 | `squad_players` | Squad Roster Mapping | Junction mapping players to squads | `(squad_id, player_id)` | `squad_id -> squads.id`, `player_id -> players.id` |
| 7 | `test_metric_definitions` | Dynamic Metrics | Configurable test metric definitions | `id` (TEXT) | `school_id -> schools.id` |
| 8 | `player_test_logs` | Fitness Evaluations | Log entries for dynamic fitness metrics | `id` (TEXT) | `player_id -> players.id`, `metric_id -> test_metric_definitions.id` |
| 9 | `academic_logs` | Academic Records | Academic term grades & discipline scores | `id` (INTEGER) | `player_id -> players.id` |
| 10 | `fitness_baselines` | Fitness Records | Initial physical baseline test metrics | `id` (INTEGER) | `player_id -> players.id` |
| 11 | `fitness_progression` | Fitness Progression | Milestone week progression metrics | `id` (INTEGER) | `player_id -> players.id` |
| 12 | `match_stats` | Match Performance | Rugby & sport match statistics | `id` (INTEGER) | `player_id -> players.id` |
| 13 | `attendance` | Attendance Tracking | Session attendance (Gym/Field/uGroup) | `(player_id, session_type, date)` | `player_id -> players.id` |
| 14 | `events` | Calendar / Schedule | Training sessions, field sessions & fixtures | `id` (TEXT) | `school_id -> schools.id` |
| 15 | `action_plans` | Action Plans | Player academic and development goals | `id` (TEXT) | None |
| 16 | `notifications` | Push Notifications | System and push notification items | `id` (TEXT) | None |
| 17 | `parent_child_links` | Link Requests | Parent-athlete linking requests | `id` (INTEGER) | None |
| 18 | `medical_records` | Medical Records | Player medical records & clearance logs | `id` (TEXT) | `player_id -> players.id` |

---

## 3. Dynamic Sport Template Configuration (SaaS Extensibility)

To support Netball, Soccer, and other sports, `sports.config_json` defines custom fields and scoring rules.

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
