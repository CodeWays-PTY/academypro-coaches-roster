-- Assign Neels Venter and Tiaan Vorster as coaches for U15 squad
UPDATE squads 
SET coach_id = 'cch_1785841411823,cch_1785841426303', 
    coach_name = 'Neels Venter & Tiaan Vorster'
WHERE id = 'sq-1785841532380' OR name = 'U15';

-- Ensure Neels Venter and Tiaan Vorster are active coaches for School 1
UPDATE users 
SET role = 'Coach', school_id = '1' 
WHERE id IN ('cch_1785841411823', 'cch_1785841426303') 
   OR email IN ('neelsventer13@gmail.com', 'tiaanvorster14@gmail.com');

-- Purge all previous events, test metrics, player test logs, event checkins, and attendance records
DELETE FROM events;
DELETE FROM test_metric_definitions;
DELETE FROM player_test_logs;
DELETE FROM event_checkins;
DELETE FROM attendance;
DELETE FROM custom_actions;
