# Worker Structural Analysis Report: `worker/src/index.ts`

**Date**: 2026-08-03  
**Target File**: `worker/src/index.ts` (Total Lines: 4003)  
**Agent**: Explorer 3 (`teamwork_preview_explorer`)

---

## Executive Summary

A comprehensive line-by-line inspection of `worker/src/index.ts` was performed. The worker script contains 4,003 lines of code implementing 71 total HTTP endpoint registrations, middleware functions, and database helpers.

### Metric Summary:
- **Total Endpoint Registrations**: 71
- **Active Production Endpoints**: 52
- **Route Aliases & Forwarding Wrappers**: 7
- **Legacy / Dead Endpoints (Unreferenced)**: 9
- **Shadowed / Duplicate Handlers**: 3
- **Total Lines Recommended for Pruning**: 226 lines (approx. 5.6% reduction)

---

## Complete Endpoint Audit & Categorization

| # | HTTP Method | Path | Line Range | Status | Usage / Notes |
|---|---|---|---|---|---|
| 1 | POST | `/api/auth/send-otp` | 307–390 | **Active** | Auth OTP Dispatch (Email) |
| 2 | POST | `/api/auth/verify-otp` | 393–454 | **Active** | Auth OTP Verification & JWT Sign |
| 3 | GET | `/api/auth/profile` | 457–501 | **Active** | User Profile Fetch |
| 4 | GET | `/api/coach/profile` | 502 | **Alias** | Redirects to `/api/auth/profile` |
| 5 | POST | `/api/auth/profile` | 504–555 | **Active** | User Profile Update |
| 6 | POST | `/api/auth/send-email-change-otp` | 558–604 | **Active** | Email Change OTP Dispatch |
| 7 | POST | `/api/auth/verify-new-email` | 607–643 | **Active** | Email Change OTP Verification |
| 8 | GET | `/api/athletes` | 686–707 | 🔴 **Legacy** | Superseded by `/api/school/players` |
| 9 | POST | `/api/athletes` | 709–737 | 🔴 **Legacy** | Superseded by `/api/players` |
| 10 | PUT | `/api/athletes/:id` | 739–759 | 🔴 **Legacy** | Superseded by `/api/players/:id/position` |
| 11 | DELETE | `/api/athletes/:id` | 761–771 | 🔴 **Legacy** | Superseded by `/api/squads/:id/players/remove` |
| 12 | POST | `/api/test-results` | 773–792 | 🔴 **Legacy** | Superseded by `/api/test-logs/batch` |
| 13 | GET | `/api/coaches` | 794–812 | 🔴 **Legacy** | Unreferenced coach listing |
| 14 | POST | `/api/coaches` | 814–846 | 🔴 **Legacy** | Unreferenced coach registration |
| 15 | DELETE | `/api/coaches/:id` | 848–857 | 🔴 **Legacy** | Unreferenced coach deletion |
| 16 | GET | `/api/test-results` | 859–878 | 🔴 **Legacy** | Superseded by `/api/student-portal` test logs |
| 17 | GET | `/api/test-metrics` | 880–888 | ⚠️ **Shadowed** | Shadows scoped handler at line 2777! |
| 18 | GET | `/api/squads` | 999–1046 | **Active** | Coach Squads Listing |
| 19 | POST | `/api/squads` | 1049–1117 | **Active** | Coach Squad Creation |
| 20 | GET | `/api/rosters/:age_group` | 1120–1192 | **Active** | Team Roster Fetch |
| 21 | POST | `/api/players/:id/squads` | 1195–1254 | **Active** | Player Squad Assignments Update |
| 22 | GET | `/api/dashboard/summary` | 1257–1344 | **Active** | Dashboard Summary KPIs |
| 23 | GET | `/api/dashboard/flags` | 1347–1431 | **Active** | Flagged Players List |
| 24 | GET | `/api/events` | 1468–1473 | **Alias** | Forwards to `/api/dashboard/events` |
| 25 | GET | `/api/dashboard/events` | 1476–1582 | **Active** | Events List |
| 26 | POST | `/api/dashboard/events` | 1585–1709 | **Active** | Event Creation |
| 27 | POST | `/api/dashboard/events/:id` | 1711–1793 | **Active** | Event Update |
| 28 | DELETE | `/api/dashboard/events/:id` | 1795–1805 | **Active** | Event Deletion |
| 29 | POST | `/api/dashboard/events/:id/delete` | 1807–1816 | ⚠️ **Duplicate** | Duplicate POST alias for DELETE |
| 30 | GET | `/api/dashboard/actions` | 1819–1890 | **Active** | Action Plans Fetch |
| 31 | POST | `/api/dashboard/actions` | 1892–1960 | **Active** | Action Plan Creation |
| 32 | POST | `/api/dashboard/actions/:id/toggle` | 1962–1999 | **Active** | Action Plan Completion Toggle |
| 33 | POST | `/api/dashboard/actions/:id/delete` | 2001–2011 | **Active** | Action Plan Deletion |
| 34 | GET | `/api/dashboard/rising-stars` | 2014–2081 | **Active** | Rising Stars List |
| 35 | POST | `/api/dashboard/checkin` | 2084–2202 | **Active** | Practice Attendance Check-In |
| 36 | GET | `/api/dashboard/events/:id/attendance` | 2205–2234 | **Active** | Event Attendance Fetch |
| 37 | POST | `/api/match-stats` | 2237–2312 | **Active** | Match Stats Logging & Auto-Score |
| 38 | GET | `/api/student-portal` | 2315–2641 | **Active** | Student & Parent Portal Feed |
| 39 | POST | `/api/student-portal/profile` | 2644–2732 | **Active** | Student Profile Update |
| 40 | POST | `/api/player/evaluation-baseline` | 2735–2774 | **Active** | Single Baseline Metric Update |
| 41 | GET | `/api/test-metrics` | 2777–2804 | **Active** | Scoped Test Metrics Fetch (Currently Shadowed) |
| 42 | POST | `/api/test-metrics` | 2807–2853 | **Active** | Test Metric Definition Create/Update |
| 43 | DELETE | `/api/test-metrics/:id` | 2856–2865 | **Active** | Test Metric Definition Delete |
| 44 | POST | `/api/dashboard/test-logs/batch` | 2868–2872 | **Alias** | Forwards to `/api/test-logs/batch` |
| 45 | POST | `/api/dashboard/test-logs` | 2873–2877 | **Alias** | Forwards to `/api/test-logs/batch` |
| 46 | POST | `/api/test-logs` | 2878–2882 | **Alias** | Forwards to `/api/test-logs/batch` |
| 47 | POST | `/api/test-logs/batch` | 2885–2968 | **Active** | Batch Test Scores Logger |
| 48 | GET | `/api/admin/all-players` | 2972–2998 | **Active** | Web Admin Configurator Player Search |
| 49 | GET | `/api/school/players` | 3001–3069 | **Active** | School Player Roster Search & Squads |
| 50 | POST | `/api/squads/:squadId/players/add` | 3072–3121 | **Active** | Add Player to Squad |
| 51 | POST | `/api/squads/:squadId/players/remove` | 3124–3164 | **Active** | Remove Player from Squad |
| 52 | POST | `/api/upload` | 3167–3192 | **Active** | R2 / Base64 Image Upload |
| 53 | POST | `/api/admin/bulk-upload` | 3195–3293 | **Active** | Web Admin Bulk CSV Stats Uploader |
| 54 | GET | `/api/admin/sports-config` | 3296–3311 | **Active** | Web Admin Sports Metrics Config |
| 55 | POST | `/api/players/:id/position` | 3313–3340 | **Active** | Update Player Position |
| 56 | POST | `/api/players` | 3343–3454 | **Active** | Player Creation & Invite Dispatch |
| 57 | POST | `/api/parent/link-request` | 3476–3549 | **Active** | Parent-Child Link Request |
| 58 | GET | `/api/player/link-requests` | 3552–3586 | **Active** | Player Pending Link Requests |
| 59 | POST | `/api/player/link-requests/:id/respond` | 3589–3613 | **Active** | Player Link Request Response |
| 60 | GET | `/api/parent/children` | 3616–3651 | **Active** | Parent Linked Children Profiles |
| 61 | GET | `/api/notifications` | 3658–3733 | **Active** | Notifications List |
| 62 | POST | `/api/notifications/:id/read` | 3736–3748 | **Active** | Mark Notification Read |
| 63 | POST | `/api/notifications/read-all` | 3750–3777 | **Active** | Mark All Notifications Read |
| 64 | DELETE | `/api/notifications/:id` | 3779–3792 | **Active** | Delete Notification |
| 65 | POST | `/api/notifications/:id/delete` | 3794–3806 | ⚠️ **Duplicate** | Duplicate POST alias for DELETE |
| 66 | POST | `/api/notifications/send` | 3809–3863 | **Active** | Send Notification |
| 67 | POST | `/api/coach/send-sms-otp` | 3866–3870 | **Alias** | Forwards to `/api/sms/send-verification` |
| 68 | POST | `/api/sms/send-verification` | 3873–3940 | **Active** | Dispatch SMS Verification |
| 69 | POST | `/api/coach/verify-sms-otp` | 3943–3947 | **Alias** | Forwards to `/api/sms/verify-code` |
| 70 | POST | `/api/sms/verify-code` | 3950–3999 | **Active** | Verify SMS Verification Code |

