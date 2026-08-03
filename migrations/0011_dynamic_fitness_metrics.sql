-- Migration: 0011_dynamic_fitness_metrics.sql
-- Description: Dynamic Coach-Defined Fitness Test Metrics and Time-Series Logs

PRAGMA foreign_keys = OFF;

-- ==========================================
-- 1. TEST METRIC DEFINITIONS (Coach/School Defined)
-- ==========================================
CREATE TABLE IF NOT EXISTS test_metric_definitions (
    id TEXT PRIMARY KEY,
    school_id TEXT NOT NULL,
    sport_id TEXT DEFAULT 'rugby',
    name TEXT NOT NULL,
    category TEXT CHECK(category IN ('Speed', 'Strength', 'Endurance', 'Agility', 'Power', 'General')) NOT NULL,
    unit TEXT NOT NULL,
    goal_direction TEXT CHECK(goal_direction IN ('HIGHER_IS_BETTER', 'LOWER_IS_BETTER')) DEFAULT 'HIGHER_IS_BETTER',
    target_benchmark REAL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

-- ==========================================
-- 2. PLAYER TEST LOGS (Time-Series Evaluation Results)
-- ==========================================
CREATE TABLE IF NOT EXISTS player_test_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id TEXT NOT NULL,
    metric_id TEXT NOT NULL,
    test_date TEXT NOT NULL,
    session_name TEXT DEFAULT 'Testing Evaluation',
    score REAL NOT NULL,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
    FOREIGN KEY (metric_id) REFERENCES test_metric_definitions(id) ON DELETE CASCADE,
    UNIQUE(player_id, metric_id, test_date)
);

CREATE INDEX IF NOT EXISTS idx_player_test_logs_player ON player_test_logs(player_id);
CREATE INDEX IF NOT EXISTS idx_player_test_logs_metric ON player_test_logs(metric_id);

PRAGMA foreign_keys = ON;

