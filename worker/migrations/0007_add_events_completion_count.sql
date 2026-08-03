-- Migration 0007: Ensure completion_count column exists on events table
ALTER TABLE events ADD COLUMN completion_count INTEGER DEFAULT 0;
