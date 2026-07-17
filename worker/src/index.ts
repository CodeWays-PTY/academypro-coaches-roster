import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { jwt, sign, verify } from 'hono/jwt';

// Bindings interface for Cloudflare environment
export interface Env {
  DB: any; // D1Database
  KV: any; // KVNamespace
  INTERNAL_API_KEY?: string;
  JWT_SECRET?: string;
}

const app = new Hono<{ Bindings: Env }>();

// Global references for local mock fallbacks
let localD1Instance: any = null;
let localKVInstance: any = null;

// Self-configuring environment for local Node.js runs (zero config fallback)
app.use('*', async (c, next) => {
  if (!c.env) {
    (c as any).env = {};
  }

  // 1. If D1 is missing, load local usport.db SQLite dynamically using async import
  if (!c.env.DB && !localD1Instance) {
    try {
      const { DatabaseSync } = await import('node:sqlite');
      const path = await import('path');
      const fs = await import('fs');

      const dbPath = path.join(process.cwd(), 'usport.db');
      if (fs.existsSync(dbPath)) {
        const dbSync = new DatabaseSync(dbPath);

        localD1Instance = {
          prepare(sql: string) {
            return {
              bind(...params: any[]) {
                return {
                  async all() {
                    const results = dbSync.prepare(sql).all(...params);
                    return { results, success: true };
                  },
                  async get() {
                    return dbSync.prepare(sql).get(...params) || null;
                  },
                  async run() {
                    const res = dbSync.prepare(sql).run(...params);
                    return {
                      success: true,
                      meta: {
                        last_row_id: res.lastInsertRowid,
                        changes: res.changes
                      }
                    };
                  }
                };
              },
              async get() {
                return dbSync.prepare(sql).get() || null;
              },
              async all() {
                const results = dbSync.prepare(sql).all();
                return { results, success: true };
              }
            };
          }
        };
      }
    } catch (e) {
      console.warn('Local database fallback failed:', e);
    }
  }

  // 2. If KV is missing, load global in-memory KV mock
  if (!c.env.KV && !localKVInstance) {
    const store = new Map();
    localKVInstance = {
      async put(key: string, val: string) {
        store.set(key, val);
      },
      async get(key: string) {
        return store.get(key) || null;
      },
      async delete(key: string) {
        store.delete(key);
      }
    };
  }

  await next();
});

// Helper to get D1 database
function getDB(c: any) {
  return c.env?.DB || localD1Instance;
}

// Helper to get KV namespace
function getKV(c: any) {
  return c.env?.KV || localKVInstance;
}

// 3. CORS Middleware
app.use('*', cors({
  origin: '*',
  allowHeaders: ['Content-Type', 'Authorization', 'X-Internal-API-Key'],
  allowMethods: ['POST', 'GET', 'OPTIONS'],
  exposeHeaders: ['Content-Length'],
  maxAge: 600,
  credentials: true,
}));

// 4. URL Standardization: Strip trailing slashes (excluding root)
app.use('*', async (c, next) => {
  const url = new URL(c.req.url);
  if (url.pathname !== '/' && url.pathname.endsWith('/')) {
    url.pathname = url.pathname.slice(0, -1);
    return c.redirect(url.toString(), 301);
  }
  await next();
});

// Helper for JWT Secret Key
const getSecret = (c: any) => c.env?.JWT_SECRET || 'usport-secret-key-928374';

