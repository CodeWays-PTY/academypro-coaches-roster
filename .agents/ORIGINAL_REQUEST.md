# Original User Request

## 2026-08-03T11:10:07Z

Perform a comprehensive codebase audit to identify and eliminate unused, dead, and redundant API endpoints in Cloudflare Worker (`worker/src/index.ts`) as well as unused frontend screens, widgets, controllers, and functions in `academypro_app` (Flutter) and `web_admin`.

Working directory: c:\Development\academypro

## Audit Scope & Targets

1. **Backend API Endpoints Audit (`worker/src/index.ts`)**:
   - Identify legacy, uncalled, or duplicate API routes (e.g. legacy `/api/athletes`, `/api/coaches`, `/api/test-results` superseded by `/api/school/players`, `/api/test-metrics`, `/api/test-logs`).
   - Prune unreferenced endpoints while preserving active API routes used by `academypro_app`, `web_admin`, and automated seed scripts.
   - Verify TypeScript compilation and deploy clean Worker via `wrangler deploy`.

2. **Flutter Frontend Codebase Audit (`academypro_app`)**:
   - Scan `lib/features/` (`auth`, `dashboard`, `notifications`, `parent`, `student`) and `lib/core/` for unreferenced widgets, dead screens, unused models, orphaned controller methods, and dead helper utilities.
   - Remove dead code safely while preserving active UI routes and state management.
   - Validate Flutter codebase integrity with `flutter analyze`.

3. **Web Admin Audit (`web_admin`)**:
   - Audit `web_admin/index.html` and `web_admin/uploader.html` to remove obsolete script references or orphaned API integrations.

## Requirements

### R1. Worker API Pruning & Verification
Audit `worker/src/index.ts` to identify and remove dead/uncalled API routes that are no longer invoked by any client application or internal service. Ensure all remaining active endpoints pass TypeScript compilation and deploy to Cloudflare Workers.

### R2. Flutter App Code Pruning & Static Analysis
Audit `academypro_app/lib/` for unused classes, dead functions, unreferenced widgets, and orphaned models/controllers. Remove dead code and verify that `flutter analyze` passes with zero errors and zero warnings.

### R3. Web Admin & Documentation Alignment
Audit `web_admin` files for dead endpoints or orphaned JS functions. Update `API_SPECIFICATION.md` to document only the active, clean API routes.

## Acceptance Criteria

### API Integrity
- [ ] `worker/src/index.ts` builds cleanly without TypeScript compiler errors.
- [ ] Live Cloudflare Worker deployment succeeds (`wrangler deploy`).
- [ ] No active frontend API calls break due to endpoint pruning.

### Flutter App Cleanliness
- [ ] All unreferenced files, unused functions, and dead models in `academypro_app` are safely removed.
- [ ] `flutter analyze` completes with 0 errors and 0 warnings.
- [ ] All primary user workflows (Coach Dashboard, Student Portal, Parent Linking, Notifications) remain 100% operational.
