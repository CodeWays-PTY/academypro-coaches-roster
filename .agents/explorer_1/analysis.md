# Cloudflare D1 Database, SQL Migrations, and Schema Analysis Report

**Explorer**: Explorer 1  
**Working Directory**: `C:\Development\academypro\.agents\explorer_1`  
**Date**: 2026-07-28  
**Scope**: Read-only exploration of Cloudflare D1 database migrations (`C:\Development\academypro\worker\migrations\` and `C:\Development\academypro\migrations\`), schema documentation (`C:\Development\academypro\DATABASE_SCHEMA.md`), and related column references (`parent_contact`, `email`).

---

## Executive Summary

1. **Dual Migration Directories Identified**:
   - `C:\Development\academypro\worker\migrations\` (Worker D1 Migrations: 6 files, `0001` through `0006`).
   - `C:\Development\academypro\migrations\` (Root D1 Migrations: 15 files, `0001` through `0015`).
   
2. **Mock Seed Scripts & Static Password Hashes**:
   - Static mock password hashes (`'sha256$mockedhash'`) are present in 5 root migration files (`0002_seed_data.sql`, `0006_seed_test_coach_user.sql`, `0009_seed_jrobertse_coach_user.sql`, `0012_seed_janmen778_student_user.sql`).
   - Mock dataset seed scripts exist across both directories (`migrations/0004_seed_dashboard_mock_data.sql`, `migrations/0005_seed_player_details.sql`, `migrations/0013_seed_student_events_and_images.sql`, `migrations/0014_seed_student_notifications.sql`, `worker/migrations/0004_seed_coach_squads.sql`, `worker/migrations/0005_assign_jrobertse_u15_squad.sql`).

3. **`parent_contact` and `email` Column Audit**:
   - `parent_contact` was originally present in `migrations/0001_initialize_schema.sql` (Line 41) and `migrations/0002_seed_data.sql` (Lines 20–72), but was explicitly dropped from D1 in `worker/migrations/0003_remove_parent_phone_columns.sql` (Line 3). It remains incorrectly documented in `DATABASE_SCHEMA.md` (Line 66).
   - `email` is present in `users.email` across multiple schema and seed files, in `players.email` (`worker/migrations/0001_ensure_all_tables.sql:18`, `worker/migrations/0002_add_missing_columns.sql:3`), and in `parent_child_links` (`parent_email`, `player_email` in `worker/migrations/0001_ensure_all_tables.sql:178,180`).

4. **`DATABASE_SCHEMA.md` Discrepancies & Missing Documentation**:
   - **7 Missing Tables**: `squads`, `squad_players`, `test_metric_definitions`, `player_test_logs`, `action_plans`, `notifications`, `parent_child_links` are completely absent from `DATABASE_SCHEMA.md`.
   - **Outdated / Inaccurate Schemas**: `players` table docs list dropped `parent_contact` and miss `email`, `phone`, `dob`, `preferred_position`. `users` table docs miss `phone` and `Parent` role. `events` table docs use `INTEGER PRIMARY KEY` instead of production `TEXT PRIMARY KEY` and miss `age_group`, `team`, `workout_image_path`. `attendance` table docs miss `event_id`.

---

## Task 1: Examination of Migration Files, Mock Seed Scripts & Password Hashes

### Directory 1: `C:\Development\academypro\worker\migrations\`
This directory contains production worker migrations executed directly against D1 (`wrangler d1 execute`).

| File | Purpose | Key Findings & Content |
|---|---|---|
| `worker/migrations/0001_ensure_all_tables.sql` | Schema Creation | Creates 14 D1 production tables (`users`, `players`, `squads`, `squad_players`, `academic_logs`, `test_metric_definitions`, `player_test_logs`, `fitness_baselines`, `fitness_progression`, `match_stats`, `attendance`, `events`, `action_plans`, `notifications`, `parent_child_links`). Line 7 defines `password_hash TEXT` (unseeded). |
| `worker/migrations/0002_add_missing_columns.sql` | Schema Alteration | Line 2: `ALTER TABLE users ADD COLUMN phone TEXT;`<br>Line 3: `ALTER TABLE players ADD COLUMN email TEXT;`<br>Line 4: `ALTER TABLE players ADD COLUMN phone TEXT;`<br>Line 5: `ALTER TABLE players ADD COLUMN parent_phone TEXT;`<br>Line 6: `ALTER TABLE players ADD COLUMN dob TEXT;`<br>Line 7: `ALTER TABLE players ADD COLUMN preferred_position TEXT;` |
| `worker/migrations/0003_remove_parent_phone_columns.sql` | Schema Alteration | Line 2: `ALTER TABLE players DROP COLUMN parent_phone;`<br>Line 3: `ALTER TABLE players DROP COLUMN parent_contact;` |
| `worker/migrations/0004_seed_coach_squads.sql` | Mock Seed Script | Lines 2–6: Seeds mock squad records (`sq-u15-elite`, `sq-u14-first`, `sq-u16-first`, `sq-first-team`) assigned to `USR-COACH-2`.<br>Lines 9–19: Maps players to squads based on `age_group` and `team`. |
| `worker/migrations/0005_assign_jrobertse_u15_squad.sql` | Mock Seed Script | Lines 2–4: Updates `jrobertse1@gmail.com` user record.<br>Lines 6–7: Seeds squad `sq-u15-jrob`.<br>Lines 10–17: Reassigns squad `sq-u15-elite` to `USR-COACH-JROB` and maps U15 players. |
| `worker/migrations/0006_add_event_id_to_attendance.sql` | Schema Alteration | Line 2: `ALTER TABLE attendance ADD COLUMN event_id TEXT;`<br>Line 5: `CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_player_event ON attendance(player_id, event_id);` |

---

### Directory 2: `C:\Development\academypro\migrations\`
This directory contains 15 migration files used during initial development and local SQLite test setups.

| File | Type | Line Nos. | Findings |
|---|---|---|---|
| `migrations/0001_initialize_schema.sql` | Schema | 1–144 | Defines initial 10 tables (`schools`, `users`, `sports`, `players`, `academic_logs`, `fitness_baselines`, `fitness_progression`, `match_stats`, `attendance`, `events`). `password_hash TEXT NOT NULL` at Line 14; `parent_contact TEXT` at Line 41. |
| `migrations/0002_seed_data.sql` | Seed & Mock Hash | 11, 14, 17 | Contains static mock password hashes:<br>- Line 11: `USR-COACH-1`, `coach.ross@overkruin.co.za`, `'sha256$mockedhash'`<br>- Line 14: `USR-STUDENT-1`, `student@overkruin.co.za`, `'sha256$mockedhash'`<br>- Line 17: `PAR-OVK-001`, `parent@overkruin.co.za`, `'sha256$mockedhash'`<br>Also seeds 53 player rows (Lines 20–72) with mock names and null values. |
| `migrations/0003_create_events_table.sql` | Schema & Seed | 22–25 | Seeds 4 mock events for `OVK`. |
| `migrations/0004_seed_dashboard_mock_data.sql` | Mock Seed Script | 1–27 | Full mock seed script for academic logs, match stats, and attendance for demo players `OVK-U15-001`, `OVK-U15-002`, `OVK-U15-003`. |
| `migrations/0005_seed_player_details.sql` | Mock Seed Script | 1–55 | Updates mock age, position, and team strings for 53 players across U14, U15, U16. |
| `migrations/0006_seed_test_coach_user.sql` | Mock Seed Script & Hash | 2–3 | Line 3: Inserts `USR-COACH-2`, `janmen777@gmail.com` with static mock password hash `'sha256$mockedhash'`. |
| `migrations/0007_update_events_table.sql` | Schema Alteration | 1–10 | Modifies events table fields. |
| `migrations/0008_add_age_group_to_events.sql` | Schema Alteration | 1–5 | Adds `age_group` to `events`. |
| `migrations/0009_seed_jrobertse_coach_user.sql` | Mock Seed Script & Hash | 1–2 | Line 2: Inserts `USR-COACH-JROB`, `jrobertse1@gmail.com` with static mock password hash `'sha256$mockedhash'`. |
| `migrations/0010_create_notifications_and_team_events.sql` | Schema & Seed | 1–25 | Creates `notifications` table and seeds events/notifications. |
| `migrations/0011_dynamic_fitness_metrics.sql` | Schema & Seed | 1–81 | Creates `test_metric_definitions` and `player_test_logs` tables. Seeds 8 default metric definitions for OVK (Lines 45–53) and converts `fitness_baselines` into `player_test_logs` (Lines 56–78). |
| `migrations/0012_seed_janmen778_student_user.sql` | Mock Seed Script & Hash | 2, 10–62 | Line 2: Inserts `USR-STUDENT-JAN`, `janmen778@gmail.com` with static mock password hash `'sha256$mockedhash'`. Lines 10–62: Seeds player profile `OVK-STUDENT-JAN`, academic logs, baseline tests, progression, match stats, and attendance. |
| `migrations/0013_seed_student_events_and_images.sql` | Mock Seed Script | 1–24 | Seeds student calendar events and workout image paths. |
| `migrations/0014_seed_student_notifications.sql` | Mock Seed Script | 1–15 | Seeds student push notification items. |
| `migrations/0015_coach_squad_ownership.sql` | Schema | 3–27 | Creates `squads` and `squad_players` tables with foreign key constraints and indexes. |

---

## Task 2: Audit of `parent_contact` and `email` References

### A. References to `parent_contact`

1. **`C:\Development\academypro\migrations\0001_initialize_schema.sql`** (Line 41):
   ```sql
   41:     parent_contact TEXT,
   ```
   *Context*: Column declaration inside `CREATE TABLE IF NOT EXISTS players`.

2. **`C:\Development\academypro\migrations\0002_seed_data.sql`** (Lines 20–72):
   ```sql
   20: INSERT INTO players (id, school_id, age_group, first_name, last_name, grade, age, position, team, status, parent_name, parent_contact, parent_id, ugroups_active, notes) VALUES ...
   ```
   *Context*: Included as the 12th column target in 53 `INSERT INTO players` statements.

3. **`C:\Development\academypro\worker\migrations\0003_remove_parent_phone_columns.sql`** (Line 3):
   ```sql
   3: ALTER TABLE players DROP COLUMN parent_contact;
   ```
   *Context*: Explicit D1 schema alteration dropping `parent_contact` from the production database.

4. **`C:\Development\academypro\DATABASE_SCHEMA.md`** (Line 66):
   ```sql
   66:     parent_contact TEXT,
   ```
   *Context*: Outdated documentation in `DATABASE_SCHEMA.md`.

---

### B. References to `email`

1. **`C:\Development\academypro\migrations\0001_initialize_schema.sql`**:
   - Line 13: `email TEXT UNIQUE NOT NULL,` (in `users` table definition).

2. **`C:\Development\academypro\migrations\0002_seed_data.sql`**:
   - Line 11: `'coach.ross@overkruin.co.za'` (in `users` seed).
   - Line 14: `'student@overkruin.co.za'` (in `users` seed).
   - Line 17: `'parent@overkruin.co.za'` (in `users` seed).

3. **`C:\Development\academypro\migrations\0006_seed_test_coach_user.sql`**:
   - Line 3: `'janmen777@gmail.com'` (in `users` seed).

4. **`C:\Development\academypro\migrations\0009_seed_jrobertse_coach_user.sql`**:
   - Line 2: `'jrobertse1@gmail.com'` (in `users` seed).

5. **`C:\Development\academypro\migrations\0012_seed_janmen778_student_user.sql`**:
   - Line 2: `'janmen778@gmail.com'` (in `users` seed).
   - Line 3: `ON CONFLICT(email)` (upsert conflict resolution).

6. **`C:\Development\academypro\worker\migrations\0001_ensure_all_tables.sql`**:
   - Line 4: `email TEXT UNIQUE,` (in `users` table definition).
   - Line 18: `email TEXT,` (in `players` table definition).
   - Line 178: `parent_email TEXT,` (in `parent_child_links` table definition).
   - Line 180: `player_email TEXT,` (in `parent_child_links` table definition).

7. **`C:\Development\academypro\worker\migrations\0002_add_missing_columns.sql`**:
   - Line 3: `ALTER TABLE players ADD COLUMN email TEXT;`

8. **`C:\Development\academypro\worker\migrations\0005_assign_jrobertse_u15_squad.sql`**:
   - Line 4: `WHERE email = 'jrobertse1@gmail.com';`

9. **`C:\Development\academypro\DATABASE_SCHEMA.md`**:
   - Line 31: `email TEXT UNIQUE NOT NULL,` (in `users` table documentation).

---

## Task 3: Accuracy Assessment of `DATABASE_SCHEMA.md`

### 1. Completely Missing Table Documentation

The following 7 tables exist in D1 production (`worker/migrations/0001_ensure_all_tables.sql`) and worker API operations (`worker/src/index.ts`), but are **completely omitted** from `DATABASE_SCHEMA.md`:

#### A. `squads`
- **Source**: `worker/migrations/0001_ensure_all_tables.sql:34-42`, `migrations/0015_coach_squad_ownership.sql:3-13`
- **Actual Schema**:
  ```sql
  CREATE TABLE IF NOT EXISTS squads (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL DEFAULT 'OVK',
      coach_id TEXT NOT NULL,
      name TEXT NOT NULL,
      code TEXT NOT NULL,
      description TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
      FOREIGN KEY (coach_id) REFERENCES users(id) ON DELETE CASCADE
  );
  ```

#### B. `squad_players`
- **Source**: `worker/migrations/0001_ensure_all_tables.sql:44-49`, `migrations/0015_coach_squad_ownership.sql:15-22`
- **Actual Schema**:
  ```sql
  CREATE TABLE IF NOT EXISTS squad_players (
      squad_id TEXT NOT NULL,
      player_id TEXT NOT NULL,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (squad_id, player_id),
      FOREIGN KEY (squad_id) REFERENCES squads(id) ON DELETE CASCADE,
      FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE
  );
  ```

#### C. `test_metric_definitions`
- **Source**: `worker/migrations/0001_ensure_all_tables.sql:60-69`, `migrations/0011_dynamic_fitness_metrics.sql:9-20`
- **Actual Schema**:
  ```sql
  CREATE TABLE IF NOT EXISTS test_metric_definitions (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL DEFAULT 'OVK',
      sport_id TEXT DEFAULT 'rugby',
      name TEXT NOT NULL,
      category TEXT CHECK(category IN ('Speed', 'Strength', 'Endurance', 'Agility', 'Power', 'General')) DEFAULT 'Speed',
      unit TEXT DEFAULT 's',
      goal_direction TEXT CHECK(goal_direction IN ('HIGHER_IS_BETTER', 'LOWER_IS_BETTER')) DEFAULT 'HIGHER_IS_BETTER',
      target_benchmark REAL DEFAULT 0.0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
  );
  ```

#### D. `player_test_logs`
- **Source**: `worker/migrations/0001_ensure_all_tables.sql:71-79`, `migrations/0011_dynamic_fitness_metrics.sql:25-37`
- **Actual Schema**:
  ```sql
  CREATE TABLE IF NOT EXISTS player_test_logs (
      id TEXT PRIMARY KEY, -- (or INTEGER PRIMARY KEY AUTOINCREMENT in 0011)
      player_id TEXT NOT NULL,
      metric_id TEXT NOT NULL,
      score REAL NOT NULL,
      test_date TEXT NOT NULL,
      session_name TEXT DEFAULT 'Evaluation',
      notes TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE CASCADE,
      FOREIGN KEY (metric_id) REFERENCES test_metric_definitions(id) ON DELETE CASCADE,
      UNIQUE(player_id, metric_id, test_date)
  );
  ```

#### E. `action_plans`
- **Source**: `worker/migrations/0001_ensure_all_tables.sql:151-162`
- **Actual Schema**:
  ```sql
  CREATE TABLE IF NOT EXISTS action_plans (
      id TEXT PRIMARY KEY,
      school_id TEXT DEFAULT 'OVK',
      title TEXT NOT NULL,
      type TEXT DEFAULT 'Academic',
      category TEXT DEFAULT 'General',
      deadline TEXT,
      player_id TEXT,
      player_name TEXT,
      is_completed INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  ```

#### F. `notifications`
- **Source**: `worker/migrations/0001_ensure_all_tables.sql:164-173`, `migrations/0010_create_notifications_and_team_events.sql`
- **Actual Schema**:
  ```sql
  CREATE TABLE IF NOT EXISTS notifications (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      type TEXT DEFAULT 'info',
      is_read INTEGER DEFAULT 0,
      date_sent DATETIME DEFAULT CURRENT_TIMESTAMP,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  ```

#### G. `parent_child_links`
- **Source**: `worker/migrations/0001_ensure_all_tables.sql:175-183`
- **Actual Schema**:
  ```sql
  CREATE TABLE IF NOT EXISTS parent_child_links (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parent_phone TEXT,
      parent_email TEXT,
      player_id TEXT,
      player_email TEXT,
      status TEXT DEFAULT 'Pending',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  ```

---

### 2. Outdated & Inaccurate Existing Table Documentation

| Documented Table | Line Range in `DATABASE_SCHEMA.md` | Issue / Inaccuracy | Actual Production State |
|---|---|---|---|
| `players` | 53–73 | Line 66 lists `parent_contact TEXT`. Misses `email`, `phone`, `dob`, `preferred_position`. | `parent_contact` dropped in `worker/migrations/0003:3`. `email`, `phone`, `dob`, `preferred_position` added in `worker/migrations/0002:3-7`. |
| `users` | 28–38 | Line 33 role check omits `'Parent'`. Misses `phone TEXT`. | `worker/migrations/0002:2` added `phone TEXT`. `migrations/0001:15` includes `'Parent'` role. |
| `events` | 170–184 | Line 171 specifies `id INTEGER PRIMARY KEY AUTOINCREMENT`. Misses `age_group`, `team`, `workout_image_path`. | `worker/migrations/0001:135` specifies `id TEXT PRIMARY KEY`. Includes `age_group TEXT`, `team TEXT`, `workout_image_path TEXT`. |
| `attendance` | 156–165 | Misses `event_id TEXT` and `idx_attendance_player_event`. | `worker/migrations/0006:2` added `event_id TEXT`. `worker/migrations/0006:5` created unique index `idx_attendance_player_event`. |
| `schools` | 18–23 | Documented in file, but missing from worker D1 initialization. | Omitted in `worker/migrations/0001_ensure_all_tables.sql`. Present in `migrations/0001_initialize_schema.sql`. |

---

## Logic Chain & Synthesis

1. **Evolution of Schemas**: The project originated with root `migrations/0001` through `0015` for static local development. Later, `worker/migrations/0001` through `0006` were created as consolidated D1 production scripts.
2. **Schema Drift**: `DATABASE_SCHEMA.md` was created based on `migrations/0001_initialize_schema.sql` and was never updated when dynamic squads (`squads`, `squad_players`), dynamic fitness testing (`test_metric_definitions`, `player_test_logs`), action plans (`action_plans`), notifications (`notifications`), parent links (`parent_child_links`), and event attachments were added.
3. **Data Integrity Standard Compliance**: To align with production standards (Zero Fake Fallbacks & Pure Production Schema), `DATABASE_SCHEMA.md` must be updated to reflect the full 15-table D1 schema, `parent_contact` must be removed from documentation, and mock password hashes/mock seed scripts must be cataloged for safe cleanup.

---

## Verification Method

1. **File & Line Verification**:
   - Inspect `C:\Development\academypro\worker\migrations\0001_ensure_all_tables.sql` to verify the 15 production table definitions.
   - Inspect `C:\Development\academypro\worker\migrations\0003_remove_parent_phone_columns.sql:3` to verify `parent_contact` column removal.
   - Inspect `C:\Development\academypro\DATABASE_SCHEMA.md` lines 28–196 to verify missing table documentation.

2. **D1 Schema Verification Command**:
   - Run `wrangler d1 execute usport-db --remote --command "SELECT name FROM sqlite_master WHERE type='table';"` to list active remote D1 tables.
