ALTER TABLE player_test_logs ADD COLUMN event_id TEXT;
ALTER TABLE player_test_logs ADD COLUMN athlete_name TEXT;
ALTER TABLE player_test_logs ADD COLUMN test_name TEXT;
ALTER TABLE player_test_logs ADD COLUMN category TEXT;
ALTER TABLE player_test_logs ADD COLUMN unit TEXT;
ALTER TABLE player_test_logs ADD COLUMN score_value REAL;
ALTER TABLE player_test_logs ADD COLUMN notes TEXT;
CREATE INDEX IF NOT EXISTS idx_ptl_player_date ON player_test_logs(player_id, test_date DESC);
CREATE INDEX IF NOT EXISTS idx_ptl_event ON player_test_logs(event_id);
