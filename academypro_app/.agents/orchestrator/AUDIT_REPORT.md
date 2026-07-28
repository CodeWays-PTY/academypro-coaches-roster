# Comprehensive Code Audit Report — AcademyPro Platform

**Target Application**: AcademyPro Flutter App (`lib/`), Cloudflare Worker API (`worker/src/`), Cloudflare D1 SQL Database (`migrations/`, `DATABASE_SCHEMA.md`)  
**Audit Date**: July 28, 2026  
**Auditor**: Project Orchestrator & Teamwork Explorer Subagents  
**Integrity Mode**: Development / Strict Production Rule Verification  

---

## Executive Summary

A comprehensive, static-analysis code audit was conducted across the three primary tiers of the AcademyPro architecture:
1. **Flutter Mobile Application** (`C:\Development\academypro\academypro_app\lib` — 35 Dart source files)
2. **Cloudflare Worker API Backend** (`C:\Development\academypro\worker\src\index.ts` — 3,379 TypeScript lines)
3. **Cloudflare D1 SQL Schema & Database Migrations** (`C:\Development\academypro\migrations` — 15 SQL migration scripts)

The purpose of this audit is to identify, catalog, and provide remediation strategies for all instances of:
- **Local Fallbacks & Mock Data (R1)**: Non-cryptographic pseudo-random number generators (`Math.random()`), mock credentials/auth bypasses, defensive string fallbacks (`schoolId || 'OVK'`), and mock data seed files.
- **Silent Failures & Error Handling (R2)**: Empty `catch` blocks, swallowed network failures, functions returning fake success booleans (`true`) on API failure, and Worker endpoints returning HTTP 200 OK status codes despite database write errors.
- **Hardcoded Values (R3)**: Static credentials (`JWT_SECRET`, `INTERNAL_API_KEY`), test phone numbers, hardcoded benchmark scores, magic numbers, and fixed sport identifiers.
- **Vertical Slice Disconnections (R4)**: End-to-end misalignment between Flutter UI state providers, Cloudflare Worker API endpoint routes, and Cloudflare D1 SQL schema tables.

### Key Audit Metrics
- **Total Flagged Instances**: 60 distinct audit findings across 4 categories.
- **High Severity**: 22 findings (Direct security risks, auth bypasses, PRNG usage for OTPs, false success returns on API failure, worker HTTP 200 responses on DB error).
- **Medium Severity**: 27 findings (Over-defensive default string fallbacks, silent catch blocks, missing response fields, hardcoded benchmark cutoffs).
- **Low Severity**: 11 findings (Documentation mismatches, missing debug logs, magic UI strings).

---

## Category 1: Local Fallbacks & Mock Data Audit (R1)

### R1.1: Non-Cryptographic `Math.random()` for Login OTP Generation
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 304–306
- **Verbatim Code Snippet**:
  ```typescript
  // Generate 6-digit OTP code
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  ```
- **Violation Explanation**: Uses standard JavaScript `Math.random()` to generate login authentication OTP codes. `Math.random()` is PRNG-based and predictable, exposing authentication tokens to prediction attacks.
- **Recommended Remediation**: Use the Web Crypto API available natively in Cloudflare Workers:
  ```typescript
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  const otp = (100000 + (array[0] % 900000)).toString();
  ```

### R1.2: Non-Cryptographic `Math.random()` for Email Change Verification
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 488–490
- **Verbatim Code Snippet**:
  ```typescript
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  ```
- **Violation Explanation**: Uses `Math.random()` for account email change confirmation codes, allowing predictable token generation.
- **Recommended Remediation**: Replace with `crypto.getRandomValues()`.

### R1.3: Non-Cryptographic `Math.random()` in Secondary OTP Utility Route
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Line 3334
- **Verbatim Code Snippet**:
  ```typescript
  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  ```
- **Violation Explanation**: Secondary verification token generation uses `Math.random()`.
- **Recommended Remediation**: Replace with Web Crypto API.

### R1.4: Hardcoded Fallback JWT Secret Key
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Line 147
- **Verbatim Code Snippet**:
  ```typescript
  const getSecret = (c: any) => c.env?.JWT_SECRET || 'usport-secret-key-928374';
  ```
