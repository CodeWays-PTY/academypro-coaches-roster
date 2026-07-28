-- Seed initial coach squads and map active players to squads in Cloudflare D1
INSERT OR REPLACE INTO squads (id, school_id, coach_id, name, code, description) VALUES
('sq-u15-elite', 'OVK', 'USR-COACH-2', 'U15 Academy Elite', 'U15', 'High Performance U15 Development Squad'),
('sq-u14-first', 'OVK', 'USR-COACH-2', 'U14 First Team', 'U14', 'Junior Academy U14 Squad'),
('sq-u16-first', 'OVK', 'USR-COACH-2', 'U16 First Team', 'U16', 'Senior Academy U16 Squad'),
('sq-first-team', 'OVK', 'USR-COACH-2', 'First Team', '1st', 'Overkruin 1st XV Team');

-- Map active players into squad_players based on their age group
INSERT OR REPLACE INTO squad_players (squad_id, player_id)
SELECT 'sq-u15-elite', id FROM players WHERE age_group = 'U15';

INSERT OR REPLACE INTO squad_players (squad_id, player_id)
SELECT 'sq-u14-first', id FROM players WHERE age_group = 'U14';

INSERT OR REPLACE INTO squad_players (squad_id, player_id)
SELECT 'sq-u16-first', id FROM players WHERE age_group = 'U16';

INSERT OR REPLACE INTO squad_players (squad_id, player_id)
SELECT 'sq-first-team', id FROM players WHERE team LIKE '%First%' OR team LIKE '%1st%';
