-- Purge all sample / dummy player records from players table
DELETE FROM players
WHERE id NOT IN ('OVK-STUDENT-JAN', 'OVK-STUDENT-JUSTIN')
   OR (email != 'janmen778@gmail.com' AND email != 'jrobertse3@gmail.com');

-- Purge orphaned squad_players records
DELETE FROM squad_players
WHERE player_id NOT IN ('OVK-STUDENT-JAN', 'OVK-STUDENT-JUSTIN');

-- Re-link Jan Student & Justin Robertse to sq-u15-elite
INSERT OR REPLACE INTO squad_players (squad_id, player_id) VALUES ('sq-u15-elite', 'OVK-STUDENT-JAN');
INSERT OR REPLACE INTO squad_players (squad_id, player_id) VALUES ('sq-u15-elite', 'OVK-STUDENT-JUSTIN');
