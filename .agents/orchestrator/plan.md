# Execution Plan: Codebase Audit & Dead-Code Elimination

## Objectives
1. **Backend API (`worker/src/index.ts`)**: Identify and remove uncalled/dead API endpoints. Ensure TypeScript compilation passes and deploy via `wrangler deploy`.
2. **Flutter Frontend (`academypro_app`)**: Identify and prune dead screens, widgets, models, controllers, unused functions, and unused imports. Ensure `flutter analyze` passes with 0 errors and 0 warnings.
3. **Web Admin & Documentation (`web_admin` & `API_SPECIFICATION.md`)**: Audit `web_admin` HTML/JS for obsolete script references and dead endpoints. Update `API_SPECIFICATION.md` to reflect all remaining active routes.

---

## Milestone 1: Backend API Endpoints Audit & Pruning (`worker/src/index.ts`)
- **Phase 1A: Exploration & Static Route Mapping**
  - Explorer scans `worker/src/index.ts` for all route definitions.
  - Cross-references all routes against `academypro_app/lib/`, `web_admin/`, and seed/test scripts to identify truly active vs dead/legacy routes.
  - Output: `dead_api_routes.md` listing endpoints to prune and active endpoints to preserve.
- **Phase 1B: Implementation & Deployment**
  - Worker prunes identified dead routes from `worker/src/index.ts`.
  - Worker runs TypeScript type checking / compilation (`npx tsc --noEmit` or `npm run build`).
  - Worker executes `wrangler deploy` to deploy the clean Worker to remote Cloudflare.
- **Phase 1C: Verification & Audit**
  - Reviewers (2) review diffs and build/deploy outputs.
  - Challengers (2) empirically verify API route health and active endpoint compatibility.
  - Forensic Auditor performs integrity check (no dummy fallbacks, authentic code removal).
  - Gate check.

---

## Milestone 2: Flutter App Audit & Dead-Code Elimination (`academypro_app`)
- **Phase 2A: Exploration & Dead-Code Scan**
  - Explorer scans `academypro_app/lib/` for unreferenced files (screens, widgets, models, controllers, services) and dead functions/variables.
  - Uses static analysis insights and grep tools to confirm zero references.
  - Output: `dead_flutter_code.md` listing files and code chunks to remove.
- **Phase 2B: Implementation & Static Analysis**
  - Worker safely removes dead files and unused functions/imports.
  - Worker runs `flutter analyze` to ensure 0 errors and 0 warnings.
- **Phase 2C: Verification & Audit**
  - Reviewers (2) verify code changes and `flutter analyze` results.
  - Challengers (2) independently run `flutter analyze` and check app integrity.
  - Forensic Auditor performs integrity check.
  - Gate check.

---

## Milestone 3: Web Admin Audit & API Specification Alignment
- **Phase 3A: Exploration & Alignment Scan**
  - Explorer scans `web_admin/index.html` and `web_admin/uploader.html` for obsolete JS or dead endpoint calls.
  - Explorer compares active Worker endpoints against `API_SPECIFICATION.md`.
- **Phase 3B: Implementation & Spec Update**
  - Worker updates `web_admin` files to remove obsolete code.
  - Worker updates `API_SPECIFICATION.md` to document active endpoints cleanly.
- **Phase 3C: Verification & Audit**
  - Reviewers (2) check `web_admin` and `API_SPECIFICATION.md`.
  - Challengers (2) verify spec completeness and HTML/JS cleanliness.
  - Forensic Auditor performs final integrity check across all milestones.
  - Gate check & Final Sentinel Notification.
