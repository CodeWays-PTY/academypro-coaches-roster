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
    user = await db.prepare('SELECT id, email, first_name, last_name, role, school_id FROM users WHERE email = ?').bind(email.trim().toLowerCase()).first();
  }

  if (!user) {
    return c.json({ success: false, message: 'User profile not found after OTP verification' }, 404);
  }

  // Delete OTP from cache
  await kv.delete(`otp:${email.trim().toLowerCase()}`);

  // Sign JWT
  const secret = getSecret(c);
  const payload = {
    sub: user.id,
    email: user.email,
    role: user.role,
    schoolId: user.school_id || null,
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
        schoolId: user.school_id || null,
        schoolName: user.school_name || null,
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

// Route: Request Email Change (Dispatches 6-digit OTP to NEW email)
app.post('/api/auth/send-email-change-otp', async (c) => {
  const db = getDB(c);
  let body: any;
  try { body = await c.req.json(); } catch (_) { return c.json({ success: false, message: 'Invalid payload' }, 400); }

  const { newEmail, currentEmail } = body;
  if (!newEmail || !currentEmail) {
    return c.json({ success: false, message: 'Current email and new email are required' }, 400);
  }

  const cleanNewEmail = newEmail.trim().toLowerCase();
  const cleanCurrentEmail = currentEmail.trim().toLowerCase();

  const existingUser = await db.prepare('SELECT id FROM users WHERE email = ? AND email != ?').bind(cleanNewEmail, cleanCurrentEmail).first();
  if (existingUser) {
    return c.json({ success: false, message: 'This email address is already registered to another account.' }, 400);
  }

  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

  await db.prepare(`
    INSERT INTO user_otps (email, otp, expires_at)
    VALUES (?, ?, ?)
    ON CONFLICT(email) DO UPDATE SET otp = excluded.otp, expires_at = excluded.expires_at
  `).bind(cleanNewEmail, otp, expiresAt).run();

  await sendTransactionalEmail(
    cleanNewEmail,
    'Verify Your New AcademyPro Email Address',
    `<div style="font-family: Arial, sans-serif; padding: 20px; color: #1E293B;">
      <h2 style="color: #003EC7;">Email Change Verification</h2>
      <p>You requested to update your primary email address on AcademyPro.</p>
      <p>Use the 6-digit verification code below to confirm this change:</p>
      <div style="font-size: 28px; font-weight: bold; color: #003EC7; letter-spacing: 4px; padding: 12px 0;">${otp}</div>
      <p style="font-size: 12px; color: #64748B;">This code is valid for 10 minutes. If you did not request this, please ignore this email.</p>
    </div>`
  );

  return c.json({
    success: true,
    message: `Verification code sent to ${cleanNewEmail}`
  });
});

// Route: Verify New Email OTP & Perform Cascading Database Update
app.post('/api/auth/verify-new-email', async (c) => {
  const db = getDB(c);
  let body: any;
  try { body = await c.req.json(); } catch (_) { return c.json({ success: false, message: 'Invalid payload' }, 400); }

  const { currentEmail, newEmail, otp } = body;
  if (!currentEmail || !newEmail || !otp) {
    return c.json({ success: false, message: 'Current email, new email, and OTP code are required' }, 400);
  }

  const cleanCurrentEmail = currentEmail.trim().toLowerCase();
  const cleanNewEmail = newEmail.trim().toLowerCase();

  const otpRecord = await db.prepare('SELECT * FROM user_otps WHERE email = ? AND otp = ?').bind(cleanNewEmail, otp.trim()).first();
  if (!otpRecord) {
    return c.json({ success: false, message: 'Invalid verification code. Please check your email and try again.' }, 400);
  }

  const now = new Date().toISOString();
  if (otpRecord.expires_at < now) {
    return c.json({ success: false, message: 'Verification code has expired. Please request a new code.' }, 400);
  }

  try {
    await db.prepare('UPDATE users SET email = ? WHERE email = ?').bind(cleanNewEmail, cleanCurrentEmail).run();
    await db.prepare('UPDATE players SET email = ? WHERE email = ?').bind(cleanNewEmail, cleanCurrentEmail).run();
    await db.prepare('UPDATE parent_child_links SET player_email = ? WHERE player_email = ?').bind(cleanNewEmail, cleanCurrentEmail).run();
    await db.prepare('DELETE FROM user_otps WHERE email = ?').bind(cleanNewEmail).run();

    return c.json({
      success: true,
      message: `Email address updated successfully to ${cleanNewEmail}`,
      data: { updatedEmail: cleanNewEmail }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to update email address in database', error: err.message }, 500);
  }
});

// ==========================================
// SECURED ENDPOINTS (COACH ROLE REQUIRED)
// ==========================================

// JWT Authentication Guard
async function enforceJwtAuth(c: any, next: any) {
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    try {
      const payload = await verify(token, getSecret(c), 'HS256');
      c.set('jwtPayload', payload);
      await next();
      return;
    } catch (_) {
      return c.json({ success: false, message: 'Invalid or expired session token' }, 401);
    }
  }
  return c.json({ success: false, message: 'Authorization header required' }, 401);
}

app.use('/api/rosters/*', enforceJwtAuth);
app.use('/api/dashboard/*', enforceJwtAuth);
app.use('/api/match-stats/*', enforceJwtAuth);
app.use('/api/match-stats', enforceJwtAuth);

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
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const db = getDB(c);

  let totalPlayersQuery = 'SELECT COUNT(*) as count FROM players WHERE school_id = ?';
  let totalParams: any[] = [schoolId];
  if (ageGroup) {
    totalPlayersQuery = 'SELECT COUNT(*) as count FROM players WHERE school_id = ? AND age_group = ?';
    totalParams.push(ageGroup);
  }
  const totalRes = await db.prepare(totalPlayersQuery).bind(...totalParams).first();
  const totalPlayers = totalRes ? totalRes.count : 0;

  let avgPerformanceQuery = 'SELECT AVG(auto_score) as avg FROM match_stats ms JOIN players p ON ms.player_id = p.id WHERE p.school_id = ?';
  let avgParams: any[] = [schoolId];
  if (ageGroup) {
    avgPerformanceQuery = 'SELECT AVG(auto_score) as avg FROM match_stats ms JOIN players p ON ms.player_id = p.id WHERE p.school_id = ? AND p.age_group = ?';
    avgParams.push(ageGroup);
  }
  const avgRes = await db.prepare(avgPerformanceQuery).bind(...avgParams).first();
  const avgScore = avgRes && avgRes.avg ? Math.round(avgRes.avg * 10) / 10 : 0.0;

  let academicQuery = `
    SELECT player_id, AVG(grade_percentage) as avg_grade
    FROM academic_logs al
    JOIN players p ON al.player_id = p.id
    WHERE p.school_id = ?
    GROUP BY player_id
  `;
  let acadParams: any[] = [schoolId];
  if (ageGroup) {
    academicQuery = `
      SELECT player_id, AVG(grade_percentage) as avg_grade
      FROM academic_logs al
      JOIN players p ON al.player_id = p.id
      WHERE p.school_id = ? AND p.age_group = ?
      GROUP BY player_id
    `;
    acadParams.push(ageGroup);
  }
  const { results: acads } = await db.prepare(academicQuery).bind(...acadParams).all();
  
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

  let attendanceQuery = `
    SELECT COUNT(*) as total, SUM(CASE WHEN att.status = 'Present' THEN 1 ELSE 0 END) as present
    FROM attendance att
    JOIN players p ON att.player_id = p.id
    WHERE p.school_id = ?
  `;
  let attParams: any[] = [schoolId];
  if (ageGroup) {
    attendanceQuery = `
      SELECT COUNT(*) as total, SUM(CASE WHEN att.status = 'Present' THEN 1 ELSE 0 END) as present
      FROM attendance att
      JOIN players p ON att.player_id = p.id
      WHERE p.school_id = ? AND p.age_group = ?
    `;
    attParams.push(ageGroup);
  }
  const attRes = await db.prepare(attendanceQuery).bind(...attParams).first();
  const attendancePercent = attRes && attRes.total > 0 ? Math.round((attRes.present / attRes.total) * 100) : 0;

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
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const db = getDB(c);

  let query = `
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
  let params: any[] = [schoolId];
  if (ageGroup) {
    query = `
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
      WHERE p.school_id = ? AND p.age_group = ?
    `;
    params.push(ageGroup);
  }

  let rows: any[] = [];
  try {
    const res = await db.prepare(query).bind(...params).all();
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

// Helper to automatically purge workout images from R2 and D1 for events older than 7 days (1 week)
async function purgeExpiredWorkoutImages(c: any, results: any[]) {
  const db = getDB(c);
  const r2 = c.env?.R2;
  const sevenDaysMs = 7 * 24 * 60 * 60 * 1000;
  const nowMs = Date.now();

  for (const r of results) {
    if (!r.workout_image_path) continue;

    try {
      const eventDateMs = new Date(r.date).getTime();
      if (!isNaN(eventDateMs) && (nowMs - eventDateMs) > sevenDaysMs) {
        const imagePath = r.workout_image_path;

        // 1. Delete object from Cloudflare R2 bucket if binding exists
        if (r2 && typeof r2.delete === 'function') {
          const key = imagePath.includes('/') ? imagePath.split('/').pop() : imagePath;
          if (key) {
            await r2.delete(key);
            console.log(`[Observer Log] [R2 PURGE] Deleted workout image '${key}' for event #${r.id} older than 7 days.`);
          }
        }

        // 2. Clear workout_image_path reference in D1 database
        await db.prepare('UPDATE events SET workout_image_path = NULL WHERE id = ?')
          .bind(r.id)
          .run();

        r.workout_image_path = null;
      }
    } catch (err) {
      console.warn(`[Observer Error] [R2 PURGE] Failed purging workout image for event #${r?.id}:`, err);
    }
  }
}

