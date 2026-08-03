# Milestone 3 Explorer Technical Analysis & Synchronization Plan

**Explorer**: Explorer M3  
**Target Project**: `academypro` (Cloudflare D1 & Flutter Web/Mobile Application)  
**Date**: 2026-08-03  

---

## 1. Executive Summary

This investigation provides a comprehensive audit of schema drift and legacy references following Milestone 1 database migration (`migrations/0020_cleanup_obsolete_schema.sql`). It details:
1. Exact updates required for `c:\Development\academypro\DATABASE_SCHEMA.md` to purge 2 dropped tables (`fitness_baselines`, `fitness_progression`) and 5 dropped columns (`players.ugroups_active`, `players.parent_name`, `players.parent_id`, `parent_child_links.parent_phone`, `parent_child_links.parent_email`), reducing total documented D1 tables from 18 to **16 active production tables**.
2. A complete audit of the Flutter codebase (`academypro_app/lib`), identifying remaining references to `ugroupsActive` and `parentPhone` across controllers and UI widgets.
3. Verification of remote Cloudflare D1 database state and Flutter toolchain health.

---

## 2. Task 1 Analysis: `DATABASE_SCHEMA.md` Audit & Update Formulation

### A. Current State Audit of `DATABASE_SCHEMA.md`
- **Total Documented Tables**: Currently documents 18 tables in Section 1 (SQL definitions) and Section 2 (Summary Table).
- **Dropped Tables Present**:
  - `fitness_baselines` (Section 1: lines 151–164, Section 2: row 10)
  - `fitness_progression` (Section 1: lines 169–180, Section 2: row 11)
- **Dropped Columns Present**:
  - `players` table definition (Section 1: lines 53–75):
    - Line 57: `parent_id TEXT,`
    - Line 61: `parent_name TEXT,`
    - Line 69: `ugroups_active INTEGER DEFAULT 1,`
  - `parent_child_links` table definition (Section 1: lines 273–282):
    - Line 275: `parent_phone TEXT,`
    - Line 276: `parent_email TEXT,`

### B. Empirical Verification against Remote Cloudflare D1 (`academypro-db`)
Remote execution of `PRAGMA table_info` confirmed:
- `players` table active columns (16 total): `id`, `school_id`, `user_id`, `first_name`, `last_name`, `phone`, `dob`, `preferred_position`, `age_group`, `position`, `team`, `grade`, `age`, `notes`, `status`, `created_at`. (`parent_id`, `parent_name`, `ugroups_active` are verified ABSENT).
- `parent_child_links` table active columns (5 total): `id`, `player_id`, `player_email`, `status`, `created_at`. (`parent_phone` and `parent_email` are verified ABSENT).
- `fitness_baselines` and `fitness_progression`: Verified ABSENT (`no such table`).

### C. Exact Update Plan for `DATABASE_SCHEMA.md`

#### 1. D1 SQL Schema Definitions (Section 1)
- **Remove Table 10 (`fitness_baselines`)**: Remove lines 149–164.
- **Remove Table 11 (`fitness_progression`)**: Remove lines 166–181.
- **Update Table 4 (`players`)**: Remove `parent_id`, `parent_name`, and `ugroups_active` column lines.
  *Updated `players` table definition*:
  ```sql
  CREATE TABLE IF NOT EXISTS players (
      id TEXT PRIMARY KEY,
      school_id TEXT DEFAULT 'OVK',
      user_id TEXT,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      phone TEXT,
      dob TEXT,
      preferred_position TEXT,
      age_group TEXT DEFAULT 'U15',
      position TEXT DEFAULT 'Athlete',
      team TEXT,
      grade INTEGER,
      age INTEGER,
      notes TEXT,
      status TEXT DEFAULT 'Active',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
  );
  ```
- **Update Table 17 (`parent_child_links`)**: Remove `parent_phone` and `parent_email` column lines.
  *Updated `parent_child_links` table definition*:
  ```sql
  CREATE TABLE IF NOT EXISTS parent_child_links (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      player_id TEXT,
      player_email TEXT,
      status TEXT DEFAULT 'Pending',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
  );
  ```
- **Renumber SQL Section Headers**: Renumber section headings sequentially from 1 to 16.

#### 2. Active Cloudflare D1 Database Tables Summary (Section 2)
- Remove Row 10 (`fitness_baselines`) and Row 11 (`fitness_progression`).
- Renumber rows 1 through 16.
- Update description for `players` (Row 4): `"Player roster (`parent_id`, `parent_name`, `ugroups_active` dropped)"`.
- Update description and columns for `parent_child_links` (Row 15).