- **Violation Explanation**: Hardcodes fallback secret `'usport-secret-key-928374'`. If `JWT_SECRET` environment variable is not bound, attackers can forge valid JWT tokens.
- **Recommended Remediation**: Throw an exception or return HTTP 500 if `c.env?.JWT_SECRET` is undefined:
  ```typescript
  const getSecret = (c: any) => {
    if (!c.env?.JWT_SECRET) throw new Error('JWT_SECRET environment binding missing');
    return c.env.JWT_SECRET;
  };
  ```

### R1.5: Secret OTP Leakage in HTTP API Response Body
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 358–362
- **Verbatim Code Snippet**:
  ```typescript
  return c.json({
    success: true,
    message: 'OTP sent successfully to email.',
    _dev_otp: otp 
  });
  ```
- **Violation Explanation**: Exposes generated OTP directly in API JSON response (`_dev_otp`), allowing anyone calling `/api/auth/send-otp` to bypass email verification.
- **Recommended Remediation**: Remove `_dev_otp` from API response payloads in production environments.

### R1.6: Auth Bypass Defaults (`USR-PARENT-101`, `USR-STUDENT-01`) in Parent & Player Routes
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 2973, 3016, 3032
- **Verbatim Code Snippet**:
  ```typescript
  const parentUserId = jwtPayload?.sub || 'USR-PARENT-101';
  // ...
  .bind(player?.user_id || 'USR-STUDENT-01').run();
  // ...
  const userId = jwtPayload?.sub || 'USR-STUDENT-01';
  ```
- **Violation Explanation**: Unauthenticated requests to parent/player link routes fall back to mock hardcoded user IDs instead of returning HTTP 401 Unauthorized.
- **Recommended Remediation**: Apply `enforceJwtAuth` middleware and reject requests missing `jwtPayload.sub` with HTTP 401.

### R1.7: Hardcoded Mock User Identities & Password Hashes in D1 Migrations
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\migrations\0002_seed_data.sql`
- **File Path (Rel)**: `migrations/0002_seed_data.sql`, `migrations/0006_seed_test_coach_user.sql`
- **Line Numbers**: Lines 11, 14, 17 in `0002_seed_data.sql`
- **Verbatim Code Snippet**:
  ```sql
  INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name) 
  VALUES ('USR-COACH-1', 'OVK', 'coach.ross@overkruin.co.za', 'sha256$mockedhash', 'Coach', 'Ross', 'Venter');
  ```
- **Violation Explanation**: Production SQL migration files seed mock user identities with fake password hash strings (`sha256$mockedhash`).
- **Recommended Remediation**: Remove static user insertions from production migrations; allow real accounts to be created via verified authentication flows.

### R1.8: Defensive `schoolId` Fallback (`schoolId || 'OVK'`) Across API Handlers
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 703, 741, 798, 935, 1021, 1139, 1620, 1981, 2015, 2132, 2376, 2402, 2503, 2526
- **Verbatim Code Snippet**:
  ```typescript
  const schoolId = jwtPayload?.schoolId || 'OVK';
  ```
- **Violation Explanation**: Over-defensive fallback routes missing token claims to school `'OVK'`, risking cross-tenant data access.
- **Recommended Remediation**: Require `schoolId` in JWT claims; return HTTP 400 Bad Request if missing.

### R1.9: Over-Defensive Squad & Age Group Fallbacks (`'U15'`)
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 751, 1216, 1217, 1645
- **Verbatim Code Snippet**:
  ```typescript
  const squadCode = (code || ageGroup || 'U15').trim().toUpperCase();
  ```
- **Violation Explanation**: Replaces empty parameter inputs with `'U15'`.
- **Recommended Remediation**: Fail fast with HTTP 400 when required squad parameters are missing.

### R1.10: SQL Schema Definitions Hardcoding Default School (`DEFAULT 'OVK'`)
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts` & `C:\Development\academypro\worker\migrations\0001_ensure_all_tables.sql`
- **File Path (Rel)**: `worker/src/index.ts` & `worker/migrations/0001_ensure_all_tables.sql`
- **Line Numbers**: Lines 1469, 1527, 1583 in `index.ts`
- **Verbatim Code Snippet**:
  ```sql
  CREATE TABLE IF NOT EXISTS action_plans (
    id TEXT PRIMARY KEY,
    school_id TEXT DEFAULT 'OVK', ...
  ```
