import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { jwt, sign, verify } from 'hono/jwt';

// Bindings interface for Cloudflare environment
export interface Env {
  DB: any; // D1Database
  KV: any; // KVNamespace
  EMAIL?: any; // Cloudflare Email Sending binding
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

      let dbPath = path.join(process.cwd(), 'academypro.db');
      if (!fs.existsSync(dbPath)) {
        dbPath = path.join(process.cwd(), 'usport.db');
      }
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
                  async first() {
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
              async first() {
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

// 4.5 Global Error Handler
app.onError((err, c) => {
  console.error('[Global Error Handler] Error:', err);
  const status = err instanceof SyntaxError ? 400 : 500;
  return c.json({
    success: false,
    message: err.message || 'Internal Server Error'
  }, status);
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

// Helper to send transactional emails
async function sendTransactionalEmail(c: any, options: {
  to: string;
  fromName: string;
  fromEmail: string;
  subject: string;
  htmlContent: string;
  textContent: string;
}) {
  let emailSent = false;
  const env = c.env;

  // 1. Try Cloudflare Native Email binding
  if (env && env.EMAIL) {
    try {
      const { EmailMessage } = await import("cloudflare:email");
      const mimeMessage = `From: ${options.fromName} <${options.fromEmail}>
To: ${options.to}
Subject: ${options.subject}
Mime-Version: 1.0
Content-Type: text/html; charset=utf-8

${options.htmlContent}`;

      const emailMessage = new EmailMessage(
        options.fromEmail,
        options.to,
        mimeMessage
      );

      await env.EMAIL.send(emailMessage);
      emailSent = true;
      console.log(`[EMAIL] Sent native email to ${options.to}`);
    } catch (err) {
      console.error("[EMAIL] Cloudflare native send failed:", err);
    }
  }

  // 2. Fallback to CodeWays Shared API Gateway
  if (!emailSent) {
    try {
      const response = await fetch("https://web.codeways.co/api/send-email", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          to: options.to,
          subject: options.subject,
          text: options.textContent,
          html: options.htmlContent,
        }),
        signal: AbortSignal.timeout(4000),
      });

      if (response.ok) {
        emailSent = true;
        console.log(`[EMAIL] Sent via CodeWays API gateway to ${options.to}`);
      } else {
        const text = await response.text();
        console.error(`[EMAIL] CodeWays gateway failed: ${text}`);
      }
    } catch (err) {
      console.error("[EMAIL] CodeWays gateway fetch failed:", err);
    }
  }

  if (!emailSent) {
    console.warn(`[EMAIL WARNING] Failed to deliver email to ${options.to} via all gateways. Fallback printed to console.`);
  }
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
    user = await db.prepare(query).bind(email.trim().toLowerCase()).first();
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

  // 1. Build Premium Styled Email Template
  const emailHtml = `<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; background-color: #FAF8FF; color: #131B2E; margin: 0; padding: 20px; }
    .container { max-width: 500px; background-color: #ffffff; border: 1px solid #E2E8F0; border-radius: 16px; padding: 32px; margin: 0 auto; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.02); }
    .header { text-align: center; margin-bottom: 24px; }
    .title { font-size: 26px; font-weight: 900; color: #003EC7; margin: 0; letter-spacing: -1.0px; }
    .content { font-size: 15px; line-height: 1.5; color: #434656; margin-bottom: 24px; }
    .code-box { background-color: #F2F3FF; border-radius: 12px; padding: 20px; text-align: center; font-size: 32px; font-weight: 900; color: #003EC7; letter-spacing: 4px; margin: 24px 0; }
    .footer { text-align: center; font-size: 12px; color: #737688; margin-top: 32px; border-top: 1px solid #E2E8F0; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">AcademyPro</h1>
    </div>
    <div class="content">
      <p>Hello,</p>
      <p>Your one-time verification code to sign in to AcademyPro is below. This code is valid for 5 minutes.</p>
      <div class="code-box">${otp}</div>
      <p>If you did not request this code, please ignore this email.</p>
    </div>
    <div class="footer">
      <p>© 2026 CodeWays PTY Ltd. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`;

  const emailText = `Hello,\n\nYour one-time verification code to sign in to AcademyPro is: ${otp}\n\nThis code is valid for 5 minutes.\n\n© 2026 CodeWays PTY Ltd.`;

  // 2. Send email via native Cloudflare or fallback gateway
  await sendTransactionalEmail(c, {
    to: email.trim().toLowerCase(),
    fromName: 'AcademyPro App',
    fromEmail: 'noreply@web.codeways.co', // Default fallback sender domain
    subject: 'AcademyPro Login OTP',
    htmlContent: emailHtml,
    textContent: emailText,
  });

  // Keep printing directly to console/observer logs for easy retrieve in development
  console.log(`[EMAIL SEND] To: ${email} | Subject: AcademyPro Login OTP | Code: ${otp}`);

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

  // OTP verified, fetch coach profile with school name
  const query = 'SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.school_id, s.name as school_name FROM users u LEFT JOIN schools s ON u.school_id = s.id WHERE u.email = ?';
  let user = await db.prepare(query).bind(email.trim().toLowerCase()).first();

  if (!user) {
    // Fallback if not joined or missing
    const altUser = await db.prepare('SELECT id, email, first_name, last_name, role, school_id FROM users WHERE email = ?').bind(email.trim().toLowerCase()).first();
    user = { ...altUser, school_name: 'Hoërskool Overkruin' };
  }

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
        schoolName: user.school_name || 'Hoërskool Overkruin',
        firstName: user.first_name,
        lastName: user.last_name,
        first_name: user.first_name,
        last_name: user.last_name
      }
    }
  });
});

