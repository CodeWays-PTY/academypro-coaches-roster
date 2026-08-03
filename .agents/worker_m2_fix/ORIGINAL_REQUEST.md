## 2026-08-03T09:54:38Z
You are the Worker for Milestone 2 Fix: Worker API Quality & User Rules Alignment.
Your working directory is: c:\Development\academypro\.agents\worker_m2_fix

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Target Task:
Fix all identified defects in `worker/src/index.ts`:
1. **Fix Missing Payload Destructuring (`POST /api/auth/profile`)**:
   At line 504 (inside `POST /api/auth/profile`), add destructuring from `body`:
   `const { id, email, firstName, first_name, lastName, last_name, avatar_url, avatarUrl, phone } = body || {};`
2. **Remove Soft Auth Fallback (Enforce Strict Auth Guards)**:
   In `enforceJwtAuth` middleware (lines 653-660), remove the soft fallback block that sets mock `jwtPayload` (`USR-COACH-1`, `SuperAdmin`). Return strict `401 Unauthorized` response when JWT token is invalid or missing (`return c.json({ success: false, message: 'Unauthorized session' }, 401);`).
3. **Remove Hardcoded OTP Bypasses**:
   In `POST /api/sms/verify-code` (lines 3984-3985), remove hardcoded OTP bypass codes `'123456'` and `'888888'`, strictly validating against KV stored OTP (`storedOtp && storedOtp.trim() === cleanCode`).
4. **Remove Arbitrary Roster Fallback in Student Portal**:
   In `GET /api/student-portal` (lines 2372-2376), remove the fallback query `SELECT * FROM players ORDER BY first_name ASC LIMIT 1`. If no matching player or parent link exists, return a clean empty profile/response state rather than leaking arbitrary student records.
5. **Clean Up `u.email as parent_email` Alias**:
   In `GET /api/player/link-requests` (lines 3572 & 3583), alias `u.email as parent_user_email` and map `parentEmail: r.parent_user_email || r.email || ''` to ensure 0 occurrence of legacy table/column alias `parent_email`.

Verification & Deployment:
- Run `npx tsc src/index.ts --noEmit --module esnext --moduleResolution node --target es2022` in `worker/` to verify zero TypeScript errors.
- Run `npx wrangler deploy --dry-run` in `worker/` to verify clean bundle generation.
- Run `npx wrangler deploy` in `worker/` to deploy the fixed worker to Cloudflare Workers.
- Document all changes and build/deploy logs in `c:\Development\academypro\.agents\worker_m2_fix\handoff.md` and update your `progress.md`.
