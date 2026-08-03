# API Audit Report: Worker vs Flutter Application (`academypro_app`)

**Date:** 2026-08-03
**Auditor:** Explorer 1 (`teamwork_preview_explorer`)
**Target Worker File:** `worker/src/index.ts` (4003 lines)
**Target Flutter Codebase:** `academypro_app/lib/` (39 Dart files)

---

## 1. Executive Summary

A full audit of `worker/src/index.ts` identified **70 route definitions / aliases / handlers** registered on the Hono application.

Cross-referencing these routes against `academypro_app/lib/` yields the following classification breakdown:
- **ACTIVE (38 routes)**: Called directly by Flutter views, modals, and controllers in `academypro_app/lib/`.
- **UNKNOWN (31 routes)**: Defined in Worker API but not called by `academypro_app`. These are dedicated web admin endpoints (`/web_admin`), internal backend aliases, multi-child parent endpoints, or database migration handlers.
- **DEAD / LEGACY (1 route)**: `GET /api/test-metrics` (line 880) — duplicate definition in `worker/src/index.ts` that is dead code because it is unconditionally superseded and overwritten by the school-scoped `GET /api/test-metrics` definition at line 2777.

---

## 2. Detailed Route Audit & Classification

### A. Authentication & User Profile Routes

| Method | Endpoint Path | Worker Line | Flutter Status | Flutter File / Call Site | Description |
|---|---|---|---|---|---|
| POST | `/api/auth/send-otp` | 307 | **ACTIVE** | `auth_state.dart:64` | Dispatches 6-digit OTP email |
| POST | `/api/auth/verify-otp` | 393 | **ACTIVE** | `auth_state.dart:99` | Verifies OTP code, returns JWT token & user profile |
| GET | `/api/auth/profile` | 457 | **ACTIVE** | `auth_state.dart:158` | Fetches fresh profile info for authenticated user |
| GET | `/api/coach/profile` | 502 | **UNKNOWN** | None | Redirect alias to `/api/auth/profile` |
| POST | `/api/auth/profile` | 504 | **ACTIVE** | `auth_state.dart:150` | Updates user profile details |
| POST | `/api/auth/send-email-change-otp` | 558 | **ACTIVE** | `profile_tab_view.dart:243` | Sends 6-digit OTP code to new email address |
| POST | `/api/auth/verify-new-email` | 607 | **ACTIVE** | `profile_tab_view.dart:349` | Verifies new email OTP & updates database |
| POST | `/api/coach/send-sms-otp` | 3866 | **ACTIVE** | `coach_welcome_wizard_screen.dart:245` | Alias to `/api/sms/send-verification` |
| POST | `/api/sms/send-verification` | 3873 | **ACTIVE** | `profile_tab_view.dart:415` | Sends SMS verification code via SMS Gateway |
| POST | `/api/coach/verify-sms-otp` | 3943 | **ACTIVE** | `coach_welcome_wizard_screen.dart:405`, `profile_tab_view.dart:541` | Alias to `/api/sms/verify-code` |
| POST | `/api/sms/verify-code` | 3950 | **UNKNOWN** | None | Raw SMS code verification endpoint (Flutter calls alias `/api/coach/verify-sms-otp`) |

---

### B. Squads, Rosters & Player Management Routes

| Method | Endpoint Path | Worker Line | Flutter Status | Flutter File / Call Site | Description |
|---|---|---|---|---|---|
| GET | `/api/squads` | 999 | **ACTIVE** | `dashboard_controller.dart:498` | Fetches squads for coach & school |
| POST | `/api/squads` | 1049 | **ACTIVE** | `dashboard_controller.dart:554` | Creates new coach squad |
| GET | `/api/rosters/:age_group` | 1120 | **ACTIVE** | `roster_controller.dart:97`, `batch_test_logger_modal.dart:163` | Fetches squad roster players |
| POST | `/api/players/:id/squads` | 1195 | **ACTIVE** | `roster_controller.dart:127` | Updates player squad assignments |
| GET | `/api/school/players` | 3001 | **ACTIVE** | `roster_controller.dart:146` | Searches school players & assigned squads |
| POST | `/api/squads/:squadId/players/add` | 3072 | **ACTIVE** | `roster_controller.dart:161` | Adds player to squad |
| POST | `/api/squads/:squadId/players/remove` | 3123 | **ACTIVE** | `roster_controller.dart:180` | Removes player from squad |
| POST | `/api/players/:id/position` | 3314 | **ACTIVE** | `roster_controller.dart:228` | Updates player position |
| POST | `/api/players` | 3343 | **ACTIVE** | `roster_controller.dart:272` | Creates player, user record & sends email invite |

---

