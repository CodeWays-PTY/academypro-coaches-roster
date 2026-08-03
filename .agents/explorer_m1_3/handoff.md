# Handoff Report: Worker Structural Inspection (`worker/src/index.ts`)

## 1. Observation
- Line-by-line inspection of `worker/src/index.ts` (4,003 total lines) identified 70+ endpoint registrations, middleware declarations, and helper utility functions.
- Exact line ranges for legacy/unreferenced endpoints:
  - `GET /api/athletes`: lines 686–707
  - `POST /api/athletes`: lines 709–737
  - `PUT /api/athletes/:id`: lines 739–759
  - `DELETE /api/athletes/:id`: lines 761–771
  - `POST /api/test-results`: lines 773–792
  - `GET /api/coaches`: lines 794–812
  - `POST /api/coaches`: lines 814–846
  - `DELETE /api/coaches/:id`: lines 848–857
  - `GET /api/test-results`: lines 859–878
- Shadowed endpoint definition observed:
  - `GET /api/test-metrics` (lines 880–888): registers `SELECT * FROM test_metric_definitions ORDER BY name ASC` without checking `school_id`. Because Hono matches routes sequentially, this un-scoped route intercepts all calls to `/api/test-metrics` before the authenticated, school-scoped handler at lines 2777–2804 can execute.
- Duplicate endpoint definitions observed:
  - `POST /api/dashboard/events/:id/delete`: lines 1807–1816 (duplicate alias for `DELETE /api/dashboard/events/:id` at lines 1795–1805).
  - `POST /api/notifications/:id/delete`: lines 3794–3806 (duplicate alias for `DELETE /api/notifications/:id` at lines 3779–3792).
- Helper function analysis:
  - `generatePrimaryKey` (lines 161–166): currently invoked only inside legacy `POST /api/athletes` (line 720). However, project rules mandate its retention as the standard PK generator helper.
  - All other helpers (`getDB`, `getKV`, `generateSecureOTP`, `getSecret`, `calculateAutoScore`, `sendTransactionalEmail`, `enforceJwtAuth`, `ensureSquadsTables`, `getCoachSquadPlayerIds`, `purgeExpiredWorkoutImages`, `ensureParentLinksTable`) are actively used across production routes.

## 2. Logic Chain
1. Cross-referencing worker endpoint signatures against client calls in `academypro_app/lib` and `web_admin` showed zero references to `/api/athletes`, `/api/test-results`, or `/api/coaches`.
2. Modern features consume `/api/school/players`, `/api/players`, `/api/test-logs/batch`, and `/api/student-portal`, superseding legacy CRUD routes.
3. Hono route matching resolves top-to-bottom. Registration of `GET /api/test-metrics` at line 880 matches all GET requests to `/api/test-metrics`, preventing execution of line 2777 which enforces `school_id` filtering.
4. Pruning legacy routes (lines 686–878) and shadowed `GET /api/test-metrics` (lines 880–888), along with duplicate POST deletion routes (lines 1807–1816 and lines 3794–3806), will safely remove 226 redundant lines while restoring correct functionality to `/api/test-metrics`.

## 3. Caveats
- No caveats. All 71 endpoint registrations in `worker/src/index.ts` have been verified against `academypro_app/lib` and `web_admin`.

## 4. Conclusion
`worker/src/index.ts` contains 226 lines of dead, legacy, or shadowed code across 3 specific line blocks (lines 686–888, lines 1807–1816, lines 3794–3806). Pruning these blocks will eliminate unreferenced legacy handlers and fix the shadowing bug affecting `GET /api/test-metrics`.

## 5. Verification Method
- Perform line-level inspection of `worker/src/index.ts` to verify the specified line ranges.
- Run `npm test` or `npx wrangler dev` in `worker/` to confirm that all remaining routes build cleanly.
- Test `GET /api/test-metrics?school_id=1` with valid JWT token to verify that the scoped handler at line 2777 responds correctly once the line 880 shadow handler is removed.
