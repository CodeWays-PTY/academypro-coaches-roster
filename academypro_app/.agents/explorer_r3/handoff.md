# Handoff Report — Requirement 3: Hardcoded Values Audit (R3)

## 1. Observation

A comprehensive scan was conducted across all Dart files in `C:\Development\academypro\academypro_app\lib` (35 files) and TypeScript/SQL files in `C:\Development\academypro\worker` (12 files + 6 migration scripts).

Below is the detailed catalog of every flagged instance organized by audit category.

---

### Category A: Static Phone Numbers, Test Credentials, & Hardcoded API Tokens/Keys

#### Instance A1: Hardcoded Fallback JWT Secret Key
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Line 147
- **Verbatim Code Snippet:**
  ```typescript
  const getSecret = (c: any) => c.env?.JWT_SECRET || 'usport-secret-key-928374';
  ```
- **Severity Level:** High
- **Explanation:** Using a hardcoded fallback string `'usport-secret-key-928374'` for JWT signing when `c.env.JWT_SECRET` is undefined allows forged JWT tokens if the environment variable is omitted in production or staging.
- **Recommended Remediation:** Remove the fallback string. Throw an explicit HTTP 500 configuration error or fail-fast error if `env.JWT_SECRET` is missing.

#### Instance A2: Hardcoded Internal API Key Fallback
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Line 3344
- **Verbatim Code Snippet:**
  ```typescript
  const apiKey = c.env.INTERNAL_API_KEY || 'agua_internal_secret_key_102938';
  ```
- **Severity Level:** High
- **Explanation:** Hardcoding a secret fallback API key `'agua_internal_secret_key_102938'` exposes backend authentication credentials to public code repository history and bypasses secure environment variable management.
- **Recommended Remediation:** Rely strictly on `c.env.INTERNAL_API_KEY`. If missing, reject the SMS request with HTTP 500 / 401.

#### Instance A3: Hardcoded Mock User Identity Bypasses in API Endpoints
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Lines 2972, 3016, 3032
- **Verbatim Code Snippet:**
  ```typescript
  const parentUserId = jwtPayload?.sub || 'USR-PARENT-101';
  // ...
  .bind(player?.user_id || 'USR-STUDENT-01').run();
  // ...
  const userId = jwtPayload?.sub || 'USR-STUDENT-01';
  ```
- **Severity Level:** High
- **Explanation:** Violates rule: *"NEVER inject mock user identities (`USR-COACH-001`, `USR-PARENT-101`) or bypass JWT auth for developer convenience. Unauthenticated requests MUST strictly return HTTP 401 Unauthorized."*
- **Recommended Remediation:** Enforce `enforceJwtAuth` middleware on parent/player routes and reject requests missing `jwtPayload.sub` with HTTP 401 Unauthorized.

#### Instance A4: Hardcoded Sample Parent & Player Phone Numbers & Emails in Flutter UI Model
- **File Path (Abs):** `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel):** `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers:** Lines 292, 293, 294
- **Verbatim Code Snippet:**
  ```dart
  this.parentName = 'Parent Contact',
  this.parentPhone = '+27 82 555 0192',
  this.parentEmail = 'parent@academypro.co.za',
  this.playerPhone = '+27 71 444 8821',
  ```
- **Severity Level:** High
- **Explanation:** Violates rule: *"NEVER use Random(), Math.random(), seeded pseudo-random generators, or hardcoded dummy values (e.g. +27 82 123 4567)... NEVER use over-defensive string fallbacks... Clean Real Empty States."*
- **Recommended Remediation:** Make `parentPhone`, `parentEmail`, and `playerPhone` default to empty strings `''` or `null`. Display real empty state UI when contact data is unrecorded.

#### Instance A5: Hardcoded User Emails in Database Migration Scripts
- **File Path (Abs):** `C:\Development\academypro\worker\migrations\0005_assign_jrobertse_u15_squad.sql`
- **File Path (Rel):** `worker/migrations/0005_assign_jrobertse_u15_squad.sql`
- **Line Numbers:** Line 4
- **Verbatim Code Snippet:**
  ```sql
  UPDATE users 
  SET school_id = 'OVK', role = 'Coach'
  WHERE email = 'jrobertse1@gmail.com';
  ```
- **Severity Level:** Medium
- **Explanation:** Hardcodes developer-specific email addresses directly in D1 table setup scripts.
- **Recommended Remediation:** Parameterize database initialization or keep seed scripts clean and generic.

---

### Category B: Hardcoded Test Metrics & Benchmark Scores

