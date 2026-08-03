# Handoff Report — API Route Audit (`worker/src/index.ts`)

**Agent**: Explorer 2 (`teamwork_preview_explorer`)
**Working Directory**: `c:\Development\academypro\.agents\explorer_m1_2`
**Date**: 2026-08-03

---

## 1. Observation

Direct observations from code inspection and cross-referencing across `worker/src/index.ts`, `web_admin/`, `academypro_app/`, system services, and `API_SPECIFICATION.md`:

1. **Worker API Surface Area (`worker/src/index.ts`)**:
   - `worker/src/index.ts` (4,003 total lines) defines 70 HTTP routes using the Hono framework.
   - Exact line numbers for route definitions span lines 307 to 3950.

2. **`web_admin/` Integration**:
   - `web_admin/index.html` (lines 150 & 160) calls `GET /api/admin/all-players` and `GET /api/admin/sports-config`.
   - `web_admin/uploader.html` (lines 157 & 411) calls `GET /api/admin/all-players` and `POST /api/admin/bulk-upload`.

3. **External Gateway & System Service Integrations**:
   - SMS Gateway (`POST https://sms-service.codeways.co` with header `X-Internal-API-Key`) is invoked in `POST /api/sms/send-verification` at line 3912.
   - Cloudflare SendEmail / CodeWays Email Gateway is invoked in `POST /api/auth/send-otp` (line 374), `POST /api/auth/send-email-change-otp` (line 585), and `POST /api/players` (line 3435).
   - Cloudflare R2 storage binding (`env.R2`) is invoked in `POST /api/upload` (line 3179) and `GET /api/dashboard/events` (line 1448).

4. **Identified Dead / Legacy Routes**:
   - `GET /api/coach/profile` (line 502): Redirects to `/api/auth/profile`. Unreferenced.
   - `GET /api/athletes` (line 686): Legacy player listing route. Superseded by `/api/school/players` and `/api/admin/all-players`.
   - `POST /api/athletes` (line 709): Legacy player insertion route. Superseded by `POST /api/players`.
   - `PUT /api/athletes/:id` (line 739): Unused legacy CRUD route.
   - `DELETE /api/athletes/:id` (line 761): Unused legacy CRUD route.
   - `POST /api/test-results` (line 773): Legacy test score logger. Superseded by `POST /api/test-logs/batch`.
   - `GET /api/coaches` (line 794): Legacy coach list route.
   - `POST /api/coaches` (line 814): Legacy coach creation route.
   - `DELETE /api/coaches/:id` (line 848): Unused legacy coach deletion route.
   - `GET /api/test-results` (line 859): Legacy test result fetcher. Superseded by `/api/student-portal`.
   - `GET /api/test-metrics` (line 880): Duplicate GET definition without school filtering. Overridden by line 2777.
   - `GET /api/events` (line 1469): Alias route for `/api/dashboard/events`. Uncalled by clients.

---

## 2. Logic Chain

1. **Observation 1 & 2**: By scanning `worker/src/index.ts` from top to bottom, every Hono route registration (`app.get`, `app.post`, `app.put`, `app.delete`) was cataloged. Cross-referencing against `web_admin/index.html` and `web_admin/uploader.html` proved that `web_admin/` actively consumes 3 specific admin endpoints (`GET /api/admin/all-players`, `GET /api/admin/sports-config`, `POST /api/admin/bulk-upload`).
2. **Observation 3**: Inspecting external service bindings confirmed that SMS OTP (`/api/sms/send-verification`), Transactional Emails (`/api/auth/send-otp`, `/api/auth/send-email-change-otp`, `/api/players`), and R2 Media Storage (`/api/upload`, `/api/dashboard/events`) are active system integration routes.
3. **Observation 4**: Cross-referencing remaining endpoints against the mobile client codebase (`academypro_app`) confirmed that 55 mobile client routes and aliases are ACTIVE. 12 endpoints (listed in Observation 4) have zero call sites across `web_admin/`, `academypro_app/`, and external services.
4. **Deduction**: Therefore, out of 70 total routes in `worker/src/index.ts`, exactly 58 are ACTIVE and 12 are DEAD/LEGACY.

---

## 3. Caveats

- **Deprecated Aliases**: Some ACTIVE routes (e.g. `/api/coach/send-sms-otp`, `/api/coach/verify-sms-otp`, `/api/dashboard/test-logs/batch`) act as forwarding wrappers to canonical endpoints (`/api/sms/send-verification`, `/api/sms/verify-code`, `/api/test-logs/batch`). These are classified as ACTIVE because client code still invokes them.
- **Future Admin Features**: The dead `/api/coaches` and `/api/athletes` CRUD endpoints may have been generated for a legacy admin UI. However, current `web_admin/` uses `POST /api/admin/bulk-upload` and `GET /api/admin/all-players` exclusively.

---

## 4. Conclusion

- **Active API Footprint**: 58 endpoints are active and supported in production across `web_admin/`, `academypro_app`, and background microservices.
- **Dead Code Cleanup Opportunity**: 12 endpoints (17.1% of the worker route handler volume) in `worker/src/index.ts` are dead/legacy and can be safely deprecated or purged in future refactoring milestones without breaking `web_admin/` or mobile client operations.

---

## 5. Verification Method

To independently verify these findings:

1. **Inspect Web Admin Network Calls**:
   - Inspect `web_admin/index.html` at lines 150 (`/api/admin/all-players`) and 160 (`/api/admin/sports-config`).
   - Inspect `web_admin/uploader.html` at lines 157 (`/api/admin/all-players`) and 411 (`/api/admin/bulk-upload`).

2. **Verify Route Existence in `worker/src/index.ts`**:
   - Verify line numbers for all 70 routes listed in `c:\Development\academypro\.agents\explorer_m1_2\api_audit_web_admin.md`.

3. **Verify Absence of Calls for Dead Routes**:
   - Execute grep search across the codebase for dead routes (e.g. `grep_search` for `/api/athletes` or `/api/coaches`).
