-- Update school name from Hoërskool Oos-Moot to Hoërskool Overkruin
UPDATE schools 
SET name = 'Hoërskool Overkruin', code = 'OVK' 
WHERE id = 1 OR id = '1' OR code = 'OVK';
