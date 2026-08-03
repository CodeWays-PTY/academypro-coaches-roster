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

19: ## 2026-08-03T13:30:18Z
20: You are Worker 3 (`teamwork_preview_worker`).
21: Working directory: `c:\Development\academypro\.agents\worker_m2`
22: 
23: MANDATORY INTEGRITY WARNING:
24: DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
25: 
26: Objective: Execute Milestone 2 dead-code elimination in `academypro_app/`, prune unused files/widgets/methods/constants, and ensure `flutter analyze` completes cleanly with 0 errors and 0 warnings.
27: 
28: Pruning Checklist:
29: 1. Delete Dead Files (verify 0 references before deletion):
30:    - `c:\Development\academypro\academypro_app\lib\core\services\permission_service.dart`
31:    - `c:\Development\academypro\academypro_app\lib\features\dashboard\presentation\add_player_modal.dart`
32:    - `c:\Development\academypro\academypro_app\lib\features\dashboard\presentation\create_squad_modal.dart`
33: 2. Prune Unused Methods & Constants:
34:    - `lib/core/storage/local_storage.dart`: Remove unused sync queue methods (`queueMatchStats`, `getSyncQueue`, `dequeueItem`, `syncQueueBoxName`).
35:    - `lib/core/config/app_config.dart`: Remove unused constants (`academicHonorCutoff`, `ratingHighThreshold`, `ratingMidThreshold`, `ratingLowThreshold`, `sportIdentifier`).
36:    - `lib/features/dashboard/controllers/checkin_controller.dart`: Remove `resetSession()` and `changeSessionType()`.
37:    - `lib/features/dashboard/controllers/roster_controller.dart`: Remove `addPlayer()`.
38:    - `lib/features/notifications/controllers/notification_controller.dart`: Remove `sendTestNotification()`.
39:    - `lib/features/dashboard/controllers/dashboard_controller.dart`: Remove unused `playerActionTasksProvider`.
40: 3. Run `flutter analyze` in `c:\Development\academypro\academypro_app`:
41:    - Clean up any unused imports or dead variables resulting from file/method deletions.
42:    - Fix or clean any remaining lints/warnings so `flutter analyze` reports 0 errors and 0 warnings.
43: 4. Document all file deletions, code edits, and the full `flutter analyze` output in `c:\Development\academypro\.agents\worker_m2\handoff.md` and `progress.md`.
44: 5. Send a completion message back to the orchestrator.
