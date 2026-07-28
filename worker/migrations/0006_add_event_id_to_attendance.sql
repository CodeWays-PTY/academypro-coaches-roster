-- Add event_id column to attendance table to isolate attendance per scheduled event
ALTER TABLE attendance ADD COLUMN event_id TEXT;

-- Create unique index to allow ON CONFLICT upserts per player and event
CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_player_event ON attendance(player_id, event_id);
