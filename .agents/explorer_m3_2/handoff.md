# API Specification Audit & Alignment Handoff Report

**Target File:** `c:\Development\academypro\API_SPECIFICATION.md`  
**Backend Source:** `c:\Development\academypro\worker\src\index.ts`  
**Date:** 2026-08-03  
**Author:** explorer_m3_2  

---

## Executive Summary

A comprehensive audit was performed comparing `API_SPECIFICATION.md` against active Hono route implementations in `worker/src/index.ts`. 

- **Documented Endpoints in `API_SPECIFICATION.md`:** 7 total endpoints.
- **Endpoints Pruned / Obsolete:** 4 endpoints (`POST /api/auth/login`, `POST /api/attendance`, `GET /api/players/:id/dashboard`, `GET /api/players/flagged`).
- **Endpoints Retained / Needing Updates:** 3 endpoints (`GET /api/rosters/:age_group`, `POST /api/match-stats`, `POST /api/admin/bulk-upload`).
- **Active Endpoints Missing from Specification:** 51 distinct active routes across 7 functional backend modules. Total active route definitions in `worker/src/index.ts` equal 58 routes (including aliases).

---

## 1. Observation

### Exact File Evidence & References

1. **`API_SPECIFICATION.md` (208 lines):**
   - Section 2 (lines 28–36) documents 7 endpoints:
     - Line 29: `POST /api/auth/login`
     - Line 30: `GET  /api/rosters/:age_group`
     - Line 31: `POST /api/match-stats`
     - Line 32: `POST /api/attendance`
     - Line 33: `POST /api/admin/bulk-upload`
     - Line 34: `GET  /api/players/:id/dashboard`
     - Line 35: `GET  /api/players/flagged`
   - Section 3 (lines 40–207) provides detailed payload models for:
     - Section 3.A: `POST /api/auth/login` (lines 42–68)
     - Section 3.B: `GET /api/rosters/:age_group` (lines 72–95)
     - Section 3.C: `POST /api/match-stats` (lines 99–133)
     - Section 3.D: `POST /api/admin/bulk-upload` (lines 137–155)
     - Section 3.E: `GET /api/players/:id/dashboard` (lines 159–207)

2. **`worker/src/index.ts` (3,788 lines):**
   - Contains 58 route definitions registered on the Hono `app` instance.
   - Password login (`POST /api/auth/login`) is **absent**. Authentication is now passwordless OTP via `POST /api/auth/send-otp` (line 307) and `POST /api/auth/verify-otp` (line 393).
   - Standalone `POST /api/attendance` is **absent**. Event check-in is handled via `POST /api/dashboard/checkin` (line 1869) and event attendance via `GET /api/dashboard/events/:id/attendance` (line 1990).
   - `GET /api/players/:id/dashboard` is **absent**. Comprehensive student portal data is handled via `GET /api/student-portal` (line 2100).
   - `GET /api/players/flagged` is **absent**. Flagged player roster is handled via `GET /api/dashboard/flags` (line 1141).

---

## 2. Logic Chain

1. **Pruned Endpoints Logic:**
   - Milestone 1 updated authentication from password-based credentials to email/SMS OTP verification. Therefore `POST /api/auth/login` is dead code and must be removed from `API_SPECIFICATION.md`.
   - Attendance logging was unified into calendar event check-ins (`POST /api/dashboard/checkin`). Therefore `POST /api/attendance` is obsolete and must be removed.
   - Dashboard endpoints were grouped under `/api/dashboard/*` and `/api/student-portal`. Legacy routes `/api/players/:id/dashboard` and `/api/players/flagged` do not exist in the backend router and must be pruned to avoid misleading API consumers.

2. **Endpoints to Retain & Align Logic:**
   - `GET /api/rosters/:age_group` (line 914), `POST /api/match-stats` (line 2022), and `POST /api/admin/bulk-upload` (line 2980) exist in `worker/src/index.ts`. However, their description and payload schemas in `API_SPECIFICATION.md` need alignment with current D1 prepared statement query parameters and response formats.

3. **New Active Endpoints to Document Logic:**
   - `worker/src/index.ts` expanded significantly during Milestone 1 & 2 to support the full vertical slice (Squads, Dashboard Actions/Events/Flags/Rising Stars, Test Metrics & Logs, Student Portal 360, Parent Link Requests, R2 Uploads, Notifications, and SMS OTP verification).
   - All 51 missing active endpoints must be cataloged in `API_SPECIFICATION.md` under clear functional headings with HTTP methods, route paths, required parameters, and sample JSON payloads.

---

## 3. Caveats