// Route: Get Coach Command Events
app.get('/api/dashboard/events', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const team = c.req.query('team');
  const db = getDB(c);

  let query = 'SELECT * FROM events WHERE school_id = ? ORDER BY date ASC, start_time ASC';
  let params: any[] = [schoolId];
  if (ageGroup) {
    query = 'SELECT * FROM events WHERE school_id = ? AND (age_group = ? OR age_group IS NULL OR age_group = "") ORDER BY date ASC, start_time ASC';
    params.push(ageGroup);
  }

  try {
    const { results } = await db.prepare(query).bind(...params).all();
    
    // Purge workout images for events older than 1 week (7 days) asynchronously
    if (c.executionCtx && typeof c.executionCtx.waitUntil === 'function') {
      c.executionCtx.waitUntil(purgeExpiredWorkoutImages(c, results || []));
    } else {
      purgeExpiredWorkoutImages(c, results || []).catch(() => {});
    }

    let events = (results || []).map((r: any) => ({
      id: r.id?.toString() || '',
      schoolId: r.school_id,
      title: r.title,
      eventType: r.event_type,
      startTime: r.start_time,
      date: r.date,
      durationMins: r.duration_mins,
      location: r.location,
      intensity: r.intensity,
      isImportant: r.is_important === 1,
      completionCount: r.completion_count,
      ageGroup: r.age_group || null,
      team: r.team || r.age_group || null,
      workoutImagePath: r.workout_image_path
    }));

    if (team) {
      events = events.filter((e: any) => e.team && e.team.toLowerCase().trim() === team.toLowerCase().trim());
    }

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
  const schoolId = jwtPayload?.schoolId || null;
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

  const { id, title, eventType, startTime, date, durationMins, location, intensity, isImportant, ageGroup, team, workoutImagePath } = body;

  if (!title || !eventType || !startTime || !date || !location) {
    return c.json({
      success: false,
      message: 'Title, eventType, startTime, date, and location are required fields.'
    }, 400);
  }

  const eventId = id ? id.toString() : `EVT-${Date.now()}`;
  const assignedTeam = team ? team.trim() : (ageGroup ? ageGroup.trim() : null);

  const query = `
    INSERT INTO events (
      id, school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, completion_count, age_group, team, workout_image_path
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `;

  try {
    const isImpVal = isImportant === true || isImportant === 1 ? 1 : 0;
    const durMinsVal = durationMins ? parseInt(durationMins.toString(), 10) : null;
    const compCountVal = eventType === 'Gym Session' ? 0 : null;

    await db.prepare(query).bind(
      eventId,
      schoolId,
      title.trim(),
      eventType.trim(),
      startTime.trim(),
      date.trim(),
      durMinsVal,
      location.trim(),
      intensity ? intensity.trim() : null,
      isImpVal,
      compCountVal,
      ageGroup ? ageGroup.trim() : null,
      assignedTeam,
      workoutImagePath || null
    ).run();

    return c.json({
      success: true,
      message: 'Event created successfully',
      data: {
        id: eventId,
        schoolId,
        title,
        eventType,
        startTime,
        date,
        durationMins: durMinsVal,
        location,
        intensity: intensity || null,
        isImportant: isImpVal === 1,
        completionCount: compCountVal,
        ageGroup: ageGroup ? ageGroup.trim() : null,
        team: assignedTeam,
        workoutImagePath: workoutImagePath || null
      }
    }, 201);
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to create event', error: err.message }, 500);
  }
});

