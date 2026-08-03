# Comprehensive API Audit: `worker/src/index.ts` vs `web_admin/`, Clients & Services

**Audit Date**: 2026-08-03
**Auditor**: Explorer 2 (`teamwork_preview_explorer`)
**Target File**: `worker/src/index.ts` (4,003 lines)

---

## 1. Executive Summary

A comprehensive audit of `worker/src/index.ts` was performed by cross-referencing all 70 defined HTTP API routes against:
1. `web_admin/` (`index.html` and `uploader.html`)
2. `academypro_app` (Flutter mobile application codebase)
3. Seed scripts, SQL migrations, and test scripts
4. `API_SPECIFICATION.md`
5. System services (SMS Gateway `https://sms-service.codeways.co`, Cloudflare SendEmail `cloudflare:email` / `web.codeways.co`, R2 storage `env.R2`)

### Audit Metrics
- **Total API Routes Defined in Worker**: 70
- **ACTIVE Routes**: 58 (82.9%)
- **DEAD / LEGACY Routes**: 12 (17.1%)

---

## 2. Web Admin Integration Map (`web_admin/`)

The `web_admin/` frontend comprises two single-page tools: `index.html` (Training Template Configurator) and `uploader.html` (Zero-Admin Bulk Uploader).

| Endpoint | Method | Worker Location | Called By | Purpose | Status |
|---|---|---|---|---|---|
| `/api/admin/all-players` | `GET` | `index.ts:2972` | `web_admin/index.html:150`<br>`web_admin/uploader.html:157` | Fetches roster for template preview and athlete ID validation | **ACTIVE** |
| `/api/admin/sports-config` | `GET` | `index.ts:3296` | `web_admin/index.html:160` | Fetches metric configuration JSON for template generator | **ACTIVE** |
| `/api/admin/bulk-upload` | `POST` | `index.ts:3195` | `web_admin/uploader.html:411` | Ingests parsed CSV/Excel metrics & grades into D1 | **ACTIVE** |

---

## 3. System Services & External Gateway Integrations

| Service / Gateway | Endpoint | Worker Location | Details | Status |
|---|---|---|---|---|
| **SMS Gateway Service** | `POST /api/sms/send-verification`<br>`POST /api/coach/send-sms-otp` | `index.ts:3873`<br>`index.ts:3866` | Dispatches OTP via `POST https://sms-service.codeways.co` using `X-Internal-API-Key` matching `env.INTERNAL_API_KEY`. | **ACTIVE** |
| **Transactional Email System** | `POST /api/auth/send-otp`<br>`POST /api/auth/send-email-change-otp`<br>`POST /api/players` | `index.ts:307`<br>`index.ts:558`<br>`index.ts:3443` | Sends HTML emails using native `cloudflare:email` binding with fallback to `https://web.codeways.co/api/send-email`. | **ACTIVE** |
| **Cloudflare R2 Bucket Storage** | `POST /api/upload`<br>`GET /api/dashboard/events` | `index.ts:3167`<br>`index.ts:1476` | Uploads base64 images to `env.R2` (`academypro-assets`) and auto-purges workout images older than 7 days. | **ACTIVE** |

---

## 4. Complete Route Audit & Classification Table

