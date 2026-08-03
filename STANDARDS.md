# AcademyPro Architectural Standard: Real-Time Sync & Zero-Cost ETag Edge Caching

## 1. Executive Summary
This document establishes the official engineering standard for data persistence, real-time client updates, and edge-caching across the **AcademyPro** ecosystem (**Cloudflare Workers API**, **Cloudflare D1 Database**, **Cloudflare Pages Web App**, and **Flutter Mobile Application**).

The objective is to provide **instant, live synchronization** when admins create or update records (e.g., events, squads, test scores) while maintaining **zero-cost resource usage** on Cloudflare via HTTP `ETag` validation and CDN edge caching.

---

## 2. Core Architectural Pillars

```
+------------------------+      POST /api/dashboard/events      +---------------------------+
|  Admin Web Dashboard   |  --------------------------------->  |   Cloudflare Worker API   |
| (Cloudflare Pages App) |                                      |  (academypro-api)         |
+------------------------+                                      +---------------------------+
                                                                             |
                                                                             | Direct D1 SQL
                                                                             v
+------------------------+      HTTP GET + If-None-Match        +---------------------------+
|   Flutter Mobile App   |  --------------------------------->  |   Cloudflare D1 Database  |
|  (20s Silent Poll)     |  <---------------------------------  |      (academypro-db)      |
+------------------------+      HTTP 304 (0 Bytes / 0 DB Reads) +---------------------------+
```

---

## 3. Standard Specifications

### Pillar A: Backend Database & REST API (`academypro-api`)

1. **Direct Cloudflare D1 Persistence**:
   - Every domain record (**coaches**, **athletes**, **squads**, **squad_members**, **events**, **event_checkins**, **test_metrics**, **test_results**, **custom_actions**, **student_otps**) MUST be persisted directly in Cloudflare D1.
   - Client applications MUST NOT store domain entity arrays in `localStorage` or offline fallbacks.

2. **ETag Generation & HTTP 304 Not Modified**:
   - Every list/feed endpoint (e.g., `GET /api/dashboard/events`) MUST generate a deterministic `ETag` header:
     ```javascript
     const etag = `W/"evt-${events.length}-${events[0]?.id || 'none'}-${events[0]?.date || ''}"`;
     const clientEtag = request.headers.get('if-none-match');

     if (clientEtag && clientEtag === etag) {
       return new Response(null, {
         status: 304,
         headers: {
           ...corsHeaders,
           'ETag': etag,
           'Cache-Control': 'public, max-age=10, s-maxage=30, stale-while-revalidate=60'
         }
       });
     }
     ```
   - When data has not changed, the Worker returns `304 Not Modified` with a `null` body. Cloudflare CDN serves this check at the edge, resulting in **0 database reads** and **0 payload transfer**.

3. **HTTP Cache-Control Headers**:
   - All response headers MUST include `Cache-Control: public, max-age=10, s-maxage=30, stale-while-revalidate=60`.

---

### Pillar B: Flutter Mobile Application (`academypro_app`)

1. **20-Second Silent Background Polling**:
   - State Notifiers (`DashboardEventsNotifier`, `StudentController`) MUST maintain a 20-second silent background polling timer:
     ```dart
     _pollingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
       fetchEvents(silent: true);
     });
     ```
   - Silent polling MUST NOT reset UI state to loading (`AsyncValue.loading()`), ensuring a smooth 60/120 FPS user experience with zero UI flickers.

2. **Lifecycle-Aware Timer Cleanup (Dispose Protocol)**:
   - Polling timers MUST be cancelled when screens/notifiers are disposed to prevent memory leaks and background resource drain:
     ```dart
     @override
     void dispose() {
       _pollingTimer?.cancel();
       super.dispose();
     }
     ```

3. **App Resume Sync (`WidgetsBindingObserver`)**:
   - Screens MUST listen to `AppLifecycleState.resumed` to immediately re-sync data from Cloudflare D1 whenever the app returns from the background.

---

### Pillar C: Web Admin App (`academypro-coaches-roster`)

1. **Immediate Vertical Slice Mutation**:
   - Every creation, update, or deletion handler (e.g., `saveEventFromCreator`, `deleteEvent`, `createSquad`) MUST issue an immediate HTTP `POST`, `PUT`, or `DELETE` API network call to Cloudflare Workers and re-fetch clean state.
2. **Purge Offline Entity Fallbacks**:
   - `localStorage` MUST ONLY be used for user session preferences (`loggedInCoach` identity and active `currentSquad` filter). Entity array setters (`saveEventsToStorage`, `saveSquadsToStorage`, etc.) MUST remain inactive empty stubs.

---

## 4. Verification Checklist for Developers & AI Agents

- [x] All 10 database tables exist in `schema.sql` and remote D1 `academypro-db`.
- [x] Worker REST API endpoints return `ETag` and `Cache-Control` headers.
- [x] Web Admin App triggers `POST`/`DELETE` API network calls on all user mutations.
- [x] Flutter App uses 20-second silent polling timers with lifecycle disposal.
- [x] App background resumption re-syncs state immediately.
- [x] All changes committed and pushed to remote GitHub `main` branches.
