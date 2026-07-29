-- Explicitly link all U15 registered players to the U15 Squad in squad_players junction table
INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT s.id, p.id
FROM players p
CROSS JOIN squads s
WHERE (p.age_group = 'U15' OR p.team LIKE '%U15%')
  AND (s.code = 'U15' OR s.name LIKE '%U15%' OR s.id LIKE '%U15%');
