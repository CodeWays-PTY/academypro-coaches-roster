-- Clean up old seed squad names in events table
UPDATE events 
SET team = 'U15 Squad' 
WHERE team = 'Academy Elite' OR team = 'U15 Academy Elite' OR team LIKE '%Academy Elite%';

UPDATE events 
SET age_group = 'U15' 
WHERE age_group = 'Academy Elite' OR age_group LIKE '%Academy Elite%';
