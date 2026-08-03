# Handoff Report — Explorer M1 (Milestone 1)

## 1. Observation
- **Remote D1 Configuration**: `worker/wrangler.json` lines 18–25 defines D1 database binding `DB`, database_name `"academypro-db"`, database_id `"c1f553a7-1dcf-48fb-a678-9885ad76e0c0"`, and `migrations_dir: "../migrations"`.
- **Existing Migrations**: Directory `migrations/` contains 19 migration files up to `migrations/0019_populate_u15_squad_players.sql`. Next sequential migration file is `migrations/0020_cleanup_obsolete_schema.sql`.
- **`fitness_baselines` Table References**:
  - `migrations/0001_initialize_schema.sql:57` (`CREATE TABLE IF NOT EXISTS fitness_baselines`)
  - `migrations/0002_seed_data.sql:78-110` (`INSERT INTO fitness_baselines...`)
  - `migrations/0011_dynamic_fitness_metrics.sql:56-78` (migrated data into `player_test_logs`)
  - `worker/src/index.ts:2473` (`SELECT * FROM fitness_baselines WHERE player_id = ?`)
  - `worker/src/index.ts:3231` (`INSERT INTO fitness_baselines...`)
  - `DATABASE_SCHEMA.md:151,326`
- **`fitness_progression` Table References**:
  - `migrations/0001_initialize_schema.sql:74` (`CREATE TABLE IF NOT EXISTS fitness_progression`)
  - `migrations/0012_seed_janmen778_student_user.sql:40` (`INSERT INTO fitness_progression...`)
  - `worker/src/index.ts:2479` (`SELECT * FROM fitness_progression WHERE player_id = ?`)
  - `DATABASE_SCHEMA.md:169,327`
- **`players` Obsolete Columns**:
  - `ugroups_active`: `migrations/0001_initialize_schema.sql:46`, `worker/src/index.ts:1186,2583`, `DATABASE_SCHEMA.md:69`.
  - `parent_name`: `migrations/0001_initialize_schema.sql:40`, `DATABASE_SCHEMA.md:61`.
  - `parent_id`: `migrations/0001_initialize_schema.sql:36`, `worker/src/index.ts:2355`, `DATABASE_SCHEMA.md:57`.
- **`parent_child_links` Obsolete Columns**:
  - `parent_phone`: `worker/migrations/0001_ensure_all_tables.sql:176`, `DATABASE_SCHEMA.md:275`.
  - `parent_email`: `worker/migrations/0001_ensure_all_tables.sql:177`, `DATABASE_SCHEMA.md:276`.

## 2. Logic Chain
1. `fitness_baselines` and `fitness_progression` were legacy static fitness tables. In migration `0011_dynamic_fitness_metrics.sql`, dynamic metrics (`test_metric_definitions`) and time-series evaluation logs (`player_test_logs`) were introduced and populated from baseline data.
2. `players.ugroups_active` is an unused legacy flag. `players.parent_name` and `players.parent_id` are legacy fields superseded by user accounts (`role = 'Parent'`) and `parent_child_links`.
3. `parent_child_links.parent_phone` and `parent_child_links.parent_email` are legacy columns superseded by `parent_user_id` linked to the `users` table (`phone`, `email`).
4. SQLite 3.35.0+ (supported by Cloudflare D1) allows `DROP TABLE IF EXISTS` and `ALTER TABLE ... DROP COLUMN ...`.
5. Therefore, creating `migrations/0020_cleanup_obsolete_schema.sql` with exact DDL drop statements will safely and cleanly purge all obsolete tables and columns from Cloudflare D1.

## 3. Caveats
- `ALTER TABLE ... DROP COLUMN ...` in SQLite must be executed as individual SQL statements per column (SQLite syntax does not support multiple columns in a single `ALTER TABLE` clause).
- After running the remote D1 migration, `worker/src/index.ts` must be refactored (lines 2473, 2479, 3231, 1186, 2355, 2583) to remove queries targeting dropped tables/columns, followed by `wrangler deploy` to ensure Worker API code stays in sync with D1 schema.

## 4. Conclusion
All target obsolete tables (`fitness_baselines`, `fitness_progression`) and columns (`players.ugroups_active`, `players.parent_name`, `players.parent_id`, `parent_child_links.parent_phone`, `parent_child_links.parent_email`) have been fully audited. The exact SQL script `migrations/0020_cleanup_obsolete_schema.sql` is formulated and ready for implementation.

### Exact SQL Script (`migrations/0020_cleanup_obsolete_schema.sql`):
```sql
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
```

## 5. Verification Method
1. **File Inspection**: Verify `migrations/0020_cleanup_obsolete_schema.sql` exists and contains the exact SQL script above.
2. **Local D1 Dry-Run Execution**:
   ```bash
   npx wrangler d1 execute academypro-db --local --file=migrations/0020_cleanup_obsolete_schema.sql
   ```
3. **Remote D1 Execution**:
   ```bash
   npx wrangler d1 execute academypro-db --remote --file=migrations/0020_cleanup_obsolete_schema.sql
   ```
4. **Schema Verification**:
   Inspect remote schema tables and columns:
   ```bash
   npx wrangler d1 execute academypro-db --remote --command="PRAGMA table_info(players);"
   npx wrangler d1 execute academypro-db --remote --command="PRAGMA table_info(parent_child_links);"
   ```
   Confirm `fitness_baselines` and `fitness_progression` do not exist, and `ugroups_active`, `parent_name`, `parent_id`, `parent_phone`, `parent_email` are absent.
