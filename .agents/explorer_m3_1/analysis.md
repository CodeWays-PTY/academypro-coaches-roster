# Technical Audit Analysis: `web_admin`

**Date**: 2026-08-03  
**Target Directory**: `c:\Development\academypro\web_admin`  
**Files Audited**: `web_admin/index.html` (572 lines), `web_admin/uploader.html` (726 lines)

---

## 1. Scope & Asset Architecture
The `web_admin` module contains 2 HTML files:
- `index.html` (33.3 KB) – Training Template Configurator
- `uploader.html` (42.5 KB) – Zero-Admin Bulk Uploader

No local external `.js` or `.css` files exist within `web_admin/`. All styling is powered by Tailwind CDN (`cdn.tailwindcss.com?plugins=forms,container-queries`), while libraries (XLSX, PapaParse, Alpine.js) are loaded via jsDelivr CDN.

---

## 2. API Endpoint Audit

### `index.html` Fetch Calls:
1. **Roster Fetch** (`index.html:150`):
   ```javascript
   const res = await fetch(`${apiBase}/api/admin/all-players`);
   ```
   - **Worker Route**: `app.get('/api/admin/all-players')` (`worker/src/index.ts:2757`)
   - **Status**: **ACTIVE & VALID**. Returns JSON roster list `{ success: true, data: [...] }`.

2. **Sports Config Fetch** (`index.html:159`):
   ```javascript
   const sportsRes = await fetch(`${apiBase}/api/admin/sports-config`);
   ```
   - **Worker Route**: `app.get('/api/admin/sports-config')` (`worker/src/index.ts:3081`)
   - **Status**: **ACTIVE & VALID**. Returns sports configuration rules `{ success: true, data: [...] }`.

### `uploader.html` Fetch Calls:
1. **Roster Fetch** (`uploader.html:157`):
   ```javascript
   const res = await fetch(`${apiBase}/api/admin/all-players`);
   ```
   - **Worker Route**: `app.get('/api/admin/all-players')` (`worker/src/index.ts:2757`)
   - **Status**: **ACTIVE & VALID**. Used for ID validation in file parser.

2. **Bulk Ingestion Commit** (`uploader.html:411`):
   ```javascript
   const res = await fetch(`${apiBase}/api/admin/bulk-upload`, {
       method: 'POST',
       headers: { 'Content-Type': 'application/json' },
       body: JSON.stringify({ records: validRecords })
   });
   ```
   - **Worker Route**: `app.post('/api/admin/bulk-upload')` (`worker/src/index.ts:2980`)
   - **Status**: **ACTIVE & VALID**. Processes array of athlete performance metrics and updates D1 `player_test_logs` and `academic_logs`.

### API Audit Conclusion:
**Zero dead or obsolete API endpoints are referenced in `web_admin`.** All 3 endpoint paths match active, production Cloudflare Worker API routes.

---

## 3. Unused JavaScript State & Dead Functions

### `index.html`:
- **Orphaned `loading` State**:
  - `loading: false` declared at line 142.
  - `this.loading = true` at line 146 and `this.loading = false` at line 199.
  - **Issue**: There is **no loading indicator element** (`x-show="loading"`) in `index.html` template. `loading` is dead state logic.
  - **Action**: Either remove `loading` property or add a visual spinner overlay like `uploader.html`.

### `uploader.html`:
- All Alpine data properties and methods (`init`, `totalPages`, `displayedRows`, `totalCount`, `validCount`, `errorCount`, `showToast`, `handleFileDrop`, `handleFileSelect`, `handleFile`, `processRawData`, `runValidation`, `fixRow`, `saveFix`, `mergeDuplicate`, `confirmUpload`) are actively referenced by UI directives.

---

## 4. External Script & Plugin Audit

