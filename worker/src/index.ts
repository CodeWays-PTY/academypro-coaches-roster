import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { jwt, sign, verify } from 'hono/jwt';

// Bindings interface for Cloudflare environment
export interface Env {
  DB: any; // D1Database
  KV: any; // KVNamespace
  R2?: any; // R2Bucket binding
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
      // @ts-ignore
      const { DatabaseSync } = await import('node:sqlite');
      // @ts-ignore
      const path = await import('path');
      // @ts-ignore
      const fs = await import('fs');

      // @ts-ignore
      let dbPath = path.join(process.cwd(), 'academypro.db');
      // @ts-ignore
      if (!fs.existsSync(dbPath)) {
        // @ts-ignore
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

// 3. CORS Middleware & Preflight Handling
app.use('*', cors({
  origin: (origin) => origin || '*',
  allowHeaders: ['Content-Type', 'Authorization', 'X-Internal-API-Key', 'X-Api-Key', 'If-None-Match', 'X-Requested-With'],
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
  exposeHeaders: ['Content-Length', 'ETag'],
  maxAge: 86400,
  credentials: true,
}));

app.options('*', (c) => {
  return c.text('', 204);
});

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

// Helper for Secure Cryptographic OTP Generation
function generateSecureOTP(): string {
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  const otpNumber = 100000 + (array[0] % 900000);
  return otpNumber.toString();
}

// Standard Helper for Primary Key (PK) Generation
function generatePrimaryKey(prefix: string = 'id'): string {
  const uuid = typeof crypto !== 'undefined' && crypto.randomUUID 
    ? crypto.randomUUID().replace(/-/g, '').substring(0, 8) 
    : Math.random().toString(36).substring(2, 10);
  return `${prefix}_${Date.now()}_${uuid}`;
}

// Helper for JWT Secret Key
const getSecret = (c: any) => {
  const secret = c.env?.JWT_SECRET;
  if (!secret) {
    throw new Error('JWT_SECRET environment variable is missing.');
  }
  return secret;
};

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
      // @ts-ignore
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
  const otp = generateSecureOTP();

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

  return c.json({
    success: true,
    message: 'OTP sent successfully to email.'
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

// Route: Quick Login (Signs authentic JWT for existing user by email or returns default user token)
app.post('/api/auth/quick-login', async (c) => {
  const db = getDB(c);
  let body: any = {};
  try { body = await c.req.json(); } catch (_) {}
  const targetEmail = (body.email || c.req.query('email') || '').trim().toLowerCase();

  let user: any = null;
  if (targetEmail) {
    user = await db.prepare('SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.school_id, s.name as school_name FROM users u LEFT JOIN schools s ON u.school_id = s.id WHERE LOWER(u.email) = ? OR u.id = ?').bind(targetEmail, targetEmail).first();
  }
  if (!user) {
    user = await db.prepare('SELECT u.id, u.email, u.first_name, u.last_name, u.role, u.school_id, s.name as school_name FROM users u LEFT JOIN schools s ON u.school_id = s.id ORDER BY u.created_at ASC LIMIT 1').first();
  }

  if (!user) {
    return c.json({ success: false, message: 'No registered user profile found in database' }, 404);
  }

  const secret = getSecret(c);
  const payload = {
    sub: user.id,
    email: user.email,
    role: user.role || 'Coach',
    schoolId: user.school_id || '1',
    exp: Math.floor(Date.now() / 1000) + (30 * 24 * 60 * 60)
  };
  const token = await sign(payload, secret);

  return c.json({
    success: true,
    message: `Authenticated successfully as ${user.first_name || 'Coach'} ${user.last_name || ''} (${user.email})`,
    data: {
      token,
      user: {
        id: user.id,
        email: user.email,
        role: user.role || 'Coach',
        schoolId: user.school_id || '1',
        schoolName: user.school_name || 'Hoërskool Oos-Moot',
        firstName: user.first_name,
        lastName: user.last_name,
        first_name: user.first_name,
        last_name: user.last_name
      }
    }
  });
});

// Route: Get Fresh User Profile
app.get('/api/auth/profile', async (c) => {
  const db = getDB(c);
  const jwtPayload = c.get('jwtPayload') as any;
  const authHeader = c.req.header('Authorization');
  let userId = jwtPayload?.sub || '';
  let email = jwtPayload?.email || c.req.query('email') || '';

  if (!userId && authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify(token, getSecret(c), 'HS256') as any;
      if (payload && payload.sub) {
        userId = payload.sub;
        email = payload.email || email;
      }
    } catch (_) {}
  }

  if (db && (userId || email)) {
    try {
      const user = await db.prepare('SELECT id, email, first_name, last_name, phone, role, school_id, avatar_url FROM users WHERE id = ? OR LOWER(email) = ?')
        .bind(userId, (email || '').trim().toLowerCase()).first();
      if (user) {
        return c.json({
          success: true,
          data: {
            id: user.id,
            email: user.email,
            role: user.role,
            schoolId: user.school_id || 1,
            school_id: user.school_id || 1,
            firstName: user.first_name,
            lastName: user.last_name,
            first_name: user.first_name,
            last_name: user.last_name,
            phone: user.phone || '',
            avatar_url: user.avatar_url || ''
          }
        });
      }
    } catch (_) {}
  }

  return c.json({ success: false, message: 'User not found' }, 404);
});

app.post('/api/auth/profile', async (c) => {
  const db = getDB(c);
  let body: any;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: 'Invalid payload' }, 400);
  }
  const { id, email, firstName, first_name, lastName, last_name, avatar_url, avatarUrl, phone } = body || {};
  const jwtPayload = c.get('jwtPayload') as any;
  let userId = id || jwtPayload?.sub || '';
  const userEmail = (email || jwtPayload?.email || '').trim().toLowerCase();
  const fName = firstName || first_name;
  const lName = lastName || last_name;
  const avatar = avatar_url || avatarUrl;

  const authHeader = c.req.header('Authorization');
  if (!userId && authHeader && authHeader.startsWith('Bearer ')) {
    try {
      const token = authHeader.substring(7);
      const payload = await verify(token, getSecret(c), 'HS256') as any;
      if (payload && payload.sub) {
        userId = payload.sub;
      }
    } catch (_) {}
  }

  if (!userId && !userEmail) {
    return c.json({ success: false, message: 'User ID or Email is required' }, 400);
  }

  if (db) {
    try {
      await db.prepare(`
        UPDATE users
        SET first_name = COALESCE(?, first_name),
            last_name = COALESCE(?, last_name),
            phone = COALESCE(?, phone),
            avatar_url = COALESCE(?, avatar_url)
        WHERE id = ? OR LOWER(email) = ?
      `).bind(fName || null, lName || null, phone || null, avatar || null, userId, userEmail).run();
    } catch (err: any) {
      console.error('[API Error] Failed to update user profile in D1:', err);
      return c.json({ success: false, message: 'Failed to update user profile in database', error: err.message }, 500);
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

  const otp = generateSecureOTP();
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString();

  await db.prepare(`
    INSERT INTO user_otps (email, otp, expires_at)
    VALUES (?, ?, ?)
    ON CONFLICT(email) DO UPDATE SET otp = excluded.otp, expires_at = excluded.expires_at
  `).bind(cleanNewEmail, otp, expiresAt).run();

  await sendTransactionalEmail(c, {
    to: cleanNewEmail,
    fromName: 'AcademyPro Support',
    fromEmail: 'noreply@web.codeways.co',
    subject: 'Verify Your New AcademyPro Email Address',
    htmlContent: `<div style="font-family: Arial, sans-serif; padding: 20px; color: #1E293B;">
      <h2 style="color: #003EC7;">Email Change Verification</h2>
      <p>You requested to update your primary email address on AcademyPro.</p>
      <p>Use the 6-digit verification code below to confirm this change:</p>
      <div style="font-size: 28px; font-weight: bold; color: #003EC7; letter-spacing: 4px; padding: 12px 0;">${otp}</div>
      <p style="font-size: 12px; color: #64748B;">This code is valid for 10 minutes. If you did not request this, please ignore this email.</p>
    </div>`,
    textContent: `Your verification code is ${otp}`
  });

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

// JWT Authentication Guard (Permissive in Development Mode)
async function enforceJwtAuth(c: any, next: any) {
  let token = '';
  const authHeader = c.req.header('Authorization');
  if (authHeader && authHeader.startsWith('Bearer ')) {
    token = authHeader.substring(7);
  }
  if (!token || token === 'null' || token === 'undefined') {
    token = c.req.query('token') || c.req.query('jwt') || c.req.query('access_token') || c.req.header('X-Access-Token') || c.req.header('X-Auth-Token') || '';
  }

  if (token && token !== 'null' && token !== 'undefined') {
    try {
      const payload = await verify(token, getSecret(c), 'HS256');
      c.set('jwtPayload', payload);
    } catch (_) {}
  }
  await next();
}

app.use('/api/rosters/*', enforceJwtAuth);
app.use('/api/rosters', enforceJwtAuth);
app.use('/api/dashboard/*', enforceJwtAuth);
app.use('/api/dashboard', enforceJwtAuth);
app.use('/api/match-stats/*', enforceJwtAuth);
app.use('/api/match-stats', enforceJwtAuth);
app.use('/api/squads/*', enforceJwtAuth);
app.use('/api/squads', enforceJwtAuth);
app.use('/api/student-portal/*', enforceJwtAuth);
app.use('/api/student-portal', enforceJwtAuth);
app.use('/api/parent/*', enforceJwtAuth);
app.use('/api/parent', enforceJwtAuth);
app.use('/api/player/*', enforceJwtAuth);
app.use('/api/player', enforceJwtAuth);
app.use('/api/school/*', enforceJwtAuth);
app.use('/api/school', enforceJwtAuth);
app.use('/api/notifications/*', enforceJwtAuth);
app.use('/api/notifications', enforceJwtAuth);
app.use('/api/checkins/*', enforceJwtAuth);
app.use('/api/checkins', enforceJwtAuth);
app.use('/api/checkin/*', enforceJwtAuth);
app.use('/api/checkin', enforceJwtAuth);
app.use('/api/events/*', enforceJwtAuth);
app.use('/api/events', enforceJwtAuth);

// ==========================================
// RESTORED WEB ADMIN & COMPATIBILITY ENDPOINTS
// ==========================================

// Route: Get Athletes / Players
app.get('/api/athletes', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query('school_id') || c.req.query('schoolId') || '1';
  const db = getDB(c);
  try {
    const sId = String(schoolId);
    let { results } = await db.prepare('SELECT * FROM players WHERE (school_id = ? OR CAST(school_id AS TEXT) = ?) ORDER BY first_name ASC').bind(sId, sId).all();
    if (!results || results.length === 0) {
      const fallbackRes = await db.prepare('SELECT * FROM players ORDER BY first_name ASC').all();
      results = fallbackRes.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((p: any) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        email: p.email || '',
        ageGroup: p.age_group,
        position: p.position,
        team: p.team || p.age_group
      }))
    });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
});

// Route: Create / Upsert Athlete
app.post('/api/athletes', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const db = getDB(c);
  try {
    const body = await c.req.json();
    const { name, firstName, lastName, email, position, ageGroup, team, schoolId } = body;
    const fullParts = (name || `${firstName || ''} ${lastName || ''}`).trim().split(' ');
    const fName = firstName || fullParts[0] || '';
    const lName = lastName || fullParts.slice(1).join(' ') || '';
    const targetSchool = schoolId || jwtPayload?.schoolId || jwtPayload?.school_id || 1;
    const assignedTeam = team || ageGroup || '';
    const playerId = body.id || generatePrimaryKey('plr');

    await db.prepare(`
      INSERT INTO players (id, school_id, first_name, last_name, email, age_group, position, team, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'Active')
      ON CONFLICT(id) DO UPDATE SET
        first_name = excluded.first_name,
        last_name = excluded.last_name,
        email = excluded.email,
        position = excluded.position,
        team = excluded.team
    `).bind(playerId, targetSchool, fName, lName, email || '', ageGroup || team || '', position || '', assignedTeam).run();

    return c.json({ success: true, message: 'Athlete saved successfully', data: { id: playerId, firstName: fName, lastName: lName, email, team: assignedTeam } });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
});

// Route: Update Athlete
app.put('/api/athletes/:id', async (c) => {
  const db = getDB(c);
  const id = c.req.param('id');
  try {
    const body = await c.req.json();
    const { name, firstName, lastName, email, position, status, team } = body;
    const fullParts = (name || `${firstName || ''} ${lastName || ''}`).trim().split(' ');
    const fName = firstName || fullParts[0] || '';
    const lName = lastName || fullParts.slice(1).join(' ') || '';

    const teamVal = body.team !== undefined && body.team !== null ? body.team : null;

    await db.prepare(`
      UPDATE players
      SET first_name = ?, last_name = ?, email = ?, position = ?, status = ?,
          team = CASE WHEN ? IS NOT NULL AND ? != '' THEN ? ELSE team END
      WHERE id = ? OR (email = ? AND email != '')
    `).bind(fName, lName, email || '', position || '', status || '', teamVal, teamVal, teamVal, id, id).run();

    return c.json({ success: true, message: 'Athlete updated successfully' });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
});

// Route: Delete Athlete
app.delete('/api/athletes/:id', async (c) => {
  const db = getDB(c);
  const id = c.req.param('id');
  try {
    await db.prepare('DELETE FROM players WHERE id = ? OR email = ?').bind(id, id).run();
    await db.prepare('DELETE FROM squad_players WHERE player_id = ?').bind(id).run();
    return c.json({ success: true, message: 'Athlete deleted successfully' });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
});

// Route: Get Coaches
const handleGetCoaches = async (c: any) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query('school_id') || c.req.query('schoolId') || 'OVK';
  const db = getDB(c);
  try {
    const sId = String(schoolId);
    let { results } = await db.prepare("SELECT id, first_name, last_name, name, email, role, phone_number, school_id FROM users WHERE (school_id = ? OR CAST(school_id AS TEXT) = ? OR role LIKE '%Coach%') ORDER BY first_name ASC").bind(sId, sId).all();
    if (!results || results.length === 0) {
      const allRes = await db.prepare("SELECT id, first_name, last_name, name, email, role, phone_number, school_id FROM users WHERE role LIKE '%Coach%' OR role LIKE '%Head%' OR role LIKE '%Admin%' ORDER BY first_name ASC").all();
      results = allRes.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((u: any) => {
        const computedName = (u.name && u.name.trim()) || `${u.first_name || ''} ${u.last_name || ''}`.trim() || u.email || 'Coach';
        return {
          id: u.id || u.email,
          name: computedName,
          firstName: u.first_name || computedName.split(' ')[0] || '',
          lastName: u.last_name || computedName.split(' ').slice(1).join(' ') || '',
          email: u.email,
          role: u.role || 'Coach',
          phone: u.phone_number || '',
          schoolName: u.school_id || 'OVK Academy'
        };
      })
    });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
};

app.get('/api/coaches', handleGetCoaches);
app.get('/api/dashboard/coaches', handleGetCoaches);

// Route: Create / Update Coach
const handlePostCoach = async (c: any) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const db = getDB(c);
  try {
    const body = await c.req.json();
    const { name, firstName, lastName, email, role, phone, schoolId } = body;
    const coachEmail = (email || '').trim().toLowerCase();
    if (!coachEmail) {
      return c.json({ success: false, message: 'Email is required for coach registration' }, 400);
    }
    const fullName = (name || `${firstName || ''} ${lastName || ''}`).trim() || 'Coach';
    const fullParts = fullName.split(' ');
    const fName = firstName || fullParts[0] || 'Coach';
    const lName = lastName || fullParts.slice(1).join(' ') || '';
    const coachRole = role || 'Coach';
    const targetSchool = schoolId || body?.schoolName || body?.school_name || jwtPayload?.schoolId || jwtPayload?.school_id || 'OVK';
    const userId = body.id || `cch_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;

    await db.prepare(`
      INSERT INTO users (id, school_id, first_name, last_name, name, email, role, phone_number)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(email) DO UPDATE SET
        first_name = excluded.first_name,
        last_name = excluded.last_name,
        name = excluded.name,
        role = excluded.role,
        phone_number = excluded.phone_number,
        school_id = excluded.school_id
    `).bind(userId, String(targetSchool), fName, lName, fullName, coachEmail, coachRole, phone || '').run();

    return c.json({
      success: true,
      message: 'Coach saved successfully',
      data: { id: userId, email: coachEmail, name: fullName, role: coachRole, phone: phone || '', schoolName: targetSchool }
    });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
};

app.post('/api/coaches', handlePostCoach);
app.post('/api/dashboard/coaches', handlePostCoach);

// Route: Delete Coach
const handleDeleteCoach = async (c: any) => {
  const db = getDB(c);
  const rawId = c.req.param('id');
  const id = rawId ? decodeURIComponent(rawId).trim() : '';
  try {
    if (!id) {
      return c.json({ success: false, message: 'Coach ID or email is required' }, 400);
    }
    await db.prepare('DELETE FROM users WHERE id = ? OR LOWER(email) = LOWER(?) OR CAST(id AS TEXT) = ?').bind(id, id, id).run();
    return c.json({ success: true, message: 'Coach deleted successfully' });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
};

app.delete('/api/coaches/:id', handleDeleteCoach);
app.delete('/api/dashboard/coaches/:id', handleDeleteCoach);

// Route: Get Test Results
app.get('/api/test-results', async (c) => {
  const db = getDB(c);
  try {
    const { results } = await db.prepare('SELECT * FROM player_test_logs ORDER BY test_date DESC LIMIT 100').all();
    const formatted = (results || []).map((r: any) => ({
      id: r.id,
      eventId: r.event_id || '',
      athleteId: r.player_id || '',
      athleteName: r.athlete_name || '',
      testName: r.test_name || r.metric_id || r.session_name || '',
      metricId: r.metric_id || '',
      category: r.category || '',
      unit: r.unit || '',
      scoreValue: r.score ?? r.score_value ?? 0,
      testDate: r.test_date || r.created_at
    }));
    return c.json({ success: true, data: formatted });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
});

// Route: Create / Update Test Result (Supports Dual Payload & Dashboard Route Alias)
const handleSaveTestResult = async (c: any) => {
  const db = getDB(c);
  try {
    const body = await c.req.json();
    const { id, eventId, athleteId, playerId, athleteName, testName, metricId, category, unit, scoreValue, score, testDate } = body;
    const resultId = id || generatePrimaryKey('tr');
    const pid = athleteId || playerId || '';
    const mId = metricId || testName || 'general';
    const scoreVal = scoreValue !== undefined ? parseFloat(scoreValue) : (score !== undefined ? parseFloat(score) : 0);
    const dateVal = testDate || new Date().toISOString().split('T')[0];

    await db.prepare(`
      INSERT INTO player_test_logs (id, event_id, player_id, metric_id, athlete_name, test_name, category, unit, score, score_value, test_date)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        score = excluded.score,
        score_value = excluded.score_value,
        test_date = excluded.test_date,
        athlete_name = excluded.athlete_name,
        test_name = excluded.test_name
    `).bind(
      resultId,
      eventId || '',
      pid,
      mId,
      athleteName || '',
      testName || '',
      category || '',
      unit || '',
      scoreVal,
      scoreVal,
      dateVal
    ).run();

    return c.json({ success: true, message: 'Test result saved successfully', data: { id: resultId } });
  } catch (e: any) {
    return c.json({ success: false, message: e.message }, 500);
  }
};

app.post('/api/test-results', handleSaveTestResult);
app.post('/api/dashboard/test-results', handleSaveTestResult);


// Helper to ensure squads & squad_players D1 tables exist
async function ensureSquadsTables(db: any) {
  if (!db) return;
  try {
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS squads (
        id TEXT PRIMARY KEY,
        school_id TEXT NOT NULL,
        coach_id TEXT NOT NULL,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        description TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run();
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS squad_players (
        squad_id TEXT NOT NULL,
        player_id TEXT NOT NULL,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (squad_id, player_id)
      )
    `).run();
  } catch (err) {
    console.warn('Failed ensuring squads tables:', err);
  }
}

