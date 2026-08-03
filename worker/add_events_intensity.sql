ALTER TABLE events ADD COLUMN intensity TEXT;
CREATE INDEX IF NOT EXISTS idx_events_school_date ON events(school_id, date DESC);
