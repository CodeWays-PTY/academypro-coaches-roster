const fs = require('fs');
const path = require('path');

// 1. Extract worker routes from index.ts
function extractWorkerRoutes(workerPath) {
  const content = fs.readFileSync(workerPath, 'utf8');
  const routeRegex = /app\.(get|post|put|delete|patch)\s*\(\s*['"`]([^'"`]+)['"`]/gi;
  const routes = new Set();
  let match;
  while ((match = routeRegex.exec(content)) !== null) {
    routes.add(`${match[1].toUpperCase()} ${match[2]}`);
  }
  return Array.from(routes).sort();
}

// 2. Extract API_SPECIFICATION.md routes
function extractApiSpecRoutes(specPath) {
  const content = fs.readFileSync(specPath, 'utf8');
  const routes = new Set();

  const tableRegex = /\|\s*([^|]*?)\s*\|\s*`(\/api\/[^`]+)`\s*\|\s*([^|]+)\s*\|/g;
  let match;
  while ((match = tableRegex.exec(content)) !== null) {
    const route = match[2].trim();
    const methodsStr = match[3].trim();
    const methods = methodsStr.split(/\s*[\/\,]\s*/);
    methods.forEach(m => {
      const cleanMethod = m.trim().toUpperCase();
      if (['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].includes(cleanMethod)) {
        routes.add(`${cleanMethod} ${route}`);
      }
    });
  }

  const sectionRegex = /\*\s*\*\*Method:\*\*\s*`?(GET|POST|PUT|DELETE|PATCH|GET\s*or\s*POST|PUT\s*or\s*DELETE)`?\s*\n\*\s*\*\*Route:\*\*\s*`?(\/api\/[^\s`\n]+)`?/gi;
  while ((match = sectionRegex.exec(content)) !== null) {
    const methodPart = match[1].trim();
    const route = match[2].trim();
    const methods = methodPart.split(/\s*(?:or|\/)\s*/i);
    methods.forEach(m => {
      const cleanMethod = m.trim().toUpperCase();
      if (['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].includes(cleanMethod)) {
        routes.add(`${cleanMethod} ${route}`);
      }
    });
  }

  return Array.from(routes).sort();
}

// 3. Extract flutter app API calls from academypro_app
function extractFlutterAppRoutes(appDir) {
  const endpoints = new Set();
  function walkDir(dir) {
    const files = fs.readdirSync(dir);
    files.forEach(file => {
      const fullPath = path.join(dir, file);
      const stat = fs.statSync(fullPath);
      if (stat.isDirectory()) {
        walkDir(fullPath);
      } else if (file.endsWith('.dart')) {
        const content = fs.readFileSync(fullPath, 'utf8');
        // Match string literals starting with /api/
        const matches = content.matchAll(/['"`](\/api\/[^\s'"`]+)['"`]/g);
        for (const m of matches) {
          endpoints.add(m[1]);
        }
      }
    });
  }
  walkDir(appDir);
  return Array.from(endpoints).sort();
}

// 4. Extract web_admin API calls
function extractWebAdminRoutes(adminDir) {
  const endpoints = new Set();
  const files = ['index.html', 'uploader.html'];
  files.forEach(f => {
    const fullPath = path.join(adminDir, f);
    if (fs.existsSync(fullPath)) {
      const content = fs.readFileSync(fullPath, 'utf8');
      const matches = content.matchAll(/['"`](\/api\/[^\s'"`\?]+)['"`]/g);
      for (const m of matches) {
        endpoints.add(m[1]);
      }
    }
  });
  return Array.from(endpoints).sort();
}

const workerPath = 'c:\\Development\\academypro\\worker\\src\\index.ts';
const specPath = 'c:\\Development\\academypro\\API_SPECIFICATION.md';
const flutterDir = 'c:\\Development\\academypro\\academypro_app';
const webAdminDir = 'c:\\Development\\academypro\\web_admin';

const workerRoutes = extractWorkerRoutes(workerPath);
const specRoutes = extractApiSpecRoutes(specPath);
const flutterRoutes = extractFlutterAppRoutes(flutterDir);
const webAdminRoutes = extractWebAdminRoutes(webAdminDir);

function normalizePath(p) {
  let clean = p;
  clean = clean.replace(/(\$(query|qParam|queryParam)|\?.*)$/i, '');
  clean = clean.replace(/{}$/, '');
  clean = clean.replace(/\$\{[^}]+\}/g, ':param');
  clean = clean.replace(/\$[a-zA-Z0-9_]+/g, ':param');
  clean = clean.replace(/:[a-zA-Z0-9_]+/g, ':param');
  clean = clean.replace(/\/+$/, '');
  return clean || '/';
}

const workerNormalized = new Set(workerRoutes.map(r => {
  const [method, p] = r.split(' ');
  return `${method} ${normalizePath(p)}`;
}));

const specNormalized = new Set(specRoutes.map(r => {
  const [method, p] = r.split(' ');
  return `${method} ${normalizePath(p)}`;
}));

const missingInWorker = specRoutes.filter(r => {
  const [method, p] = r.split(' ');
  return !workerNormalized.has(`${method} ${normalizePath(p)}`);
});

const undocumentedInSpec = workerRoutes.filter(r => {
  const [method, p] = r.split(' ');
  return !specNormalized.has(`${method} ${normalizePath(p)}`);
});

console.log('=============================================');
console.log('ROUTE PARITY & COVERAGE ANALYSIS SUMMARY');
console.log('=============================================');
console.log(`Worker total registered routes: ${workerRoutes.length}`);
console.log(`API Specification total routes: ${specRoutes.length}`);
console.log(`Spec routes missing in Worker: ${missingInWorker.length}`);
console.log(`Worker routes undocumented in Spec: ${undocumentedInSpec.length}`);

const workerPaths = new Set(workerRoutes.map(r => normalizePath(r.split(' ')[1])));

const flutterClean = flutterRoutes.map(r => normalizePath(r)).filter(r => r.startsWith('/api/'));

const missingFlutterEndpoints = Array.from(new Set(flutterClean)).filter(p => {
  const norm = normalizePath(p);
  return !workerPaths.has(norm);
});

console.log(`Flutter app endpoints missing in Worker: ${missingFlutterEndpoints.length}`);
missingFlutterEndpoints.forEach(p => console.log('  [MISSING IN WORKER]', p));

const webAdminClean = webAdminRoutes.map(r => normalizePath(r));
const missingWebAdminEndpoints = webAdminClean.filter(p => !workerPaths.has(p));

console.log(`Web Admin endpoints missing in Worker: ${missingWebAdminEndpoints.length}`);
missingWebAdminEndpoints.forEach(p => console.log('  [MISSING IN WORKER]', p));

const is100Percent = workerRoutes.length === 67 &&
                    specRoutes.length === 67 && 
                    missingInWorker.length === 0 && 
                    undocumentedInSpec.length === 0 &&
                    missingFlutterEndpoints.length === 0 &&
                    missingWebAdminEndpoints.length === 0;

console.log(`\n100% ROUTE PARITY AND COVERAGE VERDICT: ${is100Percent ? 'PASS (100% PARITY & COVERAGE CONFIRMED)' : 'FAIL'}`);
