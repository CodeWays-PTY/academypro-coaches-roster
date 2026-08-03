## 2026-08-03T11:48:20Z
You are the Worker for Milestone 2: Backend Worker API Refactoring.
Your working directory is: c:\Development\academypro\.agents\worker_m2

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Target Task:
1. Refactor `worker/src/index.ts` to remove all references to dropped tables (`fitness_baselines`, `fitness_progression`) and dropped columns (`players.ugroups_active`, `players.parent_id`).
   - `GET /api/players` (line 1186): remove `ugroupsActive: p.ugroups_active`.
   - `GET /api/student-portal` (line 2355): refactor parent player lookup from `SELECT * FROM players WHERE parent_id = ?` to join `parent_child_links`.
   - `GET /api/student-portal` (lines 2470-2481): replace queries selecting from `fitness_baselines` and `fitness_progression` with queries fetching dynamic fitness metric logs from `player_test_logs` and `test_metric_definitions`.
   - `GET /api/student-portal` profile mapper (line 2583): remove `ugroupsActive: player.ugroups_active`.
   - `POST /api/admin/bulk-upload` (lines 3229-3240): replace `INSERT INTO fitness_baselines` with `INSERT INTO player_test_logs` using dynamic metrics.
2. Build and verify TypeScript compilation/bundling by running `npx wrangler deploy --dry-run` in `worker/`.
3. Deploy the updated worker to Cloudflare Workers by running `npx wrangler deploy` in `worker/`.
4. Document code changes, build/deploy logs, and endpoint test results in your handoff report at `c:\Development\academypro\.agents\worker_m2\handoff.md` and update your `progress.md`.
