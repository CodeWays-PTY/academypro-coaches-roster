# Analysis Report: Backend Worker API Refactoring (Milestone 2)

**Author**: Explorer Agent (`explorer_m2_1`)  
**Date**: 2026-08-03  
**Working Directory**: `c:\Development\academypro\.agents\explorer_m2_1`  

---

## Executive Summary

This report delivers the complete technical analysis and exact code modification specifications for **Milestone 2: Backend Worker API Refactoring**. In Milestone 1, obsolete database tables (`fitness_baselines`, `fitness_progression`) and legacy columns (`players.ugroups_active`, `players.parent_name`, `players.parent_id`, `parent_child_links.parent_phone`, `parent_child_links.parent_email`) were permanently dropped from Cloudflare D1 database `academypro-db` via `migrations/0020_cleanup_obsolete_schema.sql`.

This investigation audited the entire `worker/` codebase (specifically `worker/src/index.ts`) for references to all dropped tables and columns. All legacy queries have been cataloged, and exact refactoring instructions have been formulated to redirect all fitness evaluation data access to `player_test_logs` and dynamic `test_metric_definitions`.

---

## 1. Audit of Obsolete References in Worker Codebase

| Target Element | Status in `worker/src/index.ts` | File & Line Numbers | Discovered Usage / Impact |
|---|---|---|---|
| `fitness_baselines` | **FOUND (2 Endpoints)** | Lines 2473, 3229, 3231 | 1. `GET /api/student-portal` (Line 2473): `SELECT * FROM fitness_baselines WHERE player_id = ?`<br>2. `POST /api/admin/bulk-upload` (Line 3231): `INSERT INTO fitness_baselines ...` |
| `fitness_progression` | **FOUND (1 Endpoint)** | Line 2479 | `GET /api/student-portal` (Line 2479): `SELECT * FROM fitness_progression WHERE player_id = ? ORDER BY week ASC` |
| `players.ugroups_active` | **FOUND (2 Places)** | Lines 1186, 2583 | 1. `GET /api/players` (Line 1186): Response object mapping `ugroupsActive: p.ugroups_active`<br>2. `GET /api/student-portal` (Line 2583): Profile mapping `ugroupsActive: player.ugroups_active` |
| `players.parent_id` | **FOUND (1 Endpoint)** | Line 2355 | `GET /api/student-portal` (Line 2355): `SELECT * FROM players WHERE parent_id = ?` |
| `players.parent_name` | **ABSENT** | N/A | 0 occurrences in `worker/src/index.ts` |
| `parent_child_links.parent_phone` | **ABSENT** | N/A | 0 occurrences in `worker/src/index.ts` |
| `parent_child_links.parent_email` | **ABSENT** | Lines 3546, 3557 | Alias `u.email as parent_email` from joined table `users u` (valid; no reference to `parent_child_links.parent_email` column) |

---

## 2. Refactoring Strategy & Endpoint Redirection

### A. Redirection to Dynamic Fitness Architecture (`player_test_logs` & `test_metric_definitions`)

1. **`GET /api/student-portal`**:
   - **Legacy Behavior**: Executed `SELECT * FROM fitness_baselines` and `SELECT * FROM fitness_progression`.
   - **Refactored Behavior**: 
     - Queries `player_test_logs` joined with `test_metric_definitions` ordered by `test_date ASC` to build time-series `progressions`.
     - Derives backward-compatible `baseline` object from calculated `dynamicMetrics` (matching metric names like `40m Sprint`, `Vertical Jump`, `Broad Jump`, `Push-Ups`, etc.).

2. **`POST /api/admin/bulk-upload`**:
   - **Legacy Behavior**: Executed `INSERT INTO fitness_baselines (player_id, vertical_jump, speed_40m, updated_at)`.
   - **Refactored Behavior**: Inserts dynamic test evaluation logs into `player_test_logs` using standard metric IDs:
     - `vertical`: `metric_id = 'm_vertical_jump'`
     - `dash40yd`: `metric_id = 'm_speed_40m'`

### B. Purging Obsolete Column Access

