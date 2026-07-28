# Handoff Report — Requirement 1 (R1: Local Fallback & Mock Data Audit)

## 1. Observation

A comprehensive code audit was conducted across the AcademyPro project repository to identify violations of strict production rules regarding mock data, pseudo-random generators, defensive string fallbacks, mock user credentials, and fallback arrays.

### Target Paths Scanned:
1. **Flutter App Dart Files**: `C:\Development\academypro\academypro_app\lib`
2. **Worker API TypeScript/JS Files**: `C:\Development\academypro\worker\src\index.ts`
3. **D1 Migrations & Schema**: `C:\Development\academypro\migrations`, `C:\Development\academypro\worker\migrations`, `C:\Development\academypro\DATABASE_SCHEMA.md`

Below is the catalog of all flagged instances organized by category.

---

### Category A: Seeded Pseudo-Random Generators (`Math.random()`, `Random()`)

#### Finding A-1: Non-Cryptographic `Math.random()` for Login OTP Generation
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Lines 304-306
- **Verbatim Code Snippet**:
```typescript
  // Generate 6-digit OTP code
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
```
- **Severity**: **High**
- **Violation Explanation**: Uses standard JavaScript `Math.random()` to generate authentication OTP codes. `Math.random()` is PRNG-based and predictable, allowing potential brute-force or token prediction attacks.
- **Recommended Concrete Remediation**: Replace with Web Crypto API available natively in Cloudflare Workers:
```typescript
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  const otp = (100000 + (array[0] % 900000)).toString();
```

#### Finding A-2: Non-Cryptographic `Math.random()` for Email Change OTP Verification
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Lines 488-490
- **Verbatim Code Snippet**:
```typescript
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
```
- **Severity**: **High**
- **Violation Explanation**: Uses `Math.random()` for generating verification codes required to update primary account email addresses. Predictable OTP tokens compromise account ownership verification.
- **Recommended Concrete Remediation**: Use `crypto.getRandomValues()` to generate 6-digit security codes securely.

#### Finding A-3: Non-Cryptographic `Math.random()` in Legacy/Utility OTP Route
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Line 3334
- **Verbatim Code Snippet**:
```typescript
  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
```
- **Severity**: **High**
- **Violation Explanation**: Uses `Math.random()` for generating secondary verification tokens.
- **Recommended Concrete Remediation**: Replace with secure cryptographically strong random integer generation via Web Crypto API (`crypto.getRandomValues()`).

---

### Category B: Hardcoded Mock Credentials, Identities & Auth Bypasses

#### Finding B-1: Hardcoded Fallback JWT Secret Key
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Line 147
- **Verbatim Code Snippet**:
```typescript
// Helper for JWT Secret Key
const getSecret = (c: any) => c.env?.JWT_SECRET || 'usport-secret-key-928374';
```
- **Severity**: **High**
- **Violation Explanation**: Hardcodes a fallback JWT signing secret (`'usport-secret-key-928374'`) when `JWT_SECRET` environment variable is not defined in Wrangler bindings. If deployed without setting secret bindings, attackers could sign arbitrary valid JWT tokens.
- **Recommended Concrete Remediation**: Fail fast by throwing an exception or returning HTTP 500 if `c.env?.JWT_SECRET` is missing:
```typescript
const getSecret = (c: any) => {
  if (!c.env?.JWT_SECRET) throw new Error('JWT_SECRET environment binding missing');
  return c.env.JWT_SECRET;
};
```

#### Finding B-2: Secret OTP Leakage in API HTTP Response Body
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Lines 358-362
- **Verbatim Code Snippet**:
```typescript
  return c.json({
    success: true,
    message: 'OTP sent successfully to email.',
    _dev_otp: otp 
  });
```
- **Severity**: **High**
- **Violation Explanation**: Exposes generated OTP directly in the API response JSON (`_dev_otp`). This allows anyone invoking `/api/auth/send-otp` to bypass email delivery entirely and log into any registered account.
- **Recommended Concrete Remediation**: Completely remove `_dev_otp` from the API response payload in production:
```typescript
  return c.json({
    success: true,
    message: 'OTP sent successfully to email.'
  });
```

#### Finding B-3: Auth Bypass Defaults (`USR-PARENT-101`, `USR-STUDENT-01`) in Parent & Player Routes
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Line 2973, Line 3016, Line 3032
- **Verbatim Code Snippet**:
```typescript
// Line 2973:
const parentUserId = jwtPayload?.sub || 'USR-PARENT-101';

// Line 3016:
VALUES (?, 'Parent Link Request', ..., player?.user_id || 'USR-STUDENT-01')

// Line 3032:
const userId = jwtPayload?.sub || 'USR-STUDENT-01';
```
- **Severity**: **High**
- **Violation Explanation**: When an unauthenticated request hits `/api/parent/link-request` or `/api/player/link-requests`, instead of rejecting the request with HTTP 401 Unauthorized, the worker falls back to mock hardcoded user IDs (`USR-PARENT-101`, `USR-STUDENT-01`).
- **Recommended Concrete Remediation**: Apply `enforceJwtAuth` middleware to `/api/parent/*` and `/api/player/*` routes. Reject requests without valid JWT claims:
```typescript
if (!jwtPayload?.sub) return c.json({ success: false, message: 'Unauthorized session' }, 401);
const parentUserId = jwtPayload.sub;
```