---

## Detailed Inspection Findings

### 1. Legacy / Obsolete Endpoints Recommended for Pruning (Lines 686–878)

- **Legacy Athletes CRUD Endpoints** (Lines 686–771):
  - `GET /api/athletes` (686–707)
  - `POST /api/athletes` (709–737)
  - `PUT /api/athletes/:id` (739–759)
  - `DELETE /api/athletes/:id` (761–771)
  - **Rationale**: Replaced by modern domain-driven routes (`GET /api/school/players`, `POST /api/players`, `POST /api/players/:id/position`, `POST /api/squads/:squadId/players/remove`). Neither `academypro_app` nor `web_admin` invoke `/api/athletes`.

- **Legacy Test Results Endpoints** (Lines 773–792 & Lines 859–878):
  - `POST /api/test-results` (773–792)
  - `GET /api/test-results` (859–878)
  - **Rationale**: Replaced by batch logger (`POST /api/test-logs/batch`) and student portal feed (`GET /api/student-portal`).

- **Legacy Coaches CRUD Endpoints** (Lines 794–857):
  - `GET /api/coaches` (794–812)
  - `POST /api/coaches` (814–846)
  - `DELETE /api/coaches/:id` (848–857)
  - **Rationale**: Unreferenced in Flutter app and web admin frontend.

