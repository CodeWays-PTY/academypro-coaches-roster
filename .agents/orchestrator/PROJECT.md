# Project: Database Schema Audit & Migration Cleanup

## Architecture
- Database: Cloudflare D1 (Relational Database)
- Backend: Cloudflare Workers (TypeScript, ES modules in `worker/src/index.ts`)
- Frontend: Flutter mobile application in `academypro_app/`
- Documentation: `DATABASE_SCHEMA.md`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | D1 Database SQL Migration | Create `migrations/0020_cleanup_obsolete_schema.sql`, execute against remote D1 | None | DONE |
| 2 | Backend Worker API Refactoring | Refactor `worker/src/index.ts` to use `player_test_logs`, deploy worker | M1 | IN_PROGRESS |
| 3 | Frontend & Documentation Sync | Update `DATABASE_SCHEMA.md` & `academypro_app` models, verify Flutter build | M1, M2 | PLANNED |

## Interface Contracts
### Worker API ↔ D1 Database
- Table `player_test_logs` serves all dynamic fitness evaluation log queries.
- `fitness_baselines` and `fitness_progression` are removed.
- `players` table no longer has `ugroups_active`, `parent_name`, `parent_id`.
- `parent_child_links` table no longer has `parent_phone`, `parent_email`.

## Code Layout
- `migrations/` - SQL migration scripts for Cloudflare D1
- `worker/src/index.ts` - Cloudflare Worker API entrypoint
- `DATABASE_SCHEMA.md` - Complete schema documentation
- `academypro_app/` - Flutter mobile application codebase
