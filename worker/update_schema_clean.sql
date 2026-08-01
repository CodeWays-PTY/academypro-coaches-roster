-- Align player_test_logs table columns to support event_id, athlete_name, test_name, category, unit, score_value
ALTER TABLE player_test_logs ADD COLUMN event_id TEXT;
ALTER TABLE player_test_logs ADD COLUMN athlete_name TEXT;
ALTER TABLE player_test_logs ADD COLUMN test_name TEXT;
ALTER TABLE player_test_logs ADD COLUMN category TEXT;
ALTER TABLE player_test_logs ADD COLUMN unit TEXT;
ALTER TABLE player_test_logs ADD COLUMN score_value REAL;