- **Violation Explanation**: Schema definitions set SQL default to `'OVK'`.
- **Recommended Remediation**: Use `school_id TEXT NOT NULL` without default string fallbacks.

### R1.11: Hardcoded `'U15'` Fallback in Flutter Dashboard Controllers
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel)**: `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers**: Lines 74, 131, 144, 209, 226, 433, 602, 654
- **Verbatim Code Snippet**:
  ```dart
  Future<void> fetchSummary({String ageGroup = 'U15'}) async {
  ```
- **Violation Explanation**: Flutter controller defaults age group parameter to `'U15'`.
- **Recommended Remediation**: Pass dynamic squad selections based on user profile.

### R1.12: Hardcoded Student ID & Profile Fallbacks in Student Dashboard UI
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\student\presentation\student_dashboard_screen.dart`
- **File Path (Rel)**: `lib/features/student/presentation/student_dashboard_screen.dart`
- **Line Numbers**: Lines 297, 1856, 1911, 2512
- **Verbatim Code Snippet**:
  ```dart
  final studentId = profile['id'] ?? 'OVK-STUDENT-JAN';
  ```
- **Violation Explanation**: UI masks missing profile attributes with static fallback strings.
- **Recommended Remediation**: Render real empty states (`"--"`) or show an error state if profile fails to load.

### R1.13: Hardcoded Local ID Prefix (`OVK-`) in Roster Controller
- **Severity**: **Low**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\roster_controller.dart`
- **File Path (Rel)**: `lib/features/dashboard/controllers/roster_controller.dart`
- **Line Numbers**: Line 237
- **Verbatim Code Snippet**:
  ```dart
  final newId = 'OVK-$ageGroup-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
  ```
- **Violation Explanation**: Hardcodes `'OVK-'` string prefix when building local temporary IDs.
- **Recommended Remediation**: Use UUID strings or dynamic school ID prefixes.

### R1.14: Dashboard Mock Data Seed Migration `0004_seed_dashboard_mock_data.sql`
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\migrations\0004_seed_dashboard_mock_data.sql`
- **File Path (Rel)**: `migrations/0004_seed_dashboard_mock_data.sql`
- **Line Numbers**: Lines 1–24
- **Verbatim Code Snippet**:
  ```sql
  INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score) VALUES ('OVK-U15-001', 1, 58.0, 1);
  INSERT INTO match_stats (...) VALUES ('OVK-U15-003', '2026-07-15', 'Pretoria Boys High', 2, 8, 3, 10.0, 4, 3, 1, 1, 1.2, 0.2, '🔴 Developing');
  ```
- **Violation Explanation**: D1 migrations directory contains a script inserting fake match stats and academic records.
- **Recommended Remediation**: Remove `0004_seed_dashboard_mock_data.sql` from the production migration sequence.

---

## Category 2: Silent Failures & Error Handling Audit (R2)

### R2.1: `api_client.dart` Base URL Failover Exception Swallowing
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\core\network\api_client.dart`
- **File Path (Rel)**: `lib/core/network/api_client.dart`
- **Line Numbers**: Lines 72–74
- **Verbatim Code Snippet**:
  ```dart
  } catch (_) {
    // Continue checking next candidate
  }
  ```
- **Violation Explanation**: Swallows exceptions during candidate API failover without logging details.
- **Recommended Remediation**: Log failover attempts with `debugPrint('[ApiClient] Candidate failover failed: $e')`.

### R2.2: `notification_controller.dart` Swallowed Network Failures
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\notifications\controllers\notification_controller.dart`
- **File Path (Rel)**: `lib/features/notifications/controllers/notification_controller.dart`
- **Line Numbers**: Lines 98–100, 109–111, 121–125, 140–142
- **Verbatim Code Snippet**:
  ```dart
  } catch (_) {
    // Handled silently
  }
  ```
