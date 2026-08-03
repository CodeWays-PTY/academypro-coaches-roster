# Review & Handoff Report — Reviewer 2 (Milestone 2: Backend Worker API Refactoring)

## 1. Observation

- **File Inspected**: `worker/src/index.ts` (4008 lines)
- **Deployment Build Check**: `cmd.exe /c "npx wrangler deploy --dry-run"` in `worker/` succeeded in dry-run mode (`Total Upload: 212.26 KiB`).
- **TypeScript Compiler Check**: `cmd.exe /c "npx tsc src/index.ts --noEmit --module esnext --moduleResolution node --target es2022"` failed with **9 TypeScript errors**:
  - `src/index.ts(506,16): error TS2304: Cannot find name 'id'.`
  - `src/index.ts(507,22): error TS2304: Cannot find name 'email'.`
  - `src/index.ts(508,17): error TS2304: Cannot find name 'firstName'.`
  - `src/index.ts(508,30): error TS2304: Cannot find name 'first_name'.`
  - `src/index.ts(509,17): error TS2304: Cannot find name 'lastName'.`
  - `src/index.ts(509,29): error TS2304: Cannot find name 'last_name'.`
  - `src/index.ts(510,18): error TS2304: Cannot find name 'avatar_url'.`
  - `src/index.ts(510,32): error TS2552: Cannot find name 'avatarUrl'. Did you mean 'avatar'?`
  - `src/index.ts(536,45): error TS2304: Cannot find name 'phone'.`
- **Missing Payload Destructuring**: Lines 497-510 in `worker/src/index.ts`:
  ```ts
  app.post('/api/auth/profile', async (c) => {
    const db = getDB(c);
    let body: any;
    try {
      body = await c.req.json();
    } catch (_) {
      return c.json({ success: false, message: 'Invalid payload' }, 400);
    }
    const jwtPayload = c.get('jwtPayload') as any;
    let userId = id || jwtPayload?.sub || '';
    const userEmail = (email || jwtPayload?.email || '').trim().toLowerCase();
    const fName = firstName || first_name;
    const lName = lastName || last_name;
    const avatar = avatar_url || avatarUrl;
  ```
  `body` is parsed, but the properties `id`, `email`, `firstName`, `first_name`, `lastName`, `last_name`, `avatar_url`, `avatarUrl`, and `phone` are referenced without destructuring them from `body`.
- **Soft JWT Auth Fallback (Mock User Identity Injection)**: Lines 653-660 in `worker/src/index.ts`:
  ```ts
  // Soft fallback for web admin requests without Auth header
  c.set('jwtPayload', {
    sub: 'USR-COACH-1',
    schoolId: 1,
    school_id: 1,
    role: 'SuperAdmin'
  });
  await next();
  ```
  When an unauthenticated request hits secured endpoints (`/api/rosters/*`, `/api/dashboard/*`, `/api/match-stats/*`, `/api/squads/*`, `/api/student-portal/*`, `/api/parent/*`, `/api/player/*`, `/api/admin/*`, `/api/school/*`, `/api/notifications/*`), instead of returning `401 Unauthorized`, `enforceJwtAuth` injects a mock `SuperAdmin` identity (`sub: 'USR-COACH-1', schoolId: 1, role: 'SuperAdmin'`).
- **Hardcoded SMS Verification Bypass**: Lines 3984-3985 in `worker/src/index.ts`:
  ```ts
  // Validate stored OTP or fallback master test code
  if ((storedOtp && storedOtp.trim() === cleanCode) || cleanCode === '123456' || cleanCode === '888888') {
  ```
  Bypasses OTP verification for any phone number when inputting `'123456'` or `'888888'`.
- **Parent-Child Link SQL Joins Verification**: Lines 2358, 2365, 3465-3474, 3521, 3533, 3572-3574, 3634-3636:
  - All parent user lookups join `parent_child_links` on `parent_user_id` and `player_id` or `player_email`.
  - Zero SQL queries in `worker/src/index.ts` reference the dropped column `players.parent_id`.
- **Unlinked Student Portal Fallback**: Lines 2372-2376 in `worker/src/index.ts`:
  ```ts
  if (!player) {
    try {
      player = await db.prepare('SELECT * FROM players ORDER BY first_name ASC LIMIT 1').first();
    } catch (_) {}
  }
  ```
  When a user query fails to find a matching player or parent link, it falls back to selecting an arbitrary player (`ORDER BY first_name ASC LIMIT 1`) and returning their data.

---

## 2. Logic Chain

