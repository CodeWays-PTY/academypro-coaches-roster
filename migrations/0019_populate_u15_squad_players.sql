-- Link all U15 registered players to the U15 squad in squad_players junction table
INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT s.id, p.id
FROM players p
JOIN squads s ON (s.code = p.age_group OR s.name LIKE '%' || p.age_group || '%' OR p.team = s.name);
