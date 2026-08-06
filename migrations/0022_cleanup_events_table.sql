UPDATE events 
SET series_id = 'EVT-1785925048902' 
WHERE id LIKE 'EVT-1785925048902_%' OR (title = 'U15 Gym Training' AND (series_id IS NULL OR series_id = ''));

ALTER TABLE events DROP COLUMN batch_id;
ALTER TABLE events DROP COLUMN completion_count;