// Helper for Auto-Score Calculation (TypeScript implementation)
function calculateAutoScore(stats: {
  tacklesMade: number;
  tacklesMissed: number;
  carries: number;
  metresGained: number;
  errors: number;
  penalties: number;
  workRate: number;
  overallRating: number;
}) {
  const {
    tacklesMade,
    tacklesMissed,
    carries,
    metresGained,
    errors,
    penalties,
    workRate,
    overallRating,
  } = stats;

  const missedAdjustment = tacklesMissed === 0 ? 0.01 : tacklesMissed;
  const tackleAccuracy = (tacklesMade / (tacklesMade + missedAdjustment)) * 2;
  const carriesTerm = carries / 10;
  const metresTerm = metresGained / 50;
  const discipline = Math.max(0, 1 - ((errors + penalties) / 5));
  const workRateTerm = (workRate / 5) * 2.5;
  const overallRatingTerm = (overallRating / 5) * 2.5;

  const totalPoints = tackleAccuracy + carriesTerm + metresTerm + discipline + workRateTerm + overallRatingTerm;
  
  // Scale out of 5 and round to 1 decimal place
  let autoScore = (totalPoints / 10) * 5;
  autoScore = Math.round(autoScore * 10) / 10;
  autoScore = Math.max(0, Math.min(5, autoScore));

  const totalTackles = tacklesMade + tacklesMissed;
  const tacklePercentage = totalTackles > 0 ? tacklesMade / totalTackles : 0;

  let category = "🔴 Developing";
  if (autoScore >= 4.0) {
    category = "🟢 Excelling";
  } else if (autoScore >= 3.0) {
    category = "🟡 On Track";
  } else if (autoScore >= 2.0) {
    category = "🟠 At Risk";
  }

  return { autoScore, tacklePercentage, category };
}

// ==========================================
// AUTHENTICATION ROUTES
// ==========================================

// Route: Send OTP (Email)
app.post('/api/auth/send-otp', async (c) => {
  const { email } = await c.req.json();
  if (!email) {
    return c.json({ success: false, message: 'Email is required' }, 400);
  }

  const db = getDB(c);
  const kv = getKV(c);

  if (!db) {
    return c.json({ success: false, message: 'Local database usport.db not found' }, 500);
  }

  // Check if user exists in database
  const query = 'SELECT * FROM users WHERE email = ?';
  let user;
  try {
    user = await db.prepare(query).bind(email.trim().toLowerCase()).get();
  } catch (err: any) {
    return c.json({ success: false, message: 'Database query failed', error: err.message }, 500);
  }

  if (!user) {
    return c.json({ success: false, message: 'Access Denied: Account not found.' }, 403);
  }

  // Generate 6-digit OTP code
  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  // Save OTP to KV cache with 5-minute TTL (300s)
  await kv.put(`otp:${email.trim().toLowerCase()}`, otp, { expirationTtl: 300 });

  // Simulate Sending Email (Print directly to console/observer logs for easy retrieve)
  console.log(`[EMAIL SEND] To: ${email} | Subject: uSPORT Login OTP | Code: ${otp}`);

  // Return success status along with the code in response (Only for sandbox dev ease! We log it)
  return c.json({
    success: true,
    message: 'OTP sent successfully to email.',
    _dev_otp: otp 
  });
});

// Route: Verify OTP
app.post('/api/auth/verify-otp', async (c) => {
  const { email, otp } = await c.req.json();
  if (!email || !otp) {
    return c.json({ success: false, message: 'Email and OTP are required' }, 400);
  }

  const db = getDB(c);
  const kv = getKV(c);

  const cachedOtp = await kv.get(`otp:${email.trim().toLowerCase()}`);
  if (!cachedOtp) {
    return c.json({ success: false, message: 'OTP expired or not found. Try again.' }, 400);
  }

  if (cachedOtp !== otp.trim()) {
    return c.json({ success: false, message: 'Invalid OTP code. Access Denied.' }, 401);
  }

  // OTP verified, fetch coach profile
  const query = 'SELECT id, email, first_name, last_name, role, school_id FROM users WHERE email = ?';
  const user = await db.prepare(query).bind(email.trim().toLowerCase()).get();

  // Delete OTP from cache
  await kv.delete(`otp:${email.trim().toLowerCase()}`);

  // Sign JWT
  const secret = getSecret(c);
  const payload = {
    sub: user.id,
    email: user.email,
    role: user.role,
    schoolId: user.school_id,
    exp: Math.floor(Date.now() / 1000) + (12 * 60 * 60) // 12 hours expiration
  };
  const token = await sign(payload, secret);

  return c.json({
    success: true,
    data: {
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role,
        schoolId: user.school_id,
        firstName: user.first_name,
        lastName: user.last_name
      }
    }
  });
});

// ==========================================
// SECURED ENDPOINTS (COACH ROLE REQUIRED)
// ==========================================

// JWT Authentication Guard
app.use('/api/rosters/*', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }
  const token = authHeader.substring(7);
  try {
    const payload = await verify(token, getSecret(c), 'HS256');
    c.set('jwtPayload', payload);
    await next();
  } catch (err) {
    return c.json({ success: false, message: 'Invalid token or session expired' }, 401);
  }
});

