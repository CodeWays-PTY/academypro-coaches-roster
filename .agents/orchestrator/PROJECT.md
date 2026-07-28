# Project: AcademyPro Audit Remediation

## Architecture
- **Frontend**: Flutter Mobile App (`C:\Development\academypro\academypro_app`)
- **Backend API**: Cloudflare Worker API (`C:\Development\academypro\worker`)
- **Database**: Cloudflare D1 Relational Database (`academypro-db`)

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | D1 Database & Schema Cleanup | Clean SQL migrations, remove `0004_seed_dashboard_mock_data.sql`, remove static password hashes, remove `parent_contact` and `email` columns from schema/migrations, update `DATABASE_SCHEMA.md` | None | DONE |
| 2 | Worker Backend API Remediation | Fix `Math.random()`, remove JWT fallback, remove dev OTP leakage, enforce strict JWT auth (401), remove over-defensive fallbacks (schoolId/squadCode -> 400), fix status codes (500/400/207), remove hardcoded API key fallback, remove `parent_contact`/`email` from Worker types/queries | M1 | DONE |
| 3 | Flutter Mobile App Remediation | Replace fallback strings with `"--"`, handle controller exceptions & error toasts, remove silent catch blocks, remove dummy phone numbers, make ratings/cutoffs dynamic, remove hardcoded grade metric (12%) & sport ('rugby'), remove `parent_contact`/`email` from models/UI, fix dev OTP key in `auth_state.dart`, bind Parent Portal ticket & checkout cards to D1 Worker API | M2 | DONE |
| 4 | Remote Execution, Deployment & Verification | Run `wrangler d1 execute academypro-db --remote`, run `wrangler deploy`, run `flutter analyze`, run forensic integrity audit | M1, M2, M3 | DONE |

## Interface Contracts
### Worker API ↔ Flutter App
- All endpoints must strictly require valid JWT bearer tokens or return HTTP 401.
- Payload validation failure must return HTTP 400 with clean JSON error response.
- `parent_contact` and `email` fields removed completely from JSON contracts.

## Code Layout
- Worker: `C:\Development\academypro\worker\src\index.ts`
- Migrations: `C:\Development\academypro\worker\migrations\`
- Schema Doc: `C:\Development\academypro\DATABASE_SCHEMA.md`
- Flutter App: `C:\Development\academypro\academypro_app\lib\`
