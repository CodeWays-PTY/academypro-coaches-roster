// Accurate Empirical Route Verifier for AcademyPro Worker API & Clients
import fs from 'fs';
import path from 'path';

// 1. Load Backend Routes from worker/src/index.ts
const workerPath = path.resolve('c:/Development/academypro/worker/src/index.ts');
const workerContent = fs.readFileSync(workerPath, 'utf8');

const routeRegex = /app\.(get|post|put|delete|patch)\(\s*['"]([^'"]+)['"]/g;
const backendRoutes = [];
let match;

while ((match = routeRegex.exec(workerContent)) !== null) {
  backendRoutes.push({
    method: match[1].toUpperCase(),
    path: match[2],
    line: workerContent.substring(0, match.index).split('\n').length
  });
}

console.log(`=== BACKEND WORKER ROUTE INVENTORY (${backendRoutes.length} endpoints) ===`);
backendRoutes.forEach(r => console.log(`Line ${r.line.toString().padStart(4)}: ${r.method.padEnd(6)} ${r.path}`));

// 2. Check for Duplicate Routes in Backend
const routeMap = new Map();
const duplicateRoutes = [];
for (const r of backendRoutes) {
  const key = `${r.method} ${r.path}`;
  if (routeMap.has(key)) {
    duplicateRoutes.push({ key, line1: routeMap.get(key).line, line2: r.line });
  } else {
    routeMap.set(key, r);
  }
}

console.log(`\n=== DUPLICATE BACKEND ROUTE CHECK ===`);
if (duplicateRoutes.length === 0) {
  console.log('PASS: 0 duplicate/shadowed route definitions found on backend.');
} else {
  console.log('FAIL: Duplicate backend routes found:', duplicateRoutes);
}

// 3. Scan Flutter App and Web Admin for API Calls
const flutterFiles = [
  'c:/Development/academypro/academypro_app/lib/features/auth/presentation/auth_state.dart',
  'c:/Development/academypro/academypro_app/lib/features/auth/presentation/coach_welcome_wizard_screen.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/controllers/checkin_controller.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/controllers/dashboard_controller.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/controllers/roster_controller.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/presentation/batch_test_logger_modal.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/presentation/manage_metrics_modal.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/presentation/profile_tab_view.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/presentation/roster_tab_view.dart',
  'c:/Development/academypro/academypro_app/lib/features/dashboard/presentation/single_player_baseline_modal.dart',
  'c:/Development/academypro/academypro_app/lib/features/notifications/controllers/notification_controller.dart',
  'c:/Development/academypro/academypro_app/lib/features/parent/presentation/parent_dashboard_screen.dart',
  'c:/Development/academypro/academypro_app/lib/features/student/controllers/student_controller.dart',
  'c:/Development/academypro/academypro_app/lib/features/student/presentation/student_dashboard_screen.dart'
];

const webAdminFiles = [
  'c:/Development/academypro/web_admin/index.html',
  'c:/Development/academypro/web_admin/uploader.html'
];

const clientCalls = [];

function parseClientCalls(filePath) {
  if (!fs.existsSync(filePath)) return;
  const content = fs.readFileSync(filePath, 'utf8');

  // Match method + route call across newlines: .post( ... '/api/...' ), .get( ... '/api/...' ), .delete( ... '/api/...' ), fetch( ... '/api/...' )
  const methodCallRegex = /\.(post|get|delete|put|getAndCache|fetch)\s*\(\s*([^;]+?)(['"]\/api\/[^'"]+['"])/gs;
  
  // Simple regex for string literals containing /api/
  const stringRegex = /['"](\/api\/[^'"]+)['"]/g;
  let strMatch;

  const lines = content.split('\n');

  lines.forEach((lineText, idx) => {
    let m;
    const lineStrRegex = /['"](\/api\/[^'"]+)['"]/g;
    while ((m = lineStrRegex.exec(lineText)) !== null) {
      let rawPath = m[1];
      // Clean query strings & template interpolations
      let cleanPath = rawPath.split('?')[0].split('{')[0];
      
      // Determine HTTP method from line or previous lines
      let method = 'GET';
      const surroundingContext = lines.slice(Math.max(0, idx - 4), idx + 2).join(' ');
      if (/\.post\b/i.test(surroundingContext)) method = 'POST';
      else if (/\.delete\b/i.test(surroundingContext)) method = 'DELETE';
      else if (/\.put\b/i.test(surroundingContext)) method = 'PUT';
      else if (/\.get\b|\.getAndCache\b|fetch\b/i.test(surroundingContext)) method = 'GET';

      // Ignore cache keys or local storage calls if not actual API endpoints
      if (lineText.includes('LocalStorage.cacheData') || lineText.includes('getCachedData')) return;

      clientCalls.push({
        file: path.basename(filePath),
        line: idx + 1,
        method,
        rawPath,
        cleanPath
      });
    }
  });
}

flutterFiles.forEach(parseClientCalls);
webAdminFiles.forEach(parseClientCalls);

console.log(`\n=== EXTRACTED CLIENT API CALLS (${clientCalls.length} calls) ===`);

function normalize(p) {
  return p
    .replace(/\$\{?[a-zA-Z0-9_.]+\}?/g, ':param')
    .replace(/:[a-zA-Z0-9_]+/g, ':param')
    .replace(/\/+$/, '');
}

const backendNormalized = backendRoutes.map(b => ({
  ...b,
  norm: normalize(b.path)
}));

const auditResults = [];

for (const call of clientCalls) {
  const callNorm = normalize(call.cleanPath);

  // Find matching backend route by normalized path
  const matchingPaths = backendNormalized.filter(b => b.norm === callNorm);

  if (matchingPaths.length === 0) {
    auditResults.push({
      status: 'MISSING',
      call,
      reason: 'No backend endpoint handles this path'
    });
  } else {
    const exactMatch = matchingPaths.find(b => b.method === call.method);
    if (exactMatch) {
      auditResults.push({
        status: 'OK',
        call,
        matchedRoute: exactMatch
      });
    } else {
      auditResults.push({
        status: 'METHOD_MISMATCH',
        call,
        expectedMethods: matchingPaths.map(b => b.method)
      });
    }
  }
}

const missing = auditResults.filter(a => a.status === 'MISSING');
const mismatches = auditResults.filter(a => a.status === 'METHOD_MISMATCH');
const ok = auditResults.filter(a => a.status === 'OK');

console.log(`\n--- AUDIT SUMMARY ---`);
console.log(`Matched Routes (OK): ${ok.length}`);
console.log(`Method Mismatches:   ${mismatches.length}`);
console.log(`Missing Endpoints:   ${missing.length}`);

if (mismatches.length > 0) {
  console.log(`\n=== METHOD MISMATCHES DETAILS ===`);
  mismatches.forEach(m => {
    console.log(`[MISMATCH] ${m.call.file}:${m.call.line} -> ${m.call.method} ${m.call.cleanPath} | Backend expects: ${m.expectedMethods.join(', ')}`);
  });
}

if (missing.length > 0) {
  console.log(`\n=== MISSING ENDPOINTS DETAILS ===`);
  missing.forEach(m => {
    console.log(`[MISSING] ${m.call.file}:${m.call.line} -> ${m.call.method} ${m.call.cleanPath} (Normalized: ${normalize(m.call.cleanPath)})`);
  });
}