1. **`players.ugroups_active`**: Removed `ugroupsActive` mapping in `GET /api/players` and `GET /api/student-portal`.
2. **`players.parent_id`**: Replaced `SELECT * FROM players WHERE parent_id = ?` in `GET /api/student-portal` with a join on `parent_child_links` (`JOIN parent_child_links pcl ON (pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id)) WHERE pcl.parent_user_id = ? AND pcl.status IN ('accepted', 'approved')`).

---

## 3. Exact Code Modification Specifications for `worker/src/index.ts`

### Modification 1: Remove `ugroups_active` from `GET /api/players`
**Location**: Lines 1178–1189 in `worker/src/index.ts`

```diff
<<<<
      players: (results || []).map((p: any) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        ageGroup: p.age_group,
        position: p.position,
        team: p.team,
        status: p.status,
        ugroupsActive: p.ugroups_active,
        age: p.age,
        assignedSquads: playerSquadMap[p.id] || []
      }))
====
      players: (results || []).map((p: any) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        ageGroup: p.age_group,
        position: p.position,
        team: p.team,
        status: p.status,
        age: p.age,
        assignedSquads: playerSquadMap[p.id] || []
      }))
>>>>
```

---

### Modification 2: Refactor `parent_id` lookup in `GET /api/student-portal`
**Location**: Lines 2354–2356 in `worker/src/index.ts`

```diff
<<<<
    } else if (!player && (roleLower === 'parent' || roleLower.includes('parent'))) {
      player = await db.prepare('SELECT * FROM players WHERE parent_id = ?').bind(userId).first();
    }
====
    } else if (!player && (roleLower === 'parent' || roleLower.includes('parent'))) {
      const link: any = await db.prepare(`
        SELECT p.* FROM players p
        JOIN parent_child_links pcl ON (pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id))
        WHERE pcl.parent_user_id = ? AND pcl.status IN ('accepted', 'approved')
        LIMIT 1
      `).bind(userId).first();
      player = link || null;
    }
>>>>
```

---

### Modification 3: Replace `fitness_baselines` and `fitness_progression` in `GET /api/student-portal`
**Location**: Lines 2470–2481 in `worker/src/index.ts`

```diff
<<<<
  // 2. Fetch Fitness Baseline
  let baseline: any = null;
  try {
    baseline = await db.prepare('SELECT * FROM fitness_baselines WHERE player_id = ?').bind(playerId).first();
  } catch (_) {}

  // 3. Fetch Fitness Progressions
  let progressions: any[] = [];
  try {
    const { results } = await db.prepare('SELECT * FROM fitness_progression WHERE player_id = ? ORDER BY week ASC').bind(playerId).all();
    progressions = results || [];
  } catch (_) {}
====
  // 2. Derive Fitness Progressions from dynamic player_test_logs
  let progressions: any[] = [];
  try {
    const { results: logResults } = await db.prepare(`
      SELECT ptl.*, tmd.name as metric_name, tmd.unit
      FROM player_test_logs ptl
      LEFT JOIN test_metric_definitions tmd ON ptl.metric_id = tmd.id
      WHERE ptl.player_id = ?
      ORDER BY ptl.test_date ASC
    `).bind(playerId).all();
    
    if (logResults && logResults.length > 0) {
      progressions = logResults.map((l: any, idx: number) => ({
        week: idx + 1,
        date: l.test_date,
        metricId: l.metric_id,
        metricName: l.metric_name || l.test_name || 'Evaluation',
        score: l.score !== undefined && l.score !== null ? l.score : (l.score_value || 0),
        unit: l.unit || '',
        sessionName: l.session_name || 'Evaluation'
      }));
    }
  } catch (_) {}

  // 3. Derive backward-compatible baseline object from dynamicMetrics
  const baselineData: Record<string, any> = {};
  for (const dm of dynamicMetrics) {
    const nameLower = (dm.name || '').toLowerCase();
    if (nameLower.includes('40m') || nameLower.includes('dash')) baselineData.speed40m = dm.latestScore;
    else if (nameLower.includes('60m')) baselineData.speed60m = dm.latestScore;
    else if (nameLower.includes('broad')) baselineData.broadJump = dm.latestScore;
    else if (nameLower.includes('push')) baselineData.pushUps = dm.latestScore;
    else if (nameLower.includes('pull')) baselineData.pullUps = dm.latestScore;
    else if (nameLower.includes('squat')) baselineData.squats40kg = dm.latestScore;
    else if (nameLower.includes('vertical')) baselineData.verticalJump = dm.latestScore;
    else if (nameLower.includes('t-test') || nameLower.includes('agility')) baselineData.tTest = dm.latestScore;
  }
  const baseline: any = Object.keys(baselineData).length > 0 ? baselineData : null;
>>>>
```