#### Instance B1: Hardcoded Category Thresholds in Auto-Score Calculation
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Lines 189–196
- **Verbatim Code Snippet:**
  ```typescript
  let category = "🔴 Developing";
  if (autoScore >= 4.0) {
    category = "🟢 Excelling";
  } else if (autoScore >= 3.0) {
    category = "🟡 On Track";
  } else if (autoScore >= 2.0) {
    category = "🟠 At Risk";
  }
  ```
- **Severity Level:** Medium
- **Explanation:** Hardcodes performance rating score thresholds directly into application code rather than fetching dynamic sports benchmark definitions from `test_metric_definitions`.
- **Recommended Remediation:** Use benchmark definitions from Cloudflare D1 table `test_metric_definitions`.

#### Instance B2: Hardcoded Academic KPI Cutoffs & Flag Reasons
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Lines 986–991, 1069–1077
- **Verbatim Code Snippet:**
  ```typescript
  acads.forEach((row: any) => {
    const score = row.avg_grade;
    if (score >= 65) uniReadyCount++;
    else if (score >= 60) onTrackCount++;
    else if (score >= 50) atRiskCount++;
    else dangerCount++;
  });
  // ...
  if (avgGrade !== null && avgGrade < 60) {
    isFlagged = true;
    categoryType = avgGrade < 50 ? 'Critical' : 'Warning';
    reason = `Academic Drop: Average grade is ${avgGrade}%. Requires tutoring check-in.`;
  }
  ```
- **Severity Level:** Medium
- **Explanation:** Academic benchmark percentages (65%, 60%, 50%) are hardcoded into server business logic without supporting configurable school settings or dynamic threshold tables.
- **Recommended Remediation:** Store academic grade threshold bands in D1 (e.g. `school_settings` or `academic_benchmarks`) and query them dynamically.

#### Instance B3: Hardcoded Mock Grade Improvement Score
- **File Path (Abs):** `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel):** `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers:** Line 211
- **Verbatim Code Snippet:**
  ```dart
  gradeImprovement = gradeImprovement ?? 12,
  ```
- **Severity Level:** Medium
- **Explanation:** Injects a fake default grade improvement metric (`12%`) if the field is missing. Violates zero dummy data policy.
- **Recommended Remediation:** Default to `0` or `null` when no grade improvement data exists.

#### Instance B4: Hardcoded Metric Score Hint in Single Player Baseline Modal
- **File Path (Abs):** `C:\Development\academypro\academypro_app\lib\features\dashboard\presentation\single_player_baseline_modal.dart`
- **File Path (Rel):** `lib/features/dashboard/presentation/single_player_baseline_modal.dart`
- **Line Numbers:** Line 249
- **Verbatim Code Snippet:**
  ```dart
  hintText: 'e.g. ${selectedMetric?['targetBenchmark'] ?? '5.2'}',
  ```
- **Severity Level:** Low
- **Explanation:** Uses hardcoded fallback `'5.2'` in UI input hint instead of relying dynamically on metric definition target benchmarks.
- **Recommended Remediation:** Show `'e.g. Score'` when `targetBenchmark` is null.

---

### Category C: Hardcoded Array Lists, Squad Lists, Status Labels, & Magic Numbers

#### Instance C1: Over-Defensive Fallback School ID ('OVK') Across API Handlers
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Lines 703, 741, 798, 935, 1020, 1139, 1469, 1529, 1619, 1981, 2016, 2132, 2376, 2402, 2503, 2526
- **Verbatim Code Snippet:**
  ```typescript
  const schoolId = jwtPayload?.schoolId || 'OVK';
  ```
- **Severity Level:** High
- **Explanation:** Violates rule: *"NEVER use over-defensive string fallbacks (e.g., `team || 'U15 Academy Elite'`, `schoolId || 'OVK'`) to mask missing fields or parameters."* Unauthenticated or school-less requests fallback to `'OVK'`.
- **Recommended Remediation:** Require `schoolId` from the verified JWT payload. If missing, fail fast with HTTP 401 Unauthorized / 400 Bad Request.