- **Network Restrictions:** Investigation was executed strictly in read-only offline CODE_ONLY mode using local workspace files. No remote Cloudflare Workers were mutated or queried.
- **Route Aliases:** `worker/src/index.ts` contains several route aliases designed for dual payload or route backward-compatibility (e.g., `POST /api/dashboard/test-logs` alias for `POST /api/test-logs`, `POST /api/coach/send-sms-otp` alias for `POST /api/sms/send-verification`). These are documented together in the specification.

---

## 4. Conclusion & Detailed Action Plan

`API_SPECIFICATION.md` requires a major structural revision. Below are the exact sections to **PRUNE**, **UPDATE**, and **ADD**.

---

### A. SECTIONS TO PRUNE (REMOVE FROM `API_SPECIFICATION.md`)

| Section in `API_SPECIFICATION.md` | Endpoint | Line Numbers | Rationale |
| --- | --- | --- | --- |
| **Directory & Section 3.A** | `POST /api/auth/login` | Lines 29, 42–68 | Replaced by OTP endpoints (`/api/auth/send-otp` & `/api/auth/verify-otp`) |
| **Directory** | `POST /api/attendance` | Line 32 | Replaced by `/api/dashboard/checkin` |
| **Directory & Section 3.E** | `GET /api/players/:id/dashboard` | Lines 34, 159–207 | Replaced by `/api/student-portal` |
| **Directory** | `GET /api/players/flagged` | Line 35 | Replaced by `/api/dashboard/flags` |

---

### B. SECTIONS TO UPDATE & ALIGN

| Endpoint | Line in `worker/src/index.ts` | Required Documentation Update |
| --- | --- | --- |
| `GET /api/rosters/:age_group` | Line 914 | Update response model to match current D1 fallback logic (`schoolId` query support, player objects including `ugroupsActive`, `position`, `team`). |
| `POST /api/match-stats` | Line 2022 | Align payload schema (`playerId`, `matchDate`, `opponent`, `tacklesMade`, `tacklesMissed`, `carries`, `metresGained`, `errors`, `penalties`, `workRate`, `overallRating`) and response fields (`id`, `playerId`, `autoScore`, `autoScorePercent`, `tacklePercentage`, `category`). |
| `POST /api/admin/bulk-upload` | Line 2980 | Update description to reflect multipart form-data handling (`file`, `schoolId`, `term`) and detailed JSON response (`inserted`, `updated`, `errors`). |

---

### C. SECTIONS TO ADD (51 MISSING ACTIVE ENDPOINTS BY MODULE)

#### Module 1: Authentication & Account Security (`/api/auth/*`)
1. `POST /api/auth/send-otp` (Line 307) — Dispatches 6-digit OTP code to user email.
2. `POST /api/auth/verify-otp` (Line 393) — Verifies email OTP code and returns JWT bearer token + user profile.
3. `GET /api/auth/profile` (Line 457) — Retrieves current authenticated user profile details from D1.
4. `POST /api/auth/profile` (Line 503) — Updates user profile (`firstName`, `lastName`, `phone`, `avatar_url`).
5. `POST /api/auth/send-email-change-otp` (Line 557) — Dispatches verification OTP code to a new email address.
6. `POST /api/auth/verify-new-email` (Line 606) — Verifies new email OTP code and performs cascading database email updates.

#### Module 2: Squad & Roster Management (`/api/squads/*`, `/api/school/*`, `/api/admin/*`, `/api/players/*`)
7. `GET /api/squads` (Line 793) — Fetches squads owned by coach or associated with school.
8. `POST /api/squads` (Line 843) — Creates a new squad record in D1.
9. `POST /api/players/:id/squads` (Line 989) — Assigns player to squad.
10. `POST /api/squads/:squadId/players/add` (Line 2857) — Adds player to squad in `squad_players` table.
11. `POST /api/squads/:squadId/players/remove` (Line 2909) — Removes player assignment from squad.
12. `GET /api/admin/all-players` (Line 2757) — Admin endpoint returning all registered players across schools.
13. `GET /api/school/players` (Line 2786) — Returns filtered player list for a specific school (supports squad/search filtering).
14. `POST /api/players` (Line 3128) — Creates a new player profile record.
15. `POST /api/players/:id/position` (Line 3099) — Updates primary playing position for athlete.