// Route: Update Coach Command Event
app.post('/api/dashboard/events/:id', async (c) => {
  const id = c.req.param('id');
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

  const { title, eventType, startTime, date, durationMins, location, intensity, isImportant, ageGroup, team, workoutImagePath } = body;
  const isImpVal = isImportant === true || isImportant === 1 ? 1 : 0;
  const durMinsVal = durationMins ? parseInt(durationMins.toString(), 10) : null;

  try {
    const query = `
      UPDATE events SET 
        title = ?, event_type = ?, start_time = ?, date = ?, duration_mins = ?, 
        location = ?, intensity = ?, is_important = ?, age_group = ?, team = ?, workout_image_path = ?
      WHERE CAST(id AS TEXT) = ? OR id = ?
    `;
    await db.prepare(query).bind(
      title.trim(), eventType.trim(), startTime.trim(), date.trim(), durMinsVal,
      location.trim(), intensity ? intensity.trim() : null, isImpVal, ageGroup ? ageGroup.trim() : null,
      team ? team.trim() : (ageGroup ? ageGroup.trim() : null), workoutImagePath || null, id.toString(), id.toString()
    ).run();

    return c.json({ success: true, message: 'Event updated successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to update event', error: err.message }, 500);
  }
});

// Route: Delete Coach Command Event
app.delete('/api/dashboard/events/:id', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c);
  try {
    await db.prepare('DELETE FROM events WHERE CAST(id AS TEXT) = ? OR id = ?').bind(id.toString(), id.toString()).run();
    return c.json({ success: true, message: 'Event deleted successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to delete event', error: err.message }, 500);
  }
});

app.post('/api/dashboard/events/:id/delete', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c);
  try {
    await db.prepare('DELETE FROM events WHERE CAST(id AS TEXT) = ? OR id = ?').bind(id.toString(), id.toString()).run();
    return c.json({ success: true, message: 'Event deleted successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to delete event', error: err.message }, 500);
  }
});

// Route: Get Coach Action Plans from D1
app.get('/api/dashboard/actions', async (c) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: 'Database connection unavailable' }, 500);
  }

  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS action_plans (
        id TEXT PRIMARY KEY,
        school_id TEXT DEFAULT 'OVK',
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        player_id TEXT,
        player_name TEXT,
        parent_name TEXT,
        parent_phone TEXT,
        parent_email TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    const { results } = await db.prepare('SELECT * FROM action_plans ORDER BY created_at DESC').all();
    return c.json({
      success: true,
      data: (results || []).map((row: any) => ({
        id: row.id,
        title: row.title,
        type: row.type,
        category: row.category || row.type,
        deadline: row.deadline,
        dateAdded: row.date_added || 'Today',
        isCompleted: Boolean(row.is_completed),
        playerId: row.player_id,
        playerName: row.player_name || '',
        parentName: row.parent_name || '',
        parentPhone: row.parent_phone || '',
        parentEmail: row.parent_email || '',
        playerPhone: row.player_phone || '',
        notes: row.notes || ''
      }))
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to fetch action plans', error: err.message }, 500);
  }
});

// Route: Create Coach Action Plan in D1
app.post('/api/dashboard/actions', async (c) => {
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

  const { id, title, type, category, deadline, playerId, playerName, notes } = body;
  const actionId = id || `ACT-${Date.now()}`;

  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS action_plans (
        id TEXT PRIMARY KEY,
        school_id TEXT DEFAULT 'OVK',
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        player_id TEXT,
        player_name TEXT,
        parent_name TEXT,
        parent_phone TEXT,
        parent_email TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    await db.prepare(`
      INSERT INTO action_plans (id, title, type, category, deadline, date_added, is_completed, player_id, player_name, notes)
      VALUES (?, ?, ?, ?, ?, 'Today', 0, ?, ?, ?)
    `).bind(
      actionId,
      title ? title.trim() : 'Coach Action Item',
      type ? type.trim() : 'General',
      category ? category.trim() : 'General',
      deadline ? deadline.trim() : 'Today',
      playerId || null,
      playerName ? playerName.trim() : '',
      notes ? notes.trim() : ''
    ).run();

    return c.json({
      success: true,
      message: 'Action plan created successfully',
      data: {
        id: actionId,
        title,
        type: type || 'General',
        category: category || type || 'General',
        deadline: deadline || 'Today',
        isCompleted: false,
        playerId,
        playerName: playerName || ''
      }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to create action plan', error: err.message }, 500);
  }
});

// Route: Toggle Action Plan Completion Status in D1
app.post('/api/dashboard/actions/:id/toggle', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c);
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS action_plans (
        id TEXT PRIMARY KEY,
        school_id TEXT DEFAULT 'OVK',
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        player_id TEXT,
        player_name TEXT,
        parent_name TEXT,
        parent_phone TEXT,
        parent_email TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    await db.prepare('UPDATE action_plans SET is_completed = CASE WHEN is_completed = 1 THEN 0 ELSE 1 END WHERE id = ?').bind(id).run();
    return c.json({ success: true, message: 'Action plan status updated successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to update action plan status', error: err.message }, 500);
  }
});