#### Instance C2: Hardcoded Age Group & Squad Fallbacks ('U15', 'Forward', 'Athlete')
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts` & `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart`
- **File Path (Rel):** `worker/src/index.ts` and `lib/features/dashboard/controllers/dashboard_controller.dart`
- **Line Numbers:** `worker/src/index.ts`: 751, 1216, 1645; `dashboard_controller.dart`: 74, 131, 144, 209
- **Verbatim Code Snippet:**
  ```typescript
  const squadCode = (code || ageGroup || 'U15').trim().toUpperCase();
  ageGroup: r.age_group || 'U15',
  ```
  ```dart
  Future<void> fetchSummary({String ageGroup = 'U15'}) async
  position = position ?? 'Forward',
  ```
- **Severity Level:** Medium
- **Explanation:** Hardcodes specific age groups (`'U15'`) and position strings (`'Forward'`) as defaults across multiple API and UI layers rather than querying actual user squad assignments.
- **Recommended Remediation:** Requiring dynamic squad selection from database queries and avoiding hardcoded fallback strings.

#### Instance C3: Hardcoded Sport ID ('rugby') in Metric Definition Handler
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Line 2422
- **Verbatim Code Snippet:**
  ```typescript
  VALUES (?, ?, 'rugby', ?, ?, ?, ?, ?)
  ```
- **Severity Level:** Medium
- **Explanation:** Hardcodes `'rugby'` into test metric definition insertion statements, preventing support for other sports categories.
- **Recommended Remediation:** Pass `sportId` dynamically from the request payload or school configuration.

#### Instance C4: Hardcoded Email Domain Suffix (`@academypro.co.za`)
- **File Path (Abs):** `C:\Development\academypro\worker\src\index.ts`
- **File Path (Rel):** `worker/src/index.ts`
- **Line Numbers:** Lines 2855, 2985
- **Verbatim Code Snippet:**
  ```typescript
  const playerEmail = (email && email.trim()) ? email.trim().toLowerCase() : `${firstName.toLowerCase().replace(/\s+/g, '')}.${lastName.toLowerCase().replace(/\s+/g, '')}@academypro.co.za`;
  ```
- **Severity Level:** Low
- **Explanation:** Synthesizes dummy email addresses with fixed domain `@academypro.co.za` when email is missing during player creation.
- **Recommended Remediation:** Require explicit email input from the coach during player creation or allow nullable email fields.

#### Instance C5: Hardcoded Local API Candidate URLs in Flutter ApiClient
- **File Path (Abs):** `C:\Development\academypro\academypro_app\lib\core\network\api_client.dart`
- **File Path (Rel):** `lib/core/network/api_client.dart`
- **Line Numbers:** Lines 12–17
- **Verbatim Code Snippet:**
  ```dart
  return [
    'http://$host:8787',
    'http://$host:3000',
    'http://$host:8080',
    'http://$host:80',
  ];
  ```
- **Severity Level:** Low
- **Explanation:** Magic port numbers hardcoded in client network library.
- **Recommended Remediation:** Environment-configurable base URLs via build flavors or config constants.

---

## 2. Logic Chain

1. **Rule Baseline Analysis:** The project rules explicitly forbid:
   - Hardcoded tokens/secret keys, static phone numbers, test credentials, and mock user identities.
   - Seeded dummy metric scores (e.g. `"83.6%"`, `"753"`, `78.0`, `88`).
   - Over-defensive fallback strings (e.g. `schoolId || 'OVK'`, `team || 'U15 Academy Elite'`) that obscure missing parameters or missing records.
2. **Codebase Inspection:** Every file in `lib/` and `worker/` was systematically searched and reviewed.
3. **Pattern Verification:**
   - Secrets: Line 147 (`'usport-secret-key-928374'`) and line 3344 (`'agua_internal_secret_key_102938'`) in `worker/src/index.ts` act as dangerous fallbacks if environment variables are not provided.
   - Mock Identity / Bypasses: Lines 2972, 3016, 3032 in `worker/src/index.ts` inject `'USR-PARENT-101'` and `'USR-STUDENT-01'` if JWT verification is missing.
   - Dummy Data in Models: Lines 292-294 in `dashboard_controller.dart` populate dummy phone numbers (`+27 82 555 0192`, `+27 71 444 8821`) and email (`parent@academypro.co.za`).
   - Over-defensive String Fallbacks: `'OVK'` is hardcoded as fallback in over 16 route handlers in `worker/src/index.ts`.
4. **Classification:** Findings have been categorized into Severity levels (High, Medium, Low) based on security risk and compliance with production rules.

---

## 3. Caveats

- **No Caveats:** Investigation was complete. All 35 Flutter Dart files and 12 Worker files + 6 SQL migrations were thoroughly scanned and evaluated.

---

## 4. Conclusion

A total of 14 distinct flagged items spanning security risks, dummy data violations, and over-defensive string fallbacks were identified. Remediation of these items will bring the codebase into full compliance with strict production data architecture rules.

---

## 5. Verification Method

To independently verify these findings:
1. **File Inspection:** Use `view_file` on `C:\Development\academypro\worker\src\index.ts` at lines 147, 703, 1069, 2972, 3016, 3344.
2. **Flutter Inspection:** Use `view_file` on `C:\Development\academypro\academypro_app\lib\features\dashboard\controllers\dashboard_controller.dart` at lines 292–294.
3. **SQL Inspection:** Use `view_file` on `C:\Development\academypro\worker\migrations\0005_assign_jrobertse_u15_squad.sql` at line 4.
