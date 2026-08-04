-- Standardize school_id to numeric string '1' across all database tables
UPDATE users SET school_id = '1' WHERE school_id = 'OVK' OR school_id = 'OVK Academy' OR school_id = '1.0' OR school_id IS NULL;
UPDATE players SET school_id = '1' WHERE school_id = 'OVK' OR school_id = 'OVK Academy' OR school_id = '1.0' OR school_id IS NULL;
UPDATE squads SET school_id = '1' WHERE school_id = 'OVK' OR school_id = 'OVK Academy' OR school_id = '1.0' OR school_id IS NULL;
UPDATE test_metric_definitions SET school_id = '1' WHERE school_id = 'OVK' OR school_id = 'OVK Academy' OR school_id = '1.0' OR school_id IS NULL;