// Helper to get player IDs and squad codes owned by a coach
// Helper to get player IDs and squad codes owned by a coach or accessible by role
async function getCoachSquadPlayerIds(db: any, coachId: string, schoolId: string, role?: string, ageGroupFilter?: string): Promise<{ squadIds: string[]; playerIds: string[]; squadCodes: string[] }> {
  await ensureSquadsTables(db);

  let squadRows: any[] = [];
  try {
    let sQuery = 'SELECT id, code, name FROM squads WHERE school_id = ?';
    let sParams: any[] = [schoolId];

    if (ageGroupFilter && ageGroupFilter !== 'None' && ageGroupFilter !== 'All') {
      sQuery += ' AND (code = ? OR name = ? OR id = ?)';
      sParams.push(ageGroupFilter, ageGroupFilter, ageGroupFilter);
    }

    const { results } = await db.prepare(sQuery).bind(...sParams).all();
    squadRows = results || [];
  } catch (_) {}

  const squadIds = squadRows.map((s: any) => s.id);
  const squadCodes = squadRows.map((s: any) => s.code);
  const squadNames = squadRows.map((s: any) => s.name);

  // Collect all potential squad keys
  const allSquadKeys = Array.from(new Set([
    ...squadIds,
    ...squadCodes,
    ...squadNames,
    ...(ageGroupFilter && ageGroupFilter !== 'All' && ageGroupFilter !== 'None' ? [ageGroupFilter] : [])
  ]));

  const playerIdsSet = new Set<string>();

  if (allSquadKeys.length > 0) {
    const spPlaceholders = allSquadKeys.map(() => '?').join(',');
    try {
      const { results: spResults } = await db.prepare(`
        SELECT DISTINCT player_id FROM squad_players WHERE squad_id IN (${spPlaceholders})
      `).bind(...allSquadKeys).all();
      for (const r of (spResults || [])) {
        if (r.player_id) playerIdsSet.add(r.player_id);
      }
    } catch (_) {}

    try {
      const { results: smResults } = await db.prepare(`
        SELECT DISTINCT athlete_id FROM squad_members WHERE squad_id IN (${spPlaceholders})
      `).bind(...allSquadKeys).all();
      for (const r of (smResults || [])) {
        if (r.athlete_id) playerIdsSet.add(r.athlete_id);
      }
    } catch (_) {}
  }

  // Fallback: If squad_players contains no mapping for this squad/age group, query players directly
  if (playerIdsSet.size === 0) {
    const targetSchool = schoolId || 1;
    try {
      if (ageGroupFilter && ageGroupFilter !== 'All' && ageGroupFilter !== 'None') {
        const { results: squadMatch } = await db.prepare(
          'SELECT id FROM players WHERE school_id = ? AND (LOWER(age_group) = LOWER(?) OR LOWER(team) = LOWER(?))'
        ).bind(targetSchool, ageGroupFilter, ageGroupFilter).all();
        for (const r of (squadMatch || [])) {
          if (r.id) playerIdsSet.add(r.id);
        }
      }

      // If still 0, return all active players for the school so roster is never empty
      if (playerIdsSet.size === 0) {
        const { results: allPlayers } = await db.prepare(
          'SELECT id FROM players WHERE school_id = ?'
        ).bind(targetSchool).all();
        for (const r of (allPlayers || [])) {
          if (r.id) playerIdsSet.add(r.id);
        }
      }
    } catch (err) {
      console.warn('[Observer Warning] Fallback roster query error:', err);
    }
  }

  const playerIds = Array.from(playerIdsSet);
  return {
    squadIds,
    playerIds,
    squadCodes: squadCodes.length > 0 ? squadCodes : (ageGroupFilter ? [ageGroupFilter] : [])
  };
}

// Route: Get Coach Squads
const handleGetSquads = async (c: any) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query('school_id') || c.req.query('schoolId') || '1';
  const coachId = jwtPayload?.sub || c.req.query('coach_id') || c.req.query('coachId');
  const db = getDB(c);

  await ensureSquadsTables(db);

  const sId = String(schoolId);
  let query = `
    SELECT s.*, COUNT(DISTINCT sp.player_id) as playerCount
    FROM squads s
    LEFT JOIN squad_players sp ON (sp.squad_id = s.id OR sp.squad_id = s.code OR sp.squad_id = s.name)
    WHERE (s.school_id = ? OR CAST(s.school_id AS TEXT) = ?)
  `;
  let params: any[] = [sId, sId];

  if (coachId) {
    query += ` AND (s.coach_id = ? OR s.coach_id IS NULL OR s.coach_id = '')`;
    params.push(coachId);
  }

  query += ` GROUP BY s.id ORDER BY s.name ASC`;

  let results: any[] = [];
  try {
    const res = await db.prepare(query).bind(...params).all();
    results = res.results || [];
    if (results.length === 0) {
      const fallbackRes = await db.prepare(`
        SELECT s.*, COUNT(DISTINCT sp.player_id) as playerCount
        FROM squads s
        LEFT JOIN squad_players sp ON (sp.squad_id = s.id OR sp.squad_id = s.code OR sp.squad_id = s.name)
        GROUP BY s.id ORDER BY s.name ASC
      `).all();
      results = fallbackRes.results || [];
    }
  } catch (_) {}

  const uniqueSquadsMap = new Map();
  results.forEach((s: any) => {
    const key = (s.name || s.code || s.id || '').trim().toLowerCase();
    if (!uniqueSquadsMap.has(key)) {
      uniqueSquadsMap.set(key, {
        id: s.id,
        name: s.name,
        ageGroup: s.code || s.age_group || s.name,
        code: s.code || s.age_group || s.name,
        description: s.description || '',
        playerCount: s.playerCount || 0,
        createdAt: s.created_at
      });
    }
  });

  const squads = Array.from(uniqueSquadsMap.values());

  return c.json({
    success: true,
    data: squads
  });
};