### C. Coach Dashboard, Events & Action Plans Routes

| Method | Endpoint Path | Worker Line | Flutter Status | Flutter File / Call Site | Description |
|---|---|---|---|---|---|
| GET | `/api/dashboard/summary` | 1257 | **ACTIVE** | `dashboard_controller.dart:80` | Fetches dashboard KPI summary |
| GET | `/api/dashboard/flags` | 1347 | **ACTIVE** | `dashboard_controller.dart:167` | Fetches flagged players list |
| GET | `/api/events` | 1469 | **UNKNOWN** | None | Route alias re-fetching `/api/dashboard/events` |
| GET | `/api/dashboard/events` | 1476 | **ACTIVE** | `dashboard_controller.dart:754`, `batch_test_logger_modal.dart:102`, `single_player_baseline_modal.dart:84` | Fetches coach schedule events |
| POST | `/api/dashboard/events` | 1584 | **ACTIVE** | `dashboard_controller.dart:814` | Creates schedule event |
| POST | `/api/dashboard/events/:id` | 1712 | **ACTIVE** | `dashboard_controller.dart:865` | Updates existing event |
| DELETE | `/api/dashboard/events/:id` | 1796 | **UNKNOWN** | None | Standard HTTP DELETE event handler (Flutter uses `POST /delete`) |
| POST | `/api/dashboard/events/:id/delete` | 1807 | **ACTIVE** | `dashboard_controller.dart:899` | Deletes schedule event via POST |
| GET | `/api/dashboard/actions` | 1819 | **ACTIVE** | `dashboard_controller.dart:344` | Fetches coach action plans |
| POST | `/api/dashboard/actions` | 1893 | **ACTIVE** | `dashboard_controller.dart:410` | Creates new action plan |
| POST | `/api/dashboard/actions/:id/toggle` | 1963 | **ACTIVE** | `dashboard_controller.dart:442` | Toggles action plan completion |
| POST | `/api/dashboard/actions/:id/delete` | 2002 | **UNKNOWN** | None | Deletes action plan (Backend endpoint available) |
| GET | `/api/dashboard/rising-stars` | 2014 | **ACTIVE** | `dashboard_controller.dart:251` | Fetches top rising star players |
| POST | `/api/dashboard/checkin` | 2084 | **ACTIVE** | `checkin_controller.dart:336` | Records practice attendance check-in |
| GET | `/api/dashboard/events/:id/attendance` | 2205 | **ACTIVE** | `checkin_controller.dart:173` | Fetches attendance check-in state for event |

---

### D. Performance Metrics & Test Logging Routes

| Method | Endpoint Path | Worker Line | Flutter Status | Flutter File / Call Site | Description |
|---|---|---|---|---|---|
| GET | `/api/test-metrics` | 880 | **DEAD / LEGACY** | None (Overwritten by line 2777) | Unfiltered metric definitions query (Dead code due to duplicate handler) |
| GET | `/api/test-metrics` | 2777 | **ACTIVE** | `batch_test_logger_modal.dart:154`, `manage_metrics_modal.dart:54`, `single_player_baseline_modal.dart:134` | Fetches test metric definitions for school |
| POST | `/api/test-metrics` | 2807 | **ACTIVE** | `manage_metrics_modal.dart:74` | Creates/updates metric definition |
| DELETE | `/api/test-metrics/:id` | 2856 | **ACTIVE** | `manage_metrics_modal.dart:106` | Deletes metric definition |
| POST | `/api/dashboard/test-logs/batch` | 2868 | **UNKNOWN** | None | Route alias to `/api/test-logs/batch` |
| POST | `/api/dashboard/test-logs` | 2873 | **UNKNOWN** | None | Route alias to `/api/test-logs/batch` |
| POST | `/api/test-logs` | 2878 | **UNKNOWN** | None | Route alias to `/api/test-logs/batch` |
| POST | `/api/test-logs/batch` | 2885 | **ACTIVE** | `batch_test_logger_modal.dart:265`, `single_player_baseline_modal.dart:206` | Batch logs test scores for multiple players |
| POST | `/api/player/evaluation-baseline` | 2735 | **UNKNOWN** | None | Single-player baseline score logger |
| POST | `/api/match-stats` | 2237 | **UNKNOWN** | None | Individual match statistics logger |

---

### E. Student Portal, Parent Linking & Media Upload Routes