---

### 2. Shadowed & Duplicate Endpoint Handlers

- **CRITICAL: Shadowed `GET /api/test-metrics`** (Lines 880–888):
  - **Problem**: Lines 880–888 register `app.get('/api/test-metrics', ...)` returning un-scoped test metrics (`SELECT * FROM test_metric_definitions ORDER BY name ASC`).
  - **Impact**: Because Hono executes route handlers in registration order, requests to `GET /api/test-metrics` are caught at line 880 and **never reach** the authenticated, school-scoped handler at lines 2777–2804 (`WHERE school_id = ?`).
  - **Remediation**: Prune lines 880–888 completely.

- **Duplicate Event Deletion Handler** (Lines 1807–1816):
  - `POST /api/dashboard/events/:id/delete` duplicates `DELETE /api/dashboard/events/:id` (lines 1795–1805).
  - Both Flutter app and backend support HTTP DELETE.

- **Duplicate Notification Deletion Handler** (Lines 3794–3806):
  - `POST /api/notifications/:id/delete` duplicates `DELETE /api/notifications/:id` (lines 3779–3792).

---

### 3. Helper Functions & Type Audit

1. `generatePrimaryKey(prefix: string = 'id')` (Lines 161–166):
   - Currently only called inside legacy `POST /api/athletes` (Line 720).
   - **Recommendation**: Keep in `worker/src/index.ts` as specified by project standard rules (`USER_RULES` PK Auto-Generation standard).

2. Helper functions (`getDB`, `getKV`, `generateSecureOTP`, `getSecret`, `calculateAutoScore`, `sendTransactionalEmail`, `enforceJwtAuth`, `ensureSquadsTables`, `getCoachSquadPlayerIds`, `purgeExpiredWorkoutImages`, `ensureParentLinksTable`):
   - All actively used across core production routes.

---

## Actionable Pruning Recommendations

### Block 1: Remove Legacy / Unreferenced Block (Lines 686–888)
- Remove `GET /api/athletes` (686–707)
- Remove `POST /api/athletes` (709–737)
- Remove `PUT /api/athletes/:id` (739–759)
- Remove `DELETE /api/athletes/:id` (761–771)
- Remove `POST /api/test-results` (773–792)
- Remove `GET /api/coaches` (794–812)
- Remove `POST /api/coaches` (814–846)
- Remove `DELETE /api/coaches/:id` (848–857)
- Remove `GET /api/test-results` (859–878)
- Remove Shadowed `GET /api/test-metrics` (880–888)
- **Total Lines Pruned**: 203 lines

### Block 2: Remove Duplicate Event Delete POST Route (Lines 1807–1816)
- Remove `POST /api/dashboard/events/:id/delete`
- **Total Lines Pruned**: 10 lines

### Block 3: Remove Duplicate Notification Delete POST Route (Lines 3794–3806)
- Remove `POST /api/notifications/:id/delete`
- **Total Lines Pruned**: 13 lines

**Total Reduction**: 226 lines removed cleanly from `worker/src/index.ts`.