---

### Modification 4: Remove `ugroups_active` profile mapping in `GET /api/student-portal`
**Location**: Line 2583 in `worker/src/index.ts`

```diff
<<<<
        grade: player.grade,
        age: player.age,
        ugroupsActive: player.ugroups_active,
        notes: player.notes,
====
        grade: player.grade,
        age: player.age,
        notes: player.notes,
>>>>
```

---

### Modification 5: Refactor `POST /api/admin/bulk-upload` to write to `player_test_logs`
**Location**: Lines 3229–3240 in `worker/src/index.ts`

```diff
<<<<
      // 1. Upsert fitness_baselines
      const sqlFitness = `
        INSERT INTO fitness_baselines (player_id, vertical_jump, speed_40m, updated_at)
        VALUES (?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(player_id) DO UPDATE SET
          vertical_jump = excluded.vertical_jump,
          speed_40m = excluded.speed_40m,
          updated_at = CURRENT_TIMESTAMP
      `;
      const vertValue = vertical !== undefined && vertical !== null && vertical !== '' ? parseFloat(vertical) : null;
      const dashValue = dash40yd !== undefined && dash40yd !== null && dash40yd !== '' ? parseFloat(dash40yd) : null;
      await db.prepare(sqlFitness).bind(player_id, vertValue, dashValue).run();
====
      // 1. Upsert dynamic test logs for vertical jump & 40m sprint into player_test_logs
      const testDate = new Date().toISOString().split('T')[0];
      const vertValue = vertical !== undefined && vertical !== null && vertical !== '' ? parseFloat(vertical) : null;
      const dashValue = dash40yd !== undefined && dash40yd !== null && dash40yd !== '' ? parseFloat(dash40yd) : null;

      if (vertValue !== null && !isNaN(vertValue)) {
        const vertLogId = `ptl_${player_id}_m_vertical_jump_${testDate}`;
        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name)
          VALUES (?, ?, 'm_vertical_jump', ?, ?, 'Bulk Upload')
          ON CONFLICT(id) DO UPDATE SET score = excluded.score
        `).bind(vertLogId, player_id, vertValue, testDate).run();
      }

      if (dashValue !== null && !isNaN(dashValue)) {
        const dashLogId = `ptl_${player_id}_m_speed_40m_${testDate}`;
        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name)
          VALUES (?, ?, 'm_speed_40m', ?, ?, 'Bulk Upload')
          ON CONFLICT(id) DO UPDATE SET score = excluded.score
        `).bind(dashLogId, player_id, dashValue, testDate).run();
      }
>>>>
```

---

## 4. Build and Deployment Verification Protocol

### Build & Type-Check Verification
To test bundling and TypeScript compilation prior to deployment:
```cmd
cmd /c npx wrangler deploy --dry-run
```
*Expected Output*: `Total Upload: ~210.8 KiB`, `--dry-run: exiting now.`

### Remote Deployment Command
To deploy the refactored Worker API to Cloudflare:
```cmd
cmd /c npx wrangler deploy
```

---

## 5. Summary of Verification & Next Steps

1. **Implementer Step**: Apply the 5 code refactorings to `worker/src/index.ts`.
2. **Build Step**: Execute `cmd /c npx wrangler deploy --dry-run` to verify compilation.
3. **Deploy Step**: Execute `cmd /c npx wrangler deploy` to release to production.
4. **Audit Step**: Verify `/api/student-portal`, `/api/players`, and `/api/admin/bulk-upload` return `200 OK` and execute cleanly against remote D1 database.
