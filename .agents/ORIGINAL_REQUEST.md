# Original User Request

## Initial Request — 2026-07-28T15:23:39Z

Fix all 60 cataloged audit findings across the AcademyPro platform (Flutter Mobile App `C:\Development\academypro\academypro_app`, Cloudflare Worker API `C:\Development\academypro\worker`, and Cloudflare D1 Database). This includes replacing local fallbacks/mock data with clean empty states/fail-fast responses, resolving silent catch blocks, removing hardcoded constants, aligning all vertical slices, performing complete end-to-end removal of `parent_contact` and `email` fields from D1 schema/Worker/Flutter, and executing D1 SQL migrations & Worker deployment.

Working directory: `C:\Development\academypro\academypro_app`
Integrity mode: development

## Requirements

### R1. Fix Local Fallbacks & Mock Data
- Replace `Math.random()` with Web Crypto API (`crypto.getRandomValues()`) in Worker API (`worker/src/index.ts`).
- Remove hardcoded JWT secret fallback (`usport-secret-key-928374`) and throw an explicit error if `c.env.JWT_SECRET` is missing.
- Remove `_dev_otp` token leakage from `/api/auth/send-otp` response payload.
- Enforce strict JWT auth on unauthenticated parent/student endpoints; return HTTP 401 Unauthorized instead of defaulting to `'USR-PARENT-101'` or `'USR-STUDENT-01'`.
- Remove over-defensive `schoolId || 'OVK'` and `squadCode || 'U15'` fallbacks; fail fast with HTTP 400 when required parameters are missing.
- Remove `0004_seed_dashboard_mock_data.sql` and static mock user password hashes from SQL migrations.
- In Flutter UI, replace default fallback strings (e.g. `'OVK-STUDENT-JAN'`) with clean empty states (`"--"`).

### R2. Fix Silent Failures & Error Handling
- Update Flutter controllers (`RosterController`, `DashboardController`, `NotificationController`) to return `false` or rethrow on network exceptions, display error toasts (`AppToast.showError`), and avoid emitting fake empty data (`AsyncValue.data([])`) on network errors.
- Ensure Worker endpoints (`/api/auth/profile`, `/api/admin/bulk-upload`) return correct HTTP error status codes (HTTP 500, 400, or 207) instead of HTTP 200 OK when database queries or records fail.
- Remove empty `catch (_)` blocks in Flutter UI and Worker access helpers; log and handle errors explicitly.

### R3. Fix Hardcoded Values & Credentials
- Remove hardcoded internal API key fallback `'agua_internal_secret_key_102938'` in Worker API.
- Remove hardcoded dummy phone numbers (`+27 82 555 0192`, `+27 71 444 8821`) from Flutter models (`dashboard_controller.dart`).
- Make rating thresholds (4.0, 3.0, 2.0) and academic cutoffs (65%, 60%, 50%) dynamic or configurable rather than hardcoded in server/UI logic.
- Remove hardcoded grade improvement metric (`12%`) and hardcoded sport identifier (`'rugby'`).

### R4. End-to-End Field Removal & Vertical Slice Alignment
- **End-to-End Removal**: Remove `parent_contact` and `email` fields end-to-end across Cloudflare D1 database tables (`players`), D1 SQL migration scripts, Worker API request/response types and queries (`worker/src/index.ts`), and Flutter UI models/widgets.
- Fix dev OTP key name mismatch in `auth_state.dart`.
- Bind Parent Portal "Upcoming Match Ticket" and "Campus Checkout Status" UI cards to real D1 database tables/Worker endpoints instead of static mock strings.
- Update `DATABASE_SCHEMA.md` to accurately document `squads`, `squad_players`, `test_metric_definitions`, and `player_test_logs` tables.

### R5. Automated D1 Execution & Worker Deployment
- Execute raw SQL migration scripts against the Cloudflare D1 database (`wrangler d1 execute academypro-db --remote`).
- Deploy updated Cloudflare Worker API backend (`wrangler deploy`).
- Run `flutter analyze` or build verification to ensure zero Flutter compilation errors.

## Acceptance Criteria

### Execution & Code Quality
- 100% of the 60 cataloged audit findings are fixed without breaking existing app functionality.
- `parent_contact` and `email` fields are completely excised end-to-end from D1 SQL schema, Worker API routes, and Flutter UI models.
- Zero non-cryptographic `Math.random()`, zero hardcoded fallback secrets, zero silent catch blocks, and zero auth bypass defaults remaining.
- D1 SQL migration scripts executed against remote D1 database and Worker API deployed successfully via Wrangler CLI.
- Flutter app passes static analysis cleanly without compilation or type errors.