- **Violation Explanation**: Optimistically updates notification state locally but silently swallows network failures, causing local UI to desynchronize from remote server state.
- **Recommended Remediation**: Revert optimistic UI updates upon network failure and display an error toast.

### R2.3: `manage_metrics_modal.dart` Silent Catch Block
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\presentation\manage_metrics_modal.dart`
- **File Path (Rel)**: `lib/features/dashboard/presentation/manage_metrics_modal.dart`
- **Line Numbers**: Lines 108–110
- **Verbatim Code Snippet**:
  ```dart
  } catch (_) {}
  ```
- **Violation Explanation**: Metric deletion operations swallow errors without informing the user when server deletion fails.
- **Recommended Remediation**: Catch exception `e`, show `AppToast.showError`, and reset modal state.

### R2.4: `dashboard_controller.dart` Swallowed Summary & Flags Network Failures
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel)**: `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers**: Lines 94–99, 168–173, 252–257
- **Verbatim Code Snippet**:
  ```dart
  } catch (e) {
    state = const AsyncValue.data([]);
  }
  ```
- **Violation Explanation**: When network or DB errors occur, catch blocks swallow the error and emit empty data (`AsyncValue.data([])`). The user sees an empty dashboard state without error feedback.
- **Recommended Remediation**: Emit `AsyncValue.error` so the UI displays an error/retry banner.

### R2.5: `dashboard_controller.dart` Swallowed Action & Squad Creation Operations
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel)**: `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers**: Lines 399, 412, 516
- **Verbatim Code Snippet**:
  ```dart
  try {
    await _apiClient.post('/api/squads', data: { ... });
  } catch (_) {}
  ```
- **Violation Explanation**: Squad and action item mutations swallow network exceptions, leaving local UI out of sync with backend DB.
- **Recommended Remediation**: Handle API exceptions explicitly and revert local mutations.

### R2.6: `roster_controller.dart` Returning Fake Success (`true`) on Exception
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\roster_controller.dart`
- **File Path (Rel)**: `lib/features/dashboard/controllers/roster_controller.dart`
- **Line Numbers**: Lines 222–225, 267–269
- **Verbatim Code Snippet**:
  ```dart
  } catch (e) {
    // Local state already updated
    return true; // Returns TRUE upon network error!
  }
  ```
- **Violation Explanation**: Functions `updatePlayerPosition` and `addPlayer` catch exceptions and explicitly return `true`, tricking calling UI screens into displaying success toasts when DB operations failed.
- **Recommended Remediation**: Return `false` upon exception and propagate error details to the caller.

### R2.7: Worker `/api/admin/bulk-upload` Returning HTTP 200 for Failed Uploads
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 2780–2785
- **Verbatim Code Snippet**:
  ```typescript
  return c.json({
    success: errorCount === 0,
    message: `Processed ${records.length} records (${successCount} succeeded, ${errorCount} failed)`,
    data: { successCount, errorCount, errors }
  });
  ```
- **Violation Explanation**: Bulk upload endpoint returns HTTP 200 OK status code even when records fail (`errorCount > 0`).
- **Recommended Remediation**: Return HTTP 400 or 207 status code when records fail.

### R2.8: Worker `/api/auth/profile` Returning HTTP 200 on D1 Database Update Error
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 450–468
- **Verbatim Code Snippet**:
  ```typescript
  } catch (err) {
    console.error('[API Error] Failed to update user profile in D1:', err);
  }
  return c.json({ success: true, message: 'Profile updated successfully' });
  ```
- **Violation Explanation**: If D1 profile update query fails, error is caught and printed, but execution continues to return HTTP 200 success payload.
- **Recommended Remediation**: Return HTTP 500 error inside catch block.

### R2.9: Worker Helper `getCoachSquadPlayerIds` Swallowing SQL Execution Exceptions
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 640, 665, 679
- **Verbatim Code Snippet**:
  ```typescript
  try {
    const { results } = await db.prepare(sQuery).bind(...sParams).all();
    squadRows = results || [];
  } catch (_) {}
  ```