#### 3. Active 16 Production Tables Checklist
1. `schools`
2. `users`
3. `sports`
4. `players`
5. `squads`
6. `squad_players`
7. `test_metric_definitions`
8. `player_test_logs`
9. `academic_logs`
10. `match_stats`
11. `attendance`
12. `events`
13. `action_plans`
14. `notifications`
15. `parent_child_links`
16. `medical_records`

---

## 3. Task 2 Analysis: Flutter Codebase (`academypro_app/`) Audit

### A. Summary of Grep Search Results in `academypro_app/lib`

| Identifier | Occurrences in `lib/` | Files Affected | Status / Action Needed |
|---|---|---|---|
| `fitness_baselines` | 0 | None | Already Clean |
| `fitness_progression` | 0 | None | Already Clean |
| `parent_id` | 0 | None | Already Clean |
| `parent_email` | 0 | None | Already Clean |
| `ugroups_active` / `ugroupsActive` | 6 | `roster_controller.dart`, `checkin_controller.dart` | **Requires Cleanup** |
| `parent_name` / `parentName` | 5 | `dashboard_controller.dart`, `dashboard_screen.dart` | **Requires Cleanup / Review** |
| `parent_phone` / `parentPhone` | 13 | `roster_controller.dart`, `dashboard_controller.dart`, `add_existing_player_modal.dart`, `dashboard_screen.dart` | **Requires Cleanup** |

### B. Detailed Code Locations & Modification Plans

#### 1. `ugroups_active` / `ugroupsActive` References
- **`lib/features/dashboard/controllers/roster_controller.dart`**:
  - Line 30: `final int ugroupsActive;` -> Remove property from `RosterPlayer` model.
  - Line 43: `required this.ugroupsActive,` -> Remove constructor parameter.
  - Line 61: `ugroupsActive: json['ugroupsActive'] ?? 0,` -> Remove from `fromJson`.
  - Line 225: `ugroupsActive: p.ugroupsActive,` -> Remove from copy/mapping.
  - Line 274: `ugroupsActive: 1,` -> Remove from `addPlayer` mock instantiation.
- **`lib/features/dashboard/controllers/checkin_controller.dart`**:
  - Line 246: `ugroupsActive: 0,` -> Remove parameter from fallback `RosterPlayer` instantiation.

#### 2. `parent_phone` / `parentPhone` References
- **`lib/features/dashboard/controllers/roster_controller.dart`**:
  - Line 32: `final String parentPhone;` -> Remove property from `RosterPlayer` model.
  - Line 45, 47: `String? parentPhone,` constructor parameter and initializer -> Remove.
  - Line 51, 63: `final rawPhone = json['parentPhone'];` and `parentPhone: ...` -> Remove from `fromJson`.
  - Line 263, 275, 292: `String? parentPhone` parameter in `addPlayer()` and payload `'parentPhone': parentPhone` -> Remove.
- **`lib/features/dashboard/controllers/dashboard_controller.dart`**:
  - Lines 282, 298, 316, 332, 377: `parentPhone` field on `CoachActionItem` model.
- **`lib/features/dashboard/presentation/add_existing_player_modal.dart`**:
  - Line 73: `final phone = p.parentPhone.toLowerCase();` -> Remove phone filter clause.
- **`lib/features/dashboard/presentation/dashboard_screen.dart`**:
  - Lines 727–782: Section header `"PARENT / GUARDIAN CONTACT"` and buttons copying `item.parentPhone`. Since `players` table dropped `parent_name` / `parent_id` and contact is managed via `users` table or `parent_child_links`, update or conditionally hide when phone is empty.

---

## 4. Task 3 Analysis: Flutter Environment & Verification Check

1. **Remote Database Verification**: Verified remote Cloudflare D1 database (`academypro-db`) status via Wrangler CLI (`npx wrangler d1 execute academypro-db --remote --command="..."`). Verified remote `players` table (16 columns) and `parent_child_links` table (5 columns).
2. **Flutter Toolchain Status**: Executed `flutter analyze` in `academypro_app/`.
   - Command completed in 241.3s with 214 info/warning lint issues (e.g. deprecated `withOpacity`, `use_super_parameters`, `unnecessary_underscores`).
   - Zero blocking syntax errors in core codebase models. `flutter pub get` resolved all dependencies cleanly.