1. In `app.post('/api/auth/profile')`, the developer added code to handle updating user profile attributes from the request payload `body`. However, `const { id, email, firstName, first_name, lastName, last_name, avatar_url, avatarUrl, phone } = body || {};` was omitted. In TypeScript, referencing undeclared variables causes compilation errors (`TS2304`) and runtime `ReferenceError` exceptions whenever the endpoint is called.
2. In `enforceJwtAuth`, unauthenticated HTTP requests bypass JWT validation by automatically assuming a `SuperAdmin` identity with `sub: 'USR-COACH-1'` and `schoolId: 1`. This directly violates project security rules: *"NEVER inject mock user identities (`USR-COACH-001`, `USR-PARENT-101`) or bypass JWT auth for developer convenience. Unauthenticated requests MUST strictly return HTTP 401 Unauthorized."*
3. In `POST /api/sms/verify-code`, hardcoded master test codes `'123456'` and `'888888'` bypass OTP check in production code.
4. In `GET /api/student-portal`, falling back to returning the first player in the database when no match exists leaks sensitive athlete data across accounts instead of returning a clean empty state or 404 error.
5. In contrast, target requirement 2 (verifying that parent lookups cleanly join `parent_child_links` without referencing dropped column `parent_id`) was verified completely: all queries use `parent_child_links` correctly.

---

## 3. Caveats

- Wrangler deploy dry-run (`wrangler deploy --dry-run`) bundles JS via esbuild without strict `tsc` type checking, which is why wrangler did not abort on the missing variable declarations. Running `tsc --noEmit` directly exposed the reference errors.

---

## 4. Conclusion & Review Summary

**Verdict**: **REQUEST_CHANGES**

### Findings

#### [Critical] Finding 1 — Missing Payload Destructuring & Reference Errors (TS2304)
- **Where**: `worker/src/index.ts`, lines 506-536 (`app.post('/api/auth/profile')`)
- **Why**: Variables `id`, `email`, `firstName`, `first_name`, `lastName`, `last_name`, `avatar_url`, `avatarUrl`, and `phone` are referenced without being destructured from `body`. Causes 9 TypeScript compilation errors and crashes at runtime.
- **Suggestion**: Add destructuring at line 504:
  `const { id, email, firstName, first_name, lastName, last_name, avatar_url, avatarUrl, phone } = body || {};`

#### [Critical] Finding 2 — INTEGRITY VIOLATION: Soft Auth Fallback Injecting Mock SuperAdmin Identity
- **Where**: `worker/src/index.ts`, lines 653-660 (`enforceJwtAuth`) and line 1123
- **Why**: Unauthenticated requests to secured endpoints are granted `SuperAdmin` access under `USR-COACH-1`. Violates system rules prohibiting mock user identities and auth bypasses.
- **Suggestion**: Remove the soft fallback block (lines 653-660). Return `c.json({ success: false, message: 'Unauthorized session' }, 401)` when token is missing or invalid.

#### [Major] Finding 3 — INTEGRITY VIOLATION: Hardcoded SMS Verification Bypass
- **Where**: `worker/src/index.ts`, lines 3984-3985 (`app.post('/api/sms/verify-code')`)
- **Why**: Allows bypassing OTP verification using hardcoded test codes `'123456'` and `'888888'`.
- **Suggestion**: Remove hardcoded master code checks and validate strictly against KV-stored OTPs.

#### [Major] Finding 4 — Arbitrary Roster Fallback Leaking Student Data
- **Where**: `worker/src/index.ts`, lines 2372-2376 (`app.get('/api/student-portal')`)
- **Why**: `SELECT * FROM players ORDER BY first_name ASC LIMIT 1` exposes an unrelated athlete's full profile to unlinked or invalid queries.
- **Suggestion**: Remove the arbitrary fallback query. Return clean empty profile data or `404 Not Found`.

---

## Verified Claims

- Parent user lookups cleanly join `parent_child_links` without referencing dropped `parent_id` column → Verified via `grep_search` and AST line inspection of SQL queries → PASS.
- `npx wrangler deploy --dry-run` executes in `worker/` → Verified via `cmd.exe /c "npx wrangler deploy --dry-run"` → PASS (Dry-run succeeded).
- TypeScript compilation and type safety → Verified via `npx tsc src/index.ts --noEmit` → FAIL (9 TS errors found).

---

## 5. Verification Method

To independently verify all findings:
1. **Type Safety & Reference Errors**:
   Run in `worker/`:
   `cmd.exe /c "npx tsc src/index.ts --noEmit --module esnext --moduleResolution node --target es2022"`
   Observe the 9 TS2304/TS2552 errors on lines 506-536.
2. **Auth Bypass Check**:
   Inspect `worker/src/index.ts` lines 653-660 to see mock `SuperAdmin` fallback.
3. **OTP Bypass Check**:
   Inspect `worker/src/index.ts` lines 3984-3985 to see hardcoded `'123456'` and `'888888'` checks.
4. **Parent Link Join Check**:
   Grep `parent_id` in `worker/src/index.ts`. Confirm 0 matches in SQL statements, and inspect lines 2358, 3573, 3634 to confirm clean `parent_child_links` joins.