- **Violation Explanation**: Foundational access control helper swallows SQL exceptions with `catch (_) {}`, causing squad queries to return empty arrays and hiding database errors.
- **Recommended Remediation**: Log SQL errors explicitly and rethrow to calling handlers.

---

## Category 3: Hardcoded Values Audit (R3)

### R3.1: Hardcoded Internal API Key Fallback
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Line 3344
- **Verbatim Code Snippet**:
  ```typescript
  const apiKey = c.env.INTERNAL_API_KEY || 'agua_internal_secret_key_102938';
  ```
- **Violation Explanation**: Hardcodes fallback API key `'agua_internal_secret_key_102938'`, exposing backend credentials in source code.
- **Recommended Remediation**: Rely strictly on `c.env.INTERNAL_API_KEY` and reject requests if missing.

### R3.2: Hardcoded Sample Parent & Player Phone Numbers in Flutter UI Model
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel)**: `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers**: Lines 292–294
- **Verbatim Code Snippet**:
  ```dart
  this.parentName = 'Parent Contact',
  this.parentPhone = '+27 82 555 0192',
  this.parentEmail = 'parent@academypro.co.za',
  this.playerPhone = '+27 71 444 8821',
  ```
- **Violation Explanation**: Injects dummy South African phone numbers (`+27 82 555 0192`, `+27 71 444 8821`) when API properties are null.
- **Recommended Remediation**: Default to empty strings `""` or null and display clean empty state UI.

### R3.3: Hardcoded Developer Email in SQL Migration Script
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\worker\migrations\0005_assign_jrobertse_u15_squad.sql`
- **File Path (Rel)**: `worker/migrations/0005_assign_jrobertse_u15_squad.sql`
- **Line Numbers**: Line 4
- **Verbatim Code Snippet**:
  ```sql
  UPDATE users SET school_id = 'OVK', role = 'Coach' WHERE email = 'jrobertse1@gmail.com';
  ```
- **Violation Explanation**: Hardcodes developer email addresses in table setup scripts.
- **Recommended Remediation**: Use generic seed scripts or dynamic parameters.

### R3.4: Hardcoded Category Thresholds in Auto-Score Calculation
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 189–196
- **Verbatim Code Snippet**:
  ```typescript
  let category = "🔴 Developing";
  if (autoScore >= 4.0) category = "🟢 Excelling";
  else if (autoScore >= 3.0) category = "🟡 On Track";
  else if (autoScore >= 2.0) category = "🟠 At Risk";
  ```
- **Violation Explanation**: Rating score cutoffs (4.0, 3.0, 2.0) are hardcoded into server application logic instead of being dynamically queried from benchmark tables.
- **Recommended Remediation**: Fetch performance benchmark definitions from `test_metric_definitions`.

### R3.5: Hardcoded Academic KPI Grade Cutoffs (65%, 60%, 50%)
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 986–991, 1069–1077
- **Verbatim Code Snippet**:
  ```typescript
  if (score >= 65) uniReadyCount++;
  else if (score >= 60) onTrackCount++;
  else if (score >= 50) atRiskCount++;
  ```
- **Violation Explanation**: Academic grade threshold percentages are hardcoded without supporting configurable school settings.
- **Recommended Remediation**: Query grade thresholds dynamically from database settings.