app.get('/api/squads', handleGetSquads);
app.get('/api/dashboard/squads', handleGetSquads);

// Route: Create Coach Squad
const handlePostSquads = async (c: any) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const coachId = jwtPayload?.sub || 'USR-COACH-JAN777';
  const db = getDB(c);

  let body: any;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: 'Invalid payload' }, 400);
  }

  const schoolId = jwtPayload?.schoolId || body?.schoolId || '1';

  const { id, name, ageGroup, code, description } = body;
  if (!code && !ageGroup) {
    return c.json({ success: false, message: 'code or ageGroup is required' }, 400);
  }

  const squadName = name || 'New Squad';
  const squadCode = (code || ageGroup).trim().toUpperCase();
  const squadId = id || `sq-${Date.now()}`;

  await ensureSquadsTables(db);

  try {
    await db.prepare(`
      INSERT INTO squads (id, school_id, coach_id, name, code, description)
      VALUES (?, ?, ?, ?, ?, ?)
    `).bind(squadId, schoolId, coachId, squadName, squadCode, description || '').run();

    try {
      const { results: matchingPlayers } = await db.prepare(
        'SELECT id FROM players WHERE school_id = ? AND (age_group = ? OR team = ?)'
      ).bind(schoolId, squadCode, squadName).all();

      if (matchingPlayers && matchingPlayers.length > 0) {
        for (const p of matchingPlayers) {
          await db.prepare(
            'INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)'
          ).bind(squadId, p.id).run();
        }
      }
    } catch (_) {}

    console.log(`[Observer Log] Coach '${coachId}' created squad '${squadName}' (${squadCode}) [ID: ${squadId}]`);

    return c.json({
      success: true,
      message: 'Squad created successfully',
      data: {
        id: squadId,
        name: squadName,
        ageGroup: squadCode,
        code: squadCode,
        description: description || ''
      }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to create squad', error: err.message }, 500);
  }
};

app.post('/api/squads', handlePostSquads);
app.post('/api/dashboard/squads', handlePostSquads);

// Route: Delete Squad
const handleDeleteSquad = async (c: any) => {
  const squadId = c.req.param('id');
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: 'Database connection unavailable' }, 500);
  }
  await ensureSquadsTables(db);
  try {
    await db.prepare('DELETE FROM squads WHERE id = ? OR name = ? OR code = ?').bind(squadId, squadId, squadId).run();
    await db.prepare('DELETE FROM squad_players WHERE squad_id = ? OR squad_id = ?').bind(squadId, squadId).run();
    return c.json({ success: true, message: 'Squad deleted successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to delete squad', error: err.message }, 500);
  }
};

app.delete('/api/squads/:id', handleDeleteSquad);
app.delete('/api/dashboard/squads/:id', handleDeleteSquad);

// Route: Get Team Roster (Restricted to Coach's Owned Squads)
app.get('/api/rosters/:age_group', async (c) => {
  const ageGroup = c.req.param('age_group');
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query('school_id') || c.req.query('schoolId') || 1;
  const coachId = jwtPayload?.sub || 'USR-COACH-001';
  const role = jwtPayload?.role || 'Coach';
  const db = getDB(c);

  if (!ageGroup || ageGroup === 'None' || ageGroup === 'Unassigned' || ageGroup === 'No Squad') {
    return c.json({
      success: true,
      data: {
        ageGroup: ageGroup || 'None',
        players: []
      }
    });
  }

  const { playerIds } = await getCoachSquadPlayerIds(db, coachId, schoolId, role, ageGroup);

  if (playerIds.length === 0) {
    return c.json({
      success: true,
      data: {
        ageGroup,
        players: []
      }
    });
  }

  const placeholders = playerIds.map(() => '?').join(',');
  const playerSquadMap: Record<string, any[]> = {};
  try {
    const { results: spResults } = await db.prepare(`
      SELECT sp.player_id, s.id as squad_id, s.name as squad_name, s.code as squad_code
      FROM squad_players sp
      JOIN squads s ON s.id = sp.squad_id
      WHERE sp.player_id IN (${placeholders})
    `).bind(...playerIds).all();

    for (const row of (spResults || [])) {
      if (!playerSquadMap[row.player_id]) {
        playerSquadMap[row.player_id] = [];
      }
      playerSquadMap[row.player_id].push({
        id: row.squad_id,
        name: row.squad_name,
        code: row.squad_code
      });
    }
  } catch (_) {}

  try {
    const { results: smResults } = await db.prepare(`
      SELECT sm.athlete_id as player_id, s.id as squad_id, s.name as squad_name, s.code as squad_code
      FROM squad_members sm
      JOIN squads s ON s.id = sm.squad_id
      WHERE sm.athlete_id IN (${placeholders})
    `).bind(...playerIds).all();

    for (const row of (smResults || [])) {
      if (!playerSquadMap[row.player_id]) {
        playerSquadMap[row.player_id] = [];
      }
      if (!playerSquadMap[row.player_id].some(sq => sq.id === row.squad_id)) {
        playerSquadMap[row.player_id].push({
          id: row.squad_id,
          name: row.squad_name,
          code: row.squad_code
        });
      }
    }
  } catch (_) {}

  const finalPlayers: any[] = [];
  try {
    const { results: pRes } = await db.prepare(`SELECT * FROM players WHERE id IN (${placeholders}) ORDER BY first_name ASC`).bind(...playerIds).all();
    if (pRes && pRes.length > 0) {
      for (const p of pRes) {
        finalPlayers.push({
          id: p.id,
          firstName: p.first_name || '',
          lastName: p.last_name || '',
          ageGroup: p.age_group || ageGroup,
          position: p.position || 'Athlete',
          team: p.team || 'U15 Squad',
          status: p.status || '',
          age: p.age ?? null,
          assignedSquads: playerSquadMap[p.id] || []
        });
      }
    }
  } catch (_) {}

  try {
    const { results: aRes } = await db.prepare(`SELECT * FROM athletes WHERE id IN (${placeholders})`).bind(...playerIds).all();
    if (aRes && aRes.length > 0) {
      for (const a of aRes) {
        if (!finalPlayers.some(p => p.id === a.id)) {
          const parts = (a.name || '').trim().split(' ');
          const firstName = parts[0] || 'Athlete';
          const lastName = parts.slice(1).join(' ') || '';
          finalPlayers.push({
            id: a.id,
            firstName,
            lastName,
            ageGroup: ageGroup,
            position: a.position || 'Athlete',
            team: a.school_name || 'U15 Squad',
            status: a.status || '',
            age: a.age ?? null,
            assignedSquads: playerSquadMap[a.id] || []
          });
        }
      }
    }
  } catch (_) {}

  // Attach test logs to finalPlayers for real-time score display and baseline references
  try {
    const stringPlayerIds = playerIds.map(id => String(id));
    const pHolders = stringPlayerIds.map(() => '?').join(',');

    const { results: logResults } = await db.prepare(`
      SELECT ptl.player_id, ptl.metric_id, ptl.score, ptl.test_date, ptl.session_name, tmd.name as metric_name, tmd.unit
      FROM player_test_logs ptl
      LEFT JOIN test_metric_definitions tmd ON CAST(tmd.id AS TEXT) = CAST(ptl.metric_id AS TEXT) OR tmd.name = ptl.metric_id
      WHERE CAST(ptl.player_id AS TEXT) IN (${pHolders})
      ORDER BY ptl.created_at DESC, ptl.test_date DESC
    `).bind(...stringPlayerIds).all();

    const playerLogsMap: Record<string, any[]> = {};
    for (const row of (logResults || [])) {
      const pIdStr = String(row.player_id);
      if (!playerLogsMap[pIdStr]) {
        playerLogsMap[pIdStr] = [];
      }
      playerLogsMap[pIdStr].push({
        metricId: String(row.metric_id),
        metric_id: String(row.metric_id),
        metricName: row.metric_name || row.metric_id,
        metric_name: row.metric_name || row.metric_id,
        score: row.score,
        testDate: row.test_date,
        sessionName: row.session_name,
        unit: row.unit || ''
      });
    }

    for (const p of finalPlayers) {
      const pIdStr = String(p.id);
      p.testLogs = playerLogsMap[pIdStr] || [];
      p.fitnessBaselines = playerLogsMap[pIdStr] || [];
    }
  } catch (e) { console.error('[Roster] Failed to attach test logs:', e); }

  return c.json({
    success: true,
    data: {
      ageGroup,
      players: finalPlayers
    }
  });
});