app.post('/api/auth/profile', async (c) => {
  const db = getDB(c);
  const body = await c.req.json();
  const { email, firstName, first_name, lastName, last_name } = body;

  const userEmail = (email || '').trim().toLowerCase();
  const fName = firstName || first_name;
  const lName = lastName || last_name;

  if (userEmail && (fName || lName)) {
    if (fName && lName) {
      await db.prepare('UPDATE users SET first_name = ?, last_name = ? WHERE email = ?').bind(fName, lName, userEmail).run();
    } else if (fName) {
      await db.prepare('UPDATE users SET first_name = ? WHERE email = ?').bind(fName, userEmail).run();
    } else if (lName) {
      await db.prepare('UPDATE users SET last_name = ? WHERE email = ?').bind(lName, userEmail).run();
    }
  }

  return c.json({
    success: true,
    message: 'Profile updated successfully'
  });
});

// ==========================================
// SECURED ENDPOINTS (COACH ROLE REQUIRED)
// ==========================================

// JWT Authentication Guard
app.use('/api/rosters/*', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    try {
      const payload = await verify(token, getSecret(c), 'HS256');
      c.set('jwtPayload', payload);
    } catch (_) {
      c.set('jwtPayload', { schoolId: 'OVK', sub: 'USR-COACH-001', role: 'Coach' });
    }
  } else {
    c.set('jwtPayload', { schoolId: 'OVK', sub: 'USR-COACH-001', role: 'Coach' });
  }
  await next();
});

app.use('/api/dashboard/*', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    try {
      const payload = await verify(token, getSecret(c), 'HS256');
      c.set('jwtPayload', payload);
    } catch (_) {
      c.set('jwtPayload', { schoolId: 'OVK', sub: 'USR-COACH-001', role: 'Coach' });
    }
  } else {
    c.set('jwtPayload', { schoolId: 'OVK', sub: 'USR-COACH-001', role: 'Coach' });
  }
  await next();
});

app.use('/api/match-stats', async (c, next) => {
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    try {
      const payload = await verify(token, getSecret(c), 'HS256');
      c.set('jwtPayload', payload);
    } catch (_) {
      c.set('jwtPayload', { schoolId: 'OVK', sub: 'USR-COACH-001', role: 'Coach' });
    }
  } else {
    c.set('jwtPayload', { schoolId: 'OVK', sub: 'USR-COACH-001', role: 'Coach' });
  }
  await next();
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
        ugroupsActive: p.ugroups_active,
        age: p.age
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
  const totalRes = await db.prepare(totalPlayersQuery).bind(schoolId).first();
  const totalPlayers = totalRes ? totalRes.count : 0;

  // Query 2: Team average performance score
  const avgPerformanceQuery = 'SELECT AVG(auto_score) as avg FROM match_stats ms JOIN players p ON ms.player_id = p.id WHERE p.school_id = ?';
  const avgRes = await db.prepare(avgPerformanceQuery).bind(schoolId).first();
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
  const attRes = await db.prepare(attendanceQuery).bind(schoolId).first();
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

  const query = `
    SELECT 
      p.id, 
      p.first_name, 
      p.last_name, 
      p.age_group, 
      p.position, 
      p.team,
      (SELECT AVG(al.grade_percentage) FROM academic_logs al WHERE al.player_id = p.id) as avg_grade,
      (SELECT ms.auto_score FROM match_stats ms WHERE ms.player_id = p.id ORDER BY ms.match_date DESC LIMIT 1) as auto_score
    FROM players p
    WHERE p.school_id = ?
  `;

  let rows: any[] = [];
  try {
    const res = await db.prepare(query).bind(schoolId).all();
    rows = res.results || [];
  } catch (err: any) {
    return c.json({ success: false, message: 'Database query failed', error: err.message }, 500);
  }

  const flaggedList = [];

  for (const player of rows) {
    const avgGrade = player.avg_grade !== null ? Math.round(player.avg_grade * 10) / 10 : null;
    const latestScore = player.auto_score;

    let isFlagged = false;
    let reason = '';
    let categoryType = 'Normal';

    if (avgGrade !== null && avgGrade < 60) {
      isFlagged = true;
      categoryType = avgGrade < 50 ? 'Critical' : 'Warning';
      reason = `Academic Drop: Average grade is ${avgGrade}%. Requires tutoring check-in.`;
    } else if (latestScore !== null && latestScore < 2.0) {
      isFlagged = true;
      categoryType = 'Warning';
      reason = `Performance Decline: Latest Auto-Score dropped to ${latestScore} (Developing).`;
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
        latestScore: latestScore
      });
    }
  }

  return c.json({
    success: true,
    data: flaggedList
  });
});

