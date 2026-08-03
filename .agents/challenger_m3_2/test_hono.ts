import { sign } from 'hono/jwt';

async function runEmpiricalHonoTest() {
  const { default: app } = await import('../../worker/src/index.ts');
  console.log('Loaded Hono app from worker/src/index.ts');

  const secret = 'test_secret_key_12345';
  const token = await sign(
    { sub: 'USR-TEST-001', email: 'test@example.com', role: 'Coach', schoolId: 'OVK', exp: Math.floor(Date.now() / 1000) + 3600 },
    secret
  );

  // Wrap app.fetch to provide c.env.JWT_SECRET
  const fetchWithEnv = async (path: string, method: string) => {
    const req = new Request(`http://localhost${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`
      }
    });
    return await (app as any).fetch(req, { JWT_SECRET: secret }, {});
  };

  const testCases = [
    // 1. Valid endpoints registered in worker/src/index.ts (MUST NOT return 404)
    { method: 'DELETE', path: '/api/dashboard/events/EVT123', expectedStatusNot: 404, name: 'Active DELETE /api/dashboard/events/:id' },
    { method: 'POST', path: '/api/dashboard/events/EVT123/delete', expectedStatusNot: 404, name: 'Active POST /api/dashboard/events/:id/delete' },
    { method: 'DELETE', path: '/api/test-metrics/MET123', expectedStatusNot: 404, name: 'Active DELETE /api/test-metrics/:id' },
    { method: 'DELETE', path: '/api/notifications/NOT123', expectedStatusNot: 404, name: 'Active DELETE /api/notifications/:id' },
    { method: 'POST', path: '/api/notifications/NOT123/delete', expectedStatusNot: 404, name: 'Active POST /api/notifications/:id/delete' },
    { method: 'POST', path: '/api/coach/send-sms-otp', expectedStatusNot: 404, name: 'Active POST /api/coach/send-sms-otp' },
    { method: 'POST', path: '/api/sms/send-verification', expectedStatusNot: 404, name: 'Active POST /api/sms/send-verification' },
    { method: 'POST', path: '/api/coach/verify-sms-otp', expectedStatusNot: 404, name: 'Active POST /api/coach/verify-sms-otp' },
    { method: 'POST', path: '/api/sms/verify-code', expectedStatusNot: 404, name: 'Active POST /api/sms/verify-code' },

    // 2. Pruned/non-existent routes documented in API_SPECIFICATION.md (MUST RETURN 404 NOT FOUND)
    { method: 'DELETE', path: '/api/dashboard/events/EVT123/delete', expectedStatus: 404, name: 'Pruned DELETE /api/dashboard/events/:id/delete' },
    { method: 'DELETE', path: '/api/test-metrics', expectedStatus: 404, name: 'Pruned DELETE /api/test-metrics (missing :id)' },
    { method: 'DELETE', path: '/api/notifications/NOT123/delete', expectedStatus: 404, name: 'Pruned DELETE /api/notifications/:id/delete' },
    { method: 'POST', path: '/api/notifications/NOT123', expectedStatus: 404, name: 'Non-existent POST /api/notifications/:id' }
  ];

  console.log('\n--- Empirical Route Matching Results (With Valid JWT Environment) ---');
  let passCount = 0;
  let failCount = 0;

  for (const tc of testCases) {
    const res = await fetchWithEnv(tc.path, tc.method);
    const status = res.status;

    if (tc.expectedStatus !== undefined) {
      if (status === tc.expectedStatus) {
        console.log(`[PASS] ${tc.method.padEnd(6)} ${tc.path.padEnd(45)} -> HTTP ${status} (Correctly 404 Not Found: ${tc.name})`);
        passCount++;
      } else {
        console.error(`[FAIL] ${tc.method.padEnd(6)} ${tc.path.padEnd(45)} -> HTTP ${status}, expected ${tc.expectedStatus} (${tc.name})`);
        failCount++;
      }
    } else if (tc.expectedStatusNot !== undefined) {
      if (status !== tc.expectedStatusNot) {
        console.log(`[PASS] ${tc.method.padEnd(6)} ${tc.path.padEnd(45)} -> HTTP ${status} (Confirmed active route: ${tc.name})`);
        passCount++;
      } else {
        console.error(`[FAIL] ${tc.method.padEnd(6)} ${tc.path.padEnd(45)} -> HTTP ${status} (ROUTE NOT FOUND: ${tc.name})`);
        failCount++;
      }
    }
  }

  console.log(`\nEmpirical Hono Test Summary: ${passCount} Passed, ${failCount} Failed.`);
}

runEmpiricalHonoTest().catch(console.error);
