## 2026-07-28T15:39:14Z
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

You are Worker 2. Your working directory is `C:\Development\academypro\.agents\worker_2`.
Create your working directory and your `BRIEFING.md` first.

Read Explorer 2's report at `C:\Development\academypro\.agents\explorer_2\analysis.md` and `C:\Development\academypro\.agents\explorer_2\handoff.md`.

Your objective is to complete Milestone 2: Cloudflare Worker API Backend Remediation in `C:\Development\academypro\worker\src\index.ts` and `C:\Development\academypro\worker\wrangler.json`:
1. Replace all non-cryptographic `Math.random()` calls (lines 305, 489, 3334) with Web Crypto API (`crypto.getRandomValues()`).
2. Remove hardcoded JWT secret fallback `'usport-secret-key-928374'` (line 147). Throw explicit Error if `c.env.JWT_SECRET` is missing.
3. Remove `_dev_otp` token leakage from `/api/auth/send-otp` response payload (line 361).
4. Remove unauthenticated user identity bypass fallbacks `'USR-PARENT-101'` and `'USR-STUDENT-01'` (lines 2973, 3016, 3032). Ensure strict JWT auth guards are applied to parent/student/admin routes, returning HTTP 401 Unauthorized for unauthenticated requests.
5. Remove all over-defensive string fallbacks (`schoolId || 'OVK'`, `squadCode || 'U15'`) across lines 703, 741, 751, 798, 935, 1021, 1138, 1216, 1469, 1529, 1620, 1645, 1979, 1981, 2016, 2133, 2376, 2402, 2503, 2526, 2845, 2994. Return HTTP 400 Bad Request if required parameters are missing.
6. Fix HTTP error status codes: update `POST /api/auth/profile` to return HTTP 500 on D1 errors instead of HTTP 200 `{ success: true }`; update `POST /api/admin/bulk-upload` to return HTTP 400 / HTTP 207 on failures instead of default 200 OK.
7. Remove hardcoded internal API key fallback `'agua_internal_secret_key_102938'` in `src/index.ts:3344` and `wrangler.json:37`.
8. Complete end-to-end removal of `parent_contact` and `email` fields from `players` table types, SQL queries (`SELECT`, `INSERT`, `UPDATE`), and API payload handlers in `src/index.ts`.
9. Document all changes in `C:\Development\academypro\.agents\worker_2\changes.md`.
10. Write `C:\Development\academypro\.agents\worker_2\handoff.md` and send a message back to the orchestrator upon completion.
