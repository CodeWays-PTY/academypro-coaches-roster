SELECT id, name, code, school_id, coach_id FROM squads;
SELECT squad_id, player_id FROM squad_players LIMIT 5;
SELECT id, school_id, age_group, team FROM players WHERE school_id = '1' LIMIT 5;
SELECT id, school_id, age_group, team FROM players WHERE school_id = 1 LIMIT 5;