| # | Route | Method | Line Number | Category | Usage / Evidence | Status |
|---|---|---|---|---|---|---|
| 1 | `/api/auth/send-otp` | POST | 307 | Auth | Mobile app (`auth_state.dart:64`), uses transactional email system | **ACTIVE** |
| 2 | `/api/auth/verify-otp` | POST | 393 | Auth | Mobile app (`auth_state.dart:99`), KV OTP verification & JWT issuance | **ACTIVE** |
| 3 | `/api/auth/profile` | GET | 457 | Auth | Mobile app (`auth_state.dart:158`), returns authenticated user profile | **ACTIVE** |
| 4 | `/api/coach/profile` | GET | 502 | Auth | Redirect alias to `/api/auth/profile`. Uncalled by modern clients. | **DEAD / LEGACY** |
| 5 | `/api/auth/profile` | POST | 504 | Auth | Mobile app (`auth_state.dart:150`), updates user profile fields | **ACTIVE** |
| 6 | `/api/auth/send-email-change-otp` | POST | 558 | Auth | Mobile app (`profile_tab_view.dart:243`), dispatches OTP for email update | **ACTIVE** |
| 7 | `/api/auth/verify-new-email` | POST | 607 | Auth | Mobile app (`profile_tab_view.dart:349`), updates email in D1 users & links | **ACTIVE** |
| 8 | `/api/athletes` | GET | 686 | Roster | Unreferenced legacy route. Superseded by `/api/school/players` & `/api/admin/all-players` | **DEAD / LEGACY** |
| 9 | `/api/athletes` | POST | 709 | Roster | Unreferenced legacy route. Superseded by `POST /api/players` | **DEAD / LEGACY** |
| 10 | `/api/athletes/:id` | PUT | 739 | Roster | Unreferenced legacy CRUD route | **DEAD / LEGACY** |
| 11 | `/api/athletes/:id` | DELETE | 761 | Roster | Unreferenced legacy CRUD route | **DEAD / LEGACY** |
| 12 | `/api/test-results` | POST | 773 | Evaluation | Unreferenced legacy route. Superseded by `/api/test-logs/batch` | **DEAD / LEGACY** |
| 13 | `/api/coaches` | GET | 794 | Admin | Unreferenced legacy route for fetching coaches | **DEAD / LEGACY** |
| 14 | `/api/coaches` | POST | 814 | Admin | Unreferenced legacy route for registering coaches | **DEAD / LEGACY** |
| 15 | `/api/coaches/:id` | DELETE | 848 | Admin | Unreferenced legacy route for deleting coaches | **DEAD / LEGACY** |
| 16 | `/api/test-results` | GET | 859 | Evaluation | Unreferenced legacy route. Superseded by `/api/student-portal` | **DEAD / LEGACY** |
| 17 | `/api/test-metrics` | GET | 880 | Evaluation | First definition of `/api/test-metrics`. Duplicate/overridden by line 2777 | **DEAD / LEGACY** |
| 18 | `/api/squads` | GET | 999 | Squads | Mobile app (`dashboard_controller.dart:498`), retrieves coach squads | **ACTIVE** |
| 19 | `/api/squads` | POST | 1049 | Squads | Mobile app (`dashboard_controller.dart:554`), creates new squad in D1 | **ACTIVE** |
| 20 | `/api/rosters/:age_group` | GET | 1120 | Roster | Mobile app (`roster_controller.dart:97`), in `API_SPECIFICATION.md` | **ACTIVE** |
| 21 | `/api/players/:id/squads` | POST | 1195 | Roster | Mobile app (`roster_controller.dart:127`), updates squad assignments | **ACTIVE** |
| 22 | `/api/dashboard/summary` | GET | 1257 | Dashboard | Mobile app (`dashboard_controller.dart:80`), summary KPIs | **ACTIVE** |
| 23 | `/api/dashboard/flags` | GET | 1347 | Dashboard | Mobile app (`dashboard_controller.dart:167`), flagged players list | **ACTIVE** |
| 24 | `/api/events` | GET | 1469 | Events | Redirect alias to `/api/dashboard/events`. Uncalled by modern clients. | **DEAD / LEGACY** |
| 25 | `/api/dashboard/events` | GET | 1476 | Events | Mobile app (`dashboard_controller.dart:754`), fetches events + R2 image purge | **ACTIVE** |
| 26 | `/api/dashboard/events` | POST | 1585 | Events | Mobile app (`dashboard_controller.dart:814`), creates event in D1 | **ACTIVE** |
| 27 | `/api/dashboard/events/:id` | POST | 1712 | Events | Mobile app (`dashboard_controller.dart:865`), updates event in D1 | **ACTIVE** |
| 28 | `/api/dashboard/events/:id` | DELETE | 1796 | Events | Event deletion endpoint (REST standard DELETE) | **ACTIVE** |
| 29 | `/api/dashboard/events/:id/delete` | POST | 1807 | Events | Mobile app (`dashboard_controller.dart:899`), POST delete fallback | **ACTIVE** |
| 30 | `/api/dashboard/actions` | GET | 1819 | Actions | Mobile app (`dashboard_controller.dart:344`), 24h auto-purge protocol | **ACTIVE** |
| 31 | `/api/dashboard/actions` | POST | 1893 | Actions | Mobile app (`dashboard_controller.dart:410`), creates action plan | **ACTIVE** |
| 32 | `/api/dashboard/actions/:id/toggle` | POST | 1963 | Actions | Mobile app (`dashboard_controller.dart:442`), toggles completion status | **ACTIVE** |
| 33 | `/api/dashboard/actions/:id/delete` | POST | 2002 | Actions | Deletes action plan item from D1 | **ACTIVE** |
| 34 | `/api/dashboard/rising-stars` | GET | 2014 | Dashboard | Mobile app (`dashboard_controller.dart:251`), top performer list | **ACTIVE** |
| 35 | `/api/dashboard/checkin` | POST | 2084 | Attendance | Mobile app (`checkin_controller.dart:336`), practice attendance check-in | **ACTIVE** |
| 36 | `/api/dashboard/events/:id/attendance` | GET | 2205 | Attendance | Mobile app (`checkin_controller.dart:173`), checked-in players for event | **ACTIVE** |
| 37 | `/api/match-stats` | POST | 2237 | Match Stats | Mobile app, calculates Auto-Score & saves to D1, in `API_SPECIFICATION.md` | **ACTIVE** |
| 38 | `/api/student-portal` | GET | 2315 | Student Portal | Mobile app (`roster_tab_view.dart:734`), 360-degree athlete portal | **ACTIVE** |
| 39 | `/api/student-portal/profile` | POST | 2644 | Student Portal | Mobile app, updates student profile details in D1 | **ACTIVE** |
| 40 | `/api/player/evaluation-baseline` | POST | 2735 | Evaluation | Mobile app (`single_player_baseline_modal.dart:93`), single score logger | **ACTIVE** |
| 41 | `/api/test-metrics` | GET | 2777 | Evaluation | Mobile app (`batch_test_logger_modal.dart:154`), fetches metric definitions | **ACTIVE** |
| 42 | `/api/test-metrics` | POST | 2807 | Evaluation | Mobile app (`manage_metrics_modal.dart:74`), creates/updates metric definition | **ACTIVE** |
| 43 | `/api/test-metrics/:id` | DELETE | 2856 | Evaluation | Mobile app (`manage_metrics_modal.dart:106`), deletes metric definition | **ACTIVE** |
| 44 | `/api/dashboard/test-logs/batch` | POST | 2868 | Evaluation | Alias route forwarding to `/api/test-logs/batch` | **ACTIVE** |
| 45 | `/api/dashboard/test-logs` | POST | 2873 | Evaluation | Alias route forwarding to `/api/test-logs/batch` | **ACTIVE** |
| 46 | `/api/test-logs` | POST | 2878 | Evaluation | Alias route forwarding to `/api/test-logs/batch` | **ACTIVE** |
| 47 | `/api/test-logs/batch` | POST | 2885 | Evaluation | Mobile app (`batch_test_logger_modal.dart:265`), batch score logger | **ACTIVE** |
| 48 | `/api/admin/all-players` | GET | 2972 | Admin | `web_admin/index.html:150` & `web_admin/uploader.html:157` | **ACTIVE** |
| 49 | `/api/school/players` | GET | 3001 | School | Mobile app (`roster_controller.dart:146`), player search & squad mapping | **ACTIVE** |
| 50 | `/api/squads/:squadId/players/add` | POST | 3072 | Squads | Mobile app (`roster_controller.dart:161`), adds player to squad | **ACTIVE** |
| 51 | `/api/squads/:squadId/players/remove` | POST | 3123 | Squads | Mobile app (`roster_controller.dart:180`), removes player from squad | **ACTIVE** |
| 52 | `/api/upload` | POST | 3167 | Upload | Mobile app avatar/workout image upload to R2 (`env.R2`) | **ACTIVE** |
| 53 | `/api/admin/bulk-upload` | POST | 3195 | Admin | `web_admin/uploader.html:411`, in `API_SPECIFICATION.md` | **ACTIVE** |
| 54 | `/api/admin/sports-config` | GET | 3296 | Admin | `web_admin/index.html:160`, returns sports metric config JSON | **ACTIVE** |
| 55 | `/api/players/:id/position` | POST | 3314 | Players | Mobile app (`roster_controller.dart:228`), updates player position | **ACTIVE** |
| 56 | `/api/players` | POST | 3443 | Players | Mobile app (`roster_controller.dart:272`), creates player + email invite | **ACTIVE** |
| 57 | `/api/parent/link-request` | POST | 3476 | Parent | Mobile app, parent requests link to child | **ACTIVE** |
| 58 | `/api/player/link-requests` | GET | 3552 | Player | Mobile app, player views link requests | **ACTIVE** |
| 59 | `/api/player/link-requests/:id/respond` | POST | 3589 | Player | Mobile app, player accepts/rejects link request | **ACTIVE** |
| 60 | `/api/parent/children` | GET | 3616 | Parent | Mobile app, parent views linked children profiles | **ACTIVE** |
| 61 | `/api/notifications` | GET | 3658 | Notifications | Mobile app (`notification_controller.dart:61`), notification feed | **ACTIVE** |
| 62 | `/api/notifications/:id/read` | POST | 3736 | Notifications | Mobile app (`notification_controller.dart:97`), mark single read | **ACTIVE** |
| 63 | `/api/notifications/read-all` | POST | 3750 | Notifications | Mobile app (`notification_controller.dart:108`), mark all read | **ACTIVE** |
| 64 | `/api/notifications/:id` | DELETE | 3780 | Notifications | Mobile app (`notification_controller.dart:123`), delete notification | **ACTIVE** |
| 65 | `/api/notifications/:id/delete` | POST | 3794 | Notifications | Mobile app (`notification_controller.dart:120`), POST delete fallback | **ACTIVE** |
| 66 | `/api/notifications/send` | POST | 3809 | Notifications | Mobile app, creates/sends in-app notification | **ACTIVE** |
| 67 | `/api/coach/send-sms-otp` | POST | 3866 | SMS | Mobile app (`coach_welcome_wizard_screen.dart:245`), alias route | **ACTIVE** |
| 68 | `/api/sms/send-verification` | POST | 3873 | SMS | Mobile app, SMS gateway (`https://sms-service.codeways.co`) integration | **ACTIVE** |
| 69 | `/api/coach/verify-sms-otp` | POST | 3943 | SMS | Mobile app (`coach_welcome_wizard_screen.dart:405`), alias route | **ACTIVE** |
| 70 | `/api/sms/verify-code` | POST | 3950 | SMS | Mobile app, verifies SMS OTP against KV | **ACTIVE** |

