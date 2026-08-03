# Route Cross-Reference Verification Report

**Target Workspace**: `c:\Development\academypro`  
**Worker Specification**: `worker/src/index.ts`  
**API Documentation**: `API_SPECIFICATION.md`  
**Verdict**: **FAIL**

---

## 1. Observation

### Active Backend Endpoints in `worker/src/index.ts`
Total registered HTTP endpoints: **58 active endpoints** (plus 16 middleware declarations).

| Line | HTTP Method | Active Worker Route Path |
| --- | --- | --- |
| 307 | `POST` | `/api/auth/send-otp` |
| 393 | `POST` | `/api/auth/verify-otp` |
| 457 | `GET` | `/api/auth/profile` |
| 503 | `POST` | `/api/auth/profile` |
| 557 | `POST` | `/api/auth/send-email-change-otp` |
| 606 | `POST` | `/api/auth/verify-new-email` |
| 802 | `GET` | `/api/squads` |
| 852 | `POST` | `/api/squads` |
| 923 | `GET` | `/api/rosters/:age_group` |
| 1051 | `POST` | `/api/players/:id/squads` |
| 1113 | `GET` | `/api/dashboard/summary` |
| 1203 | `GET` | `/api/dashboard/flags` |
| 1323 | `GET` | `/api/dashboard/events` |
| 1432 | `POST` | `/api/dashboard/events` |
| 1559 | `POST` | `/api/dashboard/events/:id` |
| 1643 | `DELETE` | `/api/dashboard/events/:id` |
| 1654 | `POST` | `/api/dashboard/events/:id/delete` |
| 1666 | `GET` | `/api/dashboard/actions` |
| 1740 | `POST` | `/api/dashboard/actions` |
| 1810 | `POST` | `/api/dashboard/actions/:id/toggle` |
| 1849 | `POST` | `/api/dashboard/actions/:id/delete` |
| 1861 | `GET` | `/api/dashboard/rising-stars` |
| 1931 | `POST` | `/api/dashboard/checkin` |
| 2052 | `GET` | `/api/dashboard/events/:id/attendance` |
| 2084 | `POST` | `/api/match-stats` |
| 2162 | `GET` | `/api/student-portal` |
| 2491 | `POST` | `/api/student-portal/profile` |
| 2582 | `POST` | `/api/player/evaluation-baseline` |
| 2624 | `GET` | `/api/test-metrics` |
| 2654 | `POST` | `/api/test-metrics` |
| 2703 | `DELETE` | `/api/test-metrics/:id` |
| 2715 | `POST` | `/api/dashboard/test-logs/batch` *(Alias)* |
| 2720 | `POST` | `/api/dashboard/test-logs` *(Alias)* |
| 2725 | `POST` | `/api/test-logs` |
| 2732 | `POST` | `/api/test-logs/batch` |
| 2819 | `GET` | `/api/admin/all-players` |
| 2848 | `GET` | `/api/school/players` |
| 2919 | `POST` | `/api/squads/:squadId/players/add` |
| 2971 | `POST` | `/api/squads/:squadId/players/remove` |
| 3014 | `POST` | `/api/upload` |
| 3042 | `POST` | `/api/admin/bulk-upload` |
| 3143 | `GET` | `/api/admin/sports-config` |
| 3161 | `POST` | `/api/players/:id/position` |
| 3190 | `POST` | `/api/players` |
| 3323 | `POST` | `/api/parent/link-request` |
| 3399 | `GET` | `/api/player/link-requests` |
| 3436 | `POST` | `/api/player/link-requests/:id/respond` |
| 3463 | `GET` | `/api/parent/children` |
| 3505 | `GET` | `/api/notifications` |
| 3583 | `POST` | `/api/notifications/:id/read` |
| 3598 | `POST` | `/api/notifications/read-all` |
| 3627 | `DELETE` | `/api/notifications/:id` |
| 3641 | `POST` | `/api/notifications/:id/delete` |
| 3656 | `POST` | `/api/notifications/send` |
| 3713 | `POST` | `/api/coach/send-sms-otp` *(Alias)* |
| 3720 | `POST` | `/api/sms/send-verification` |
| 3790 | `POST` | `/api/coach/verify-sms-otp` *(Alias)* |
| 3797 | `POST` | `/api/sms/verify-code` |

---

### Discrepancy Breakdown

