# Execution Plan

## Overview
Perform database schema audit and migration cleanup across Cloudflare D1 SQL database, Worker API (`worker/src/index.ts`), and Flutter application (`academypro_app`).

## Milestones

### Milestone 1: D1 Database SQL Migration & Cleanup
- **Goal**: Create `migrations/0020_cleanup_obsolete_schema.sql` to drop obsolete tables (`fitness_baselines`, `fitness_progression`) and drop unused columns (`players.ugroups_active`, `players.parent_name`, `players.parent_id`, `parent_child_links.parent_phone`, `parent_child_links.parent_email`).
- **Action**: Execute raw D1 SQL script against remote Cloudflare D1 database (`npx wrangler d1 execute academypro-db --remote --file=...`).
- **Verification**: Query remote database schema to verify table and column removal.

### Milestone 2: Backend Worker API Refactoring
- **Goal**: Update `worker/src/index.ts` to remove references to dropped tables and columns, redirecting all fitness evaluation queries to `player_test_logs`.
- **Action**: Refactor Worker API, verify type safety / compilation (`npm run build` or `npx tsc`), and deploy worker (`npx wrangler deploy`).
- **Verification**: Worker builds cleanly without TypeScript errors, deploys successfully, and endpoints return dynamic evaluation data from `player_test_logs`.

### Milestone 3: Frontend & Documentation Synchronization
- **Goal**: Update `DATABASE_SCHEMA.md` to reflect 16 active production tables. Update Flutter frontend models in `academypro_app` to remove obsolete field references.
- **Action**: Modify `DATABASE_SCHEMA.md` and `academypro_app` models. Run `flutter analyze` or `flutter build` to ensure clean build with zero missing property errors.
- **Verification**: Flutter app builds without errors; documentation is completely aligned.

## Orchestration Strategy
For each milestone:
1. Dispatch Explorer subagent to investigate codebase and produce execution plan.
2. Dispatch Worker subagent to perform modifications, run builds/migrations, and report results.
3. Dispatch 2 Reviewer subagents to review changes independently.
4. Dispatch 2 Challenger subagents to verify functionality and stress-test.
5. Dispatch Auditor subagent to perform forensic integrity check.
6. Gate check: If all pass, proceed to next milestone. If audit or verification fails, loop back with Explorer.
