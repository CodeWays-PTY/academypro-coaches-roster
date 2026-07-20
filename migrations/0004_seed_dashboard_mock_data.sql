-- Migration: Seed Dashboard Mock Data (Academic and Match logs)
PRAGMA foreign_keys = OFF;

-- Clean up existing logs for test players
DELETE FROM academic_logs WHERE player_id IN ('OVK-U15-001', 'OVK-U15-002');
DELETE FROM match_stats WHERE player_id = 'OVK-U15-003';
DELETE FROM attendance WHERE player_id IN ('OVK-U15-001', 'OVK-U15-002', 'OVK-U15-003');

-- Seed academic logs (triggers academic warnings/critical flags)
INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score) VALUES ('OVK-U15-001', 1, 58.0, 1);
INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score) VALUES ('OVK-U15-001', 2, 52.0, 2);
INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score) VALUES ('OVK-U15-002', 1, 46.0, 0);
INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score) VALUES ('OVK-U15-002', 2, 44.0, 1);

-- Seed match stats (triggers performance warning flag)
INSERT INTO match_stats (player_id, match_date, opponent, tackles_made, tackles_missed, carries, metres_gained, errors, penalties, work_rate, overall_rating, auto_score, tackle_percentage, category) VALUES ('OVK-U15-003', '2026-07-15', 'Pretoria Boys High', 2, 8, 3, 10.0, 4, 3, 1, 1, 1.2, 0.2, '🔴 Developing');

-- Seed attendance data (calculates to a non-100% KPI average)
INSERT INTO attendance (player_id, session_type, date, status) VALUES ('OVK-U15-001', 'Gym', '2026-07-19', 'Present');
INSERT INTO attendance (player_id, session_type, date, status) VALUES ('OVK-U15-001', 'Field', '2026-07-20', 'Present');
INSERT INTO attendance (player_id, session_type, date, status) VALUES ('OVK-U15-002', 'Gym', '2026-07-19', 'Present');
INSERT INTO attendance (player_id, session_type, date, status) VALUES ('OVK-U15-002', 'Field', '2026-07-20', 'Absent');
INSERT INTO attendance (player_id, session_type, date, status) VALUES ('OVK-U15-003', 'Gym', '2026-07-19', 'Present');
INSERT INTO attendance (player_id, session_type, date, status) VALUES ('OVK-U15-003', 'Field', '2026-07-20', 'Present');

PRAGMA foreign_keys = ON;