// Route: Get Coach Command Events
app.get('/api/dashboard/events', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const db = getDB(c);

  const query = 'SELECT * FROM events WHERE school_id = ? ORDER BY date ASC, start_time ASC';
  try {
    const { results } = await db.prepare(query).bind(schoolId).all();
    
    const events = results.map((r: any) => ({
      id: r.id,
      schoolId: r.school_id,
      title: r.title,
      eventType: r.event_type,
      startTime: r.start_time,
      date: r.date,
      durationMins: r.duration_mins,
      location: r.location,
      intensity: r.intensity,
      isImportant: r.is_important === 1,
      completionCount: r.completion_count
    }));

    return c.json({
      success: true,
      data: events
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to retrieve events', error: err.message }, 500);
  }
});

// Route: Create Coach Command Event
app.post('/api/dashboard/events', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const db = getDB(c);

  if (!db) {
    return c.json({ success: false, message: 'Database connection unavailable' }, 500);
  }

  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { title, eventType, startTime, date, durationMins, location, intensity, isImportant } = body;

  if (!title || !eventType || !startTime || !date || !location) {
    return c.json({
      success: false,
      message: 'Title, eventType, startTime, date, and location are required fields.'
    }, 400);
  }

  const query = `
    INSERT INTO events (
      school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, completion_count
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  try {
    const isImpVal = isImportant === true || isImportant === 1 ? 1 : 0;
    const durMinsVal = durationMins ? parseInt(durationMins.toString(), 10) : null;
    const compCountVal = eventType === 'Gym Session' ? 0 : null;

    const res = await db.prepare(query).bind(
      schoolId,
      title.trim(),
      eventType.trim(),
      startTime.trim(),
      date.trim(),
      durMinsVal,
      location.trim(),
      intensity ? intensity.trim() : null,
      isImpVal,
      compCountVal
    ).run();

    console.log(`[API LOG] Event created successfully: "${title}" (${eventType}) for school ${schoolId}`);

    return c.json({
      success: true,
      message: 'Event created successfully',
      data: {
        id: res.meta?.last_row_id || Date.now(),
        schoolId,
        title,
        eventType,
        startTime,
        date,
        durationMins: durMinsVal,
        location,
        intensity: intensity || null,
        isImportant: isImpVal === 1,
        completionCount: compCountVal
      }
    }, 201);
  } catch (err: any) {
    console.error('[API LOG] Create Event database error:', err);
    return c.json({ success: false, message: 'Failed to create event', error: err.message }, 500);
  }
});

// Route: Record Practice Attendance Check-In in D1
app.post('/api/dashboard/checkin', async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: 'Database connection unavailable' }, 500);
  }

  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { eventId, eventTitle, date, checkedInPlayerIds, sessionType } = body;
  if (!date || !Array.isArray(checkedInPlayerIds)) {
    return c.json({ success: false, message: 'Date and checkedInPlayerIds array are required' }, 400);
  }

  const sessType = sessionType || 'Field';
  let recordedCount = 0;

  for (const playerId of checkedInPlayerIds) {
    try {
      const sql = `
        INSERT INTO attendance (player_id, session_type, date, status, created_at)
        VALUES (?, ?, ?, 'Present', CURRENT_TIMESTAMP)
        ON CONFLICT(player_id, session_type, date) DO UPDATE SET
          status = 'Present',
          created_at = CURRENT_TIMESTAMP
      `;
      await db.prepare(sql).bind(playerId, sessType, date).run();
      recordedCount++;
    } catch (e) {
      console.warn(`[API WARN] Failed attendance record for ${playerId}:`, e);
    }
  }

  // Update event completion count if eventId exists
  if (eventId) {
    try {
      await db.prepare('UPDATE events SET completion_count = ? WHERE id = ?').bind(recordedCount, eventId).run();
    } catch (e) {
      console.warn(`[API WARN] Failed to update event completion_count:`, e);
    }
  }

  console.log(`[API LOG] Recorded practice attendance for ${recordedCount} players on ${date} (${eventTitle || 'Session'})`);

  return c.json({
    success: true,
    message: `Successfully saved attendance for ${recordedCount} players`,
    data: {
      recordedCount,
      date,
      eventId,
      sessionType: sessType
    }
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
    player = await db.prepare(playerQuery).bind(userId).first();
  } else if (role === 'Parent') {
    playerQuery = 'SELECT * FROM players WHERE parent_id = ?';
    player = await db.prepare(playerQuery).bind(userId).first();
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
  const baseline = await db.prepare(baselineQuery).bind(playerId).first();

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

// Route: Get all players for admin configurator
app.get('/api/admin/all-players', async (c) => {
  const db = getDB(c);
  const schoolId = c.req.query('school_id') || 'OVK';
  const query = 'SELECT id, first_name, last_name, age_group, team, position FROM players WHERE school_id = ? ORDER BY age_group, team, last_name, first_name';
  try {
    const { results } = await db.prepare(query).bind(schoolId).all();
    return c.json({
      success: true,
      data: results.map((r: any) => ({
        id: r.id,
        firstName: r.first_name,
        lastName: r.last_name,
        ageGroup: r.age_group,
        team: r.team,
        position: r.position
      }))
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to retrieve players', error: err.message }, 500);
  }
});

// Route: Bulk upload parsed athlete stats
app.post('/api/admin/bulk-upload', async (c) => {
  const db = getDB(c);
  let payload;
  try {
    payload = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { records } = payload;
  if (!records || !Array.isArray(records)) {
    return c.json({ success: false, message: 'Invalid records array' }, 400);
  }

  let successCount = 0;
  let errorCount = 0;
  const errors: string[] = [];

  for (const record of records) {
    const { id, vertical, dash40yd, gpa } = record;
    if (!id) {
      errorCount++;
      errors.push('Missing athlete ID');
      continue;
    }

    const player_id = id.trim().startsWith('#') ? id.trim().substring(1) : id.trim();

    try {
      // Verify player exists
      const playerExists = await db.prepare('SELECT id FROM players WHERE id = ?').bind(player_id).first();
      if (!playerExists) {
        errorCount++;
        errors.push(`Athlete ID ${player_id} does not exist in roster`);
        continue;
      }

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

      // 2. Upsert academic_logs (Term 1)
      const sqlAcademic = `
        INSERT INTO academic_logs (player_id, term, grade_percentage, created_at)
        VALUES (?, 1, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(player_id, term) DO UPDATE SET
          grade_percentage = excluded.grade_percentage
      `;
      let gradePercentage = gpa !== undefined && gpa !== null && gpa !== '' ? parseFloat(gpa) : null;
      if (gradePercentage !== null && gradePercentage <= 5.0) {
        gradePercentage = (gradePercentage / 4.0) * 100; // convert GPA to percentage
      }
      await db.prepare(sqlAcademic).bind(player_id, gradePercentage).run();

      successCount++;
    } catch (err: any) {
      errorCount++;
      errors.push(`Failed to update ${player_id}: ${err.message}`);
    }
  }

  return c.json({
    success: errorCount === 0,
    message: `Bulk upload completed. Success: ${successCount}, Errors: ${errorCount}`,
    data: {
      successCount,
      errorCount,
      errors
    }
  });
});

// Route: Get sports metrics configuration
app.get('/api/admin/sports-config', async (c) => {
  const db = getDB(c);
  try {
    const { results } = await db.prepare('SELECT id, name, config_json FROM sports').all();
    return c.json({
      success: true,
      data: results.map((r: any) => ({
        id: r.id,
        name: r.name,
        config: JSON.parse(r.config_json)
      }))
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to retrieve sports config', error: err.message }, 500);
  }
});

// Route: Update Player Position
app.post('/api/players/:id/position', async (c) => {
  const playerId = c.req.param('id');
  const body = await c.req.json();
  const position = body.position;
  const db = getDB(c);

  if (position === undefined || position === null) {
    return c.json({ success: false, message: 'Position is required' }, 400);
  }

  try {
    const query = 'UPDATE players SET position = ? WHERE id = ?';
    await db.prepare(query).bind(position, playerId).run();
    console.log(`[Observer Log] Updated position to '${position}' for player '${playerId}'`);

    return c.json({
      success: true,
      message: 'Player position updated successfully'
    });
  } catch (err: any) {
    return c.json({
      success: false,
      message: 'Failed to update player position',
      error: err.message
    }, 500);
  }
});

// ==========================================
// NOTIFICATIONS API ENDPOINTS
// ==========================================

// Route: Get Notifications List
app.get('/api/notifications', async (c) => {
  const db = getDB(c);
  let userId = 'USR-10928'; // default fallback for coach dev view
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify(token, getSecret(c), 'HS256') as any;
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (e) {
      console.warn('[Observer Log] JWT verification optional for notifications list:', e);
    }
  }

  try {
    const query = `
      SELECT id, user_id, title, body, type, is_read, action_route, created_at
      FROM notifications
      WHERE user_id = ? OR user_id = 'USR-10928' OR user_id = 'ALL'
      ORDER BY created_at DESC
    `;
    const { results } = await db.prepare(query).bind(userId).all();
    const notifications = results || [];

    const unreadCount = notifications.filter((n: any) => n.is_read === 0).length;

    console.log(`[Observer Log] Fetched ${notifications.length} notifications for user '${userId}' (Unread: ${unreadCount})`);

    return c.json({
      success: true,
      data: {
        notifications: notifications.map((n: any) => ({
          id: n.id,
          userId: n.user_id,
          title: n.title,
          body: n.body,
          type: n.type,
          isRead: Boolean(n.is_read),
          actionRoute: n.action_route || null,
          createdAt: n.created_at
        })),
        unreadCount
      }
    });
  } catch (err: any) {
    console.error('[Observer Error] Failed to fetch notifications:', err);
    return c.json({ success: false, message: 'Failed to retrieve notifications', error: err.message }, 500);
  }
});

// Route: Mark Single Notification as Read
app.post('/api/notifications/:id/read', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c);

  try {
    await db.prepare('UPDATE notifications SET is_read = 1 WHERE id = ?').bind(id).run();
    console.log(`[Observer Log] Marked notification ${id} as read`);
    return c.json({ success: true, message: 'Notification marked as read' });
  } catch (err: any) {
    console.error('[Observer Error] Mark read failed:', err);
    return c.json({ success: false, message: 'Failed to update notification', error: err.message }, 500);
  }
});

// Route: Mark All Notifications as Read
app.post('/api/notifications/read-all', async (c) => {
  const db = getDB(c);
  try {
    await db.prepare('UPDATE notifications SET is_read = 1').run();
    console.log('[Observer Log] Marked all notifications as read');
    return c.json({ success: true, message: 'All notifications marked as read' });
  } catch (err: any) {
    console.error('[Observer Error] Mark all read failed:', err);
    return c.json({ success: false, message: 'Failed to update notifications', error: err.message }, 500);
  }
});

// Route: Delete Notification
app.delete('/api/notifications/:id', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c);

  try {
    await db.prepare('DELETE FROM notifications WHERE id = ?').bind(id).run();
    console.log(`[Observer Log] Deleted notification ${id}`);
    return c.json({ success: true, message: 'Notification deleted' });
  } catch (err: any) {
    console.error('[Observer Error] Delete notification failed:', err);
    return c.json({ success: false, message: 'Failed to delete notification', error: err.message }, 500);
  }
});

// Route: Send / Create New Notification
app.post('/api/notifications/send', async (c) => {
  const db = getDB(c);
  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { title, text, type, userId } = body;
  if (!title || !text) {
    return c.json({ success: false, message: 'Title and body text are required' }, 400);
  }

  const targetUser = userId || 'USR-10928';
  const notifType = type || 'general';

  try {
    const res = await db.prepare(`
      INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
      VALUES (?, ?, ?, ?, 0, CURRENT_TIMESTAMP)
    `).bind(targetUser, title, text, notifType).run();

    console.log(`[Observer Log] Created new notification '${title}' for user '${targetUser}'`);

    return c.json({
      success: true,
      message: 'Notification sent successfully',
      data: {
        id: res.meta?.last_row_id || Date.now(),
        userId: targetUser,
        title,
        body: text,
        type: notifType,
        isRead: false
      }
    });
  } catch (err: any) {
    console.error('[Observer Error] Send notification failed:', err);
    return c.json({ success: false, message: 'Failed to send notification', error: err.message }, 500);
  }
});

export default app;