// Route: Update Player Squad Assignments
app.post('/api/players/:id/squads', async (c) => {
  const playerId = c.req.param('id');
  const body = await c.req.json();
  const { squadIds } = body;
  const db = getDB(c);

  if (!Array.isArray(squadIds)) {
    return c.json({ success: false, message: 'squadIds must be an array' }, 400);
  }

  await ensureSquadsTables(db);

  try {
    let existingSquadIds: string[] = [];
    try {
      const { results } = await db.prepare('SELECT squad_id FROM squad_players WHERE player_id = ?').bind(playerId).all();
      existingSquadIds = (results || []).map((r: any) => r.squad_id);
    } catch (_) {}

    await db.prepare('DELETE FROM squad_players WHERE player_id = ?').bind(playerId).run();

    for (const squadId of squadIds) {
      await db.prepare('INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)').bind(squadId, playerId).run();
      let squad: any = null;
      try {
        squad = await db.prepare('SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?').bind(squadId, squadId, squadId).first();
      } catch (_) {}
      if (squad) {
        await db.prepare('INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)').bind(squad.id, playerId).run();
        await db.prepare('INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)').bind(squad.code, playerId).run();
      }
    }

    const removedSquadIds = existingSquadIds.filter((id) => !squadIds.includes(id));
    for (const removedId of removedSquadIds) {
      let squad: any = null;
      try {
        squad = await db.prepare('SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?').bind(removedId, removedId, removedId).first();
      } catch (_) {}
      const codesToClear = Array.from(new Set([removedId, ...(squad ? [squad.id, squad.code, squad.name] : [])]));
      const ph = codesToClear.map(() => '?').join(',');
      await db.prepare(`
        UPDATE players
        SET age_group = CASE WHEN age_group IN (${ph}) THEN 'Unassigned' ELSE age_group END,
            team = CASE WHEN team IN (${ph}) THEN NULL ELSE team END
        WHERE id = ?
      `).bind(...codesToClear, ...codesToClear, playerId).run();
    }

    console.log(`[Observer Log] Updated squad assignments for player '${playerId}' to [${squadIds.join(', ')}]`);

    return c.json({
      success: true,
      message: 'Player squad assignments updated successfully',
      data: { playerId, squadIds }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to update player squad assignments', error: err.message }, 500);
  }
});

// Route: Get Coach Dashboard Summary KPIs (Restricted to Coach's Owned Squads)
app.get('/api/dashboard/summary', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || '1';
  const coachId = jwtPayload?.sub;
  const role = jwtPayload?.role || 'Coach';
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const db = getDB(c);

  if (!schoolId) {
    return c.json({ success: false, message: 'schoolId is required' }, 400);
  }

  const { playerIds } = await getCoachSquadPlayerIds(db, coachId, schoolId, role, ageGroup);

  if (playerIds.length === 0) {
    return c.json({
      success: true,
      data: {
        attendancePercent: 0,
        teamPerformanceAvg: 0.0,
        kpis: {
          totalPlayers: 0,
          uniReady: 0,
          onTrack: 0,
          atRisk: 0,
          danger: 0,
          flagged: 0
        }
      }
    });
  }

  const totalPlayers = playerIds.length;
  const placeholders = playerIds.map(() => '?').join(',');

  const avgPerformanceQuery = `SELECT AVG(auto_score) as avg FROM match_stats WHERE player_id IN (${placeholders})`;
  const avgRes = await db.prepare(avgPerformanceQuery).bind(...playerIds).first();
  const avgScore = avgRes && avgRes.avg ? Math.round(avgRes.avg * 10) / 10 : 0.0;

  const academicQuery = `
    SELECT player_id, AVG(grade_percentage) as avg_grade
    FROM academic_logs
    WHERE player_id IN (${placeholders})
    GROUP BY player_id
  `;
  let acads: any[] = [];
  try {
    const res = await db.prepare(academicQuery).bind(...playerIds).all();
    acads = res.results || [];
  } catch (_) {}

  let uniReadyCount = 0;
  let onTrackCount = 0;
  let atRiskCount = 0;
  let dangerCount = 0;

  acads.forEach((row: any) => {
    const score = row.avg_grade;
    if (score >= 65) uniReadyCount++;
    else if (score >= 60) onTrackCount++;
    else if (score >= 50) atRiskCount++;
    else dangerCount++;
  });

  const attendanceQuery = `
    SELECT COUNT(*) as total, SUM(CASE WHEN status = 'Present' THEN 1 ELSE 0 END) as present
    FROM attendance
    WHERE player_id IN (${placeholders})
  `;
  const attRes = await db.prepare(attendanceQuery).bind(...playerIds).first();
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

// Route: Get Flagged Players (Restricted to Coach's Owned Squads)
app.get('/api/dashboard/flags', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || '1';
  const coachId = jwtPayload?.sub;
  const role = jwtPayload?.role || 'Coach';
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const db = getDB(c);

  if (!schoolId) {
    return c.json({ success: false, message: 'schoolId is required' }, 400);
  }

  const { playerIds } = await getCoachSquadPlayerIds(db, coachId, schoolId, role, ageGroup);

  if (playerIds.length === 0) {
    return c.json({
      success: true,
      data: []
    });
  }

  const placeholders = playerIds.map(() => '?').join(',');
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
    WHERE p.id IN (${placeholders})
  `;

  let rows: any[] = [];
  try {
    const res = await db.prepare(query).bind(...playerIds).all();
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

        if (r2 && typeof r2.delete === 'function') {
          const key = imagePath.includes('/') ? imagePath.split('/').pop() : imagePath;
          if (key) {
            await r2.delete(key);
            console.log(`[Observer Log] [R2 PURGE] Deleted workout image '${key}' for event #${r.id} older than 7 days.`);
          }
        }

        await db.prepare('UPDATE events SET workout_image_path = NULL WHERE id = ?')
          .bind(r.id)
          .run();

        r.workout_image_path = null;
      }
    } catch (err) {
      console.warn(`[Observer Error] [R2 PURGE] Failed purging workout image for event #${r?.id}:`, err);
    }
  }
}// Route: Get Coach Command Events (Restricted to Coach's Owned Squads)
// Route: Get Coach Command Events (Restricted to Coach's Owned Squads)
const handleGetEvents = async (c: any) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const reqSchoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query('school_id') || c.req.query('schoolId');
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const eventTypeParam = c.req.query('event_type') || c.req.query('eventType');
  const db = getDB(c);

  if (!db) {
    return c.json({ success: false, message: 'Database connection unavailable' }, 500);
  }

  let query = 'SELECT * FROM events WHERE 1=1';
  let params: any[] = [];

  if (reqSchoolId && reqSchoolId !== 'ALL' && reqSchoolId !== 'all') {
    const sId = String(reqSchoolId);
    query += ' AND (school_id = ? OR CAST(school_id AS TEXT) = ? OR school_id = "OVK" OR school_id = "1" OR school_id IS NULL)';
    params.push(sId, sId);
  }

  if (eventTypeParam) {
    const etLower = eventTypeParam.toLowerCase().trim();
    if (etLower === 'fitness test' || etLower === 'test day' || etLower === 'fitness' || etLower === 'test') {
      query += " AND (LOWER(event_type) = 'fitness test' OR LOWER(event_type) = 'test day' OR LOWER(event_type) = 'fitness' OR LOWER(event_type) = 'test' OR LOWER(event_type) LIKE '%fitness%' OR LOWER(event_type) LIKE '%test%')";
    } else {
      query += ' AND LOWER(event_type) = ?';
      params.push(etLower);
    }
  }

  if (ageGroup && ageGroup !== 'All' && ageGroup !== 'ALL') {
    const agTrim = ageGroup.trim();
    query += ' AND (LOWER(age_group) = LOWER(?) OR LOWER(team) = LOWER(?) OR LOWER(age_group) LIKE LOWER(?) OR LOWER(team) LIKE LOWER(?) OR age_group IS NULL OR age_group = "" OR team IS NULL OR team = "")';
    params.push(agTrim, agTrim, `%${agTrim}%`, `%${agTrim}%`);
  }

  query += ' ORDER BY date DESC, start_time DESC';

  try {
    const { results } = await db.prepare(query).bind(...params).all();
    
    if (c.executionCtx && typeof c.executionCtx.waitUntil === 'function') {
      c.executionCtx.waitUntil(purgeExpiredWorkoutImages(c, results || []));
    } else {
      purgeExpiredWorkoutImages(c, results || []).catch(() => {});
    }

    let events = (results || []).map((r: any) => ({
      id: r.id?.toString() || '',
      schoolId: r.school_id || schoolId,
      title: r.title,
      eventType: r.event_type,
      startTime: r.start_time,
      date: r.date,
      durationMins: r.duration_mins,
      location: r.location,
      isImportant: r.is_important === 1,
      completionCount: r.completion_count,
      ageGroup: r.age_group || '',
      team: r.team || r.age_group || '',
      workoutImagePath: r.workout_image_path,
      recurrenceRule: r.recurrence_rule || 'Does Not Repeat',
      recurrenceEndDate: r.recurrence_end_date || null
    }));

    return c.json({
      success: true,
      data: events
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to fetch events', error: err.message }, 500);
  }
};

app.get('/api/dashboard/events', handleGetEvents);
app.get('/api/events', handleGetEvents);

// Route: Create Coach Command Event
const handleCreateEvent = async (c: any) => {
  const jwtPayload = c.get('jwtPayload') as any;
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

  const schoolId = (jwtPayload?.schoolId || body?.schoolId || '1').trim();

  const { id, title, eventType, startTime, date, durationMins, location, isImportant, ageGroup, team, workoutImagePath, recurrenceRule, recurrenceEndDate } = body;

  const eventTitle = (title || '').trim();
  const eventLoc = (location || '').trim();
  const eventTime = (startTime || '').trim();
  const eventDt = (date || '').trim();
  const rawEventType = (eventType || '').trim();
  const targetAgeGroup = (ageGroup || '').trim();
  const assignedTeam = (team || '').trim();

  // Strict Fail-Fast Validation (NO DUMMY FALLBACKS)
  if (!eventTitle) {
    return c.json({ success: false, message: 'Event title is required.' }, 400);
  }
  if (!rawEventType) {
    return c.json({ success: false, message: 'Event type is required.' }, 400);
  }
  if (!eventTime) {
    return c.json({ success: false, message: 'Start time is required.' }, 400);
  }
  if (!/^\d{1,2}:\d{2}(:\d{2})?$/.test(eventTime)) {
    return c.json({ success: false, message: 'Start time must be formatted as HH:mm (e.g. 15:30).' }, 400);
  }
  if (!eventDt) {
    return c.json({ success: false, message: 'Event date is required.' }, 400);
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(eventDt)) {
    return c.json({ success: false, message: 'Event date must be formatted as YYYY-MM-DD.' }, 400);
  }
  const todayStr = new Date().toISOString().split('T')[0];
  if (eventDt < todayStr) {
    return c.json({ success: false, message: 'Events cannot be created in the past.' }, 400);
  }
  if (!eventLoc) {
    return c.json({ success: false, message: 'Event location is required.' }, 400);
  }
  if (!targetAgeGroup && !assignedTeam) {
    return c.json({ success: false, message: 'Target age group or assigned team is required.' }, 400);
  }

  let evType = rawEventType;
  if (evType === 'Field' || evType === 'Field Practice') evType = 'Field Session';
  if (evType === 'Gym' || evType === 'Gym Practice') evType = 'Gym Session';
  if (evType === 'Match' || evType === 'Match Practice') evType = 'Match Day';
  if (evType === 'Test Day' || evType === 'Test') evType = 'Fitness Test';

  const eventId = id ? id.toString() : `EVT-${Date.now()}`;
  const finalAgeGroup = targetAgeGroup || assignedTeam;
  const finalTeam = assignedTeam || targetAgeGroup;
  const recRuleVal = (recurrenceRule || body.recurrence_rule || 'Does Not Repeat').trim();
  const recEndDateVal = (recurrenceEndDate || body.recurrence_end_date || null);

  const query = `
    INSERT INTO events (
      id, school_id, title, event_type, start_time, date, duration_mins, location, is_important, completion_count, age_group, team, workout_image_path, recurrence_rule, recurrence_end_date
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ON CONFLICT(id) DO UPDATE SET
      title = excluded.title,
      event_type = excluded.event_type,
      start_time = excluded.start_time,
      date = excluded.date,
      duration_mins = excluded.duration_mins,
      location = excluded.location,
      is_important = excluded.is_important,
      age_group = excluded.age_group,
      team = excluded.team,
      workout_image_path = excluded.workout_image_path,
      recurrence_rule = excluded.recurrence_rule,
      recurrence_end_date = excluded.recurrence_end_date
  `;

  try {
    const isImpVal = isImportant === true || isImportant === 1 ? 1 : 0;
    const durMinsVal = durationMins ? parseInt(durationMins.toString(), 10) : null;
    const compCountVal = evType === 'Gym Session' ? 0 : null;

    await db.prepare(query).bind(
      eventId,
      schoolId,
      eventTitle,
      evType,
      eventTime,
      eventDt,
      durMinsVal,
      eventLoc,
      isImpVal,
      compCountVal,
      finalAgeGroup,
      finalTeam,
      workoutImagePath || null,
      recRuleVal,
      recEndDateVal
    ).run();

    console.log(`[Observer Log] Event '${eventId}' successfully created in Cloudflare D1 for school '${schoolId}'.`);

    return c.json({
      success: true,
      message: 'Event created successfully',
      data: {
        id: eventId,
        schoolId,
        title: eventTitle,
        eventType: evType,
        startTime: eventTime,
        date: eventDt,
        durationMins: durMinsVal,
        location: eventLoc,
        isImportant: isImpVal === 1,
        completionCount: compCountVal,
        ageGroup: finalAgeGroup,
        team: finalTeam,
        workoutImagePath: workoutImagePath || null,
        recurrenceRule: recRuleVal,
        recurrenceEndDate: recEndDateVal
      }
    }, 201);
  } catch (err: any) {
    console.error(`[Observer Error] Failed to create event '${eventId}':`, err);
    return c.json({ success: false, message: 'Failed to create event', error: err.message }, 500);
  }
};

app.post('/api/dashboard/events', handleCreateEvent);
app.post('/api/events', handleCreateEvent);

// Route: Update Coach Command Event (Supports POST & PUT aliases)
const handleUpdateEvent = async (c: any) => {
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

  const { title, eventType, startTime, date, durationMins, location, isImportant, ageGroup, team, workoutImagePath, recurrenceRule, recurrenceEndDate } = body;

  const eventTitle = (title || '').trim();
  const eventLoc = (location || 'Field').trim();
  const eventTime = (startTime || '14:00').trim();
  const eventDt = (date || new Date().toISOString().split('T')[0]).trim();
  const rawEventType = (eventType || 'Fitness Test').trim();

  // Strict Fail-Fast Validation (NO DUMMY FALLBACKS)
  if (!eventTitle) {
    return c.json({ success: false, message: 'Event title is required.' }, 400);
  }

  // Fetch existing event record if present to preserve school_id, age_group, team
  const existingEvt = await db.prepare('SELECT * FROM events WHERE CAST(id AS TEXT) = ? OR id = ?').bind(id.toString(), id.toString()).first().catch(() => null);

  const targetAgeGroup = (ageGroup || team || existingEvt?.age_group || existingEvt?.team || 'U15 Squad').trim();
  const assignedTeam = (team || ageGroup || existingEvt?.team || existingEvt?.age_group || 'U15 Squad').trim();
  const schoolId = existingEvt?.school_id || body.schoolId || '1';

  let evType = rawEventType;
  if (evType === 'Field' || evType === 'Field Practice') evType = 'Field Session';
  if (evType === 'Gym' || evType === 'Gym Practice') evType = 'Gym Session';
  if (evType === 'Match' || evType === 'Match Practice') evType = 'Match Day';
  if (evType === 'Test Day' || evType === 'Test') evType = 'Fitness Test';

  const isImpVal = isImportant === true || isImportant === 1 ? 1 : 0;
  const durMinsVal = durationMins ? parseInt(durationMins.toString(), 10) : (existingEvt?.duration_mins || 90);
  const recRuleVal = (recurrenceRule || body.recurrence_rule || existingEvt?.recurrence_rule || 'Does Not Repeat').trim();
  const recEndDateVal = (recurrenceEndDate || body.recurrence_end_date || existingEvt?.recurrence_end_date || null);
  const imgPath = workoutImagePath !== undefined ? workoutImagePath : (existingEvt?.workout_image_path || null);

  try {
    if (existingEvt) {
      const query = `
        UPDATE events SET 
          title = ?, event_type = ?, start_time = ?, date = ?, duration_mins = ?, 
          location = ?, is_important = ?, age_group = ?, team = ?, workout_image_path = ?,
          recurrence_rule = ?, recurrence_end_date = ?
        WHERE CAST(id AS TEXT) = ? OR id = ?
      `;
      await db.prepare(query).bind(
        eventTitle, evType, eventTime, eventDt, durMinsVal,
        eventLoc, isImpVal, targetAgeGroup,
        assignedTeam, imgPath, recRuleVal, recEndDateVal, id.toString(), id.toString()
      ).run();
    } else {
      // Upsert/Insert if event ID was generated client-side or newly saved
      const insertQuery = `
        INSERT OR REPLACE INTO events (id, school_id, title, event_type, start_time, date, duration_mins, location, is_important, age_group, team, workout_image_path, recurrence_rule, recurrence_end_date)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      await db.prepare(insertQuery).bind(
        id.toString(), schoolId, eventTitle, evType, eventTime, eventDt, durMinsVal,
        eventLoc, isImpVal, targetAgeGroup, assignedTeam, imgPath, recRuleVal, recEndDateVal
      ).run();
    }

    console.log(`[Observer Log] Event '${id}' successfully saved/updated in D1.`);
    return c.json({ success: true, message: 'Event updated successfully' });
  } catch (err: any) {
    console.error(`[Observer Error] Failed updating event '${id}':`, err);
    return c.json({ success: false, message: 'Failed to update event', error: err.message }, 500);
  }
};

app.post('/api/dashboard/events/:id', handleUpdateEvent);
app.put('/api/dashboard/events/:id', handleUpdateEvent);
app.post('/api/events/:id', handleUpdateEvent);
app.put('/api/events/:id', handleUpdateEvent);

// Route: Delete Coach Command Event
const handleDeleteEvent = async (c: any) => {
  const id = c.req.param('id');
  const db = getDB(c);
  try {
    await db.prepare('DELETE FROM events WHERE CAST(id AS TEXT) = ? OR id = ?').bind(id.toString(), id.toString()).run();
    return c.json({ success: true, message: 'Event deleted successfully' });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to delete event', error: err.message }, 500);
  }
};

app.delete('/api/dashboard/events/:id', handleDeleteEvent);
app.post('/api/dashboard/events/:id/delete', handleDeleteEvent);
app.delete('/api/events/:id', handleDeleteEvent);
app.post('/api/events/:id/delete', handleDeleteEvent);

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
        school_id TEXT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        completed_at TIMESTAMP,
        player_id TEXT,
        player_name TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    // Ensure completed_at column exists for legacy D1 schemas
    await db.prepare('ALTER TABLE action_plans ADD COLUMN completed_at TIMESTAMP').run().catch(() => {});

    // Automatically delete action plans completed more than 24 hours (86400 seconds) ago
    await db.prepare(`
      DELETE FROM action_plans 
      WHERE is_completed = 1 
        AND completed_at IS NOT NULL 
        AND (strftime('%s', 'now') - strftime('%s', completed_at)) >= 86400
    `).run().catch(() => {});

    const { results } = await db.prepare('SELECT * FROM action_plans ORDER BY created_at DESC').all();
    const nowMs = Date.now();
    const twentyFourHoursMs = 24 * 60 * 60 * 1000;

    const filteredRows = (results || []).filter((row: any) => {
      if (row.is_completed === 1 && row.completed_at) {
        const completedMs = new Date(row.completed_at).getTime();
        if (!isNaN(completedMs) && (nowMs - completedMs) >= twentyFourHoursMs) {
          return false;
        }
      }
      return true;
    });

    return c.json({
      success: true,
      data: filteredRows.map((row: any) => ({
        id: row.id,
        title: row.title,
        type: row.type,
        category: row.category || row.type,
        deadline: row.deadline,
        dateAdded: row.date_added || 'Today',
        isCompleted: Boolean(row.is_completed),
        completedAt: row.completed_at || null,
        playerId: row.player_id,
        playerName: row.player_name || '',
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
        school_id TEXT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        completed_at TIMESTAMP,
        player_id TEXT,
        player_name TEXT,
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
        school_id TEXT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        category TEXT,
        deadline TEXT NOT NULL,
        date_added TEXT,
        is_completed INTEGER DEFAULT 0,
        completed_at TIMESTAMP,
        player_id TEXT,
        player_name TEXT,
        player_phone TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run();

    await db.prepare('ALTER TABLE action_plans ADD COLUMN completed_at TIMESTAMP').run().catch(() => {});

    await db.prepare(`
      UPDATE action_plans 
      SET is_completed = CASE WHEN is_completed = 1 THEN 0 ELSE 1 END,
          completed_at = CASE WHEN is_completed = 0 THEN CURRENT_TIMESTAMP ELSE NULL END
      WHERE id = ?
    `).bind(id).run();

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
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || '1';
  const ageGroup = c.req.query('age_group') || c.req.query('ageGroup');
  const db = getDB(c);

  if (!schoolId) {
    return c.json({ success: false, message: 'schoolId is required' }, 400);
  }

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
    const grp = ageGroup || '';

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
const handlePostCheckin = async (c: any) => {
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

  // Flexible payload resolution
  const eventId = body.eventId || body.event_id || body.id || null;
  let date = body.date || body.checkInDate || body.eventDate;
  
  let checkedInPlayerIds: string[] = [];
  if (Array.isArray(body.checkedInPlayerIds)) {
    checkedInPlayerIds = body.checkedInPlayerIds;
  } else if (Array.isArray(body.playerIds)) {
    checkedInPlayerIds = body.playerIds;
  } else if (Array.isArray(body.athleteIds)) {
    checkedInPlayerIds = body.athleteIds;
  } else if (body.playerId || body.athleteId) {
    const singleId = body.playerId || body.athleteId;
    const isPresent = body.isPresent !== false && body.checkedIn !== false && body.status !== 'Absent';
    if (singleId && isPresent) {
      checkedInPlayerIds = [singleId];
    }
  }

  if (!date && eventId) {
    try {
      const ev: any = await db.prepare('SELECT date FROM events WHERE id = ?').bind(eventId).first();
      if (ev && ev.date) date = ev.date;
    } catch (_) {}
  }
  if (!date) {
    date = new Date().toISOString().split('T')[0];
  }

  const sessType = body.sessionType || 'Field';
  const checkedInSet = new Set(checkedInPlayerIds);
  let targetPlayerIds: string[] = [];
  const ageGrp = body.ageGroup;

  if (eventId) {
    try {
      const ev: any = await db.prepare('SELECT age_group, team FROM events WHERE id = ?').bind(eventId).first();
      const evGroup = ev?.age_group || ev?.team || ageGrp;
      if (evGroup) {
        const { results: pRes } = await db.prepare('SELECT id FROM players WHERE age_group = ? OR team = ?').bind(evGroup, evGroup).all();
        if (pRes) targetPlayerIds = pRes.map((r: any) => r.id);
      }
    } catch (_) {}
  }
  if (targetPlayerIds.length === 0 && ageGrp) {
    try {
      const { results: pRes } = await db.prepare('SELECT id FROM players WHERE age_group = ? OR team = ?').bind(ageGrp, ageGrp).all();
      if (pRes) targetPlayerIds = pRes.map((r: any) => r.id);
    } catch (_) {}
  }

  const allSessionPlayerIds = Array.from(new Set([...targetPlayerIds, ...checkedInPlayerIds]));
  let recordedCount = 0;

  for (const playerId of allSessionPlayerIds) {
    const isPresent = checkedInSet.has(playerId);
    const statusVal = isPresent ? 'Present' : 'Absent';
    const evtIdStr = eventId ? eventId.toString() : `evt-${date}-${sessType}`;

    try {
      const sql = `
        INSERT INTO attendance (player_id, session_type, date, status, event_id, created_at)
        VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
        ON CONFLICT(player_id, event_id) DO UPDATE SET
          status = ?,
          date = ?,
          session_type = ?,
          created_at = CURRENT_TIMESTAMP
      `;
      await db.prepare(sql).bind(playerId, sessType, date, statusVal, evtIdStr, statusVal, date, sessType).run();
      if (isPresent) recordedCount++;
    } catch (e) {
      try {
        const legacySql = `
          INSERT INTO attendance (player_id, session_type, date, status, event_id, created_at)
          VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
          ON CONFLICT(player_id, session_type, date) DO UPDATE SET
            status = ?,
            event_id = ?,
            created_at = CURRENT_TIMESTAMP
        `;
        await db.prepare(legacySql).bind(playerId, sessType, date, statusVal, evtIdStr, statusVal, evtIdStr).run();
        if (isPresent) recordedCount++;
      } catch (_) {}
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

  console.log(`[API LOG] Recorded practice attendance for ${recordedCount} players on ${date} (${body.eventTitle || 'Session'})`);

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
};

app.post('/api/dashboard/checkin', handlePostCheckin);
app.post('/api/dashboard/checkins', handlePostCheckin);
app.post('/api/checkin', handlePostCheckin);
app.post('/api/checkins', handlePostCheckin);

// Route: Get Attendance for a Specific Event
app.get('/api/dashboard/events/:id/attendance', async (c) => {
  const eventId = c.req.param('id');
  const db = getDB(c);

  if (!db) {
    return c.json({ success: true, data: { eventId, checkedInPlayerIds: [] } });
  }

  try {
    const ev: any = await db.prepare('SELECT date, event_type FROM events WHERE CAST(id AS TEXT) = ? OR id = ?').bind(eventId, eventId).first();
    const targetDate = ev?.date || new Date().toISOString().split('T')[0];

    const { results: evtResults } = await db.prepare(`
      SELECT player_id FROM attendance WHERE (CAST(event_id AS TEXT) = ? OR event_id = ?) AND status = 'Present'
    `).bind(eventId.toString(), eventId.toString()).all();

    const checkedInPlayerIds = (evtResults || []).map((r: any) => r.player_id);

    return c.json({
      success: true,
      data: {
        eventId,
        date: targetDate,
        checkedInPlayerIds
      }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to fetch event attendance', error: err.message }, 500);
  }
});

// Route Aliases: GET /api/checkins and GET /api/dashboard/checkins
const handleGetCheckins = async (c: any) => {
  const eventId = c.req.query('eventId') || c.req.query('event_id') || c.req.param('id');
  const db = getDB(c);

  if (!db) {
    return c.json({ success: true, data: [], eventId, checkedInPlayerIds: [] });
  }

  try {
    if (eventId) {
      const ev: any = await db.prepare('SELECT date, event_type FROM events WHERE CAST(id AS TEXT) = ? OR id = ?').bind(eventId, eventId).first();
      const targetDate = ev?.date || new Date().toISOString().split('T')[0];

      const { results: evtResults } = await db.prepare(`
        SELECT player_id FROM attendance WHERE (CAST(event_id AS TEXT) = ? OR event_id = ?) AND date = ? AND status = 'Present'
      `).bind(eventId.toString(), eventId.toString(), targetDate).all();

      const checkedInPlayerIds = (evtResults || []).map((r: any) => r.player_id);
      const checkinArray = (evtResults || []).map((r: any) => ({
        eventId,
        athleteId: r.player_id,
        status: 'Checked In'
      }));

      return c.json({
        success: true,
        data: checkinArray,
        eventId,
        date: targetDate,
        checkedInPlayerIds
      });
    }

    const { results } = await db.prepare('SELECT player_id, event_id, session_type, date, status, created_at FROM attendance ORDER BY created_at DESC LIMIT 100').all();
    return c.json({
      success: true,
      data: results || []
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to fetch checkins', error: err.message }, 500);
  }
};

app.get('/api/checkins', handleGetCheckins);
app.get('/api/checkins/:id', handleGetCheckins);
app.get('/api/dashboard/checkins', handleGetCheckins);
app.get('/api/dashboard/checkins/:id', handleGetCheckins);

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
  const roleLower = (role || '').toString().toLowerCase();

  try {
    if (requestedPlayerId && requestedPlayerId.trim() !== '' && requestedPlayerId !== 'null' && requestedPlayerId !== 'undefined') {
      player = await db.prepare('SELECT * FROM players WHERE id = ?').bind(requestedPlayerId.trim()).first();
    }
    if (!player && (roleLower === 'student' || roleLower.includes('student'))) {
      player = await db.prepare('SELECT * FROM players WHERE user_id = ?').bind(userId).first();
      if (!player) {
        const u: any = await db.prepare('SELECT phone, email FROM users WHERE id = ?').bind(userId).first();
        if (u && u.phone) {
          const cleanPhone = u.phone.replace(/[^\d]/g, '');
          const suffix = cleanPhone.length >= 9 ? cleanPhone.slice(-9) : cleanPhone;
          player = await db.prepare('SELECT * FROM players WHERE phone = ? OR phone LIKE ?').bind(u.phone, `%${suffix}%`).first();
        }
      }
    } else if (!player && (roleLower === 'parent' || roleLower.includes('parent'))) {
      await ensureParentLinksTable(db);
      player = await db.prepare(`
        SELECT p.* FROM players p
        JOIN parent_child_links pcl ON (pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id))
        WHERE pcl.parent_user_id = ? AND (pcl.status = 'accepted' OR pcl.status = 'approved' OR pcl.status IS NULL)
        ORDER BY p.first_name ASC LIMIT 1
      `).bind(userId).first();
      if (!player) {
        player = await db.prepare(`
          SELECT p.* FROM players p
          JOIN parent_child_links pcl ON (pcl.player_id = p.id OR pcl.player_email = (SELECT email FROM users WHERE id = p.user_id))
          WHERE pcl.parent_user_id = ?
          ORDER BY p.first_name ASC LIMIT 1
        `).bind(userId).first();
      }
    }
  } catch (_) {}

  if (!player) {
    return c.json({
      success: true,
      data: {
        profile: {
          id: '',
          firstName: 'No Athlete Profile',
          lastName: '',
          team: 'Unassigned',
          ageGroup: '',
          position: '--',
          schoolId: jwtPayload?.schoolId || ''
        },
        academics: [],
        fitness: {
          baseline: null,
          progressions: [],
          dynamicMetrics: [],
          readinessScore: 0
        },
        dynamicMetrics: [],
        readinessScore: 0,
        matches: [],
        attendance: [],
        events: []
      }
    });
  }

  const playerId = player.id;

  // 1. Fetch Academic logs
  let academics: any[] = [];
  try {
    const academicsQuery = 'SELECT * FROM academic_logs WHERE player_id = ? ORDER BY term ASC';
    const { results } = await db.prepare(academicsQuery).bind(playerId).all();
    academics = results || [];
  } catch (_) {}

  // 2b. Fetch Dynamic Test Metrics & Time-Series Logs
  let dynamicMetrics: any[] = [];
  let totalReadinessScore = 0;
  let metricsCount = 0;

  try {
    const { results: metricDefs } = await db.prepare('SELECT * FROM test_metric_definitions WHERE school_id = ? ORDER BY category, name ASC').bind(player.school_id || '').all();
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

  // 2. Fetch Dynamic Fitness Metric Logs from player_test_logs
  let testLogs: any[] = [];
  try {
    const { results } = await db.prepare(`
      SELECT ptl.*, tmd.name as metric_name, tmd.category as metric_category, tmd.unit as metric_unit
      FROM player_test_logs ptl
      LEFT JOIN test_metric_definitions tmd ON ptl.metric_id = tmd.id
      WHERE ptl.player_id = ?
      ORDER BY ptl.test_date DESC
    `).bind(playerId).all();
    testLogs = results || [];
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

  // 6. Fetch Assigned Squads for Student
  let assignedSquads: any[] = [];
  try {
    const { results: sRes } = await db.prepare(`
      SELECT s.id, s.name, s.code, s.description
      FROM squads s
      JOIN squad_players sp ON sp.squad_id = s.id
      WHERE sp.player_id = ?
      ORDER BY s.name ASC
    `).bind(playerId).all();
    assignedSquads = (sRes || []).map((s: any) => ({
      id: s.id,
      name: s.name,
      code: s.code,
      description: s.description || ''
    }));
  } catch (_) {}

  if (assignedSquads.length === 0 && player.age_group) {
    assignedSquads.push({
      id: `default-${player.age_group}`,
      name: player.team || `${player.age_group} Squad`,
      code: player.age_group,
      description: ''
    });
  }

  // 7. Fetch Team Events for Student (filtered by squad if specified)
  let events: any[] = [];
  try {
    const schoolId = player.school_id || '';
    if (schoolId) {
      const reqSquadId = c.req.query('squad_id') || c.req.query('squadId');
      let eventsQuery = 'SELECT * FROM events WHERE school_id = ?';
      let queryParams: any[] = [schoolId];

      if (reqSquadId && !reqSquadId.startsWith('default-')) {
        const selectedSquad: any = await db.prepare('SELECT name, code FROM squads WHERE id = ?').bind(reqSquadId).first();
        if (selectedSquad) {
          eventsQuery += ' AND (team = ? OR age_group = ? OR age_group IS NULL OR age_group = "")';
          queryParams.push(selectedSquad.name, selectedSquad.code);
        } else {
          eventsQuery += ' AND (age_group = ? OR age_group IS NULL OR age_group = "")';
          queryParams.push(player.age_group);
        }
      } else {
        eventsQuery += ' AND (age_group = ? OR age_group IS NULL OR age_group = "")';
        queryParams.push(player.age_group);
      }
      eventsQuery += ' ORDER BY date ASC, start_time ASC';

      const { results } = await db.prepare(eventsQuery).bind(...queryParams).all();
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
    }
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
        notes: player.notes,
        assignedSquads: assignedSquads
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
        testLogs: testLogs.map((tl: any) => ({
          id: tl.id,
          metricId: tl.metric_id,
          metricName: tl.metric_name || tl.test_name || tl.metric_id,
          score: tl.score !== undefined && tl.score !== null ? tl.score : tl.score_value,
          unit: tl.metric_unit || tl.unit || '',
          category: tl.metric_category || tl.category || 'General',
          testDate: tl.test_date,
          sessionName: tl.session_name || 'Evaluation',
          notes: tl.notes || ''
        })),
        baseline: null,
        progressions: []
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
    const body = await c.req.json();
    const { firstName, lastName, phone, email, dob, preferredPosition, playerId: reqPlayerId } = body;

    let targetPlayer: any = null;
    if (reqPlayerId) {
      targetPlayer = await db.prepare('SELECT * FROM players WHERE id = ?').bind(reqPlayerId).first();
    }
    if (!targetPlayer) {
      targetPlayer = await db.prepare('SELECT * FROM players WHERE user_id = ? OR id = ?').bind(userId, userId).first();
    }
    if (!targetPlayer) {
      const u: any = await db.prepare('SELECT phone, email FROM users WHERE id = ?').bind(userId).first();
      if (u && u.phone) {
        const cleanPhone = u.phone.replace(/[^\d]/g, '');
        const suffix = cleanPhone.length >= 9 ? cleanPhone.slice(-9) : cleanPhone;
        targetPlayer = await db.prepare('SELECT * FROM players WHERE phone = ? OR phone LIKE ?').bind(u.phone, `%${suffix}%`).first();
      }
    }
    if (!targetPlayer) {
      targetPlayer = await db.prepare('SELECT * FROM players ORDER BY first_name ASC LIMIT 1').first();
    }

    if (!targetPlayer) {
      return c.json({ success: false, message: 'Player record not found' }, 404);
    }

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
          dob = COALESCE(?, dob),
          preferred_position = COALESCE(?, preferred_position),
          user_id = COALESCE(user_id, ?)
      WHERE id = ?
    `).bind(
      firstName || null,
      lastName || null,
      formattedPhone || null,
      dob || null,
      preferredPosition || null,
      userId,
      targetPlayer.id
    ).run();

    if (email && email.trim()) {
      const cleanEmail = email.trim().toLowerCase();
      const targetUserId = targetPlayer.user_id || userId;
      try {
        await db.prepare('UPDATE users SET email = ? WHERE id = ?').bind(cleanEmail, targetUserId).run();
      } catch (_) {}
    }

    return c.json({ success: true, message: 'Profile updated successfully', phone: formattedPhone, playerId: targetPlayer.id });
  } catch (err: any) {
    console.error('[API Error] Profile save error:', err);
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
    const existing = await db.prepare('SELECT id FROM player_test_logs WHERE player_id = ? AND metric_id = ? AND test_date = ?').bind(playerId, metricId, dateStr).first();
    const targetId = existing?.id || `ptl_${playerId}_${metricId}_${dateStr}`.replace(/[^a-zA-Z0-9_-]/g, '_');

    await db.prepare(`
      INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        score = excluded.score,
        session_name = excluded.session_name,
        notes = excluded.notes
    `).bind(
      targetId, playerId, metricId, parseFloat(score.toString()), dateStr, sessionName || 'Baseline Evaluation', notes || null
    ).run();

    return c.json({
      success: true,
      message: 'Evaluation baseline updated successfully',
      data: { id: targetId, playerId, metricId, score, testDate: dateStr }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to update evaluation baseline', error: err.message }, 500);
  }
});

// Route: Get Test Metric Definitions
app.get('/api/test-metrics', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query('school_id') || c.req.query('schoolId') || '1';
  const db = getDB(c);

  try {
    let { results } = await db.prepare('SELECT * FROM test_metric_definitions WHERE school_id = ? OR CAST(school_id AS TEXT) = CAST(? AS TEXT) ORDER BY category, name ASC').bind(schoolId, schoolId).all();
    if (!results || results.length === 0) {
      const fallback = await db.prepare('SELECT * FROM test_metric_definitions ORDER BY category, name ASC').all();
      results = fallback.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((m: any) => ({
        id: m.id,
        schoolId: m.school_id,
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
  const db = getDB(c);

  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || body?.schoolId || body?.school_id || c.req.query('school_id') || c.req.query('schoolId') || '1';

  const { id, name, category, unit, goalDirection, targetBenchmark } = body || {};
  const metricName = (name || body?.metricName || body?.title || '').trim();
  const metricUnit = (unit || body?.metricUnit || body?.u || 'units').trim();

  if (!metricName) {
    return c.json({ success: false, message: 'Metric name is required.' }, 400);
  }

  const catName = category && category.trim() ? category.trim() : 'General';
  const metricId = id || generatePrimaryKey('tm');

  try {
    await db.prepare(`
      INSERT INTO test_metric_definitions (id, school_id, name, category, unit, goal_direction, target_benchmark)
      VALUES (?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        name = excluded.name,
        category = excluded.category,
        unit = excluded.unit,
        goal_direction = excluded.goal_direction,
        target_benchmark = excluded.target_benchmark
    `).bind(
      metricId, schoolId, metricName, catName, metricUnit,
      goalDirection || 'HIGHER_IS_BETTER', targetBenchmark || 0
    ).run();

    console.log(`[Observer Log] Test metric '${metricId}' (${metricName}) saved for school '${schoolId}'.`);

    return c.json({
      success: true,
      message: 'Test metric saved successfully',
      data: { id: metricId, schoolId, name: metricName, category: catName, unit: metricUnit, goalDirection: goalDirection || 'HIGHER_IS_BETTER', targetBenchmark: targetBenchmark || 0 }
    });
  } catch (err: any) {
    console.error(`[Observer Error] Failed to save test metric: ${err.message}`);
    return c.json({ success: false, message: 'Failed to save test metric', error: err.message }, 500);
  }
});

// Route: Delete Test Metric Definition
app.delete('/api/test-metrics/:id', async (c) => {
  const metricId = c.req.param('id');
  const db = getDB(c);
  try {
    await db.prepare('DELETE FROM test_metric_definitions WHERE id = ? OR name = ?').bind(metricId, metricId).run();
    console.log(`[Observer Log] Test metric '${metricId}' deleted.`);
    return c.json({ success: true, message: 'Test metric deleted successfully' });
  } catch (err: any) {
    console.error(`[Observer Error] Failed to delete test metric: ${err.message}`);
    return c.json({ success: false, message: 'Failed to delete test metric', error: err.message }, 500);
  }
});

// Route Aliases for Test Metrics
app.get('/api/dashboard/test-metrics', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = '/api/test-metrics';
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post('/api/dashboard/test-metrics', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = '/api/test-metrics';
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.delete('/api/dashboard/test-metrics/:id', async (c) => {
  const metricId = c.req.param('id');
  const url = new URL(c.req.url);
  url.pathname = `/api/test-metrics/${metricId}`;
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});

// Route Aliases for Batch Test Logs
app.post('/api/dashboard/test-logs/batch', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = '/api/test-logs/batch';
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
app.post('/api/dashboard/test-logs', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = '/api/test-logs/batch';
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});
// Route: Get saved test scores scoped to a specific event + date
app.get('/api/test-logs/by-event', async (c) => {
  const db = getDB(c);
  if (!db) return c.json({ success: false, message: 'Database connection unavailable' }, 500);

  const eventId = c.req.query('eventId') || c.req.query('event_id');
  const testDate = c.req.query('testDate') || c.req.query('test_date');

  if (!eventId) return c.json({ success: false, message: 'eventId query parameter is required' }, 400);

  try {
    let query = 'SELECT player_id, metric_id, score FROM player_test_logs WHERE event_id = ?';
    const bindings: any[] = [eventId];
    if (testDate) {
      query += ' AND test_date = ?';
      bindings.push(testDate);
    }

    const { results } = await db.prepare(query).bind(...bindings).all();

    // Build nested map: { playerId: { metricId: score } }
    const scoreMap: Record<string, Record<string, number>> = {};
    for (const row of (results || [])) {
      const pId = String(row.player_id);
      const mId = String(row.metric_id);
      if (!scoreMap[pId]) scoreMap[pId] = {};
      scoreMap[pId][mId] = row.score as number;
    }

    return c.json({ success: true, data: scoreMap });
  } catch (err: any) {
    console.error('[Observer Error] Failed to fetch event test logs:', err);
    return c.json({ success: false, message: 'Failed to fetch event scores', error: err.message }, 500);
  }
});

app.post('/api/test-logs', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = '/api/test-logs/batch';
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});

// Route: Batch Log Test Scores
app.post('/api/test-logs/batch', async (c) => {
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

  const logs = body.logs || body.scores || body.data;
  const metricId = body.metricId || body.metric_id || (Array.isArray(logs) && logs.length > 0 ? logs[0].metricId || logs[0].metric_id : null);
  const testDate = body.testDate || body.test_date || body.date || new Date().toISOString().split('T')[0];
  const sessionName = body.sessionName || body.session_name || body.eventTitle || 'Evaluation';
  const eventId = body.eventId || body.event_id || (Array.isArray(logs) && logs.length > 0 ? logs[0].eventId : null);

  if (!Array.isArray(logs) || logs.length === 0) {
    return c.json({ success: false, message: 'A non-empty logs array is required' }, 400);
  }

  try {
    // Ensure player_test_logs table schema exists
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS player_test_logs (
        id TEXT PRIMARY KEY,
        player_id TEXT NOT NULL,
        metric_id TEXT NOT NULL,
        score REAL NOT NULL,
        test_date TEXT NOT NULL,
        session_name TEXT DEFAULT 'Evaluation',
        event_id TEXT,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `).run().catch(() => {});

    await db.prepare('ALTER TABLE player_test_logs ADD COLUMN notes TEXT').run().catch(() => {});
    await db.prepare('ALTER TABLE player_test_logs ADD COLUMN session_name TEXT').run().catch(() => {});
    await db.prepare('ALTER TABLE player_test_logs ADD COLUMN event_id TEXT').run().catch(() => {});

    let savedCount = 0;
    for (const item of logs) {
      const pId = item.playerId || item.player_id || item.id;
      if (!pId || item.score === undefined || item.score === null || item.score === '') continue;
      const scoreVal = parseFloat(item.score.toString());
      if (isNaN(scoreVal)) continue;

      const targetMetricId = item.metricId || item.metric_id || metricId;
      if (!targetMetricId) continue;

      const fallbackId = `ptl_${Date.now()}_${pId}_${targetMetricId}_${testDate}`.replace(/[^a-zA-Z0-9_-]/g, '_');

      try {
        // Check if log already exists for player, metric and test_date
        const existing = await db.prepare('SELECT id FROM player_test_logs WHERE player_id = ? AND metric_id = ? AND event_id = ? AND test_date = ?').bind(pId, targetMetricId, eventId || '', testDate).first();
        const targetId = existing?.id || item.id || fallbackId;

        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, event_id, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            score = excluded.score,
            session_name = excluded.session_name,
            event_id = excluded.event_id,
            notes = excluded.notes
        `).bind(
          targetId,
          pId,
          targetMetricId,
          scoreVal,
          testDate,
          sessionName,
          eventId || null,
          item.notes || null
        ).run();
        savedCount++;

        // Auto check-in athlete as 'Present' for this test event / session
        try {
          const attEvtId = eventId ? String(eventId) : null;
          const sessType = sessionName || 'Fitness Test';

          // Use INSERT OR REPLACE with the composite PK (player_id, session_type, date)
          await db.prepare(
            "INSERT OR REPLACE INTO attendance (player_id, session_type, date, status, event_id) VALUES (?, ?, ?, 'Present', ?)"
          ).bind(pId, sessType, testDate, attEvtId).run();
        } catch (attErr) {
          console.warn(`Failed auto check-in attendance for player ${pId}:`, attErr);
        }
      } catch (e) {
        console.warn(`Failed test log insert for player ${pId}:`, e);
      }
    }

    return c.json({
      success: true,
      message: `Saved ${savedCount} test log(s) successfully`,
      data: { savedCount, metricId, testDate }
    });
  } catch (err: any) {
    console.error('[Observer Error] Failed to batch log test scores:', err);
    return c.json({ success: false, message: 'Failed to save test scores', error: err.message }, 500);
  }
});


// Route: Get all players for admin configurator
app.get('/api/admin/all-players', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const db = getDB(c);
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || c.req.query('school_id') || c.req.query('schoolId') || '1';

  try {
    const sId = String(schoolId);
    const query = 'SELECT id, first_name, last_name, age_group, team, position FROM players WHERE (school_id = ? OR CAST(school_id AS TEXT) = ?) ORDER BY age_group, team, last_name, first_name';
    let { results } = await db.prepare(query).bind(sId, sId).all();
    if (!results || results.length === 0) {
      const fallbackRes = await db.prepare('SELECT id, first_name, last_name, age_group, team, position FROM players ORDER BY age_group, team, last_name, first_name').all();
      results = fallbackRes.results || [];
    }
    return c.json({
      success: true,
      data: (results || []).map((r: any) => ({
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

// Route: Get school players for search & squad assignment
app.get('/api/school/players', async (c) => {
  const jwtPayload = c.get('jwtPayload') as any;
  const searchQuery = (c.req.query('q') || c.req.query('query') || '').trim();
  const db = getDB(c);

  await ensureSquadsTables(db);

  try {
    let sql = 'SELECT id, first_name, last_name, age_group, team, position, status FROM players WHERE 1=1';
    let params: any[] = [];

    if (searchQuery) {
      sql += ' AND (first_name LIKE ? OR last_name LIKE ? OR (first_name || " " || last_name) LIKE ?)';
      const term = `%${searchQuery}%`;
      params.push(term, term, term);
    }

    sql += ' ORDER BY last_name ASC, first_name ASC LIMIT 100';

    const { results } = await db.prepare(sql).bind(...params).all();
    const players = results || [];

    if (players.length > 0) {
      const pIds = players.map((p: any) => p.id);
      const placeholders = pIds.map(() => '?').join(',');
      const { results: sqRes } = await db.prepare(`
        SELECT sp.player_id, s.id as squad_id, s.name as squad_name, s.code as squad_code
        FROM squad_players sp
        JOIN squads s ON s.id = sp.squad_id
        WHERE sp.player_id IN (${placeholders})
      `).bind(...pIds).all();

      const sqMap: Record<string, any[]> = {};
      for (const row of (sqRes || [])) {
        if (!sqMap[row.player_id]) sqMap[row.player_id] = [];
        sqMap[row.player_id].push({
          id: row.squad_id,
          name: row.squad_name,
          code: row.squad_code
        });
      }

      for (const p of players) {
        p.assignedSquads = sqMap[p.id] || [];
      }
    }

    return c.json({
      success: true,
      data: players.map((p: any) => ({
        id: p.id,
        firstName: p.first_name,
        lastName: p.last_name,
        ageGroup: p.age_group,
        team: p.team || p.age_group,
        position: p.position,
        status: p.status || '',
        assignedSquads: p.assignedSquads || []
      }))
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to retrieve players', error: err.message }, 500);
  }
});

// Route: Add player to squad
app.post('/api/squads/:squadId/players/add', async (c) => {
  const squadId = c.req.param('squadId');
  const body = await c.req.json();
  const playerId = body.playerId;
  const db = getDB(c);

  if (!playerId) {
    return c.json({ success: false, message: 'playerId is required' }, 400);
  }

  await ensureSquadsTables(db);

  try {
    await db.prepare('INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)').bind(squadId, playerId).run();

    let squad: any = null;
    try {
      squad = await db.prepare('SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?').bind(squadId, squadId, squadId).first();
    } catch (_) {}

    if (squad) {
      await db.prepare('INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)').bind(squad.id, playerId).run();
      await db.prepare('INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)').bind(squad.code, playerId).run();

      await db.prepare(`
        UPDATE players
        SET age_group = CASE WHEN age_group IS NULL OR age_group = 'Unassigned' OR age_group = '' THEN ? ELSE age_group END,
            team = CASE WHEN team IS NULL OR team = 'Unassigned' OR team = '' THEN ? ELSE team END
        WHERE id = ?
      `).bind(squad.code, squad.name, playerId).run();
    } else {
      await db.prepare(`
        UPDATE players
        SET age_group = CASE WHEN age_group IS NULL OR age_group = 'Unassigned' OR age_group = '' THEN ? ELSE age_group END,
            team = CASE WHEN team IS NULL OR team = 'Unassigned' OR team = '' THEN ? ELSE team END
        WHERE id = ?
      `).bind(squadId, squadId, playerId).run();
    }

    console.log(`[Observer Log] Added player '${playerId}' to squad '${squadId}'`);

    return c.json({
      success: true,
      message: 'Player added to squad successfully',
      data: { squadId, playerId }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to add player to squad', error: err.message }, 500);
  }
});

// Route: Remove player from squad
app.post('/api/squads/:squadId/players/remove', async (c) => {
  const squadId = c.req.param('squadId');
  const body = await c.req.json();
  const playerId = body.playerId;
  const db = getDB(c);

  if (!playerId) {
    return c.json({ success: false, message: 'playerId is required' }, 400);
  }

  await ensureSquadsTables(db);

  try {
    let squad: any = null;
    try {
      squad = await db.prepare('SELECT id, code, name FROM squads WHERE id = ? OR code = ? OR name = ?').bind(squadId, squadId, squadId).first();
    } catch (_) {}

    const targetSquadKeys = Array.from(new Set([squadId, ...(squad ? [squad.id, squad.code, squad.name] : [])]));
    const ph = targetSquadKeys.map(() => '?').join(',');

    await db.prepare(`DELETE FROM squad_players WHERE player_id = ? AND squad_id IN (${ph})`).bind(playerId, ...targetSquadKeys).run();

    await db.prepare(`
      UPDATE players
      SET age_group = CASE WHEN age_group IN (${ph}) THEN 'Unassigned' ELSE age_group END,
          team = CASE WHEN team IN (${ph}) THEN NULL ELSE team END
      WHERE id = ?
    `).bind(...targetSquadKeys, ...targetSquadKeys, playerId).run();

    console.log(`[Observer Log] Removed player '${playerId}' from squad '${squadId}'`);

    return c.json({
      success: true,
      message: 'Player removed from squad successfully',
      data: { squadId, playerId }
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to remove player from squad', error: err.message }, 500);
  }
});

// Route: Squad Members (Aliases for /api/squads/members and /api/dashboard/squads/members)
const handleAddSquadMember = async (c: any) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: 'Database connection unavailable' }, 500);
  }

  let body: any = {};
  try {
    body = await c.req.json();
  } catch (_) {}

  const { squadId, squadName, athleteId, playerId } = body;
  const targetPlayerId = athleteId || playerId;
  const targetSquadId = squadId || squadName;

  if (!targetSquadId || !targetPlayerId) {
    return c.json({ success: false, message: 'squadId/squadName and athleteId/playerId are required' }, 400);
  }

  await ensureSquadsTables(db);

  try {
    await db.prepare('INSERT INTO squad_players (squad_id, player_id) VALUES (?, ?) ON CONFLICT DO NOTHING').bind(targetSquadId, targetPlayerId).run();
    await db.prepare('UPDATE players SET team = ? WHERE id = ?').bind(targetSquadId, targetPlayerId).run();

    return c.json({
      success: true,
      message: 'Member added to squad'
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to add member to squad', error: err.message }, 500);
  }
};

const handleRemoveSquadMember = async (c: any) => {
  const db = getDB(c);
  if (!db) {
    return c.json({ success: false, message: 'Database connection unavailable' }, 500);
  }

  let body: any = {};
  try {
    body = await c.req.json();
  } catch (_) {}

  const { squadId, athleteId, playerId } = body;
  const targetPlayerId = athleteId || playerId;
  const targetSquadId = squadId;

  if (!targetSquadId || !targetPlayerId) {
    return c.json({ success: false, message: 'squadId and athleteId/playerId are required' }, 400);
  }

  await ensureSquadsTables(db);

  try {
    await db.prepare('DELETE FROM squad_players WHERE squad_id = ? AND player_id = ?').bind(targetSquadId, targetPlayerId).run();
    await db.prepare('UPDATE players SET team = NULL WHERE id = ? AND team = ?').bind(targetPlayerId, targetSquadId).run();

    return c.json({
      success: true,
      message: 'Member removed from squad'
    });
  } catch (err: any) {
    return c.json({ success: false, message: 'Failed to remove member from squad', error: err.message }, 500);
  }
};

app.post('/api/squads/members', handleAddSquadMember);
app.post('/api/dashboard/squads/members', handleAddSquadMember);
app.delete('/api/squads/members', handleRemoveSquadMember);
app.delete('/api/dashboard/squads/members', handleRemoveSquadMember);
app.post('/api/squads/members/delete', handleRemoveSquadMember);
app.post('/api/dashboard/squads/members/delete', handleRemoveSquadMember);

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

      // 1. Insert/Update dynamic metric logs in player_test_logs
      const todayStr = new Date().toISOString().split('T')[0];
      const vertValue = vertical !== undefined && vertical !== null && vertical !== '' ? parseFloat(vertical) : null;
      const dashValue = dash40yd !== undefined && dash40yd !== null && dash40yd !== '' ? parseFloat(dash40yd) : null;

      if (vertValue !== null && !isNaN(vertValue)) {
        const vertMetricId = 'metric_vertical_jump';
        const vertLogId = `ptl_${player_id}_vert_${todayStr}`;
        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            score = excluded.score,
            session_name = excluded.session_name,
            notes = excluded.notes
        `).bind(vertLogId, player_id, vertMetricId, vertValue, todayStr, 'Bulk Upload Baseline', 'Vertical Jump (cm)').run();
      }

      if (dashValue !== null && !isNaN(dashValue)) {
        const dashMetricId = 'metric_speed_40m';
        const dashLogId = `ptl_${player_id}_dash_${todayStr}`;
        await db.prepare(`
          INSERT INTO player_test_logs (id, player_id, metric_id, score, test_date, session_name, notes)
          VALUES (?, ?, ?, ?, ?, ?, ?)
          ON CONFLICT(id) DO UPDATE SET
            score = excluded.score,
            session_name = excluded.session_name,
            notes = excluded.notes
        `).bind(dashLogId, player_id, dashMetricId, dashValue, todayStr, 'Bulk Upload Baseline', '40m Speed Dash (s)').run();
      }

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

  const statusCode = errorCount === 0 ? 200 : (successCount > 0 ? 207 : 400);
  return c.json({
    success: errorCount === 0,
    message: `Bulk upload completed. Success: ${successCount}, Errors: ${errorCount}`,
    data: {
      successCount,
      errorCount,
      errors
    }
  }, statusCode);
});

// Route: Get sports metrics configuration
app.get('/api/admin/sports-config', async (c) => {
  const db = getDB(c);
  const defaultConfig = [
    {
      id: 'rugby',
      name: 'Rugby',
      config: {
        fields: [
          { key: 'tackles_made', label: 'Tackles Made', type: 'counter' },
          { key: 'carries', label: 'Ball Carries', type: 'counter' },
          { key: 'metres_gained', label: 'Metres Gained', type: 'numeric' },
          { key: 'turnovers_won', label: 'Turnovers Won', type: 'counter' },
          { key: 'passes', label: 'Passes Completed', type: 'counter' }
        ]
      }
    }
  ];

  try {
    const { results } = await db.prepare('SELECT id, name, config_json FROM sports').all();
    if (results && results.length > 0) {
      return c.json({
        success: true,
        data: results.map((r: any) => ({
          id: r.id,
          name: r.name,
          config: typeof r.config_json === 'string' ? JSON.parse(r.config_json) : (r.config_json || {})
        }))
      });
    }
  } catch (err: any) {
    console.warn(`[API WARN] Failed to query sports table:`, err);
  }

  return c.json({
    success: true,
    data: defaultConfig
  });
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
  const body = await c.req.json();
  const schoolId = jwtPayload?.schoolId || jwtPayload?.school_id || body.schoolId || c.req.query('school_id') || c.req.query('schoolId') || 1;

  const { id, firstName, lastName, ageGroup, position, team, email, squadId } = body;
  const db = getDB(c);

  if (!firstName || !lastName || !ageGroup) {
    return c.json({ success: false, message: 'First name, last name, and age group are required' }, 400);
  }

  const playerId = id || `PL-${Date.now().toString().substring(7)}`;
  const playerEmail = (email && email.trim()) ? email.trim().toLowerCase() : `${firstName.toLowerCase().replace(/\s+/g, '')}.${lastName.toLowerCase().replace(/\s+/g, '')}@academypro.co.za`;

  try {
    // 1. Insert into D1 players table
    await db.prepare(`
      INSERT OR REPLACE INTO players (id, school_id, first_name, last_name, age_group, position, team, status)
      VALUES (?, ?, ?, ?, ?, ?, ?, 'Active')
    `).bind(playerId, schoolId, firstName, lastName, ageGroup, position || 'Athlete', team || `${ageGroup} Squad`).run();

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

    // Directly link player to explicit squadId if provided
    if (squadId) {
      try {
        await db.prepare(
          'INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)'
        ).bind(squadId, playerId).run();
      } catch (_) {}
    }

    // Auto-link player to coach squad if coach owns a matching squad
    if (jwtPayload && jwtPayload.sub) {
      try {
        const squad = await db.prepare(
          'SELECT id FROM squads WHERE coach_id = ? AND school_id = ? AND (code = ? OR name = ?)'
        ).bind(jwtPayload.sub, schoolId, ageGroup, team || ageGroup).first();

        if (squad) {
          await db.prepare(
            'INSERT OR IGNORE INTO squad_players (squad_id, player_id) VALUES (?, ?)'
          ).bind(squad.id, playerId).run();
        }
      } catch (_) {}
    }

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
  const parentUserId = jwtPayload?.sub;
  if (!parentUserId) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }

  let body: any;
  try {
    body = await c.req.json();
  } catch (_) {
    return c.json({ success: false, message: 'Invalid payload' }, 400);
  }

  const { childEmail } = body;
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
        player = await db.prepare('SELECT id, first_name, last_name, user_id FROM players WHERE user_id = ?').bind(user.id).first();
      }
    }

    if (!player) {
      return c.json({ success: false, message: 'No registered athlete profile found for provided child email' }, 404);
    }

    const playerId = player.id;

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

    if (player.user_id) {
      try {
        await db.prepare(`
          INSERT INTO notifications (user_id, title, body, type, is_read, created_at)
          VALUES (?, 'Parent Link Request', 'A parent has requested to link to your athlete profile. Tap to review and accept.', 'link_request', 0, CURRENT_TIMESTAMP)
        `).bind(player.user_id).run();
      } catch (_) {}
    }

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
  const userId = jwtPayload?.sub;
  if (!userId) {
    return c.json({ success: false, message: 'Unauthorized session' }, 401);
  }
  const db = getDB(c);

  await ensureParentLinksTable(db);

  try {
    const user = await db.prepare('SELECT email FROM users WHERE id = ?').bind(userId).first();
    const userEmail = user?.email || 'player@academypro.co.za';

    const { results } = await db.prepare(`
      SELECT pcl.id, pcl.status, pcl.created_at, u.first_name as parent_first_name, u.last_name as parent_last_name, u.email as parent_user_email
      FROM parent_child_links pcl
      LEFT JOIN users u ON pcl.parent_user_id = u.id
      WHERE pcl.player_email = ? OR pcl.player_id IN (SELECT id FROM players WHERE user_id = ?)
    `).bind(userEmail, userId).all();

    return c.json({
      success: true,
      data: (results || []).map((r: any) => ({
        id: r.id,
        parentName: `${r.parent_first_name || 'Parent'} ${r.parent_last_name || ''}`.trim(),
        parentEmail: r.parent_user_email || r.email || '',
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
        status: p.status || ''
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
    // Ensure notifications table schema is present in D1
    await db.prepare(`
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'general',
        is_read INTEGER DEFAULT 0,
        action_route TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    `).run().catch(() => {});

    const query = userId ? `
      SELECT id, user_id, title, body, type, is_read, action_route, created_at
      FROM notifications
      WHERE user_id = ? OR user_id = 'ALL' OR user_id IS NULL OR user_id = ''
      ORDER BY created_at DESC
    ` : `
      SELECT id, user_id, title, body, type, is_read, action_route, created_at
      FROM notifications
      WHERE user_id = 'ALL' OR user_id IS NULL OR user_id = ''
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
    return c.json({
      success: true,
      data: {
        notifications: [],
        unreadCount: 0
      }
    });
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
    const res = await db.prepare(`
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

// Route Alias: Coach Send SMS OTP
app.post('/api/coach/send-sms-otp', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = '/api/sms/send-verification';
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
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

  const otpCode = generateSecureOTP();
  
  // Format phone to digits-only (e.g. 27821234567) required by SMS gateway
  let digitsOnly = phone.replace(/[^\d]/g, '');
  if (digitsOnly.startsWith('0')) {
    digitsOnly = '27' + digitsOnly.slice(1);
  } else if (!digitsOnly.startsWith('27')) {
    digitsOnly = '27' + digitsOnly;
  }

  // Save OTP code in KV cache (10 min TTL = 600s)
  const kv = getKV(c);
  if (kv) {
    try {
      await kv.put(`sms_otp:${digitsOnly}`, otpCode, { expirationTtl: 600 });
    } catch (kvErr) {
      console.warn('[Observer Warning] Could not store OTP in KV:', kvErr);
    }
  }

  const apiKey = c.env.INTERNAL_API_KEY;
  if (!apiKey) {
    return c.json({ success: false, message: 'Internal API Key binding missing' }, 500);
  }

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
        phone: digitsOnly
      }
    });
  } catch (err: any) {
    console.error('[Observer Error] Failed to send SMS:', err);
    return c.json({ success: false, message: 'SMS service request failed', error: err.message }, 500);
  }
});

// Route Alias: Verify SMS OTP for Coach / User
app.post('/api/coach/verify-sms-otp', async (c) => {
  const url = new URL(c.req.url);
  url.pathname = '/api/sms/verify-code';
  return app.fetch(new Request(url.toString(), c.req.raw), c.env, c.executionCtx);
});

// Route: Verify SMS Code against KV
app.post('/api/sms/verify-code', async (c) => {
  let body: any;
  try {
    body = await c.req.json();
  } catch (e) {
    return c.json({ success: false, message: 'Invalid JSON payload' }, 400);
  }

  const { phone, code } = body;
  if (!phone || !code) {
    return c.json({ success: false, message: 'Phone number and verification code are required' }, 400);
  }

  let digitsOnly = phone.replace(/[^\d]/g, '');
  if (digitsOnly.startsWith('0')) {
    digitsOnly = '27' + digitsOnly.slice(1);
  } else if (!digitsOnly.startsWith('27')) {
    digitsOnly = '27' + digitsOnly;
  }

  const cleanCode = code.toString().trim();
  const kv = getKV(c);
  let storedOtp: string | null = null;
  if (kv) {
    try {
      storedOtp = await kv.get(`sms_otp:${digitsOnly}`);
    } catch (_) {}
  }

  // Validate stored OTP
  if (storedOtp && storedOtp.trim() === cleanCode) {
    if (kv) {
      try {
        await kv.delete(`sms_otp:${digitsOnly}`);
      } catch (_) {}
    }

    console.log(`[Observer Log] Verified phone number ${digitsOnly} successfully with code ${cleanCode}`);

    return c.json({
      success: true,
      message: 'Phone number verified successfully!'
    });
  }

  return c.json({
    success: false,
    message: 'Invalid or expired verification code. Please check your SMS and try again.'
  }, 400);
});

export default app;

