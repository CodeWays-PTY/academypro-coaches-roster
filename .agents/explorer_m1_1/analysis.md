# Milestone 1: D1 Database SQL Migration & Cleanup — Explorer Analysis Report

## Executive Summary
This report presents the complete investigation and formulation of **Milestone 1: D1 Database SQL Migration & Cleanup**. The objective of Milestone 1 is to eliminate legacy schema debt in Cloudflare D1 by dropping obsolete tables (`fitness_baselines`, `fitness_progression`) and pruning obsolete columns from `players` (`ugroups_active`, `parent_name`, `parent_id`) and `parent_child_links` (`parent_phone`, `parent_email`).

---

## 1. D1 Database Configuration & Target Binding
Inspection of `worker/wrangler.json` (lines 18–25) confirms the target remote D1 database configuration:
- **Binding Name**: `DB`
- **Database Name**: `academypro-db`
- **Database ID**: `c1f553a7-1dcf-48fb-a678-9885ad76e0c0`
- **Migrations Directory**: `../migrations` (resolves to root directory `c:\Development\academypro\migrations`)

Existing migrations in `migrations/` range from `0001_initialize_schema.sql` to `0019_populate_u15_squad_players.sql`. The new migration file for this milestone must be named `migrations/0020_cleanup_obsolete_schema.sql`.

---

## 2. Inventory of Obsolete Schema Elements & Codebase References

### A. Obsolete Tables to Drop

1. **`fitness_baselines`**
   - **Original Purpose**: Stored hardcoded single-point fitness test values (`speed_40m`, `vertical_jump`, `push_ups`, etc.).
   - **Superseded By**: Dynamic metric system (`test_metric_definitions` and `player_test_logs`). Data was already migrated in `migrations/0011_dynamic_fitness_metrics.sql` (lines 56–78).
   - **Locations in Codebase**:
     - `migrations/0001_initialize_schema.sql` (Line 57: `CREATE TABLE IF NOT EXISTS fitness_baselines`)
     - `migrations/0002_seed_data.sql` (Lines 78–110: Initial seed inserts)
     - `worker/migrations/0001_ensure_all_tables.sql` (Line 80: Table creation)
     - `DATABASE_SCHEMA.md` (Lines 151–164 & Summary Table Line 326)
     - `worker/src/index.ts`:
       - Line 2473: `baseline = await db.prepare('SELECT * FROM fitness_baselines WHERE player_id = ?').bind(playerId).first();`
       - Lines 3229, 3231: `INSERT INTO fitness_baselines (player_id, vertical_jump, speed_40m, updated_at)`
   - **Recommended Action**: Drop table via `DROP TABLE IF EXISTS fitness_baselines;` and refactor `worker/src/index.ts` to source fitness scores exclusively from `player_test_logs`.

2. **`fitness_progression`**
   - **Original Purpose**: Stored weekly fitness progression records (`week`, `speed_40m`, `strength_reps`, etc.).
   - **Superseded By**: Time-series `player_test_logs` (ordered by `test_date`).
   - **Locations in Codebase**:
     - `migrations/0001_initialize_schema.sql` (Line 74: `CREATE TABLE IF NOT EXISTS fitness_progression`)
     - `migrations/0012_seed_janmen778_student_user.sql` (Line 40: Seed insert)
     - `worker/migrations/0001_ensure_all_tables.sql` (Line 94: Table creation)
     - `DATABASE_SCHEMA.md` (Lines 169–180 & Summary Table Line 327)
     - `worker/src/index.ts`:
       - Line 2479: `const { results } = await db.prepare('SELECT * FROM fitness_progression WHERE player_id = ? ORDER BY week ASC').bind(playerId).all();`
   - **Recommended Action**: Drop table via `DROP TABLE IF EXISTS fitness_progression;` and refactor `worker/src/index.ts` to fetch time-series logs from `player_test_logs`.

---

### B. Obsolete Columns to Drop

1. **`players.ugroups_active`**
   - **Purpose & Status**: Legacy integer flag (`DEFAULT 1`). Unused in application logic.
   - **Locations in Codebase**:
     - `migrations/0001_initialize_schema.sql` (Line 46)
     - `migrations/0002_seed_data.sql` (Line 20)
     - `worker/migrations/0001_ensure_all_tables.sql` (Line 27)
     - `DATABASE_SCHEMA.md` (Line 69)
     - `worker/src/index.ts` (Lines 1186, 2583: `ugroupsActive: p.ugroups_active`)
   - **Recommended Action**: `ALTER TABLE players DROP COLUMN ugroups_active;` and remove property mapping in `worker/src/index.ts`.

2. **`players.parent_name`**
   - **Purpose & Status**: Legacy text column storing parent name. Superseded by `users` accounts (`role = 'Parent'`) and `parent_child_links`.
   - **Locations in Codebase**:
     - `migrations/0001_initialize_schema.sql` (Line 40)
     - `migrations/0002_seed_data.sql` (Line 20)
     - `worker/migrations/0001_ensure_all_tables.sql` (Line 19)
     - `DATABASE_SCHEMA.md` (Line 61)
   - **Recommended Action**: `ALTER TABLE players DROP COLUMN parent_name;`.

