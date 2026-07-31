-- Delete all legacy seed player records except real registered athletes (Jan Student & Justin Robertse)
DELETE FROM players
WHERE email NOT IN ('janmen778@gmail.com', 'jrobertse3@gmail.com')
  AND id NOT IN ('OVK-STUDENT-JAN', 'OVK-STUDENT-JUSTIN');

-- Delete orphaned squad_players mappings
DELETE FROM squad_players
WHERE player_id NOT IN (SELECT id FROM players);

-- Delete orphaned player test logs
DELETE FROM player_test_logs
WHERE player_id NOT IN (SELECT id FROM players);

-- Delete orphaned parent-child links
DELETE FROM parent_child_links
WHERE player_email NOT IN (SELECT email FROM players);
