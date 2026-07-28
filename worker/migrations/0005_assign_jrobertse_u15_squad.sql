-- Assign user jrobertse1@gmail.com to Overkruin (OVK) and create U15 Squad mapping
UPDATE users 
SET school_id = 'OVK', role = 'Coach'
WHERE email = 'jrobertse1@gmail.com';

INSERT OR REPLACE INTO squads (id, school_id, coach_id, name, code, description) VALUES
('sq-u15-jrob', 'OVK', 'USR-COACH-JROB', 'U15 Academy Elite', 'U15', 'Hoërskool Overkruin U15 High Performance Squad');

-- Also associate sq-u15-elite to USR-COACH-JROB
UPDATE squads SET coach_id = 'USR-COACH-JROB' WHERE id = 'sq-u15-elite';

-- Link all U15 players to USR-COACH-JROB's U15 squad
INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT 'sq-u15-jrob', id FROM players WHERE age_group = 'U15';

INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT 'sq-u15-elite', id FROM players WHERE age_group = 'U15';
