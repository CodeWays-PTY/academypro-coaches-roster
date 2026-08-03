-- Migration: 0020_cleanup_obsolete_schema.sql
-- Description: Drop obsolete tables (fitness_baselines, fitness_progression) and prune legacy columns from players and parent_child_links.

PRAGMA foreign_keys = OFF;

-- ==========================================
-- 1. DROP OBSOLETE TABLES
-- ==========================================
DROP TABLE IF EXISTS fitness_baselines;
DROP TABLE IF EXISTS fitness_progression;

-- ==========================================
-- 2. PRUNE OBSOLETE COLUMNS FROM PLAYERS
-- ==========================================
ALTER TABLE players DROP COLUMN ugroups_active;
ALTER TABLE players DROP COLUMN parent_name;
ALTER TABLE players DROP COLUMN parent_id;

-- ==========================================
-- 3. PRUNE OBSOLETE COLUMNS FROM PARENT_CHILD_LINKS
-- ==========================================
ALTER TABLE parent_child_links DROP COLUMN parent_phone;
ALTER TABLE parent_child_links DROP COLUMN parent_email;

PRAGMA foreign_keys = ON;
