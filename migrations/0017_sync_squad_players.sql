-- Sync all registered players with squad_players junction table based on age_group/team
INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT s.id, p.id 
FROM players p 
JOIN squads s ON (s.code = p.age_group OR s.name LIKE '%' || p.age_group || '%' OR p.team = s.name);
