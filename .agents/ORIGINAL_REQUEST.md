# Original User Request

## Initial Request — 2026-08-03T09:39:03Z

Perform a complete database schema audit and migration cleanup to remove redundant, obsolete tables and columns across Cloudflare D1 SQL database, Worker API, and Flutter frontend models.

Working directory: c:\Development\academypro

## Preliminary Audit Findings (Discovered Entities & Target Cleanup)

1. **Obsolete Tables to Drop / Deprecate**:
   - `fitness_baselines`: Superseded by dynamic `test_metric_definitions` & `player_test_logs`.
   - `fitness_progression`: Superseded by time-series `player_test_logs`.

2. **Unused / Obsolete Columns to Drop**:
   - `players.ugroups_active`: Unused legacy flag (never read or written in Worker or Flutter app).
   - `players.parent_name` / `players.parent_id`: Superseded by `users` accounts & `parent_child_links`.
   - `parent_child_links.parent_phone` / `parent_child_links.parent_email`: Replaced by `parent_user_id` and `player_email`.

3. **Schema Alignment & Migration**:
   - Update `DATABASE_SCHEMA.md` to reflect the clean 16 active production tables.
   - Generate raw D1 SQL migration script to drop obsolete tables/columns and sync remote Cloudflare D1.

## Requirements

### R1. D1 Database SQL Migration & Cleanup
Create a SQL migration script (`migrations/0020_cleanup_obsolete_schema.sql`) to drop obsolete tables (`fitness_baselines`, `fitness_progression`) and drop/prune unused columns from `players` and `parent_child_links`. Execute against Cloudflare D1 remote database.

### R2. Backend Worker API Refactoring
Refactor `worker/src/index.ts` to remove legacy queries selecting from `fitness_baselines` and `fitness_progression`, redirecting all fitness evaluation data access to `player_test_logs`. Deploy the updated worker.

### R3. Frontend & Documentation Synchronization
Update `DATABASE_SCHEMA.md` and any affected models in `academypro_app` to remove references to dropped tables and columns.

## Acceptance Criteria

### D1 Migration Verification
- [ ] Raw SQL script executes cleanly on Cloudflare D1 without foreign key or dependency errors.
- [ ] Obsolete tables `fitness_baselines` and `fitness_progression` are removed from D1 schema.
- [ ] Unused column `ugroups_active` is purged from `players` table.

### API & App Integrity
- [ ] Worker API builds and deploys to Cloudflare Workers (`wrangler deploy`) with zero typescript/compilation errors.
- [ ] Fitness testing endpoints return dynamic evaluation data from `player_test_logs`.
- [ ] Flutter app builds cleanly (`flutter build` or `flutter analyze`) without missing property errors.