---

## 5. Detailed Breakdown of Dead / Legacy Routes

The following 12 routes in `worker/src/index.ts` were identified as DEAD / LEGACY:

1. `GET /api/coach/profile` (Line 502): Redirects to `/api/auth/profile`. Unreferenced by web admin or mobile clients.
2. `GET /api/athletes` (Line 686): Legacy player list route. Superseded by `/api/school/players` and `/api/admin/all-players`.
3. `POST /api/athletes` (Line 709): Legacy player insertion route. Superseded by `POST /api/players`.
4. `PUT /api/athletes/:id` (Line 739): Unused legacy player update route.
5. `DELETE /api/athletes/:id` (Line 761): Unused legacy player deletion route.
6. `POST /api/test-results` (Line 773): Legacy test score logger. Superseded by `POST /api/test-logs/batch`.
7. `GET /api/coaches` (Line 794): Legacy coach list route.
8. `POST /api/coaches` (Line 814): Legacy coach creation route.
9. `DELETE /api/coaches/:id` (Line 848): Unused legacy coach deletion route.
10. `GET /api/test-results` (Line 859): Legacy test result fetcher. Superseded by `/api/student-portal`.
11. `GET /api/test-metrics` (Line 880): Overridden duplicate definition. The active definition at line 2777 handles `school_id` filtering properly.
12. `GET /api/events` (Line 1469): Alias route for `/api/dashboard/events`. Uncalled by modern clients.
