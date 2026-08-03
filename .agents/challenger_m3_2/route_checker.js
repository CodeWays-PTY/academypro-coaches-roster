const fs = require('fs');
const path = require('path');

const workerPath = path.join(__dirname, '..', '..', 'worker', 'src', 'index.ts');
const specPath = path.join(__dirname, '..', '..', 'API_SPECIFICATION.md');

const workerCode = fs.readFileSync(workerPath, 'utf-8');
const specCode = fs.readFileSync(specPath, 'utf-8');

const lines = workerCode.split('\n');

// Extract routes from worker/src/index.ts
// Patterns: app.get('/path', ...), app.post('/path', ...), app.put('/path', ...), app.delete('/path', ...), app.patch('/path', ...), app.use('/path', ...)
const workerRoutes = [];
const routeRegex = /app\.(get|post|put|delete|patch|use|on)\s*\(\s*['"`]([^'"`]+)['"`]/g;

lines.forEach((line, idx) => {
  let match;
  // reset regex for each line or execute regex line-by-line
  const regex = /app\.(get|post|put|delete|patch|use|on)\s*\(\s*['"`]([^'"`]+)['"`]/g;
  while ((match = regex.exec(line)) !== null) {
    const method = match[1].toUpperCase();
    const route = match[2];
    workerRoutes.push({
      line: idx + 1,
      method,
      route,
      rawLine: line.trim()
    });
  }
});

console.log(`=== Extracted ${workerRoutes.length} route handlers / middleware from worker/src/index.ts ===`);
workerRoutes.forEach(r => {
  console.log(`Line ${r.line}: ${r.method} ${r.route}`);
});

// Extract documented routes from API_SPECIFICATION.md
// In markdown tables and code blocks / text headers:
// e.g. | `/api/auth/send-otp` | POST | ...
// e.g. * **Route:** `/api/auth/send-otp`
// e.g. * **Method:** `POST`
const specLines = specCode.split('\n');
const specRoutes = [];

// 1. Table rows: | Module | Route | Method | Description |
specLines.forEach((line, idx) => {
  // Check table row pattern e.g. | ... | `/api/...` | GET / POST | ...
  const tableMatch = line.match(/\|\s*`(\/api\/[^`]+)`\s*\|\s*([A-Z\s\/]+)\s*\|/);
  if (tableMatch) {
    const route = tableMatch[1];
    const methodsStr = tableMatch[2].trim();
    const methods = methodsStr.split('/').map(m => m.trim());
    methods.forEach(method => {
      specRoutes.push({
        source: 'table',
        line: idx + 1,
        method,
        route
      });
    });
  }

  // Check detail section pattern e.g. * **Route:** `/api/...`
  const routeDetailMatch = line.match(/\*\s*\*\*Route:\*\*\s*`([^`]+)`/);
  if (routeDetailMatch) {
    const route = routeDetailMatch[1];
    // look nearby for Method
    let method = 'UNKNOWN';
    for (let i = Math.max(0, idx - 5); i < Math.min(specLines.length, idx + 5); i++) {
      const methodMatch = specLines[i].match(/\*\s*\*\*Method:\*\*\s*`?([A-Z\s\/]+)`?/);
      if (methodMatch) {
        method = methodMatch[1].trim();
        break;
      }
    }
    const methods = method.split('/').map(m => m.trim());
    methods.forEach(m => {
      specRoutes.push({
        source: 'detail',
        line: idx + 1,
        method: m,
        route
      });
    });
  }
});

console.log(`\n=== Extracted ${specRoutes.length} route references from API_SPECIFICATION.md ===`);
specRoutes.forEach(r => {
  console.log(`Spec Line ${r.line} (${r.source}): ${r.method} ${r.route}`);
});

fs.writeFileSync(path.join(__dirname, 'extracted_worker_routes.json'), JSON.stringify(workerRoutes, null, 2));
fs.writeFileSync(path.join(__dirname, 'extracted_spec_routes.json'), JSON.stringify(specRoutes, null, 2));
