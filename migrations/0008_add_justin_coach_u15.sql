-- Add Justin to U15 Squad as coach alongside Neels Venter and Tiaan Vorster
UPDATE squads 
SET coach_id = 'cch_1785841398413,cch_1785841411823,cch_1785841426303', 
    coach_name = 'Justin, Neels Venter & Tiaan Vorster'
WHERE id = 'sq-1785841532380' OR name = 'U15';

-- Ensure Justin is active Coach for School 1
UPDATE users 
SET role = 'Coach', school_id = '1' 
WHERE id = 'cch_1785841398413' OR email = 'jrobertse1@gmail.com';
