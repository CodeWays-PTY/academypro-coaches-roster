-- Delete all squads except U15 Squad
DELETE FROM squads WHERE id != 'sq-u15-elite' AND code != 'U15';

-- Delete squad player mappings for deleted squads
DELETE FROM squad_players WHERE squad_id != 'sq-u15-elite' AND squad_id != 'U15';

-- Ensure all players are set to U15 Squad
UPDATE players SET age_group = 'U15', team = 'U15 Squad' WHERE school_id = 'OVK';

-- Ensure U15 Squad exists cleanly
INSERT OR REPLACE INTO squads (id, school_id, coach_id, name, code, description)
VALUES ('sq-u15-elite', 'OVK', 'USR-COACH-001', 'U15 Squad', 'U15', 'High Performance U15 Development Squad');

-- Ensure all U15 players are linked to sq-u15-elite
INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT 'sq-u15-elite', id FROM players WHERE school_id = 'OVK';
