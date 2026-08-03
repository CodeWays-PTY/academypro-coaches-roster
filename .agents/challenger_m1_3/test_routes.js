const https = require('https');
const crypto = require('crypto');

const BASE_URL = 'https://academypro-api.tata-elash34.workers.dev';
const JWT_SECRET = 'usport-secret-key-928374';

function base64url(input) {
  const buf = typeof input === 'string' ? Buffer.from(input) : input;
  return buf
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function generateJwt(secret) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const payload = {
    sub: 'USR-TEST-CHALLENGER',
    email: 'challenger@test.com',
    role: 'coach',
    schoolId: 1,
    exp: Math.floor(Date.now() / 1000) + 3600
  };
  const encodedHeader = base64url(JSON.stringify(header));
  const encodedPayload = base64url(JSON.stringify(payload));
  const signatureInput = `${encodedHeader}.${encodedPayload}`;
  const signature = crypto
    .createHmac('sha256', secret)
    .update(signatureInput)
    .digest();
  const encodedSignature = base64url(signature);
  return `${signatureInput}.${encodedSignature}`;
}

function makeRequest(method, path, headers = {}) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const reqHeaders = {
      'Content-Type': 'application/json',
      ...headers
    };

    const req = https.request(
      url,
      {
        method,
        headers: reqHeaders
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => (data += chunk));
        res.on('end', () => {
          let parsed;
          try {
            parsed = JSON.parse(data);
          } catch (_) {
            parsed = data;
          }
          resolve({
            statusCode: res.statusCode,
            headers: res.headers,
            body: parsed
          });
        });
      }
    );

    req.on('error', (err) => reject(err));
    req.end();
  });
}

async function runTests() {
  const token = generateJwt(JWT_SECRET);
  console.log('Generated Test JWT Token:', token);

  const tests = [
    {
      name: 'Unauthenticated POST /api/dashboard/events/test-id-999/delete',
      method: 'POST',
      path: '/api/dashboard/events/test-id-999/delete',
      headers: {}
    },
    {
      name: 'Authenticated POST /api/dashboard/events/test-id-999/delete',
      method: 'POST',
      path: '/api/dashboard/events/test-id-999/delete',
      headers: { Authorization: `Bearer ${token}` }
    },
    {
      name: 'Unauthenticated POST /api/notifications/test-id-999/delete',
      method: 'POST',
      path: '/api/notifications/test-id-999/delete',
      headers: {}
    },
    {
      name: 'Authenticated POST /api/notifications/test-id-999/delete',
      method: 'POST',
      path: '/api/notifications/test-id-999/delete',
      headers: { Authorization: `Bearer ${token}` }
    },
    {
      name: 'Control test: Non-existent route POST /api/dashboard/events/test-id-999/unknown_action',
      method: 'POST',
      path: '/api/dashboard/events/test-id-999/unknown_action',
      headers: { Authorization: `Bearer ${token}` }
    }
  ];

  console.log('\n================ EMPIRICAL ROUTE VERIFICATION RESULTS ================');
  for (const t of tests) {
    try {
      const res = await makeRequest(t.method, t.path, t.headers);
      console.log(`\nTest: ${t.name}`);
      console.log(`URL: ${BASE_URL}${t.path}`);
      console.log(`Status: ${res.statusCode}`);
      console.log(`Response Body:`, JSON.stringify(res.body));
      const passed = res.statusCode !== 404;
      console.log(`Non-404 Result: ${passed ? 'PASS (Status ' + res.statusCode + ')' : 'FAIL (404 Not Found)'}`);
    } catch (err) {
      console.error(`Error executing test ${t.name}:`, err.message);
    }
  }
}

runTests();