app.use('/api/dashboard/*', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }
  const token = authHeader.substring(7);
  try {
    const payload = await verify(token, getSecret(c), 'HS256');
    c.set('jwtPayload', payload);
    await next();
  } catch (err) {
    return c.json({ success: false, message: 'Invalid token or session expired' }, 401);
  }
});

app.use('/api/match-stats', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }
  const token = authHeader.substring(7);
  try {
    const payload = await verify(token, getSecret(c), 'HS256');
    c.set('jwtPayload', payload);
    await next();
  } catch (err) {
    return c.json({ success: false, message: 'Invalid token or session expired' }, 401);
  }
});

// Route: Get Team Roster
app.get('/api/rosters/:age_group', async (c) => {
  const ageGroup = c.req.param('age_group');
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload.schoolId;
  const db = getDB(c);

  const query = 'SELECT * FROM players WHERE school_id = ? AND age_group = ? ORDER BY first_name ASC';
  const { results } = await db.prepare(query).bind(schoolId, ageGroup).all();

  return c.json({
    success: true,
    data: {
      ageGroup,
      players: results.map((p: any) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        ageGroup: p.age_group,
        position: p.position,
        team: p.team,
        status: p.status,
        ugroupsActive: p.ugroups_active
      }))
    }
  });
});

// Route: Get Coach Dashboard Summary KPIs
app.get('/api/dashboard/summary', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload.schoolId;
  const db = getDB(c);

  // Query 1: Total Players
  const totalPlayersQuery = 'SELECT COUNT(*) as count FROM players WHERE school_id = ?';
  const totalRes = await db.prepare(totalPlayersQuery).bind(schoolId).get();
  const totalPlayers = totalRes ? totalRes.count : 0;

  // Query 2: Team average performance score
  const avgPerformanceQuery = 'SELECT AVG(auto_score) as avg FROM match_stats ms JOIN players p ON ms.player_id = p.id WHERE p.school_id = ?';
  const avgRes = await db.prepare(avgPerformanceQuery).bind(schoolId).get();
  const avgScore = avgRes && avgRes.avg ? Math.round(avgRes.avg * 10) / 10 : 0.0;

  // Query 3: RAG Categories count (Academics overall average mapping)
  const academicQuery = `
    SELECT player_id, AVG(grade_percentage) as avg_grade
    FROM academic_logs al
    JOIN players p ON al.player_id = p.id
    WHERE p.school_id = ?
    GROUP BY player_id
  `;
  const { results: acads } = await db.prepare(academicQuery).bind(schoolId).all();
  
  let uniReadyCount = 0; // Green
  let onTrackCount = 0;   // Amber
  let atRiskCount = 0;    // Orange
  let dangerCount = 0;    // Red

  acads.forEach((row: any) => {
    const score = row.avg_grade;
    if (score >= 65) uniReadyCount++;
    else if (score >= 60) onTrackCount++;
    else if (score >= 50) atRiskCount++;
    else dangerCount++;
  });

  // Query 4: Attendance Average (Gym, Field, uGroup attendance percentage)
  const attendanceQuery = `
    SELECT COUNT(*) as total, SUM(CASE WHEN att.status = 'Present' THEN 1 ELSE 0 END) as present
    FROM attendance att
    JOIN players p ON att.player_id = p.id
    WHERE p.school_id = ?
  `;
  const attRes = await db.prepare(attendanceQuery).bind(schoolId).get();
  const attendancePercent = attRes && attRes.total > 0 ? Math.round((attRes.present / attRes.total) * 100) : 100;

  return c.json({
    success: true,
    data: {
      attendancePercent,
      teamPerformanceAvg: avgScore,
      kpis: {
        totalPlayers,
        uniReady: uniReadyCount,
        onTrack: onTrackCount,
        atRisk: atRiskCount,
        danger: dangerCount,
        flagged: atRiskCount + dangerCount
      }
    }
  });
});

