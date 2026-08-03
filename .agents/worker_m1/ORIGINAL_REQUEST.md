## 2026-08-03T09:42:24Z

You are the Worker for Milestone 1: D1 Database SQL Migration & Cleanup.
Your working directory is: c:\Development\academypro\.agents\worker_m1

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Target Task:
1. Create `migrations/0020_cleanup_obsolete_schema.sql` with the following exact contents:
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

2. Execute the migration against the remote Cloudflare D1 database:
Run: `npx wrangler d1 execute academypro-db --remote --file=migrations/0020_cleanup_obsolete_schema.sql`

3. Verify the migration results on remote Cloudflare D1 database:
Run:
`npx wrangler d1 execute academypro-db --remote --command="SELECT name FROM sqlite_master WHERE type='table';"`
`npx wrangler d1 execute academypro-db --remote --command="PRAGMA table_info(players);"`
`npx wrangler d1 execute academypro-db --remote --command="PRAGMA table_info(parent_child_links);"`

4. Document all command execution outputs and verification results in your handoff report at `c:\Development\academypro\.agents\worker_m1\handoff.md` and update your `progress.md`.

## 2026-08-03T13:13:58Z

You are Worker 1 (`teamwork_preview_worker`).
Working directory: `c:\Development\academypro\.agents\worker_m1`

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Objective: Prune dead and legacy API endpoints from `worker/src/index.ts`, verify TypeScript compilation, and deploy the updated Worker via `wrangler deploy`.

Context & Detailed Pruning Plan:
The Explorers have identified 12 dead/legacy API endpoints (~226 lines of redundant code) in `worker/src/index.ts` to safely prune:
1. Lines 502–506: `GET /api/coach/profile` (Redundant redirect to `/api/auth/profile`)
2. Lines 686–770: Legacy `/api/athletes` CRUD routes (`GET/POST/PUT/DELETE /api/athletes`, superseded by `/api/school/players` & `/api/players`)
3. Lines 773–791: `POST /api/test-results` (Legacy test score logger, superseded by `/api/test-logs/batch`)
4. Lines 794–856: Legacy `/api/coaches` CRUD routes (`GET/POST/DELETE /api/coaches`, superseded by `/api/dashboard/coaches`)
5. Lines 859–878: `GET /api/test-results` (Legacy test result fetcher)
6. Lines 880–888: `GET /api/test-metrics` (Unscoped duplicate definition shadowing the school-scoped handler at line 2777)
7. Lines 1469–1477: `GET /api/events` (Uncalled alias for `/api/dashboard/events`)
8. Lines 1807–1816: `POST /api/dashboard/events/:id/delete` (Duplicate POST handler for HTTP DELETE at line 1789)
9. Lines 3794–3806: `POST /api/notifications/:id/delete` (Duplicate POST handler for HTTP DELETE at line 3777)

Task Instructions:
1. Carefully edit `worker/src/index.ts` to prune these dead/legacy handlers and any unused helper functions or imports associated strictly with them. Ensure no active routes (such as `/api/school/players`, `/api/admin/all-players`, `/api/admin/bulk-upload`, `/api/test-logs/batch`, `/api/auth/*`, `/api/sms/*`) are touched or broken.
2. In the `worker` directory (`c:\Development\academypro\worker`), run TypeScript type checking / build commands to verify there are 0 compilation errors.
3. Deploy the updated Cloudflare Worker to remote using `wrangler deploy` (or `npx wrangler deploy` inside `worker/`). Document the deployment output, Worker URL, and deployment ID.
4. Record your work and build/deploy output in `c:\Development\academypro\.agents\worker_m1\handoff.md` and update `progress.md`.
5. Send a completion message back to the orchestrator.
