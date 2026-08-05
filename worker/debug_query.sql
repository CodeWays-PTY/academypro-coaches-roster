SELECT id, email, first_name, last_name, role, school_id FROM users ORDER BY created_at ASC;
SELECT id, name, code, school_id, coach_id FROM squads ORDER BY name ASC;
SELECT COUNT(*) as total_players FROM players;
SELECT COUNT(*) as total_squad_players FROM squad_players;
SELECT sp.squad_id, COUNT(*) as player_count FROM squad_players sp GROUP BY sp.squad_id;
SELECT id, first_name, last_name, school_id, age_group, team FROM players LIMIT 10;
SELECT DISTINCT school_id FROM players;
SELECT DISTINCT school_id FROM squads;