3. **`players.parent_id`**
   - **Purpose & Status**: Legacy text column storing single parent user ID. Superseded by `parent_child_links` (`parent_user_id` / `player_id` mapping).
   - **Locations in Codebase**:
     - `migrations/0001_initialize_schema.sql` (Line 36)
     - `migrations/0002_seed_data.sql` (Line 20)
     - `worker/migrations/0001_ensure_all_tables.sql` (Line 15)
     - `DATABASE_SCHEMA.md` (Line 57)
     - `worker/src/index.ts` (Line 2355: `SELECT * FROM players WHERE parent_id = ?`)
   - **Recommended Action**: `ALTER TABLE players DROP COLUMN parent_id;` and refactor worker route at Line 2355 to join `parent_child_links`.

4. **`parent_child_links.parent_phone`**
   - **Purpose & Status**: Legacy text column. Replaced by `parent_user_id` linking directly to `users.phone`.
   - **Locations in Codebase**:
     - `worker/migrations/0001_ensure_all_tables.sql` (Line 176)
     - `DATABASE_SCHEMA.md` (Line 275)
   - **Recommended Action**: `ALTER TABLE parent_child_links DROP COLUMN parent_phone;`.

5. **`parent_child_links.parent_email`**
   - **Purpose & Status**: Legacy text column. Replaced by `parent_user_id` linking directly to `users.email`.
   - **Locations in Codebase**:
     - `worker/migrations/0001_ensure_all_tables.sql` (Line 177)
     - `DATABASE_SCHEMA.md` (Line 276)
   - **Recommended Action**: `ALTER TABLE parent_child_links DROP COLUMN parent_email;`.

---

## 3. SQLite & Cloudflare D1 Syntax Compatibility
Cloudflare D1 runs SQLite 3.35.0+, which natively supports:
1. `DROP TABLE IF EXISTS table_name;`
2. `ALTER TABLE table_name DROP COLUMN column_name;`

*Note on SQLite Constraints*:
- In SQLite, each column drop must be executed as an independent `ALTER TABLE` statement (multiple column drops in a single `ALTER TABLE` clause are not supported).
- `PRAGMA foreign_keys = OFF;` should precede schema modifications to prevent potential foreign key check errors during table drops, followed by `PRAGMA foreign_keys = ON;`.

---

## 4. Exact Formulated SQL Script (`migrations/0020_cleanup_obsolete_schema.sql`)

Below is the complete, production-ready SQL script to be created in `migrations/0020_cleanup_obsolete_schema.sql`:

```sql
-- Migration: 0020_cleanup_obsolete_schema.sql
-- Description: Drop obsolete tables (fitness_baselines, fitness_progression) and prune legacy columns from players and parent_child_links.

PRAGMA foreign_keys = OFF;

-- ==========================================
-- 1. DROP OBSOLETE TABLES
-- ==========================================
-- fitness_baselines: Superseded by dynamic test_metric_definitions & player_test_logs
DROP TABLE IF EXISTS fitness_baselines;

-- fitness_progression: Superseded by time-series player_test_logs
DROP TABLE IF EXISTS fitness_progression;

-- ==========================================
-- 2. PRUNE OBSOLETE COLUMNS FROM PLAYERS
-- ==========================================
-- ugroups_active: Unused legacy flag
ALTER TABLE players DROP COLUMN ugroups_active;

-- parent_name: Superseded by users accounts & parent_child_links
ALTER TABLE players DROP COLUMN parent_name;

-- parent_id: Superseded by parent_child_links table
ALTER TABLE players DROP COLUMN parent_id;

-- ==========================================
-- 3. PRUNE OBSOLETE COLUMNS FROM PARENT_CHILD_LINKS
-- ==========================================
-- parent_phone: Replaced by parent_user_id linked to users.phone
ALTER TABLE parent_child_links DROP COLUMN parent_phone;

-- parent_email: Replaced by parent_user_id linked to users.email
ALTER TABLE parent_child_links DROP COLUMN parent_email;

PRAGMA foreign_keys = ON;
```

---

## 5. Implementer Action Plan & Downstream Worker Refactoring

When the Implementer agent creates `migrations/0020_cleanup_obsolete_schema.sql` and executes it against D1 (`npx wrangler d1 execute academypro-db --remote --file=migrations/0020_cleanup_obsolete_schema.sql`), the following code updates in `worker/src/index.ts` must accompany the migration:

1. **Remove `fitness_baselines` queries** (Lines 2473, 3229–3231 in `worker/src/index.ts`):
   - Replace baseline lookups with dynamic queries on `player_test_logs` joined with `test_metric_definitions`.
2. **Remove `fitness_progression` query** (Line 2479 in `worker/src/index.ts`):
   - Replace progression lookups with `player_test_logs` ordered by `test_date ASC`.
3. **Remove `ugroups_active` mapping** (Lines 1186, 2583 in `worker/src/index.ts`):
   - Remove `ugroupsActive` from JSON response DTOs.
4. **Refactor `parent_id` lookup** (Line 2355 in `worker/src/index.ts`):
   - Replace `SELECT * FROM players WHERE parent_id = ?` with `SELECT p.* FROM players p JOIN parent_child_links pcl ON p.id = pcl.player_id WHERE pcl.parent_user_id = ?`.
5. **Update `DATABASE_SCHEMA.md`**:
   - Remove `fitness_baselines` and `fitness_progression` sections.
   - Remove `parent_id`, `parent_name`, `ugroups_active` from `players` table documentation.
   - Remove `parent_phone`, `parent_email` from `parent_child_links` table documentation.
   - Update summary table from 18 to 16 active D1 tables.
