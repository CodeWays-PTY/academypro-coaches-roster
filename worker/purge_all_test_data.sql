-- Purge all test events, action plans, logs, and non-whitelisted users/athletes
DELETE FROM events;
DELETE FROM action_plans;
DELETE FROM player_test_logs;
DELETE FROM attendance;
DELETE FROM academic_logs;
DELETE FROM notifications;
DELETE FROM parent_child_links;

DELETE FROM squad_players 
WHERE player_id NOT IN (
    SELECT id FROM players WHERE LOWER(COALESCE(email, '')) IN ('janmen777@gmail.com', 'janmen778@gmail.com')
);

DELETE FROM players 
WHERE LOWER(COALESCE(email, '')) NOT IN ('janmen777@gmail.com', 'janmen778@gmail.com')
  AND LOWER(id) NOT IN ('janmen777@gmail.com', 'janmen778@gmail.com', 'plr_jan');

DELETE FROM users 
WHERE LOWER(COALESCE(email, '')) NOT IN ('janmen777@gmail.com', 'janmen778@gmail.com')
  AND LOWER(id) NOT IN ('janmen777@gmail.com', 'janmen778@gmail.com');
