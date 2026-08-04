-- Deduplicate and clean U15 players and squad memberships
PRAGMA foreign_keys = OFF;

DELETE FROM players WHERE id LIKE 'plr_17858430%' OR id LIKE 'AC-%';
DELETE FROM users WHERE id LIKE 'usr_17858430%' OR email = 'janmen788@gmail.com';
DELETE FROM squad_players WHERE player_id LIKE 'plr_17858430%' OR player_id LIKE 'AC-%';

UPDATE players SET team = 'U15', age_group = 'U15', school_id = '1' WHERE id LIKE 'plr_u15_%';
UPDATE users SET school_id = '1' WHERE id LIKE 'usr_u15_%';

INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Immanuel' AND last_name = 'Engelbrecht';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Sello' AND last_name = 'Jantie';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Wikus' AND last_name = 'De Koker';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Phatu' AND last_name = 'Motlhabane';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Shayaan' AND last_name = 'Rafiq';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Alexander' AND last_name = 'Coetzer';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Achuma' AND last_name = 'Bibi';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Taylon' AND last_name = 'Cartwright';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Bokang' AND last_name = 'Maphosa';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Kyle' AND last_name = 'Smith';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Simphiwe' AND last_name = 'Philemon';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Khumo' AND last_name = 'Kutumela';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Luvani' AND last_name = 'Nkwinika';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Liam' AND last_name = 'Maré';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Kody' AND last_name = 'Langeveldt';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Theodore' AND last_name = 'Mosia';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Shelton' AND last_name = 'Julies';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Luyanda' AND last_name = 'Nzotho';
INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT 'sq-1785841532380', id FROM players WHERE first_name = 'Siphosihle' AND last_name = 'Masemola';