- **`@alpinejs/collapse` Plugin Script**:
  - `index.html:298`: `<script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/collapse@3.14.0/dist/cdn.min.js"></script>`
  - `uploader.html:437`: `<script defer src="https://cdn.jsdelivr.net/npm/@alpinejs/collapse@3.14.0/dist/cdn.min.js"></script>`
  - **Issue**: `x-collapse` directive is **not used** anywhere in `index.html` or `uploader.html`.
  - **Note**: Alpine.js Protocol rules specify loading collapse plugin before core Alpine.js. If `x-collapse` is not required for any animated dropdown/modal accordion, this script load can be pruned to save an extra CDN network request.

---

## 5. Dead / Unwired UI Controls & Event Listeners

### `index.html`:
1. **Sidebar "Quick Action" Button** (line 346):
   `<button class="...">Quick Action</button>` — Has no `@click` or `onclick` listener.
2. **Top Header "notifications" Button** (line 377):
   `<button class="...">notifications</button>` — Unwired icon button.
3. **Top Header "help" Button** (line 380):
   `<button class="...">help</button>` — Unwired icon button.
4. **Top Header Search Input** (line 374):
   `<input ... placeholder="Search templates..."/>` — Unwired search input (no `x-model` or search handler).
5. **"Save as Draft" Button** (line 403):
   `<button class="...">Save as Draft</button>` — Unwired button (no draft save handler).

### `uploader.html`:
1. **Top Header Search Input** (line 514):
   `<input ... placeholder="Find previous logs..."/>` — Unwired input.
2. **Top Header "notifications" Button** (line 517):
   `<button class="...">notifications</button>` — Unwired button.
3. **Top Header "help" Button** (line 520):
   `<button class="...">help</button>` — Unwired button.
4. **Top Header "New..." Button** (line 523):
   `<button class="...">New...</button>` — Unwired button.
5. **Mode Switcher Toggle Buttons** (lines 539-540):
   `<button class="...">CSV/Excel</button><button class="...">API Sync</button>` — Static UI tabs with no click handler or view switcher logic.
6. **Hardcoded Mock Avatars & Initial Copy** (lines 665-669):
   `<div class="flex -space-x-2"><div ...>AR</div><div ...>SJ</div><div ...>LM</div></div>` — Hardcoded mock team initials.

---

## 6. Dead Navigation Links (`href="#"`)

### `index.html`:
- **Sidebar Links**:
  - Line 312: `href="#"` (SaaS Dashboard)
  - Line 316: `href="#"` (Tenant Manager)
  - Line 324: `href="#"` (Dashboard)
  - Line 332: `href="#"` (Team Builder)
  - Line 336: `href="#"` (Player Directory)
  - Line 340: `href="#"` (Reports)
  - Line 351: `href="#"` (Settings)
  - Line 355: `href="#"` (Support)
- **Header Link**:
  - Line 368: `href="#"` (Onboard School)

### `uploader.html`:
- **Sidebar Links**:
  - Line 456: `href="#"` (SaaS Dashboard)
  - Line 460: `href="#"` (Tenant Manager)
  - Line 472: `href="#"` (Team Builder)
  - Line 476: `href="#"` (Player Directory)
  - Line 480: `href="#"` (Reports)
- **Header Link**:
  - Line 507: `href="#"` (Onboard School)

---

## Recommended Dead-Code Pruning & Cleanup Actions

1. **Add `x-show="loading"` Spinner to `index.html`**:
   Add a loading indicator block to `index.html` matching `uploader.html` line 569 to utilize the existing `loading` state, or prune `loading` references from `configurator()`.
2. **Wire or Prune Unwired UI Buttons**:
   Attach click event handlers or explicit disabled attributes to unwired buttons ("Save as Draft", "Quick Action", "New...", Mode Switcher).
3. **Bind Search Inputs**:
   Connect search inputs to list filtering logic or remove placeholder inputs.
4. **Standardize Navigation Routing**:
   Replace `href="#"` with active routes or valid empty route anchors (`href="javascript:void(0)"`).
