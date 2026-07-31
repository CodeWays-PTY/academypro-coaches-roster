-- Fix Jan Student record in players
UPDATE players
SET first_name = 'Jan',
    last_name = 'Student',
    email = 'janmen778@gmail.com',
    age_group = 'U15',
    team = 'U15 Squad'
WHERE email = 'janmen778@gmail.com' OR id = 'OVK-STUDENT-JAN';

-- Insert Justin Robertse record into players if not exists
INSERT OR REPLACE INTO players (id, school_id, first_name, last_name, email, age_group, position, team, status)
VALUES ('OVK-STUDENT-JUSTIN', 'OVK', 'Justin', 'Robertse', 'jrobertse3@gmail.com', 'U15', 'Forward / Wing', 'U15 Squad', 'Active');

-- Assign Jan Student & Justin Robertse to sq-u15-elite squad in squad_players
INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES ('sq-u15-elite', 'OVK-STUDENT-JAN');
INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES ('sq-u15-elite', 'OVK-STUDENT-JUSTIN');