| Method | Endpoint Path | Worker Line | Flutter Status | Flutter File / Call Site | Description |
|---|---|---|---|---|---|
| GET | `/api/student-portal` | 2315 | **ACTIVE** | `student_controller.dart:201`, `roster_tab_view.dart:734`, `single_player_baseline_modal.dart:140` | Fetches student/parent portal hub data |
| POST | `/api/student-portal/profile` | 2644 | **ACTIVE** | `student_dashboard_screen.dart:2087, 2412` | Updates student profile details |
| POST | `/api/upload` | 3167 | **ACTIVE** | `student_dashboard_screen.dart:2405` | Uploads base64 images to R2 storage |
| POST | `/api/parent/link-request` | 3476 | **ACTIVE** | `parent_dashboard_screen.dart:117` | Sends parent-child linking request |
| GET | `/api/player/link-requests` | 3552 | **UNKNOWN** | None | Fetches pending parent link requests for player |
| POST | `/api/player/link-requests/:id/respond` | 3589 | **UNKNOWN** | None | Responds to parent link request (accept/reject) |
| GET | `/api/parent/children` | 3616 | **UNKNOWN** | None | Fetches linked children profiles for parent |

---

### F. Notifications Routes

| Method | Endpoint Path | Worker Line | Flutter Status | Flutter File / Call Site | Description |
|---|---|---|---|---|---|
| GET | `/api/notifications` | 3658 | **ACTIVE** | `notification_controller.dart:61` | Fetches user notifications list & unread count |
| POST | `/api/notifications/:id/read` | 3736 | **ACTIVE** | `notification_controller.dart:103` | Marks single notification as read |
| POST | `/api/notifications/read-all` | 3751 | **ACTIVE** | `notification_controller.dart:115` | Marks all notifications as read |
| DELETE | `/api/notifications/:id` | 3780 | **ACTIVE** | `notification_controller.dart:131` | Deletes notification via DELETE |
| POST | `/api/notifications/:id/delete` | 3794 | **ACTIVE** | `notification_controller.dart:128` | Deletes notification via POST alias |
| POST | `/api/notifications/send` | 3809 | **ACTIVE** | `notification_controller.dart:145` | Sends / creates notification |

---

### G. Web Admin & Internal System Routes (Web Admin / Seed Scripts)

| Method | Endpoint Path | Worker Line | Flutter Status | Primary Context / Usage |
|---|---|---|---|---|
| GET | `/api/athletes` | 686 | **UNKNOWN** | Web Admin Roster View |
| POST | `/api/athletes` | 709 | **UNKNOWN** | Web Admin Athlete Upsert |
| PUT | `/api/athletes/:id` | 739 | **UNKNOWN** | Web Admin Athlete Update |
| DELETE | `/api/athletes/:id` | 761 | **UNKNOWN** | Web Admin Athlete Delete |
| POST | `/api/test-results` | 773 | **UNKNOWN** | Web Admin / Legacy Test Result Logger |
| GET | `/api/test-results` | 859 | **UNKNOWN** | Web Admin / Legacy Test Results Fetcher |
| GET | `/api/coaches` | 794 | **UNKNOWN** | Web Admin Coaches Management |
| POST | `/api/coaches` | 814 | **UNKNOWN** | Web Admin Coach Add/Edit |
| DELETE | `/api/coaches/:id` | 848 | **UNKNOWN** | Web Admin Coach Delete |
| GET | `/api/admin/all-players` | 2972 | **UNKNOWN** | Admin Configurator / Roster Exporter |
| POST | `/api/admin/bulk-upload` | 3195 | **UNKNOWN** | Admin Bulk CSV/Excel Athlete Import |
| GET | `/api/admin/sports-config` | 3296 | **UNKNOWN** | Admin Sports Metrics Configurator |

---

## 3. Analysis & Key Findings

1. **High API Alignment**: 38 out of 70 defined routes and aliases are actively called by the Flutter mobile application in `academypro_app`.
2. **Web Admin Separation**: 12 routes starting with `/api/athletes`, `/api/coaches`, `/api/test-results`, and `/api/admin/` belong exclusively to the `web_admin` frontend dashboard or admin tools.
3. **Dead Code Identified**:
   - `GET /api/test-metrics` at line 880 is dead code because Hono router replaces it with the line 2777 definition (`app.get('/api/test-metrics', ...)`). Line 880 lacks school parameter filtering and should be removed or cleaned up.
4. **Convenience & Redundancy Aliases**:
   - `POST /api/dashboard/events/:id/delete` vs `DELETE /api/dashboard/events/:id`: Flutter uses the POST version to work around HTTP DELETE restrictions on mobile/proxies.
   - `POST /api/coach/send-sms-otp` and `POST /api/coach/verify-sms-otp`: Internal Hono fetch proxies that delegate to `/api/sms/send-verification` and `/api/sms/verify-code`.
   - `POST /api/dashboard/test-logs/batch`, `/api/dashboard/test-logs`, and `/api/test-logs`: All 3 alias routes proxy to `/api/test-logs/batch`.

---
