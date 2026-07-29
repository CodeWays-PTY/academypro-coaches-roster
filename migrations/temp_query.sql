SELECT COUNT(*) as squad_count FROM squads;
SELECT COUNT(*) as player_count FROM players;
SELECT id, name, code FROM squads;
SELECT squad_id, COUNT(*) as count FROM squad_players GROUP BY squad_id;
