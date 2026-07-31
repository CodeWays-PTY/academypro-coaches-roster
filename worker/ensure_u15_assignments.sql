-- Ensure U15 squad exists
INSERT OR REPLACE INTO squads (id, school_id, coach_id, name, code, description)
VALUES ('sq-u15-elite', 'OVK', 'USR-COACH-001', 'U15 Squad', 'U15', 'High Performance U15 Development Squad');

-- Ensure Jan Student (janmen778@gmail.com) is in players table with U15 Squad
INSERT OR REPLACE INTO players (id, school_id, first_name, last_name, email, age_group, position, team, status)
VALUES ('OVK-STUDENT-JAN', 'OVK', 'Jan', 'Student', 'janmen778@gmail.com', 'U15', 'Fly-half', 'U15 Squad', 'Active');

-- Ensure Justin Robertse (jrobertse3@gmail.com) is in players table with U15 Squad
INSERT OR REPLACE INTO players (id, school_id, first_name, last_name, email, age_group, position, team, status)
VALUES ('OVK-STUDENT-JUSTIN', 'OVK', 'Justin', 'Robertse', 'jrobertse3@gmail.com', 'U15', 'Forward / Wing', 'U15 Squad', 'Active');

-- Clear any outdated squad_players entries and explicitly assign both to sq-u15-elite
DELETE FROM squad_players WHERE player_id IN ('OVK-STUDENT-JAN', 'OVK-STUDENT-JUSTIN');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-u15-elite', 'OVK-STUDENT-JAN');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-u15-elite', 'OVK-STUDENT-JUSTIN');
