## 2026-08-03T13:40:24Z
Execute Milestone 3: Web Admin Clean & `API_SPECIFICATION.md` Alignment.
Working directory: `c:\Development\academypro\.agents\worker_m3`.
Read Explorer 1 handoff: `c:\Development\academypro\.agents\explorer_m3_1\handoff.md`.
Read Explorer 2 handoff: `c:\Development\academypro\.agents\explorer_m3_2\handoff.md`.

Tasks:
1. **Web Admin Pruning & Cleanup (`c:\Development\academypro\web_admin`)**:
   - Inspect `index.html` and `uploader.html`.
   - Remove orphaned state (`loading` property in `index.html`) or connect loading spinner UI indicator (`x-show="loading"`).
   - Ensure all API fetch calls remain 100% operational against active Worker API routes (`/api/admin/all-players`, `/api/admin/sports-config`, `/api/admin/bulk-upload`).

2. **`API_SPECIFICATION.md` Documentation Alignment (`c:\Development\academypro\API_SPECIFICATION.md`)**:
   - Rewrite `API_SPECIFICATION.md` to perfectly match active Cloudflare Worker endpoints in `worker/src/index.ts`.
   - Remove the 4 obsolete endpoints (`POST /api/auth/login`, `POST /api/attendance`, `GET /api/players/:id/dashboard`, `GET /api/players/flagged`).
   - Align the 3 active endpoints (`GET /api/rosters/:age_group`, `POST /api/match-stats`, `POST /api/admin/bulk-upload`).
   - Document all 51 active endpoints across 7 functional modules:
     - Module 1: Authentication & OTP (`/api/auth/*`)
     - Module 2: Squad & Roster Management (`/api/squads/*`, `/api/school/*`)
     - Module 3: Coach Dashboard, Events & Action Plans (`/api/dashboard/*`)
     - Module 4: Performance Testing & Metrics (`/api/test-metrics`, `/api/test-logs`)
     - Module 5: Student Portal & Parent Access (`/api/student-portal/*`, `/api/parent/*`)
     - Module 6: System Admin, Storage & SMS Services (`/api/upload`, `/api/sms/*`, `/api/admin/*`)
     - Module 7: Notification System (`/api/notifications/*`)

3. **MANDATORY INTEGRITY WARNING**:
   DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

4. Write full handoff report to `c:\Development\academypro\.agents\worker_m3\handoff.md`.