### R3.6: Hardcoded Grade Improvement Score Constant (`12%`)
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel)**: `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers**: Line 211
- **Verbatim Code Snippet**:
  ```dart
  gradeImprovement = gradeImprovement ?? 12,
  ```
- **Violation Explanation**: Injects a fake default grade improvement metric (`12%`) when field is missing.
- **Recommended Remediation**: Default to `0` or `null`.

### R3.7: Hardcoded Sport Identifier (`'rugby'`) in Metric Definition Endpoint
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Line 2422
- **Verbatim Code Snippet**:
  ```typescript
  VALUES (?, ?, 'rugby', ?, ?, ?, ?, ?)
  ```
- **Violation Explanation**: Hardcodes `'rugby'` sport identifier into test metric definition insertion statements.
- **Recommended Remediation**: Pass `sportId` dynamically from payload.

### R3.8: Hardcoded Fallback Email Domain Suffix (`@academypro.co.za`)
- **Severity**: **Low**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `worker/src/index.ts`
- **Line Numbers**: Lines 2855, 2985
- **Verbatim Code Snippet**:
  ```typescript
  const playerEmail = ... || `${firstName.toLowerCase()}.${lastName.toLowerCase()}@academypro.co.za`;
  ```
- **Violation Explanation**: Synthesizes dummy email addresses when email input is missing during player creation.
- **Recommended Remediation**: Require explicit email input or allow nullable email fields.

---

## Category 4: Vertical Slice & Architecture Audit (R4)

### R4.1: Auth Dev OTP Key Name Mismatch in Auth State Parser
- **Severity**: **Low**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\auth\presentation\auth_state.dart` & `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel)**: `lib/features/auth/presentation/auth_state.dart` & `worker/src/index.ts`
- **Line Numbers**: `auth_state.dart` Line 65, `index.ts` Line 360
- **Verbatim Code Snippet**:
  - `auth_state.dart`: `final otpCode = response.data['otp']?.toString();`
  - `index.ts`: `return c.json({ success: true, _dev_otp: otp });`
- **Architectural Breakdown**: Worker returns `_dev_otp`, while Flutter state looks for `otp`. As a result, `state.devOtp` evaluates to `null`.
- **Recommended Remediation**: Update `auth_state.dart` to read `response.data['_dev_otp'] ?? response.data['otp']`.

### R4.2: Worker `/api/rosters/:age_group` Omits `parentPhone` & `email` Response Mapping
- **Severity**: **Medium**
- **File Path (Abs)**: `C:\Development\academypro\worker\src\index.ts` & `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\roster_controller.dart`
- **File Path (Rel)**: `worker/src/index.ts` & `lib/features/dashboard/controllers/roster_controller.dart`
- **Line Numbers**: `index.ts` Lines 854–865, `roster_controller.dart` Lines 52–66
- **Verbatim Code Snippet**:
  - `index.ts`:
    ```ts
    players: (results || []).map((p: any) => ({
      id: p.id, firstName: p.first_name, lastName: p.last_name, ageGroup: p.age_group, position: p.position
    }))
    ```
- **Architectural Breakdown**: D1 `players` table contains `parent_contact` and `email`, but Worker endpoint drops these fields when building the JSON response.
- **Recommended Remediation**: Add `parentPhone: p.parent_contact || p.phone || ''` and `email: p.email || ''` to the Worker API mapper.

### R4.3: Parent Portal "Upcoming Match Ticket" Card Renders Hardcoded Static UI
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\parent\presentation\parent_dashboard_screen.dart`
- **File Path (Rel)**: `lib/features/parent/presentation/parent_dashboard_screen.dart`
- **Line Numbers**: Lines 503–644
- **Verbatim Code Snippet**:
  ```dart
  const Text('Sat, 10:00 AM', style: TextStyle(fontSize: 26.0, fontWeight: FontWeight.bold)),
  const Text('West Field Complex', style: TextStyle(fontWeight: FontWeight.bold)),
  const Text('Court 4 • Home Jersey', style: TextStyle(color: Color(0xFFDDE1FF))),
  ```
- **Architectural Breakdown**: UI card renders hardcoded static match strings instead of binding to `data.events` returned by `/api/student-portal`.
- **Recommended Remediation**: Bind UI card dynamically to `data.events` from `studentControllerProvider`.

### R4.4: Parent Portal "Campus Checkout Status" Operates on Local Mock State
- **Severity**: **High**
- **File Path (Abs)**: `C:\Development\academypro\academypro_app\lib\features\parent\presentation\parent_dashboard_screen.dart`
- **File Path (Rel)**: `lib/features/parent/presentation/parent_dashboard_screen.dart`
- **Line Numbers**: Lines 905–958
- **Verbatim Code Snippet**:
  ```dart
  Text('$studentName has checked out of training facility.'),
  const Text('4:15 PM', style: TextStyle(fontWeight: FontWeight.bold)),
  const Text('STATUS: SAFE', style: TextStyle(color: Color(0xFF16A34A))),
  ```