// Route: Delete Action Plan from D1
app.post('/api/dashboard/actions/:id/delete', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c);
  try {
    await db.prepare('DELETE FROM action_plans WHERE id = ?').bind(id).run();
    return c.json({ success: true, message: 'Action plan deleted successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to delete action plan', error: err.message }, 500);
  }
});

// Route: Get Rising Stars (Top performers by age group)
app.get('/api/dashboard/rising-stars', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const db = getDB(c);

  let query = `
    SELECT 
      p.id, 
      p.first_name, 
      p.last_name, 
      p.age_group, 
      p.position, 
      p.team,
      (SELECT AVG(al.grade_percentage) FROM academic_logs al WHERE al.player_id = p.id) as avg_grade
    FROM players p
    WHERE p.school_id = ?
  `;
  let params: any[] = [schoolId];
  if (ageGroup) {
    query += ' AND p.age_group = ?';
    params.push(ageGroup);
  }
  query += ' ORDER BY p.first_name ASC LIMIT 5';

  try {
    let { results } = await db.prepare(query).bind(...params).all();
    const grp = ageGroup || 'U15';

    if (!results || results.length === 0) {
      return c.json({
        success: true,
        data: []
      });
    }

    const stars = results.map((p: any) => {
      const firstName = p.first_name || 'Player';
      const lastName = p.last_name || '';
      return {
        id: p.id,
        name: `${firstName} ${lastName}`.trim(),
        firstName,
        lastName,
        team: p.team || p.age_group || grp,
        position: p.position || 'Athlete',
        ageGroup: p.age_group || grp,
        streakWeeks: 0,
        gymConsistencyWeeks: 0,
        gradeImprovement: p.avg_grade ? Math.round(p.avg_grade) : 0,
        attendancePercent: 0,
        gymProgressPercent: 0,
        highlights: 'Consistently active squad member'
      };
    });

    return c.json({
      success: true,
      data: stars
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to retrieve rising stars', error: err.message }, 500);
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

  let player: any = null;
  const requestedPlayerId = c.req.query('player_id');

  try {
    if (requestedPlayerId) {
      player = await db.prepare('SELECT * FROM players WHERE id = ?').bind(requestedPlayerId).first();
    } else if (role === 'Student') {
      player = await db.prepare('SELECT * FROM players WHERE user_id = ?').bind(userId).first();
    } else if (role === 'Parent') {
      player = await db.prepare('SELECT * FROM players WHERE parent_id = ?').bind(userId).first();
    }
  } catch (_) {}

  if (!player && !requestedPlayerId) {
    player = await db.prepare('SELECT * FROM players ORDER BY first_name ASC LIMIT 1').first();
  }

  if (!player) {
    return c.json({ success: false, message: 'Student-athlete profile not found.' }, 404);
  }

  const playerId = player.id;

  // 1. Fetch Academic logs
  const academicsQuery = 'SELECT * FROM academic_logs WHERE player_id = ? ORDER BY term ASC';
  const { results: academics } = await db.prepare(academicsQuery).bind(playerId).all();

  // 2b. Fetch Dynamic Test Metrics & Time-Series Logs
  let dynamicMetrics: any[] = [];
  let totalReadinessScore = 0;
  let metricsCount = 0;

  try {
    const { results: metricDefs } = await db.prepare('SELECT * FROM test_metric_definitions WHERE school_id = ? ORDER BY category, name ASC').bind(player.school_id || 'OVK').all();
    if (metricDefs && metricDefs.length > 0) {
      for (const mDef of metricDefs) {
        const { results: logs } = await db.prepare('SELECT * FROM player_test_logs WHERE player_id = ? AND metric_id = ? ORDER BY test_date ASC').bind(playerId, mDef.id).all();
        if (logs && logs.length > 0) {
          const firstLog = logs[0];
          const latestLog = logs[logs.length - 1];
          const initialBaseline = firstLog.score;
          const latestScore = latestLog.score;
          const target = mDef.target_benchmark || latestScore;
          const goalDir = mDef.goal_direction || 'HIGHER_IS_BETTER';

          let targetPercent = 100;
          if (target > 0) {
            if (goalDir === 'HIGHER_IS_BETTER') {
              targetPercent = Math.min(100, Math.round((latestScore / target) * 100));
            } else {
              targetPercent = Math.min(100, Math.round((target / Math.max(0.1, latestScore)) * 100));
            }
          }

          let trendText = 'Initial';
          if (logs.length > 1 && initialBaseline > 0) {
            const diff = latestScore - initialBaseline;
            if (goalDir === 'HIGHER_IS_BETTER') {
              const pct = Math.round((diff / initialBaseline) * 100);
              trendText = pct >= 0 ? `+${pct}%` : `${pct}%`;
            } else {
              const secDiff = (initialBaseline - latestScore).toFixed(1);
              trendText = parseFloat(secDiff) >= 0 ? `-${secDiff}s` : `+${Math.abs(parseFloat(secDiff))}s`;
            }
          }

          totalReadinessScore += targetPercent;
          metricsCount++;

          dynamicMetrics.push({
            id: mDef.id,
            name: mDef.name,
            category: mDef.category,
            unit: mDef.unit,
            goalDirection: goalDir,
            targetBenchmark: target,
            initialBaseline,
            latestScore,
            targetPercent,
            trendText,
            latestTestDate: latestLog.test_date,
            sessionName: latestLog.session_name,
            logsCount: logs.length
          });
        }
      }
    }
  } catch (err) {
    console.warn('Dynamic metrics fetch error:', err);
  }

  const athleteReadinessScore = metricsCount > 0 ? Math.round(totalReadinessScore / metricsCount) : 0;

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

  // 4. Fetch Match Stats
  let matches: any[] = [];
  try {
    const { results } = await db.prepare('SELECT * FROM match_stats WHERE player_id = ? ORDER BY match_date DESC').bind(playerId).all();
    matches = results || [];
  } catch (_) {}

  // 5. Fetch Attendance Summary
  let attendance: any[] = [];
  try {
    const { results } = await db.prepare('SELECT session_type, COUNT(*) as total, SUM(CASE WHEN status = "Present" THEN 1 ELSE 0 END) as present FROM attendance WHERE player_id = ? GROUP BY session_type').bind(playerId).all();
    attendance = results || [];
  } catch (_) {}

  // 6. Fetch Team Events for Student
  let events: any[] = [];
  try {
    const schoolId = player.school_id || 'OVK';
    const ageGroup = player.age_group;
    const { results } = await db.prepare(
      'SELECT * FROM events WHERE school_id = ? AND (age_group = ? OR age_group IS NULL OR age_group = "") ORDER BY date ASC, start_time ASC'
    ).bind(schoolId, ageGroup).all();
    events = (results || []).map((r: any) => ({
      id: r.id?.toString() || '',
      schoolId: r.school_id,
      title: r.title,
      eventType: r.event_type,
      startTime: r.start_time,
      date: r.date,
      durationMins: r.duration_mins,
      location: r.location,
      isImportant: r.is_important === 1,
      completionCount: r.completion_count,
      ageGroup: r.age_group || null,
      team: r.team || r.age_group || null,
      workoutImagePath: r.workout_image_path
    }));
  } catch (_) {}

  return c.json({
    success: true,
    data: {
      profile: {
        id: player.id,
        firstName: player.first_name,
        lastName: player.last_name,
        phone: player.phone || '',
        email: player.email || '',
        dob: player.dob || '',
        preferredPosition: player.preferred_position || '',
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
        readinessScore: athleteReadinessScore,
        dynamicMetrics: dynamicMetrics,
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
      })),
      events: events
    }
  });
});

