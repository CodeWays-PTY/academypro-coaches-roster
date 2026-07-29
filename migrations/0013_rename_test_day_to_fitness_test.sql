-- Migration: Rename event_type 'Test Day' to 'Fitness Test' across database tables
UPDATE events SET event_type = 'Fitness Test' WHERE event_type = 'Test Day' OR LOWER(event_type) = 'test day';
UPDATE attendance SET session_type = 'Fitness Test' WHERE session_type = 'Test Day' OR LOWER(session_type) = 'test day';
UPDATE player_test_logs SET session_name = 'Fitness Test' WHERE session_name = 'Test Day' OR LOWER(session_name) = 'test day';
