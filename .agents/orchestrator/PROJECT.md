# Project: Codebase Audit & Dead-Code Elimination

## Architecture
- Backend API: Cloudflare Worker (`worker/src/index.ts`) with D1 SQL integration
- Flutter Frontend: `academypro_app/` mobile client (Dart / Flutter)
- Web Admin Portal: `web_admin/` (HTML / JS)
- API Documentation: `API_SPECIFICATION.md`

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | Backend API Audit & Pruning | Audit `worker/src/index.ts`, prune dead endpoints, compile TypeScript & deploy via `wrangler deploy` | None | DONE |
| 2 | Flutter App Audit & Pruning | Audit `academypro_app`, prune dead screens, widgets, models, controllers & functions, pass `flutter analyze` | M1 | DONE |
| 3 | Web Admin & API Spec Sync | Audit `web_admin` HTML/JS, remove obsolete code, update `API_SPECIFICATION.md` to reflect active routes | M1, M2 | DONE |

## Interface Contracts
### Client ↔ Worker API
- Pruned 12 dead/legacy endpoints from `worker/src/index.ts` (~226 lines removed).
- Retained and verified all active routes used by `academypro_app` (including POST delete aliases) and `web_admin`.
- Live Worker deployed to `https://academypro-api.tata-elash34.workers.dev` (Version ID: `dedf1d02-e6b9-42cd-8bab-7ccf201ad570`).

## Code Layout
- `worker/src/index.ts` - Cloudflare Worker API entrypoint
- `academypro_app/lib/` - Flutter mobile application codebase
- `web_admin/` - Web admin HTML & JS portal
- `API_SPECIFICATION.md` - API documentation
