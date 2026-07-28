-- Add missing columns to users and players tables in D1
ALTER TABLE users ADD COLUMN phone TEXT;
ALTER TABLE players ADD COLUMN phone TEXT;
ALTER TABLE players ADD COLUMN parent_phone TEXT;
ALTER TABLE players ADD COLUMN dob TEXT;
ALTER TABLE players ADD COLUMN preferred_position TEXT;
