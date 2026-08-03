import app from '../../worker/src/index.ts';
import { sign } from 'hono/jwt';

async function runEmpiricalAuthenticatedTests() {
  console.log('=== EMPIRICAL AUTHENTICATED WORKER ROUTE TEST EXECUTION ===');

  const secret = 'usport_jwt_secret_key_2026_production_secure_777';
  const token = await sign({ sub: 'USR-TEST-001', role: 'Coach', schoolId: '1', exp: Math.floor(Date.now() / 1000) + 3600 }, secret);
  const authHeaders = {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  };

  // Test 1: GET /api/dashboard/summary
  const res1 = await app.fetch(new Request('http://localhost/api/dashboard/summary', { method: 'GET', headers: authHeaders }), { JWT_SECRET: secret });
  console.log(`Test 1: GET /api/dashboard/summary -> Status ${res1.status}`);

  // Test 2 (Client Event Delete): POST /api/dashboard/events/123/delete
  const res2 = await app.fetch(new Request('http://localhost/api/dashboard/events/123/delete', { method: 'POST', headers: authHeaders }), { JWT_SECRET: secret });
  const body2 = await res2.text();
  console.log(`Test 2 (Client Event Delete): POST /api/dashboard/events/123/delete -> Status ${res2.status} | Body: ${body2.substring(0, 100)}`);

  // Test 3 (Backend Event Delete): DELETE /api/dashboard/events/123
  const res3 = await app.fetch(new Request('http://localhost/api/dashboard/events/123', { method: 'DELETE', headers: authHeaders }), { JWT_SECRET: secret });
  const body3 = await res3.text();
  console.log(`Test 3 (Backend Event Delete): DELETE /api/dashboard/events/123 -> Status ${res3.status} | Body: ${body3.substring(0, 100)}`);

  // Test 4 (Client Notif Delete Attempt): POST /api/notifications/123/delete
  const res4 = await app.fetch(new Request('http://localhost/api/notifications/123/delete', { method: 'POST', headers: authHeaders }), { JWT_SECRET: secret });
  const body4 = await res4.text();
  console.log(`Test 4 (Client Notif Delete Attempt): POST /api/notifications/123/delete -> Status ${res4.status} | Body: ${body4.substring(0, 100)}`);

  // Test 5 (Client Notif Delete Fallback): DELETE /api/notifications/123
  const res5 = await app.fetch(new Request('http://localhost/api/notifications/123', { method: 'DELETE', headers: authHeaders }), { JWT_SECRET: secret });
  const body5 = await res5.text();
  console.log(`Test 5 (Client Notif Delete Fallback): DELETE /api/notifications/123 -> Status ${res5.status} | Body: ${body5.substring(0, 100)}`);
}

runEmpiricalAuthenticatedTests().catch(err => console.error('Test execution error:', err));