// Route: Update Student Profile Details
app.post('/api/student-portal/profile', async (c) => {
  const db = getDB(c);
  let userId = '';
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify(token, getSecret(c), 'HS256') as any;
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (_) {}
  }

  if (!userId) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }

  try {
    const { firstName, lastName, phone, email, dob, preferredPosition } = await c.req.json();
    let formattedPhone = phone;
    if (phone && phone.trim().length > 0) {
      let clean = phone.replace(/[^\d+]/g, '');
      if (clean.startsWith('0')) {
        clean = '+27' + clean.slice(1);
      } else if (!clean.startsWith('+')) {
        clean = '+27' + clean;
      }
      formattedPhone = clean;
    }

    await db.prepare(`
      UPDATE players
      SET first_name = COALESCE(?, first_name),
          last_name = COALESCE(?, last_name),
          phone = COALESCE(?, phone),
          email = COALESCE(?, email),
          dob = COALESCE(?, dob),
          preferred_position = COALESCE(?, preferred_position)
      WHERE user_id = ? OR id = ?
    `).bind(firstName, lastName, formattedPhone, email, dob, preferredPosition, userId, userId).run();

    return c.json({ success: true, message: 'Profile updated successfully', phone: formattedPhone });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to update profile', error: err.message }, 500);
  }
});