#### Finding B-4: Hardcoded Mock Password Hashes in D1 Migrations
- **Absolute File Paths**: 
  - `C:\Development\academypro\migrations\0002_seed_data.sql` (Lines 11, 14, 17)
  - `C:\Development\academypro\migrations\0006_seed_test_coach_user.sql` (Line 3)
  - `C:\Development\academypro\migrations\0009_seed_jrobertse_coach_user.sql` (Line 2)
  - `C:\Development\academypro\migrations\0012_seed_janmen778_student_user.sql` (Line 2)
- **Relative File Paths**: `migrations/0002_seed_data.sql`, `migrations/0006_seed_test_coach_user.sql`, etc.
- **Line Numbers**: Various lines across migration files.
- **Verbatim Code Snippet**:
```sql
INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name) 
VALUES ('USR-COACH-1', 'OVK', 'coach.ross@overkruin.co.za', 'sha256$mockedhash', 'Coach', 'Ross', 'Venter');
```
- **Severity**: **Medium**
- **Violation Explanation**: Production SQL migration scripts contain hardcoded mock user identities (`USR-COACH-1`, `USR-STUDENT-1`, `PAR-OVK-001`, `USR-COACH-2`, `USR-COACH-JROB`) with fake password hash strings (`sha256$mockedhash`).
- **Recommended Concrete Remediation**: Remove mock account SQL insertions from production migrations. User accounts must be created dynamically through verified OTP login flows.

---

### Category C: Hardcoded Fallback Strings & Over-Defensive Defaults Masking Missing Parameters

#### Finding C-1: Over-Defensive `schoolId` Fallback (`schoolId || 'OVK'`) Across Worker API
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Lines 703, 741, 798, 935, 1021, 1139, 1620, 1981, 2015, 2132, 2376, 2402, 2503, 2526, 2845 (15+ occurrences)
- **Verbatim Code Snippet**:
```typescript
const schoolId = jwtPayload?.schoolId || 'OVK';
```
- **Severity**: **High**
- **Violation Explanation**: When extracting `schoolId` from session JWTs across squad, roster, dashboard, event, and player API endpoints, the code falls back to hardcoded school `'OVK'`. If a token is missing `schoolId`, it silently reads/writes data under school `'OVK'`, masking authorization/token missing fields and risking multi-tenant cross-school data contamination.
- **Recommended Concrete Remediation**: Strict fail-fast check:
```typescript
const schoolId = jwtPayload?.schoolId;
if (!schoolId) {
  return c.json({ success: false, message: 'Invalid token: schoolId claim missing' }, 400);
}
```

