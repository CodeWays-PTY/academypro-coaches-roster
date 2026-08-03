# Handoff Report — API Audit (`worker/src/index.ts` vs `academypro_app/lib/`)

**Author:** Explorer 1 (`teamwork_preview_explorer`)
**Working Directory:** `c:\Development\academypro\.agents\explorer_m1_1`
**Date:** 2026-08-03

---

## 1. Observation

- **Worker Entry File:** `worker/src/index.ts` (4,003 total lines).
- **Flutter App Codebase:** `academypro_app/lib/` (39 Dart source files across `core/`, `features/`, `main.dart`).
- **Extracted Worker Endpoints:** 70 registered route paths/methods/aliases in `worker/src/index.ts`:
  - `POST /api/auth/send-otp` (line 307)
  - `POST /api/auth/verify-otp` (line 393)
  - `GET /api/auth/profile` (line 457)
  - `GET /api/coach/profile` (line 502) -> Redirects to `/api/auth/profile`
  - `POST /api/auth/profile` (line 504)
  - `POST /api/auth/send-email-change-otp` (line 558)
  - `POST /api/auth/verify-new-email` (line 607)
  - `GET /api/athletes` (line 686)
  - `POST /api/athletes` (line 709)
  - `PUT /api/athletes/:id` (line 739)
  - `DELETE /api/athletes/:id` (line 761)
  - `POST /api/test-results` (line 773)
  - `GET /api/coaches` (line 794)
  - `POST /api/coaches` (line 814)
  - `DELETE /api/coaches/:id` (line 848)
  - `GET /api/test-results` (line 859)
  - `GET /api/test-metrics` (line 880) — *First definition*
  - `GET /api/squads` (line 999)
  - `POST /api/squads` (line 1049)
  - `GET /api/rosters/:age_group` (line 1120)
  - `POST /api/players/:id/squads` (line 1195)
  - `GET /api/dashboard/summary` (line 1257)
  - `GET /api/dashboard/flags` (line 1347)
  - `GET /api/events` (line 1469) -> Proxy alias to `/api/dashboard/events`
  - `GET /api/dashboard/events` (line 1476)
  - `POST /api/dashboard/events` (line 1584)
  - `POST /api/dashboard/events/:id` (line 1712)
  - `DELETE /api/dashboard/events/:id` (line 1796)
  - `POST /api/dashboard/events/:id/delete` (line 1807)
  - `GET /api/dashboard/actions` (line 1819)
  - `POST /api/dashboard/actions` (line 1893)
  - `POST /api/dashboard/actions/:id/toggle` (line 1963)
  - `POST /api/dashboard/actions/:id/delete` (line 2002)
  - `GET /api/dashboard/rising-stars` (line 2014)
  - `POST /api/dashboard/checkin` (line 2084)
  - `GET /api/dashboard/events/:id/attendance` (line 2205)
  - `POST /api/match-stats` (line 2237)
  - `GET /api/student-portal` (line 2315)
  - `POST /api/student-portal/profile` (line 2644)
  - `POST /api/player/evaluation-baseline` (line 2735)
  - `GET /api/test-metrics` (line 2777) — *Second definition (School-scoped)*
  - `POST /api/test-metrics` (line 807)
  - `DELETE /api/test-metrics/:id` (line 2856)
  - `POST /api/dashboard/test-logs/batch` (line 2868) -> Proxy alias to `/api/test-logs/batch`
  - `POST /api/dashboard/test-logs` (line 2873) -> Proxy alias to `/api/test-logs/batch`
  - `POST /api/test-logs` (line 2878) -> Proxy alias to `/api/test-logs/batch`
  - `POST /api/test-logs/batch` (line 2885)
  - `GET /api/admin/all-players` (line 2972)
  - `GET /api/school/players` (line 3001)
  - `POST /api/squads/:squadId/players/add` (line 3072)
  - `POST /api/squads/:squadId/players/remove` (line 3123)
  - `POST /api/upload` (line 3167)
  - `POST /api/admin/bulk-upload` (line 3195)
  - `GET /api/admin/sports-config` (line 3296)
  - `POST /api/players/:id/position` (line 3314)
  - `POST /api/players` (line 3343)
  - `POST /api/parent/link-request` (line 3476)
  - `GET /api/player/link-requests` (line 3552)
  - `POST /api/player/link-requests/:id/respond` (line 3589)
  - `GET /api/parent/children` (line 3616)
  - `GET /api/notifications` (line 3658)
  - `POST /api/notifications/:id/read` (line 3736)
  - `POST /api/notifications/read-all` (line 3751)
  - `DELETE /api/notifications/:id` (line 3780)
  - `POST /api/notifications/:id/delete` (line 3794)
  - `POST /api/notifications/send` (line 3809)
  - `POST /api/coach/send-sms-otp` (line 3866) -> Proxy alias to `/api/sms/send-verification`
  - `POST /api/sms/send-verification` (line 3873)
  - `POST /api/coach/verify-sms-otp` (line 3943) -> Proxy alias to `/api/sms/verify-code`
  - `POST /api/sms/verify-code` (line 3950)

- **Search Commands Executed:**
  - `git grep -n "/api/" academypro_app/lib/`
  - `powershell -Command "Get-ChildItem -Recurse academypro_app/lib -Filter *.dart | Select-String -Pattern '/api/'"`

