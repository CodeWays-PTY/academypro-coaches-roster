SELECT '--- SQUADS ---' as section;
SELECT id, name, code, coach_id FROM squads;

SELECT '--- PLAYERS ---' as section;
SELECT id, first_name, last_name, email, school_id, age_group, team FROM players;

SELECT '--- SQUAD_PLAYERS ---' as section;
SELECT * FROM squad_players;