#### Finding C-2: Over-Defensive Squad & Age Group Fallbacks (`'U15'`, `'Academy Elite'`)
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts`
- **Relative File Path**: `worker/src/index.ts`
- **Line Numbers**: Lines 751, 1216, 1217, 1645
- **Verbatim Code Snippet**:
```typescript
const squadCode = (code || ageGroup || 'U15').trim().toUpperCase();
ageGroup: r.age_group || 'U15',
team: r.team || r.age_group || 'U15',
```
- **Severity**: **Medium**
- **Violation Explanation**: Over-defensive string fallbacks substitute `'U15'` when age group or team parameter inputs are empty or missing during squad creation or event mapping.
- **Recommended Concrete Remediation**: Allow requests with missing parameters to fail fast with HTTP 400 Bad Request rather than inserting fake defaults.

#### Finding C-3: Dynamic Table Schemas Hardcoding Default School (`DEFAULT 'OVK'`)
- **Absolute File Path**: `C:\Development\academypro\worker\src\index.ts` & `C:\Development\academypro\worker\migrations\0001_ensure_all_tables.sql`
- **Relative File Path**: `worker/src/index.ts` and `worker/migrations/0001_ensure_all_tables.sql`
- **Line Numbers**: `index.ts` (Lines 1469, 1527, 1583) & `0001_ensure_all_tables.sql` (Lines 13, 36, 62, 136, 153)
- **Verbatim Code Snippet**:
```sql
CREATE TABLE IF NOT EXISTS action_plans (
  id TEXT PRIMARY KEY,
  school_id TEXT DEFAULT 'OVK', ...
```
- **Severity**: **Medium**
- **Violation Explanation**: Table creation statements define `DEFAULT 'OVK'` at the SQL schema level, masking missing `school_id` parameters on database row insertion.
- **Recommended Concrete Remediation**: Remove `DEFAULT 'OVK'` SQL constraints. Define `school_id TEXT NOT NULL` and pass verified parameters.

#### Finding C-4: Hardcoded `'U15'` Fallback in Flutter Dashboard Controllers & Models
- **Absolute File Path**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **Relative File Path**: `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers**: Lines 74, 131, 144, 209, 226, 433, 602, 654
- **Verbatim Code Snippet**:
```dart
Future<void> fetchSummary({String ageGroup = 'U15'}) async {
  ageGroup: json['ageGroup'] ?? 'U15',
```
- **Severity**: **Medium**
- **Violation Explanation**: Flutter controllers default `ageGroup` parameter to `'U15'` when fetching dashboard summaries or parsing JSON models.
- **Recommended Concrete Remediation**: Accept nullable or dynamic parameters (`String? ageGroup`), defaulting to the user's first assigned squad code fetched from `/api/squads`.

#### Finding C-5: Hardcoded Student ID & Profile Fallbacks in Student Dashboard UI
- **Absolute File Path**: `C:\Development\academypro\academypro_app\lib\features\student\presentation\student_dashboard_screen.dart`
- **Relative File Path**: `lib/features/student/presentation/student_dashboard_screen.dart`
- **Line Numbers**: Lines 297, 1856, 1911, 2512, 2513
- **Verbatim Code Snippet**:
```dart
final ageGroup = profile['ageGroup'] ?? 'U15';
'Athlete Profile • ${profile['id'] ?? 'OVK-ATHLETE'}',
final studentId = profile['id'] ?? 'OVK-STUDENT-JAN';
```
- **Severity**: **Medium**
- **Violation Explanation**: The student dashboard UI masks missing profile payload fields by displaying hardcoded strings (`'U15'`, `'OVK-ATHLETE'`, `'OVK-STUDENT-JAN'`).
- **Recommended Concrete Remediation**: Render real empty state strings (`"--"`, `"Unassigned"`) or show an error state if profile attributes fail to load.

#### Finding C-6: Hardcoded Fallback IDs in Flutter Roster Controller
- **Absolute File Path**: `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\roster_controller.dart`
- **Relative File Path**: `lib/features/dashboard/controllers/roster_controller.dart`
- **Line Numbers**: Line 237
- **Verbatim Code Snippet**:
```dart
final newId = 'OVK-$ageGroup-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
```
- **Severity**: **Low**
- **Violation Explanation**: Hardcodes `'OVK-'` string prefix when generating local temporary IDs for new players before server creation.
- **Recommended Concrete Remediation**: Construct prefixes using `currentSchoolId` or generate UUID strings.

---

### Category D: Fallback Arrays Containing Fake/Mock Records on 0 DB Rows & Seed Files

#### Finding D-1: Fake Seed File `0004_seed_dashboard_mock_data.sql` in Database Migrations
- **Absolute File Path**: `C:\Development\academypro\migrations\0004_seed_dashboard_mock_data.sql`
- **Relative File Path**: `migrations/0004_seed_dashboard_mock_data.sql`
- **Line Numbers**: Lines 1-24
- **Verbatim Code Snippet**:
```sql
-- Migration: Seed Dashboard Mock Data (Academic and Match logs)
INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score) VALUES ('OVK-U15-001', 1, 58.0, 1);
INSERT INTO match_stats (player_id, match_date, opponent, tackles_made, tackles_missed, carries, metres_gained, errors, penalties, work_rate, overall_rating, auto_score, tackle_percentage, category) 
VALUES ('OVK-U15-003', '2026-07-15', 'Pretoria Boys High', 2, 8, 3, 10.0, 4, 3, 1, 1, 1.2, 0.2, '🔴 Developing');
```
- **Severity**: **High**
- **Violation Explanation**: Production D1 migration folder contains a script dedicated to inserting fake sample records (`Pretoria Boys High`, `auto_score = 1.2`, fake academic scores) into database tables.
- **Recommended Concrete Remediation**: Remove `0004_seed_dashboard_mock_data.sql` from the production migration sequence. Empty tables must return empty JSON arrays `[]` and zero KPI metrics (`0.0`, `"0%"`, `"No baseline test logged"`).

#### Finding D-2: Mock Commented UI Elements in Parent Dashboard
- **Absolute File Path**: `C:\Development\academypro\academypro_app\lib\features\parent\presentation\parent_dashboard_screen.dart`
- **Relative File Path**: `lib/features/parent/presentation/parent_dashboard_screen.dart`
- **Line Numbers**: Line 617
- **Verbatim Code Snippet**:
```dart
// Ticket cutout circles (Mock)
```
- **Severity**: **Low**
- **Violation Explanation**: UI code references mock decorative elements instead of real state-driven UI.
- **Recommended Concrete Remediation**: Clean up comments and ensure widget state is tied directly to real data model properties.

---

## 2. Logic Chain

1. **Initial Assessment against Production Rules**:
   - Production rules mandate: Zero dummy/fake data, zero pseudo-random generators (`Math.random()`), zero hardcoded fallback strings (`team || 'U15'`, `schoolId || 'OVK'`), zero auth bypasses (`USR-PARENT-101`), fail-fast HTTP responses on missing input, and clean real empty states (`[]`, `0.0%`).

2. **Analysis of Pseudo-Random Generators**:
   - `Math.random()` calls found at lines 305, 489, and 3334 in `worker/src/index.ts` generate authentication & email change OTPs. Because PRNGs are non-cryptographic, this violates security standards for credentials.

3. **Analysis of Credential & Identity Bypasses**:
   - In `worker/src/index.ts` line 147, `JWT_SECRET` defaults to `'usport-secret-key-928374'`, compromising signature verification if unconfigured.
   - In line 361, `_dev_otp` returns the secret OTP directly to HTTP clients, nullifying OTP email verification security.
   - In lines 2973 and 3032, unauthenticated API calls default `parentUserId` to `'USR-PARENT-101'` and `userId` to `'USR-STUDENT-01'`, bypassing JWT authentication guards.
   - In migration files (`0002_seed_data.sql`, `0006_seed_test_coach_user.sql`, etc.), hardcoded mock users with `'sha256$mockedhash'` are seeded directly into schema files.

4. **Analysis of Defensive String Fallbacks**:
   - Across 15+ locations in `worker/src/index.ts`, `jwtPayload?.schoolId || 'OVK'` automatically routes requests missing a `schoolId` claim to school `'OVK'`.
   - In Flutter controllers and views (`dashboard_controller.dart`, `student_dashboard_screen.dart`), parameters default to `'U15'`, `'OVK-ATHLETE'`, or `'OVK-STUDENT-JAN'` rather than handling missing values or returning explicit errors.

5. **Analysis of Fake Data Seeds**:
   - Migration `0004_seed_dashboard_mock_data.sql` inserts mock match stats and academic records into D1. Violates the rule requiring clean empty states for new squads/athletes.

---

## 3. Caveats

- **External Packages**: Pre-existing third-party packages in `pubspec.lock` or `node_modules` were excluded from scanning as they are external dependencies.
- **Valid SQL Schema Definitions**: SQL files defining primary key column types (e.g. `DATABASE_SCHEMA.md` examples) were audited to distinguish between documentation sitemaps and runtime fallbacks.

---

## 4. Conclusion

The codebase contains 16 distinct flagged instances across 4 primary categories that violate strict production rules:
- **3 High Severity PRNG issues** (`Math.random()` OTP generation).
- **4 High/Medium Auth & Secret Bypass issues** (hardcoded JWT secret fallback, secret OTP returned in API response, hardcoded user ID auth bypasses, mock password hash migrations).
- **6 High/Medium Defensive Fallback issues** (`schoolId || 'OVK'`, squad/age group defaults, student ID UI fallbacks).
- **3 High/Low Mock Data & Array issues** (mock dashboard SQL migration, mock UI elements).

Refactoring these instances will ensure fail-fast error handling, cryptographically secure OTP generation, strict JWT authentication enforcement, multi-tenant isolation, and clean real empty states.

---

## 5. Verification Method

To independently verify all flagged instances:

1. **Verify `Math.random()` Usages**:
   Run PowerShell command:
   `Get-ChildItem -Path "C:\Development\academypro\worker\src\index.ts" | Select-String -Pattern "Math\.random"`
   *Expected Output*: Matches at lines 305, 489, 3334.

2. **Verify Hardcoded Secret & Auth Bypasses**:
   Run PowerShell command:
   `Get-ChildItem -Path "C:\Development\academypro\worker\src\index.ts" | Select-String -Pattern "usport-secret-key|_dev_otp|USR-PARENT-101|USR-STUDENT-01"`
   *Expected Output*: Matches at lines 147, 361, 2973, 3016, 3032.

3. **Verify Defensive `schoolId` Fallbacks**:
   Run PowerShell command:
   `Get-ChildItem -Path "C:\Development\academypro\worker\src\index.ts" | Select-String -Pattern "schoolId \|\| 'OVK'"`
   *Expected Output*: 15+ matches across worker routes.

4. **Verify Mock Seed Migration**:
   Inspect file `C:\Development\academypro\migrations\0004_seed_dashboard_mock_data.sql`.
