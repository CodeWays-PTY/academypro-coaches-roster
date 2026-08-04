INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT s.id, p.id
FROM players p
JOIN squads s ON (LOWER(s.code) = LOWER(p.age_group) OR LOWER(s.name) = LOWER(p.age_group) OR LOWER(s.name) = LOWER(p.team) OR LOWER(s.code) = LOWER(p.team));
