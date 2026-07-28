# Orchestration Plan — AcademyPro 60 Audit Findings Remediation

## Phase 1: Milestone 1 — D1 Database & Schema Cleanup
1. Dispatch Explorer to map all SQL files in `worker/migrations/` and `DATABASE_SCHEMA.md` containing `parent_contact`, `email`, seed mock data, static password hashes, or incomplete table definitions.
2. Dispatch Worker to update SQL migrations, remove `0004_seed_dashboard_mock_data.sql`, remove static password hashes, remove `parent_contact` and `email` columns, and update `DATABASE_SCHEMA.md`.
3. Dispatch Reviewer & Auditor to verify SQL schema purity.

## Phase 2: Milestone 2 — Cloudflare Worker Backend API Remediation
1. Dispatch Explorer to locate all occurrences in `worker/src/index.ts` of `Math.random()`, `usport-secret-key-928374`, `_dev_otp` in responses, default user ID fallbacks (`USR-PARENT-101`, `USR-STUDENT-01`), fallback strings (`schoolId || 'OVK'`, `squadCode || 'U15'`), HTTP 200 on errors, internal API key `'agua_internal_secret_key_102938'`, and `parent_contact`/`email`.
2. Dispatch Worker to remediate all Worker API issues, enforcing Web Crypto API, strict JWT auth, fail-fast HTTP status codes, and clean JSON payloads.
3. Dispatch Reviewer & Challenger to verify Worker API backend code.

## Phase 3: Milestone 3 — Flutter Mobile App Remediation
1. Dispatch Explorer to locate all occurrences in `academypro_app/lib/` of default string fallbacks (`'OVK-STUDENT-JAN'`), silent catch blocks, controller network error swallowing without `AppToast.showError`, hardcoded dummy phone numbers, hardcoded rating/academic cutoffs, hardcoded metrics (`12%`, `'rugby'`), `parent_contact` / `email` in models/views, dev OTP key mismatch in `auth_state.dart`, and mock strings in Parent Portal cards.
2. Dispatch Worker to update Flutter models, controllers, UI views, and state handlers.
3. Dispatch Reviewer & Challenger to verify Flutter app code quality and type safety.

## Phase 4: Milestone 4 — Deployment, Automated Verification & Forensic Audit
1. Dispatch Worker to run `wrangler d1 execute academypro-db --remote` to apply SQL migrations.
2. Dispatch Worker to run `wrangler deploy` to deploy Worker API.
3. Dispatch Worker to run `flutter analyze` in `academypro_app` directory to verify zero compilation or static analysis errors.
4. Dispatch Forensic Auditor (`teamwork_preview_auditor`) to audit the entire repository across all 60 audit findings for 100% integrity compliance.
5. Send completion report to Sentinel.