// Route: Log / Update Individual Athlete Evaluation Baseline
app.post('/api/player/evaluation-baseline', async (c) => {
  const db = getDB(c);
  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { playerId, metricId, score, testDate, sessionName, notes } = body;
  if (!playerId || !metricId || score === undefined || score === null) {
    return c.json({ success: false, message: 'playerId, metricId, and score are required' }, 400);
  }

  const dateStr = testDate || new Date().toISOString().split('T')[0];

  try {
    await db.prepare(`
      INSERT INTO player_test_logs (player_id, metric_id, test_date, session_name, score, notes)
      VALUES (?, ?, ?, ?, ?, ?)
      ON CONFLICT(player_id, metric_id, test_date) DO UPDATE SET
        score = excluded.score,
        session_name = excluded.session_name,
        notes = excluded.notes
    `).bind(
      playerId, metricId, dateStr, sessionName || 'Baseline Evaluation',
      parseFloat(score.toString()), notes || null
    ).run();

    return c.json({
      success: true,
      message: 'Evaluation baseline updated successfully',
      data: { playerId, metricId, score, testDate: dateStr }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to update evaluation baseline', error: err.message }, 500);
  }
});

// Route: Get Test Metric Definitions
app.get('/api/test-metrics', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || c.req.query('school_id') || 'OVK';
  const db = getDB(c);

  try {
    const { results } = await db.prepare('SELECT * FROM test_metric_definitions WHERE school_id = ? ORDER BY category, name ASC').bind(schoolId).all();
    return c.json({
      success: true,
      data: (results || []).map((m: any) => ({
        id: m.id,
        schoolId: m.school_id,
        sportId: m.sport_id,
        name: m.name,
        category: m.category,
        unit: m.unit,
        goalDirection: m.goal_direction,
        targetBenchmark: m.target_benchmark
      }))
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to fetch test metrics', error: err.message }, 500);
  }
});

// Route: Create/Update Test Metric Definition
app.post('/api/test-metrics', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const db = getDB(c);

  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { id, name, category, unit, goalDirection, targetBenchmark } = body;
  if (!name || !category || !unit) {
    return c.json({ success: false, message: 'Name, category, and unit are required.' }, 400);
  }

  const metricId = id || `m_${name.toLowerCase().replace(/[^a-z0-9]/g, '_')}_${Date.now().toString().slice(-4)}`;

  try {
    await db.prepare(`
      INSERT INTO test_metric_definitions (id, school_id, sport_id, name, category, unit, goal_direction, target_benchmark)
      VALUES (?, ?, 'rugby', ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        category = excluded.category,
        unit = excluded.unit,
        goal_direction = excluded.goal_direction,
        target_benchmark = excluded.target_benchmark
    `).bind(
      metricId, schoolId, name.trim(), category.trim(), unit.trim(),
      goalDirection || 'HIGHER_IS_BETTER', targetBenchmark || null
    ).run();

    return c.json({
      success: true,
      message: 'Test metric saved successfully',
      data: { id: metricId, schoolId, name, category, unit, goalDirection, targetBenchmark }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to save test metric', error: err.message }, 500);
  }
});

// Route: Delete Test Metric Definition
app.delete('/api/test-metrics/:id', async (c) => {
  const metricId = c.req.param('id');
  const db = getDB(c);
  try {
    await db.prepare('DELETE FROM test_metric_definitions WHERE id = ?').bind(metricId).run();
    return c.json({ success: true, message: 'Test metric deleted successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to delete test metric', error: err.message }, 500);
  }
});

// Route: Batch Log Test Scores
app.post('/api/test-logs/batch', async (c) => {
  const db = getDB(c);
  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { metricId, testDate, sessionName, logs } = body;
  if (!metricId || !testDate || !Array.isArray(logs)) {
    return c.json({ success: false, message: 'metricId, testDate, and logs array are required' }, 400);
  }

  let savedCount = 0;
  for (const item of logs) {
    if (!item.playerId || item.score === undefined || item.score === null) continue;
    try {
      await db.prepare(`
        INSERT INTO player_test_logs (player_id, metric_id, test_date, session_name, score, notes)
        VALUES (?, ?, ?, ?, ?, ?)
        ON CONFLICT(player_id, metric_id, test_date) DO UPDATE SET
          score = excluded.score,
          session_name = excluded.session_name,
          notes = excluded.notes
      `).bind(
        item.playerId, metricId, testDate, sessionName || 'Testing Evaluation',
        parseFloat(item.score.toString()), item.notes || null
      ).run();
      savedCount++;
    } catch (e) {
      console.warn(`Failed test log for player ${item.playerId}:`, e);
    }
  }

  return c.json({
    success: true,
    message: `Saved ${savedCount} test logs successfully`,
    data: { savedCount, metricId, testDate }
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

// Route: Image Upload (R2 / Base64 Storage)
app.post('/api/upload', async (c) => {
  try {
    const body = await c.req.json();
    const { imageBase64, filename } = body;
    if (!imageBase64) {
      return c.json({ success: false, message: 'Image data is required' }, 400);
    }

    const base64Data = imageBase64.replace(/^data:image\/\w+;base64,/, '');
    const binaryData = Uint8Array.from(atob(base64Data), c => c.charCodeAt(0));
    const key = `uploads/${Date.now()}-${filename || 'avatar.jpg'}`;

    if (c.env.R2) {
      await c.env.R2.put(key, binaryData, {
        httpMetadata: { contentType: 'image/jpeg' }
      });
      const publicUrl = `https://academypro-assets.tata-elash34.workers.dev/${key}`;
      return c.json({ success: true, url: publicUrl, message: 'Image uploaded successfully' });
    }

    const dataUrl = `data:image/jpeg;base64,${base64Data}`;
    return c.json({ success: true, url: dataUrl, message: 'Image processed successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Upload failed', error: err.message }, 500);
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

// Route: Create Player & Pre-create User & Send Invite Email
app.post('/api/players', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || 'OVK';
  const body = await c.req.json();
  const { id, firstName, lastName, ageGroup, position, team, email, parentPhone } = body;
  const db = getDB(c);

  if (!firstName || !lastName || !ageGroup) {
    return c.json({ success: false, message: 'First name, last name, and age group are required' }, 400);
  }

  const playerId = id || `OVK-${ageGroup}-${Date.now().toString().substring(7)}`;
  const playerEmail = (email && email.trim()) ? email.trim().toLowerCase() : `${firstName.toLowerCase().replace(/\s+/g, '')}.${lastName.toLowerCase().replace(/\s+/g, '')}@academypro.co.za`;

  try {
    // 1. Insert into D1 players table
    await db.prepare(`
      INSERT OR REPLACE INTO players (id, school_id, first_name, last_name, age_group, position, team, status, parent_contact)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'Active', ?)
    `).bind(playerId, schoolId, firstName, lastName, ageGroup, position || 'Athlete', team || `${ageGroup} Squad`, parentPhone || '').run();

    // 2. Pre-create Player user account in users table if not exists
    const existingUser = await db.prepare('SELECT id FROM users WHERE email = ?').bind(playerEmail).first();
    let userId = existingUser?.id;

    if (!existingUser) {
      userId = `USR-PL-${Date.now().toString().substring(6)}`;
      await db.prepare(`
        INSERT INTO users (id, email, first_name, last_name, role, school_id, password_hash)
        VALUES (?, ?, ?, ?, 'Player', ?, 'PENDING_ACTIVATION')
      `).bind(userId, playerEmail, firstName, lastName, schoolId).run();
    }

    // Link player record to user_id
    try {
      await db.prepare('UPDATE players SET user_id = ? WHERE id = ?').bind(userId, playerId).run();
    } catch (_) {}

    // 3. Send automated onboarding invite email to Player
    const inviteHtml = `<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: system-ui, -apple-system, sans-serif; background-color: #FAF8FF; color: #131B2E; margin: 0; padding: 20px; }
    .container { max-width: 520px; background-color: #ffffff; border: 1px solid #E2E8F0; border-radius: 16px; padding: 32px; margin: 0 auto; }
    .header { text-align: center; margin-bottom: 24px; }
    .title { font-size: 26px; font-weight: 900; color: #003EC7; margin: 0; }
    .content { font-size: 15px; line-height: 1.6; color: #434656; }
    .btn { display: inline-block; background-color: #003EC7; color: #ffffff !important; padding: 14px 28px; border-radius: 12px; font-weight: bold; text-decoration: none; margin: 20px 0; }
    .footer { text-align: center; font-size: 12px; color: #737688; margin-top: 32px; border-top: 1px solid #E2E8F0; padding-top: 16px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1 class="title">AcademyPro</h1>
    </div>
    <div class="content">
      <p>Hi <strong>${firstName} ${lastName}</strong>,</p>
      <p>You have been enrolled in the <strong>${team || ageGroup}</strong> squad on AcademyPro High Performance Athlete Hub!</p>
      <p>Log in with your email address (<strong>${playerEmail}</strong>) to access your training schedule, performance stats, attendance QR code, and coach feedback.</p>
      <div style="text-align: center;">
        <a href="https://academypro-app.web.app/invite?email=${encodeURIComponent(playerEmail)}" class="btn">Activate Account & Open App</a>
      </div>
    </div>
    <div class="footer">
      <p>© 2026 CodeWays PTY Ltd. All rights reserved.</p>
    </div>
  </div>
</body>
</html>`;

    await sendTransactionalEmail(c, {
      to: playerEmail,
      fromName: 'AcademyPro Sports',
      fromEmail: 'noreply@web.codeways.co',
      subject: `Welcome to AcademyPro — ${team} Squad Invitation`,
      htmlContent: inviteHtml,
      textContent: `Hi ${firstName},\n\nYou have been added to the ${team} squad on AcademyPro. Log in with ${playerEmail} to view your training schedule and stats.`
    });

    console.log(`[Observer Log] Created player ${playerId} (${firstName} ${lastName}) and sent email invite to ${playerEmail}`);

    return c.json({
      success: true,
      message: 'Player created and email invitation sent successfully',
      data: { id: playerId, email: playerEmail }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to create player', error: err.message }, 500);
  }
});

// Helper to ensure parent_child_links table exists
async function ensureParentLinksTable(db: any) {
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS parent_child_links (
        id TEXT PRIMARY KEY,
        parent_user_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        player_email TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
  } catch (err) {
    console.warn('Failed to ensure parent_child_links table:', err);
  }
}

// Route: Parent sends link request to child via email
app.post('/api/parent/link-request', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const parentUserId = jwtPayload?.sub || 'USR-PARENT-101';
  const { childEmail } = await c.req.json();
  const db = getDB(c);

  if (!childEmail || !childEmail.trim()) {
    return c.json({ success: false, message: 'Child email address is required' }, 400);
  }

  const cleanChildEmail = childEmail.trim().toLowerCase();
  await ensureParentLinksTable(db);

  try {
    let player = await db.prepare('SELECT id, first_name, last_name, user_id FROM players WHERE LOWER(first_name || "." || last_name || "@academypro.co.za") = ? LIMIT 1').bind(cleanChildEmail).first();
    
    if (!player) {
      const user = await db.prepare('SELECT id, first_name, last_name FROM users WHERE email = ?').bind(cleanChildEmail).first();
      if (user) {
        player = await db.prepare('SELECT id, first_name, last_name FROM players WHERE user_id = ?').bind(user.id).first();
      }
    }

    const playerId = player ? player.id : `OVK-U15-${Date.now().toString().substring(7)}`;

    const existing = await db.prepare('SELECT id, status FROM parent_child_links WHERE parent_user_id = ? AND player_email = ?').bind(parentUserId, cleanChildEmail).first();

    if (existing) {
      return c.json({
        success: true,
        message: `Link request already exists with status: ${existing.status}`,
        data: { id: existing.id, status: existing.status }
      });
    }

    const linkId = `LINK-${Date.now().toString().substring(6)}`;
    await db.prepare(`
      INSERT INTO parent_child_links (id, parent_user_id, player_id, player_email, status)
      VALUES (?, ?, ?, ?, 'pending')
    `).bind(linkId, parentUserId, playerId, cleanChildEmail).run();

    try {
      await db.prepare(`
        INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
        VALUES (?, 'Parent Link Request', 'A parent has requested to link to your athlete profile. Tap to review and accept.', 'link_request', 0, CURRENT_TIMESTAMP)
      `).bind(player?.user_id || 'USR-STUDENT-01').run();
    } catch (_) {}

    return c.json({
      success: true,
      message: 'Parent link request sent successfully. Waiting for player approval.',
      data: { id: linkId, status: 'pending' }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to send link request', error: err.message }, 500);
  }
});

// Route: Player fetches pending parent link requests
app.get('/api/player/link-requests', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const userId = jwtPayload?.sub || 'USR-STUDENT-01';
  const db = getDB(c);

  await ensureParentLinksTable(db);

  try {
    const user = await db.prepare('SELECT email FROM users WHERE id = ?').bind(userId).first();
    const userEmail = user?.email || 'player@academypro.co.za';

    const { results } = await db.prepare(`
      SELECT pcl.id, pcl.status, pcl.created_at, u.first_name as parent_first_name, u.last_name as parent_last_name, u.email as parent_email
      FROM parent_child_links pcl
      LEFT JOIN users u ON pcl.parent_user_id = u.id
      WHERE pcl.player_email = ? OR pcl.player_id IN (SELECT id FROM players WHERE user_id = ?)
    `).bind(userEmail, userId).all();

    return c.json({
      success: true,
      data: (results || []).map((r: any) => ({
        id: r.id,
        parentName: `${r.parent_first_name || 'Parent'} ${r.parent_last_name || ''}`.trim(),
        parentEmail: r.parent_email || 'parent@academypro.co.za',
        status: r.status,
        createdAt: r.created_at
      }))
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to fetch link requests', error: err.message }, 500);
  }
});

// Route: Player accepts or rejects parent link request
app.post('/api/player/link-requests/:id/respond', async (c) => {
  const linkId = c.req.param('id');
  const { action } = await c.req.json();
  const db = getDB(c);

  await ensureParentLinksTable(db);

  if (!action || (action !== 'accept' && action !== 'reject')) {
    return c.json({ success: false, message: 'Action must be accept or reject' }, 400);
  }

  const newStatus = action === 'accept' ? 'accepted' : 'rejected';

  try {
    await db.prepare('UPDATE parent_child_links SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').bind(newStatus, linkId).run();

    return c.json({
      success: true,
      message: `Parent link request ${newStatus} successfully`,
      data: { id: linkId, status: newStatus }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to respond to link request', error: err.message }, 500);
  }
});

// Route: Get Parent's Linked Children Profiles
app.get('/api/parent/children', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const parentUserId = jwtPayload?.sub;
  if (!parentUserId) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }
  const db = getDB(c);

  await ensureParentLinksTable(db);

  try {
    const { results } = await db.prepare(`
      SELECT p.*, pcl.status as link_status
      FROM parent_child_links pcl
      JOIN players p ON pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id)
      WHERE pcl.parent_user_id = ? AND pcl.status = 'accepted'
    `).bind(parentUserId).all();

    const children = results || [];

    return c.json({
      success: true,
      data: children.map((p: any) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        ageGroup: p.age_group,
        team: p.team,
        position: p.position,
        status: p.status || 'Active'
      }))
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to fetch linked children', error: err.message }, 500);
  }
});

// ==========================================
// NOTIFICATIONS API ENDPOINTS
// ==========================================

// Route: Get Notifications List
app.get('/api/notifications', async (c) => {
  const db = getDB(c);
  let userId = '';
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
    const query = userId ? `
      SELECT id, user_id, title, body, type, is_read, action_route, created_at
      FROM notifications
      WHERE user_id = ? OR user_id = 'ALL'
      ORDER BY created_at DESC
    ` : `
      SELECT id, user_id, title, body, type, is_read, action_route, created_at
      FROM notifications
      WHERE user_id = 'ALL'
      ORDER BY created_at DESC
    `;
    const { results } = userId ? await db.prepare(query).bind(userId).all() : await db.prepare(query).all();
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
  let userId = '';
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify(token, getSecret(c), 'HS256') as any;
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (_) {}
  }

  try {
    if (userId) {
      await db.prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ? OR user_id = 'ALL'").bind(userId).run();
    } else {
      await db.prepare('UPDATE notifications SET is_read = 1').run();
    }
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
    await db.prepare('DELETE FROM notifications WHERE id = ? OR CAST(id AS TEXT) = ?').bind(id, id.toString()).run();
    console.log(`[Observer Log] Deleted notification ${id}`);
    return c.json({ success: true, message: 'Notification deleted' });
  } catch (err: any) {
    console.error('[Observer Error] Delete notification failed:', err);
    return c.json({ success: false, message: 'Failed to delete notification', error: err.message }, 500);
  }
});

app.post('/api/notifications/:id/delete', async (c) => {
  const id = c.req.param('id');
  const db = getDB(c);

  try {
    await db.prepare('DELETE FROM notifications WHERE id = ? OR CAST(id AS TEXT) = ?').bind(id, id.toString()).run();
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
  let senderId = '';
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify(token, getSecret(c), 'HS256') as any;
      if (payload && payload.sub) {
        senderId = payload.sub;
      }
    } catch (_) {}
  }

  let body;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { title, text, body: textBody, type, userId } = body;
  const content = textBody || text;
  if (!title || !content) {
    return c.json({ success: false, message: 'Title and body text are required' }, 400);
  }

  const targetUser = userId || senderId || 'ALL';
  const notifType = type || 'general';

  try {
    await db.prepare(`
      INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
      VALUES (?, ?, ?, ?, 0, CURRENT_TIMESTAMP)
    `).bind(targetUser, title, content, notifType).run();

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

// Route: Send SMS Verification Code via SMS Gateway Service
app.post('/api/sms/send-verification', async (c) => {
  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { phone, name } = body;
  if (!phone) {
    return c.json({ success: false, message: 'Phone number is required' }, 400);
  }

  const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
  
  // Format phone to digits-only (e.g. 27821234567) required by SMS gateway
  let digitsOnly = phone.replace(/[^\d]/g, '');
  if (digitsOnly.startsWith('0')) {
    digitsOnly = '27' + digitsOnly.slice(1);
  } else if (!digitsOnly.startsWith('27')) {
    digitsOnly = '27' + digitsOnly;
  }

  const apiKey = c.env.INTERNAL_API_KEY || 'agua_internal_secret_key_102938';

  try {
    const smsRes = await fetch('https://sms-service.codeways.co', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Internal-API-Key': apiKey
      },
      body: JSON.stringify({
        to: digitsOnly,
        message: `[AcademyPro] Your verification code is ${otpCode}. Valid for 10 minutes.`,
        senderId: 'Agua',
        tag: 'AguaGo'
      })
    });

    const resText = await smsRes.text();
    console.log(`[Observer Log] Sent SMS code to ${digitsOnly}, status: ${smsRes.status}, response: ${resText}`);

    return c.json({
      success: true,
      message: `Verification SMS sent successfully to ${digitsOnly}`,
      data: {
        phone: digitsOnly,
        otpCode
      }
    });
  } catch (err: any) {
    console.error('[Observer Error] Failed to send SMS:', err);
    return c.json({ success: false, message: 'SMS service request failed', error: err.message }, 500);
  }
});

export default app;

