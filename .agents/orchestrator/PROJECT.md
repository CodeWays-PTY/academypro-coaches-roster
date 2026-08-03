# Project: Codebase Audit & Dead-Code Elimination

## Architecture
- Backend API: Cloudflare Worker (`worker/src/index.ts`) with D1 SQL integration
- Flutter Frontend: `academypro_app/` mobile client (Dart / Flutter)
- Web Admin Portal: `web_admin/` (HTML / JS)
- API Documentation: `API_SPECIFICATION.md`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Backend API Audit & Pruning | Audit `worker/src/index.ts`, prune dead endpoints, compile TypeScript & deploy via `wrangler deploy` | None | PLANNED |
| 2 | Flutter App Audit & Pruning | Audit `academypro_app`, prune dead screens, widgets, models, controllers & functions, pass `flutter analyze` | M1 | PLANNED |
| 3 | Web Admin & API Spec Sync | Audit `web_admin` HTML/JS, remove obsolete code, update `API_SPECIFICATION.md` to reflect active routes | M1, M2 | PLANNED |

## Interface Contracts
### Client ↔ Worker API
- All endpoints pruned from `worker/src/index.ts` must be verified as unreferenced by `academypro_app`, `web_admin`, and automated seed scripts.
- Active routes must retain their standard parameters, payload schemas, and response formats.
- `API_SPECIFICATION.md` must accurately document all active routes post-cleanup.

## Code Layout
- `worker/src/index.ts` - Cloudflare Worker API entrypoint
- `academypro_app/lib/` - Flutter mobile application codebase
- `web_admin/` - Web admin HTML & JS portal
- `API_SPECIFICATION.md` - API documentation
