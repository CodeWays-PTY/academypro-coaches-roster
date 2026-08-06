ALTER TABLE events ADD COLUMN series_id TEXT;
CREATE INDEX IF NOT EXISTS idx_events_series_id ON events(series_id);