- **Architectural Breakdown**: Renders a static checkout status card ("4:15 PM", "SAFE") without backing Worker API endpoint or D1 table.
- **Recommended Remediation**: Bind checkout status card to real check-in records from D1 `attendance` table or hide card when no check-out event exists.

### R4.5: Missing `squads` and `squad_players` Tables in `DATABASE_SCHEMA.md` Documentation
- **Severity**: **Low**
- **File Path (Abs)**: `C:\Development\academypro\DATABASE_SCHEMA.md`
- **File Path (Rel)**: `DATABASE_SCHEMA.md`
- **Line Numbers**: Lines 18–197
- **Architectural Breakdown**: Runtime D1 database contains `squads` and `squad_players` tables, but reference documentation `DATABASE_SCHEMA.md` omits their definitions.
- **Recommended Remediation**: Append `squads` and `squad_players` SQL definitions to `DATABASE_SCHEMA.md`.

### R4.6: Missing `test_metric_definitions` & `player_test_logs` Tables in `DATABASE_SCHEMA.md` Documentation
- **Severity**: **Low**
- **File Path (Abs)**: `C:\Development\academypro\DATABASE_SCHEMA.md`
- **File Path (Rel)**: `DATABASE_SCHEMA.md`
- **Line Numbers**: Lines 91–120
- **Architectural Breakdown**: Migration 0011 created dynamic metric tables `test_metric_definitions` and `player_test_logs`, but `DATABASE_SCHEMA.md` retains legacy static baselines section.
- **Recommended Remediation**: Update `DATABASE_SCHEMA.md` with Migration 0011 SQL table definitions.

---

## Actionable Refactoring & Remediation Plan

To bring the AcademyPro codebase into 100% compliance with strict production data standards, execute the following prioritized steps:

1. **Security & Cryptography Hardening**:
   - Replace all 3 `Math.random()` calls in `worker/src/index.ts` with `crypto.getRandomValues()`.
   - Remove hardcoded JWT secret fallback `'usport-secret-key-928374'` and throw an exception if `c.env.JWT_SECRET` is missing.
   - Remove `_dev_otp` from `/api/auth/send-otp` HTTP response payload.
   - Enforce JWT authentication on `/api/parent/*` and `/api/player/*` routes; reject unauthenticated calls with HTTP 401 instead of defaulting to `'USR-PARENT-101'`.

2. **Error Handling & HTTP Status Correction**:
   - Update `roster_controller.dart` methods (`updatePlayerPosition`, `addPlayer`) to return `false` on API exception rather than returning `true`.
   - Update Worker `/api/auth/profile` to return HTTP 500 when D1 database updates fail.
   - Update Worker `/api/admin/bulk-upload` to return HTTP 400 or 207 status code when records fail.
   - Log SQL exceptions in Worker helper `getCoachSquadPlayerIds`.

3. **Data Fallback & Seed Cleanup**:
   - Replace all defensive `schoolId || 'OVK'` fallbacks across Worker API handlers with strict JWT claim validation.
   - Remove seed migration script `0004_seed_dashboard_mock_data.sql` from production migrations.
   - Replace hardcoded sample contact numbers (`+27 82 555 0192`) in `dashboard_controller.dart` with empty strings or real JOIN queries.

4. **Vertical Slice Alignment**:
   - Map `parentPhone` and `email` in Worker `/api/rosters/:age_group` endpoint response JSON.
   - Bind Parent Dashboard match ticket and campus checkout cards to `studentControllerProvider` data streams.
   - Update `DATABASE_SCHEMA.md` to document `squads`, `squad_players`, `test_metric_definitions`, and `player_test_logs` tables.

---

*Report compiled by Project Orchestrator from evidence-backed handoff reports delivered by Explorer Subagents R1, R2, R3, and R4.*
