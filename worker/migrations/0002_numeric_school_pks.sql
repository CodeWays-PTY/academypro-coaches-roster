-- Migration: Convert schools to numeric INTEGER PRIMARY KEY AUTOINCREMENT
CREATE TABLE IF NOT EXISTS schools_new (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    code TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO schools_new (id, name, code) VALUES (1, 'Hoërskool Oos-Moot', 'OVK');

DROP TABLE IF EXISTS schools;
ALTER TABLE schools_new RENAME TO schools;

-- Update school_id references to numeric 1 across active tables
UPDATE users SET school_id = 1 WHERE school_id = 'OVK' OR school_id IS NULL;
UPDATE players SET school_id = 1 WHERE school_id = 'OVK' OR school_id IS NULL;
UPDATE squads SET school_id = 1 WHERE school_id = 'OVK' OR school_id IS NULL;
UPDATE events SET school_id = 1 WHERE school_id = 'OVK' OR school_id IS NULL;
UPDATE action_plans SET school_id = 1 WHERE school_id = 'OVK' OR school_id IS NULL;
UPDATE test_metric_definitions SET school_id = 1 WHERE school_id = 'OVK' OR school_id IS NULL;
