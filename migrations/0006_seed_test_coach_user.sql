-- Migration: Register test coach user account
INSERT OR REPLACE INTO users (id, school_id, email, password_hash, role, first_name, last_name)
VALUES ('USR-COACH-2', 'OVK', 'janmen777@gmail.com', 'sha256$mockedhash', 'Coach', 'Jan', 'Mentz');