#### 1. Active Backend Endpoints Missing / Misstated in Section 2 Overview Table (7 Discrepancies)
- `DELETE /api/dashboard/events/:id` (Worker line 1643): Table line 54 erroneously lists `DELETE /api/dashboard/events/:id/delete`.
- `DELETE /api/test-metrics/:id` (Worker line 2703): Table line 63 erroneously lists `DELETE /api/test-metrics` (omitting the mandatory `:id` path parameter).
- `POST /api/dashboard/test-logs/batch` (Worker line 2715): Table line 65 lists `/api/test-logs/batch` but omits the active alias `/api/dashboard/test-logs/batch`.
- `POST /api/dashboard/test-logs` (Worker line 2720): Table line 64 lists `/api/test-logs` but omits the active alias `/api/dashboard/test-logs`.
- `DELETE /api/notifications/:id` (Worker line 3627): Table line 80 erroneously lists `DELETE /api/notifications/:id/delete`.
- `POST /api/coach/send-sms-otp` (Worker line 3713): Table line 75 lists `/api/sms/send-verification` but omits the active alias `/api/coach/send-sms-otp`.
- `POST /api/coach/verify-sms-otp` (Worker line 3790): Table line 76 lists `/api/sms/verify-code` but omits the active alias `/api/coach/verify-sms-otp`.

#### 2. Pruned / Non-Existent Routes Remaining in `API_SPECIFICATION.md` (4 Discrepancies)
These routes are documented in `API_SPECIFICATION.md` but do **not** exist in `worker/src/index.ts` and empirically return `HTTP 404 Not Found`:
1. `DELETE /api/dashboard/events/:id/delete` (Table line 54, Section 3.6 line 419)  
   *Empirical Result*: `HTTP 404 Not Found`. Worker only handles `DELETE` on `/api/dashboard/events/:id` (line 1643) and `POST` on `/api/dashboard/events/:id/delete` (line 1654).
2. `DELETE /api/test-metrics` (Table line 63)  
   *Empirical Result*: `HTTP 404 Not Found`. Worker requires `:id` (`DELETE /api/test-metrics/:id`, line 2703).
3. `DELETE /api/notifications/:id/delete` (Table line 80, Section 7.4 line 773)  
   *Empirical Result*: `HTTP 404 Not Found`. Worker only handles `DELETE` on `/api/notifications/:id` (line 3627) and `POST` on `/api/notifications/:id/delete` (line 3641).
4. `POST /api/notifications/:id` (Section 7.4 line 773)  
   *Empirical Result*: `HTTP 404 Not Found`. Worker requires `/delete` suffix (`POST /api/notifications/:id/delete`, line 3641).

---

## 2. Logic Chain

1. **AST & Code Inspection**: Extracted every route registration line from `worker/src/index.ts` using static regex parsing and AST boundary matching. Identified 58 unique active HTTP verb + path combinations.
2. **Markdown Specification Analysis**: Parsed both Section 2 (Overview Directory Table) and Section 3 (Module Specifications) of `API_SPECIFICATION.md`.
3. **Empirical Hono Test Execution**: Constructed an automated empirical test harness (`test_hono.ts`) using Hono's native `app.fetch` dispatcher with a valid JWT token signed with `JWT_SECRET`.
4. **Validation Outcome**:
   - Confirmed all 58 active worker routes successfully route to handlers without returning `404 Not Found`.
   - Confirmed that candidate pruned routes (`DELETE /api/dashboard/events/:id/delete`, `DELETE /api/test-metrics`, `DELETE /api/notifications/:id/delete`, `POST /api/notifications/:id`) return `HTTP 404 Not Found`.
5. **Cross-Reference Failure Identification**: Cross-checking revealed that 7 active routes/aliases are missing or misstated in the Overview Table, and 4 pruned/non-existent routes remain documented in the specification file.

---

## 3. Caveats

- `app.use` declarations (e.g. `app.use('/api/rosters/*', enforceJwtAuth)`) were excluded from the active endpoint count as they are authentication middleware rather than request-handling endpoints.
- Alias routes (e.g. `/api/dashboard/test-logs` and `/api/test-logs`) execute identical handler logic in the worker, but are separate route registrations in Hono and must be documented in both Section 2 and Section 3.

---

## 4. Conclusion

**Verdict: FAIL**

The cross-reference check between `worker/src/index.ts` and `API_SPECIFICATION.md` failed due to:
1. **7 active backend routes/aliases missing or misstated** in the Overview Table (Section 2).
2. **4 pruned / non-existent routes documented** in `API_SPECIFICATION.md` that return `HTTP 404 Not Found` when invoked.

To pass, `API_SPECIFICATION.md` must be updated to align Overview Table entries with active worker endpoints and purge non-existent route combinations.

---

## 5. Verification Method

To independently verify these findings, run the empirical Hono route testing script in PowerShell/Command Prompt:

```bash
cd c:\Development\academypro\.agents\challenger_m3_2
cmd /c "npx tsx test_hono.ts"
node run_cross_check.js
```

### Invalidation Conditions
- If `API_SPECIFICATION.md` Section 2 is updated to include all 58 active routes (including aliases and correct path parameters) AND all 4 pruned/non-existent routes are removed from Section 2 and Section 3, re-running `node run_cross_check.js` will output `VERDICT: PASS`.