#### Module 3: Coach Dashboard, Events & Action Plans (`/api/dashboard/*`)
16. `GET /api/dashboard/summary` (Line 1051) — Calculates squad performance summary, average auto-score, attendance %, and academic baseline metrics.
17. `GET /api/dashboard/flags` (Line 1141) — Returns flagged at-risk players (academic drop, low attendance, performance risk).
18. `GET /api/dashboard/events` (Line 1261) — Fetches scheduled events (training, matches, evaluations) for a squad/school.
19. `POST /api/dashboard/events` (Line 1370) — Creates a new scheduled event.
20. `POST /api/dashboard/events/:id` (Line 1497) — Updates an existing event details.
21. `DELETE /api/dashboard/events/:id` (Line 1581) & `POST /api/dashboard/events/:id/delete` (Line 1592) — Deletes an event.
22. `GET /api/dashboard/actions` (Line 1604) — Fetches active improvement action plans for players.
23. `POST /api/dashboard/actions` (Line 1678) — Creates a new action plan item.
24. `POST /api/dashboard/actions/:id/toggle` (Line 1748) — Toggles action plan completion status (records `completed_at` for 24-hour auto-purge).
25. `POST /api/dashboard/actions/:id/delete` (Line 1787) — Deletes an action plan item.
26. `GET /api/dashboard/rising-stars` (Line 1799) — Retrieves top-performing athletes based on auto-score and work rate.
27. `POST /api/dashboard/checkin` (Line 1869) — Records attendance check-in for practice sessions or matches.
28. `GET /api/dashboard/events/:id/attendance` (Line 1990) — Returns list of present player IDs for a scheduled event.

#### Module 4: Performance Testing & Metrics (`/api/test-metrics`, `/api/test-logs`, `/api/player/*`)
29. `POST /api/player/evaluation-baseline` (Line 2520) — Records baseline physical testing evaluations (speed, jump, strength).
30. `GET /api/test-metrics` (Line 2562) — Retrieves defined test metrics configuration.
31. `POST /api/test-metrics` (Line 2592) — Creates or updates custom testing metrics.
32. `DELETE /api/test-metrics/:id` (Line 2641) — Deletes a test metric.
33. `POST /api/test-logs` / `POST /api/dashboard/test-logs` (Lines 2658, 2663) — Logs a single athlete test score.
34. `POST /api/test-logs/batch` / `POST /api/dashboard/test-logs/batch` (Lines 2653, 2670) — Batch inserts/updates multiple test score entries.

#### Module 5: Student Portal & Parent Access (`/api/student-portal/*`, `/api/parent/*`, `/api/player/*`)
35. `GET /api/student-portal` (Line 2100) — Returns 360-degree athlete portal dataset (profile, academics, match stats, fitness baselines, action plans, attendance summary, parent link status).
36. `POST /api/student-portal/profile` (Line 2429) — Updates student athlete self-managed profile information.
37. `POST /api/parent/link-request` (Line 3261) — Initiates a parent-child account link request.
38. `GET /api/player/link-requests` (Line 3337) — Fetches pending parent linking requests for a student athlete.
39. `POST /api/player/link-requests/:id/respond` (Line 3374) — Accepts or declines a parent link request.
40. `GET /api/parent/children` (Line 3401) — Fetches linked child athlete profiles for a verified parent account.

#### Module 6: System Admin, Storage & SMS Services (`/api/admin/*`, `/api/upload`, `/api/sms/*`)
41. `POST /api/upload` (Line 2952) — Handles image / asset uploads to storage.
42. `GET /api/admin/sports-config` (Line 3081) — Fetches school sports configuration, positions, and age groups.
43. `POST /api/sms/send-verification` / `POST /api/coach/send-sms-otp` (Lines 3651, 3658) — Sends SMS OTP verification code via SMS Gateway.
44. `POST /api/sms/verify-code` / `POST /api/coach/verify-sms-otp` (Lines 3728, 3735) — Verifies SMS OTP code stored in KV.

#### Module 7: Notification System (`/api/notifications/*`)
45. `GET /api/notifications` (Line 3443) — Retrieves notification stream for user.
46. `POST /api/notifications/:id/read` (Line 3521) — Marks single notification as read.
47. `POST /api/notifications/read-all` (Line 3536) — Marks all user notifications as read.
48. `DELETE /api/notifications/:id` / `POST /api/notifications/:id/delete` (Lines 3565, 3579) — Deletes a notification.
49. `POST /api/notifications/send` (Line 3594) — Dispatches a new notification to a target user or all users.

---

## 5. Verification Method

To verify these findings independently:

1. **Verify Pruned Endpoints Absence:**
   Execute grep search for pruned route paths in `worker/src/index.ts`:
   ```bash
   grep -E "('/api/auth/login'|'/api/attendance'|'/api/players/:id/dashboard'|'/api/players/flagged')" worker/src/index.ts
   ```
   *Expected result:* 0 matches found.

2. **Verify Active Endpoints Presence:**
   Execute grep search for active routes:
   ```bash
   grep -nE "app\.(get|post|put|delete)\(" worker/src/index.ts
   ```
   *Expected result:* 58 route handler matches corresponding line by line to Section 4.C above.

3. **Invalidation Conditions:**
   - If `worker/src/index.ts` is reverted to include `/api/auth/login` password authentication, Section 4.A must be re-evaluated.