// Route: Get Flagged Players (Requires Coach Attention)
app.get('/api/dashboard/flags', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload.schoolId;
  const db = getDB(c);

  // Pull academic averages and recent match statistics to calculate warning flags
  const playersQuery = 'SELECT id, first_name, last_name, age_group, position, team FROM players WHERE school_id = ?';
  const { results: players } = await db.prepare(playersQuery).bind(schoolId).all();

  const flaggedList = [];

  for (const player of players) {
    // 1. Calculate Academic Avg
    const avgGradeQuery = 'SELECT AVG(grade_percentage) as avg FROM academic_logs WHERE player_id = ?';
    const gradeRes = await db.prepare(avgGradeQuery).bind(player.id).get();
    const avgGrade = gradeRes && gradeRes.avg !== null ? Math.round(gradeRes.avg * 10) / 10 : null;

    // 2. Fetch Latest Match Stats
    const latestMatchQuery = 'SELECT auto_score, category, match_date FROM match_stats WHERE player_id = ? ORDER BY match_date DESC LIMIT 1';
    const matchRes = await db.prepare(latestMatchQuery).bind(player.id).get();
    
    // 3. Check for Flags
    let isFlagged = false;
    let reason = '';
    let categoryType = 'Normal';

    if (avgGrade !== null && avgGrade < 60) {
      isFlagged = true;
      categoryType = avgGrade < 50 ? 'Critical' : 'Warning';
      reason = `Academic Drop: Average grade is ${avgGrade}%. Requires tutoring check-in.`;
    } else if (matchRes && matchRes.auto_score < 2.0) {
      isFlagged = true;
      categoryType = 'Warning';
      reason = `Performance Decline: Latest Auto-Score dropped to ${matchRes.auto_score} (Developing).`;
    }

    if (isFlagged) {
      flaggedList.push({
        id: player.id,
        firstName: player.first_name,
        lastName: player.last_name,
        ageGroup: player.age_group,
        position: player.position,
        team: player.team,
        flagReason: reason,
        severity: categoryType,
        avgGrade: avgGrade || 0,
        latestScore: matchRes ? matchRes.auto_score : null
      });
    }
  }

  return c.json({
    success: true,
    data: flaggedList
  });
});