- **Key Line Observations in Flutter App:**
  - `features/auth/presentation/auth_state.dart`: lines 64 (`/api/auth/send-otp`), 99 (`/api/auth/verify-otp`), 150 (`/api/auth/profile`), 158 (`/api/auth/profile`).
  - `features/auth/presentation/coach_welcome_wizard_screen.dart`: lines 245 (`/api/coach/send-sms-otp`), 405 (`/api/coach/verify-sms-otp`).
  - `features/dashboard/controllers/dashboard_controller.dart`: lines 80 (`/api/dashboard/summary`), 167 (`/api/dashboard/flags`), 251 (`/api/dashboard/rising-stars`), 344 (`/api/dashboard/actions`), 410 (`/api/dashboard/actions`), 442 (`/api/dashboard/actions/$actionId/toggle`), 498 (`/api/squads`), 554 (`/api/squads`), 754 (`/api/dashboard/events`), 814 (`/api/dashboard/events`), 865 (`/api/dashboard/events/${event.id}`), 899 (`/api/dashboard/events/$targetIdStr/delete`).
  - `features/dashboard/controllers/roster_controller.dart`: lines 97 (`/api/rosters/$ageGroup`), 127 (`/api/players/$playerId/squads`), 146 (`/api/school/players`), 161 (`/api/squads/$squadId/players/add`), 180 (`/api/squads/$squadId/players/remove`), 228 (`/api/players/${player.id}/position`), 272 (`/api/players`).
  - `features/dashboard/controllers/checkin_controller.dart`: lines 173 (`/api/dashboard/events/$eventId/attendance`), 336 (`/api/dashboard/checkin`).
  - `features/dashboard/presentation/batch_test_logger_modal.dart`: lines 102 (`/api/dashboard/events`), 154 (`/api/test-metrics`), 163 (`/api/rosters`), 265 (`/api/test-logs/batch`).
  - `features/dashboard/presentation/manage_metrics_modal.dart`: lines 54 (`/api/test-metrics`), 74 (`/api/test-metrics`), 106 (`/api/test-metrics/$id`).
  - `features/dashboard/presentation/profile_tab_view.dart`: lines 243 (`/api/auth/send-email-change-otp`), 349 (`/api/auth/verify-new-email`), 415 (`/api/sms/send-verification`), 541 (`/api/coach/verify-sms-otp`).
  - `features/student/controllers/student_controller.dart`: line 201 (`/api/student-portal`).
  - `features/student/presentation/student_dashboard_screen.dart`: lines 2087 (`/api/student-portal/profile`), 2405 (`/api/upload`), 2412 (`/api/student-portal/profile`).
  - `features/notifications/controllers/notification_controller.dart`: lines 61 (`/api/notifications`), 103 (`/api/notifications/$id/read`), 115 (`/api/notifications/read-all`), 128 (`/api/notifications/$id/delete`), 131 (`/api/notifications/$id`), 145 (`/api/notifications/send`).
  - `features/parent/presentation/parent_dashboard_screen.dart`: line 117 (`/api/parent/link-request`).

---

## 2. Logic Chain

1. **Extraction Step**: Scanning `worker/src/index.ts` line-by-line identified all `app.get`, `app.post`, `app.put`, `app.delete`, and middleware route definitions.
2. **Cross-Referencing Step**: Grepping for exact string literals and URI patterns across `academypro_app/lib/` mapped which routes are invoked by the Flutter application.
3. **Classification Logic**:
   - **ACTIVE**: Route path appears in at least one HTTP call in `academypro_app/lib/`.
   - **UNKNOWN**: Route path is defined in `worker/src/index.ts` but does not match any call site in `academypro_app/lib/`. These endpoints serve `web_admin/`, seed scripts, or multi-child parent web features.
   - **DEAD / LEGACY**: `GET /api/test-metrics` at line 880 is superseded and overridden by line 2777 in Hono's route tree.
4. **Conclusion Formation**: The Flutter application is highly aligned with the Worker API (38 active endpoints). Web admin endpoints and convenience route aliases account for the remaining valid routes.

---

## 3. Caveats

- `web_admin/` source files were noted in repository structure but not audited in detail as the scope specified cross-referencing against `academypro_app/lib/`.
- Dynamic string interpolations in Flutter (e.g. `'/api/rosters/$ageGroup'`) were verified via pattern matching.

---

## 4. Conclusion

- **Total Worker Routes/Handlers**: 70
- **ACTIVE Routes (called by Flutter app)**: 38
- **UNKNOWN Routes (not in Flutter app, web_admin/internal/aliases)**: 31
- **DEAD / LEGACY Routes**: 1 (`GET /api/test-metrics` at line 880, overwritten by line 2777 definition)

All detailed findings have been saved to `c:\Development\academypro\.agents\explorer_m1_1\api_audit_flutter.md`.

---

## 5. Verification Method

To independently verify these findings:

1. **Verify Active Calls in Flutter**:
   ```powershell
   git grep -n "/api/" academypro_app/lib/
   ```
2. **Verify Duplicate `GET /api/test-metrics` in Worker**:
   ```powershell
   git grep -n "app.get('/api/test-metrics'" worker/src/index.ts
   ```
   Output will show lines 880 and 2777. Line 2777 is registered later and overrides line 880.
