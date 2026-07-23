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

-- ==========================================
-- 3. SEED DEFAULT TEST METRIC DEFINITIONS FOR OVK
-- ==========================================
INSERT OR IGNORE INTO test_metric_definitions (id, school_id, sport_id, name, category, unit, goal_direction, target_benchmark) VALUES
('m_speed_40m', 'OVK', 'rugby', '40m Sprint', 'Speed', 'seconds', 'LOWER_IS_BETTER', 5.0),
('m_speed_60m', 'OVK', 'rugby', '60m Sprint', 'Speed', 'seconds', 'LOWER_IS_BETTER', 7.5),
('m_t_test', 'OVK', 'rugby', 'T-Test Agility', 'Agility', 'seconds', 'LOWER_IS_BETTER', 10.0),
('m_push_ups', 'OVK', 'rugby', 'Push-Ups Reps', 'Strength', 'reps', 'HIGHER_IS_BETTER', 40.0),
('m_pull_ups', 'OVK', 'rugby', 'Pull-Ups Reps', 'Strength', 'reps', 'HIGHER_IS_BETTER', 15.0),
('m_squats_40kg', 'OVK', 'rugby', 'Squats (40kg)', 'Strength', 'reps', 'HIGHER_IS_BETTER', 30.0),
('m_broad_jump', 'OVK', 'rugby', 'Broad Jump', 'Power', 'metres', 'HIGHER_IS_BETTER', 2.5),
('m_vertical_jump', 'OVK', 'rugby', 'Vertical Jump', 'Power', 'metres', 'HIGHER_IS_BETTER', 0.65);

-- Seed initial test logs for demo players from existing baselines
INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_speed_40m', '2025-06-01', 'June Baselines', speed_40m FROM fitness_baselines WHERE speed_40m IS NOT NULL;

INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_speed_60m', '2025-06-01', 'June Baselines', speed_60m FROM fitness_baselines WHERE speed_60m IS NOT NULL;

INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_t_test', '2025-06-01', 'June Baselines', t_test FROM fitness_baselines WHERE t_test IS NOT NULL;

INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_push_ups', '2025-06-01', 'June Baselines', push_ups FROM fitness_baselines WHERE push_ups IS NOT NULL;

INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_pull_ups', '2025-06-01', 'June Baselines', pull_ups FROM fitness_baselines WHERE pull_ups IS NOT NULL;

INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_squats_40kg', '2025-06-01', 'June Baselines', squats_40kg FROM fitness_baselines WHERE squats_40kg IS NOT NULL;

INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_broad_jump', '2025-06-01', 'June Baselines', broad_jump FROM fitness_baselines WHERE broad_jump IS NOT NULL;

INSERT OR IGNORE INTO player_test_logs (player_id, metric_id, test_date, session_name, score)
SELECT player_id, 'm_vertical_jump', '2025-06-01', 'June Baselines', vertical_jump FROM fitness_baselines WHERE vertical_jump IS NOT NULL;

PRAGMA foreign_keys = ON;