// Route: Log Match Statistics
app.post('/api/match-stats', async (c) => {
  const statsInput = await c.req.json();
  const {
    playerId,
    matchDate,
    opponent,
    tacklesMade,
    tacklesMissed,
    carries,
    metresGained,
    errors,
    penalties,
    workRate,
    overallRating,
  } = statsInput;

  if (!playerId || !matchDate) {
    return c.json({ success: false, message: 'Player ID and Match Date are required' }, 400);
  }

  const db = getDB(c);

  // Calculate Auto Score & Tackle accuracy
  const { autoScore, tacklePercentage, category } = calculateAutoScore({
    tacklesMade: tacklesMade || 0,
    tacklesMissed: tacklesMissed || 0,
    carries: carries || 0,
    metresGained: metresGained || 0.0,
    errors: errors || 0,
    penalties: penalties || 0,
    workRate: workRate || 0,
    overallRating: overallRating || 0,
  });

  // Save to match_stats in D1
  const query = `
    INSERT INTO match_stats (
      player_id, match_date, opponent, tackles_made, tackles_missed, carries, 
      metres_gained, errors, penalties, work_rate, overall_rating, auto_score, 
      tackle_percentage, category
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  try {
    const res = await db.prepare(query).bind(
      playerId,
      matchDate,
      opponent || 'Unknown',
      tacklesMade || 0,
      tacklesMissed || 0,
      carries || 0,
      metresGained || 0.0,
      errors || 0,
      penalties || 0,
      workRate || 0,
      overallRating || 0,
      autoScore,
      tacklePercentage,
      category
    ).run();

    return c.json({
      success: true,
      data: {
        id: res.meta.last_row_id || null,
        playerId,
        autoScore,
        autoScorePercent: autoScore * 20,
        tacklePercentage: Math.round(tacklePercentage * 100) / 100,
        category
      }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Database insert failed', error: err.message }, 500);
  }
});

// Route: Get Student Portal data (for Students and Parents)
app.get('/api/student-portal', async (c) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }
  const token = authHeader.substring(7);
  let jwtPayload;
  try {
    jwtPayload = await verify(token, getSecret(c), 'HS256') as any;
  } catch (err) {
    return c.json({ success: false, message: 'Invalid session token' }, 401);
  }

  const userId = jwtPayload.sub;
  const role = jwtPayload.role;
  const db = getDB(c);

  if (!db) {
    return c.json({ success: false, message: 'Local database not found' }, 500);
  }

  let playerQuery = '';
  let player;

  if (role === 'Student') {
    playerQuery = 'SELECT * FROM players WHERE user_id = ?';
    player = await db.prepare(playerQuery).bind(userId).get();
  } else if (role === 'Parent') {
    playerQuery = 'SELECT * FROM players WHERE parent_id = ?';
    player = await db.prepare(playerQuery).bind(userId).get();
  } else {
    return c.json({ success: false, message: 'Access Denied: Role not authorized for student portal.' }, 403);
  }

  if (!player) {
    return c.json({ success: false, message: 'Student-athlete profile not found.' }, 404);
  }

  const playerId = player.id;

  // 1. Fetch Academic logs
  const academicsQuery = 'SELECT * FROM academic_logs WHERE player_id = ? ORDER BY term ASC';
  const { results: academics } = await db.prepare(academicsQuery).bind(playerId).all();

  // 2. Fetch Fitness Baselines & Progression
  const baselineQuery = 'SELECT * FROM fitness_baselines WHERE player_id = ?';
  const baseline = await db.prepare(baselineQuery).bind(playerId).get();

  const progressionQuery = 'SELECT * FROM fitness_progression WHERE player_id = ? ORDER BY week ASC';
  const { results: progressions } = await db.prepare(progressionQuery).bind(playerId).all();

  // 3. Fetch Match Stats History
  const matchesQuery = 'SELECT * FROM match_stats WHERE player_id = ? ORDER BY match_date DESC';
  const { results: matches } = await db.prepare(matchesQuery).bind(playerId).all();

  // 4. Fetch Attendance Summary
  const attendanceQuery = `
    SELECT session_type, COUNT(*) as total, SUM(CASE WHEN att.status = 'Present' THEN 1 ELSE 0 END) as present
    FROM attendance att
    JOIN players p ON att.player_id = p.id
    WHERE p.id = ?
    GROUP BY session_type
  `;
  const { results: attendance } = await db.prepare(attendanceQuery).bind(playerId).all();

  return c.json({
    success: true,
    data: {
      profile: {
        id: player.id,
        firstName: player.first_name,
        lastName: player.last_name,
        ageGroup: player.age_group,
        position: player.position,
        team: player.team,
        grade: player.grade,
        age: player.age,
        ugroupsActive: player.ugroups_active,
        notes: player.notes,
        parentName: player.parent_name,
        parentContact: player.parent_contact
      },
      academics: academics.map((a: any) => ({
        id: a.id,
        term: a.term,
        gradePercentage: a.grade_percentage,
        disciplineScore: a.discipline_score
      })),
      fitness: {
        baseline: baseline ? {
          speed40m: baseline.speed_40m,
          speed60m: baseline.speed_60m,
          broadJump: baseline.broad_jump,
          pushUps: baseline.push_ups,
          pullUps: baseline.pull_ups,
          squats40kg: baseline.squats_40kg,
          verticalJump: baseline.vertical_jump,
          tTest: baseline.t_test
        } : null,
        progressions: progressions.map((p: any) => ({
          week: p.week,
          speed40m: p.speed_40m,
          strengthReps: p.strength_reps,
          weight: p.weight,
          gymSessionsPerWeek: p.gym_sessions_per_week
        }))
      },
      matches: matches.map((m: any) => ({
        id: m.id,
        matchDate: m.match_date,
        opponent: m.opponent,
        tacklesMade: m.tackles_made,
        tacklesMissed: m.tackles_missed,
        carries: m.carries,
        metresGained: m.metres_gained,
        errors: m.errors,
        penalties: m.penalties,
        workRate: m.work_rate,
        overallRating: m.overall_rating,
        autoScore: m.auto_score,
        tacklePercentage: m.tackle_percentage,
        category: m.category
      })),
      attendance: attendance.map((a: any) => ({
        sessionType: a.session_type,
        total: a.total,
        present: a.present || 0
      }))
    }
  });
});

export default app;
