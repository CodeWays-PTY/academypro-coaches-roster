# uSPORT Player Development Tracker — Project Implementation Plan

## 1. Timeline & Milestone Overview

The project is structured as a **14-week** agile delivery roadmap, split into 5 phases. The goal is to build the backend infrastructure, launch the Web Admin portal, deliver the Coach Mobile App MVP, and finally ship the Student Dashboard.

```
Weeks:   1-3         4-6             7-10             11-12         13-14
       [Phase 1]   [Phase 2]       [Phase 3]        [Phase 4]     [Phase 5]
       Backend &   Web Admin &    Coach Mobile App   Student App    UAT & Go-Live
       Schema      CSV Ingest     & Offline Sync    & Visuals     (Overkruin)
```

---

## 2. Detailed Phase Breakdown

### Phase 1: Infrastructure & API Foundation (Weeks 1 - 3)
* **Goal:** Set up Cloudflare services, design the SQL schema, and implement the core backend API.
* **Tasks:**
  * Provision the Cloudflare D1 SQL database and write database migration files.
  * Initialize the Hono API framework in TypeScript running on Cloudflare Workers.
  * Configure wrangler environment settings (D1 bindings, Workers KV namespaces, and R2 buckets).
  * Build core authentication routes (JWT-based token issuance, secure password hashing, and user role validation).
  * Write the TypeScript algorithm for the Auto-Score calculation (see `AUTO_SCORE_SPEC.md`).
* **Deliverables:**
  * Active D1 database instance.
  * Hono API routes deployed to a staging Cloudflare Worker.
  * Automated backend test suite validating the Auto-Score formula.

---

### Phase 2: Web Admin & Data Ingestion (Weeks 4 - 6)
* **Goal:** Build the office portal for school administrators and import historical student records.
* **Tasks:**
  * Construct the Web Admin portal using HTML5, Alpine.js, and Tailwind CSS.
  * Build the School Admin Dashboard for team roster management and coach assignments.
  * Implement the **Bulk CSV Ingestion Engine** with drag-and-drop file upload.
  * Write the Alpine.js CSV parser and mapping logic to feed the Hono `/api/admin/bulk-upload` endpoint.
  * Load Hoërskool Overkruin's 53 U14–U16 players and baseline fitness records into the live D1 database.
* **Deliverables:**
  * Web Admin Portal deployed to Cloudflare Pages.
  * Fully functional CSV importer handling student registers, academic grades, and fitness baseline sheets.
  * Database loaded with active student accounts.

---

### Phase 3: Coach Mobile App MVP (Weeks 7 - 10)
* **Goal:** Build the core mobile app for coaches to log stats on the field.
* **Tasks:**
  * Initialize the Flutter project, establish state management (Riverpod/BLoC), and apply the sunlight-optimized theme.
  * Implement authentication login flows connecting to the Cloudflare Worker API.
  * Build the **"Tap & Go" Match Stats** screen (plus/minus digital clickers next to player lists, following [COACH_APP_DESIGN_SPEC.md](file:///C:/development/usport-player-tracker/COACH_APP_DESIGN_SPEC.md)).
  * Implement the **Smart Swipe Attendance** system for gym sessions and uGroups.
  * Integrate offline storage (Hive/SQLite) to queue updates when offline, syncing automatically via a Hono sync service.
  * Implement the "Flagged Players" dashboard and Coach Command Center (following [COACH_APP_DESIGN_SPEC.md](file:///C:/development/usport-player-tracker/COACH_APP_DESIGN_SPEC.md)).
* **Deliverables:**
  * iOS TestFlight and Android Google Play Console internal testing builds.
  * Offline-first logging functionality.
  * Live sync engine.

---

### Phase 4: Student & Parent Portals (Weeks 11 - 12)
* **Goal:** Build the student-athlete and parent portals to view personal and child metrics.
* **Tasks:**
  * Create the Student & Parent login and verification flows (linking to student records via Player ID or Parent ID).
  * Develop the Student Journey Dashboard, Bento sections, and Weekly Volume charts (following [STUDENT_PARENT_DESIGN_SPEC.md](file:///C:/development/usport-player-tracker/STUDENT_PARENT_DESIGN_SPEC.md)).
  * Develop the Parent Overview Hub featuring the ticket-cutout Match Card and segmented development metrics (following [STUDENT_PARENT_DESIGN_SPEC.md](file:///C:/development/usport-player-tracker/STUDENT_PARENT_DESIGN_SPEC.md)).
  * Integrate `fl_chart` to render animated progress lines (fitness PBs, weight trends) and custom bar charts for training volume.
  * Build the "Peace of Mind" feed (fetching D1 facility checkout logs and coach remark records).
  * Implement the "Small Wins" notification engine (fetching automated prompts from KV/D1).
* **Deliverables:**
  * Student and Parent Portal views in the mobile app.
  * Animated development charts and telemetry feeds.
  * Calendar integration action triggers.

---

### Phase 5: QA, UAT & Pilot Go-Live (Weeks 13 - 14)
* **Goal:** Run user acceptance testing and deploy to production for the pilot school.
* **Tasks:**
  * Conduct outdoor UAT: Test the mobile app on the field under direct sunlight to verify UI contrast, readability, and button clickability.
  * Perform "airplane mode" field tests to verify that data cached offline does not corrupt, and merges correctly upon reconnection.
  * Train 2-3 Hoërskool Overkruin coaches on the Match Day tracker and Attendance tracker.
  * Submit the production apps to the Apple App Store and Google Play Store.
* **Deliverables:**
  * Live mobile applications on App Stores.
  * uSPORT platform actively operating for Hoërskool Overkruin's season.

---

## 3. Git Workflow & Automated Deployment

To ensure stable and rapid iterations, the following git standards must be maintained:
* **Feature Branching:** All work must proceed on feature branches (e.g. `feature/auto-score-engine`) and be merged via Pull Requests.
* **Continuous Integration (CI):** Merges to `main` trigger automated builds of the Web App on Cloudflare Pages and execute tests on the Hono Worker.
* **Automated Commits & Pushes:** Upon completing distinct deliverables during local execution, the development agent must stage (`git add .`), commit with a descriptive, human-readable message (e.g., `git commit -m "Initialize D1 SQL schema and migrate baseline players"`), and push to the active remote branch unless explicitly asked not to.
