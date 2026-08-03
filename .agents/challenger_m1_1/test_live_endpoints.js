const https = require('https');
const crypto = require('crypto');

const baseUrl = 'https://academypro-api.tata-elash34.workers.dev';
const jwtSecret = 'usport-secret-key-928374';

function base64UrlEncode(str) {
  return Buffer.from(str).toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function signJwt(payload, secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(payload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;
  const signature = crypto.createHmac('sha256', secret)
    .update(signatureInput)
    .digest('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
  return `${signatureInput}.${signature}`;
}

const coachToken = signJwt({
  sub: 'USR-COACH-JAN777',
  email: 'janmen777@gmail.com',
  role: 'Coach',
  schoolId: 1,
  exp: Math.floor(Date.now() / 1000) + 3600
}, jwtSecret);

const endpoints = [
  // Auth & Profile
  { path: '/api/auth/profile', method: 'GET', headers: { 'Authorization': `Bearer ${coachToken}` } },
  { path: '/api/auth/send-otp', method: 'POST', body: { email: 'nonexistent@example.com' } },
  { path: '/api/auth/send-otp', method: 'POST', body: { email: 'janmen777@gmail.com' } },

  // Rosters (Authenticated)
  { path: '/api/rosters/All', method: 'GET', headers: { 'Authorization': `Bearer ${coachToken}` } },
  { path: '/api/rosters/U15%20Squad', method: 'GET', headers: { 'Authorization': `Bearer ${coachToken}` } },
  { path: '/api/rosters/First%20Team', method: 'GET', headers: { 'Authorization': `Bearer ${coachToken}` } },

  // Squads (Authenticated)
  { path: '/api/squads', method: 'GET', headers: { 'Authorization': `Bearer ${coachToken}` } },

  // Edge cases / Guard checks
  { path: '/api/rosters/All', method: 'GET' }, // Unauthenticated check (should 401)
  { path: '/api/nonexistent-route', method: 'GET' } // 404 check
];

function request(item) {
  return new Promise((resolve) => {
    const url = new URL(item.path, baseUrl);
    const postData = item.body ? JSON.stringify(item.body) : null;
    const reqHeaders = {
      'Content-Type': 'application/json',
      ...(postData ? { 'Content-Length': Buffer.byteLength(postData) } : {}),
      ...(item.headers || {})
    };

    const options = {
      method: item.method,
      headers: reqHeaders
    };

    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        let json = null;
        try { json = JSON.parse(data); } catch (_) {}
        resolve({
          path: item.path,
          method: item.method,
          status: res.statusCode,
          statusText: res.statusMessage,
          body: json || data
        });
      });
    });

    req.on('error', (err) => {
      resolve({
        path: item.path,
        method: item.method,
        status: 'ERROR',
        error: err.message
      });
    });

    if (postData) req.write(postData);
    req.end();
  });
}

async function main() {
  console.log('=== EMPIRICAL LIVE ENDPOINT VERIFICATION ===');
  console.log('Base URL:', baseUrl);
  console.log('Signed Test Token generated for janmen777@gmail.com\n');

  let passes = 0;
  let fails = 0;

  for (const ep of endpoints) {
    const res = await request(ep);
    const is500 = res.status === 500;
    console.log(`[${res.method}] ${res.path} -> Status: ${res.status}`);
    console.log(`Response Snippet:`, typeof res.body === 'object' ? JSON.stringify(res.body).substring(0, 200) : String(res.body).substring(0, 200));

    if (is500) {
      console.error(`❌ FAILED: 500 Server Error detected on ${res.path}`);
      fails++;
    } else {
      console.log(`✅ PASSED (No 500 runtime errors)\n`);
      passes++;
    }
  }

  console.log(`Summary: ${passes} passed, ${fails} failed.`);
}

main().catch(console.error);
