-- Migration: 0022_sync_real_user_data.sql
-- Description: Sync real students (Jan Student and Justin Robertse) and events to school_id = '1' and sq_u15 squad

PRAGMA foreign_keys = OFF;

-- 1. Ensure real coach user has school_id = '1'
UPDATE users SET school_id = '1' WHERE email = 'janmen777@gmail.com';

-- 2. Ensure squad sq_u15 belongs to school_id = '1' and coach_id = 'USR-COACH-JAN777'
INSERT INTO squads (id, school_id, coach_id, name, code, age_group, description)
VALUES ('sq_u15', '1', 'USR-COACH-JAN777', 'U15 Squad', 'U15', 'U15', 'Academy Development XV')
ON CONFLICT(id) DO UPDATE SET school_id = '1', coach_id = 'USR-COACH-JAN777', code = 'U15', age_group = 'U15';

-- 3. Upsert real student 'Jan Student' (janmen778@gmail.com) into players
INSERT INTO players (id, school_id, user_id, age_group, first_name, last_name, position, team, status, age)
VALUES ('ATH-STUDENT-JAN778', '1', 'USR-STUDENT-JAN778', 'U15', 'Jan', 'Student', 'Fly-half', 'U15 Squad', 'Active', 16)
ON CONFLICT(id) DO UPDATE SET school_id = '1', age_group = 'U15', team = 'U15 Squad', status = 'Active';

-- 4. Upsert real student 'Justin Robertse' (jrobertse3@gmail.com) into players
INSERT INTO players (id, school_id, user_id, age_group, first_name, last_name, position, team, status, age)
VALUES ('AC-2024', '1', 'USR-STUDENT-JUSTIN2024', 'U15', 'Justin', 'Robertse', 'Forward / Wing', 'U15 Squad', 'Active', 16)
ON CONFLICT(id) DO UPDATE SET school_id = '1', age_group = 'U15', team = 'U15 Squad', status = 'Active';

-- 5. Ensure squad_players links both real students to sq_u15
INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES
('sq_u15', 'ATH-STUDENT-JAN778'),
('sq_u15', 'AC-2024');

-- 6. Ensure squad_members links both real students to sq_u15
INSERT OR IGNORE INTO squad_members (id, squad_id, athlete_id) VALUES
('sm_jan_u15', 'sq_u15', 'ATH-STUDENT-JAN778'),
('sm_justin_u15', 'sq_u15', 'AC-2024');

-- 7. Update all events created for U15 Squad to have school_id = '1' and age_group = 'U15'
UPDATE events SET school_id = '1' WHERE school_id IS NULL OR school_id = '' OR school_id = 'OVK';
UPDATE events SET age_group = 'U15' WHERE team = 'U15 Squad' OR age_group = 'U15 Squad' OR age_group IS NULL OR age_group = '';

PRAGMA foreign_keys = ON;
