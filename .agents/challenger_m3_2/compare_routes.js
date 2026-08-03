const fs = require('fs');
const path = require('path');

const workerPath = path.join(__dirname, '..', '..', 'worker', 'src', 'index.ts');
const specPath = path.join(__dirname, '..', '..', 'API_SPECIFICATION.md');

const workerCode = fs.readFileSync(workerPath, 'utf-8');
const specCode = fs.readFileSync(specPath, 'utf-8');

// Parse worker endpoints (excluding app.use middleware)
const workerLines = workerCode.split('\n');
const workerEndpoints = [];
const workerMiddleware = [];

workerLines.forEach((line, idx) => {
  const methodMatch = line.match(/app\.(get|post|put|delete|patch|use)\s*\(\s*['"`]([^'"`]+)['"`]/);
  if (methodMatch) {
    const verb = methodMatch[1].toUpperCase();
    const routePath = methodMatch[2];
    if (verb === 'USE') {
      workerMiddleware.push({ line: idx + 1, verb, path: routePath });
    } else {
      workerEndpoints.push({ line: idx + 1, verb, path: routePath, raw: line.trim() });
    }
  }
});

// Parse API_SPECIFICATION.md overview table
const specTableEndpoints = [];
const specLines = specCode.split('\n');

specLines.forEach((line, idx) => {
  // Table rows: | Module | Route | Method | Description |
  const tableMatch = line.match(/\|\s*(?:Module \d+)?\s*\|\s*`([^`]+)`\s*\|\s*([^|]+)\|/);
  if (tableMatch) {
    const routePath = tableMatch[1].trim();
    const methodsStr = tableMatch[2].trim();
    if (routePath !== 'Route' && !routePath.startsWith('---')) {
      const methods = methodsStr.split('/').map(m => m.trim());
      methods.forEach(method => {
        specTableEndpoints.push({ line: idx + 1, verb: method.toUpperCase(), path: routePath });
      });
    }
  }
});

// Parse API_SPECIFICATION.md detail sections
const specDetailEndpoints = [];
let currentMethod = null;
let currentRoute = null;
let currentLine = 0;

specLines.forEach((line, idx) => {
  const methodMatch = line.match(/\*\s*\*\*Method:\*\*\s*`?([A-Z\s\/]+)`?/);
  const routeMatch = line.match(/\*\s*\*\*Route:\*\*\s*`([^`]+)`/);

  if (routeMatch) {
    currentRoute = routeMatch[1].trim();
    currentLine = idx + 1;
    if (currentMethod) {
      const methods = currentMethod.split('/').map(m => m.trim());
      methods.forEach(m => {
        specDetailEndpoints.push({ line: currentLine, verb: m.toUpperCase(), path: currentRoute });
      });
      currentMethod = null;
    }
  } else if (methodMatch) {
    currentMethod = methodMatch[1].trim();
    if (currentRoute) {
      const methods = currentMethod.split('/').map(m => m.trim());
      methods.forEach(m => {
        specDetailEndpoints.push({ line: currentLine, verb: m.toUpperCase(), path: currentRoute });
      });
      currentRoute = null;
      currentMethod = null;
    }
  }
});

console.log('=== WORKER ENDPOINTS count:', workerEndpoints.length);
console.log('=== SPEC TABLE ENDPOINTS count:', specTableEndpoints.length);
console.log('=== SPEC DETAIL ENDPOINTS count:', specDetailEndpoints.length);

// Normalize routes for comparison (e.g. key format: VERB + ' ' + PATH)
const workerKeyMap = new Map();
workerEndpoints.forEach(e => {
  const key = `${e.verb} ${e.path}`;
  if (!workerKeyMap.has(key)) workerKeyMap.set(key, []);
  workerKeyMap.get(key).push(e);
});

const specTableKeyMap = new Map();
specTableEndpoints.forEach(e => {
  const key = `${e.verb} ${e.path}`;
  if (!specTableKeyMap.has(key)) specTableKeyMap.set(key, []);
  specTableKeyMap.get(key).push(e);
});

const specDetailKeyMap = new Map();
specDetailEndpoints.forEach(e => {
  const key = `${e.verb} ${e.path}`;
  if (!specDetailKeyMap.has(key)) specDetailKeyMap.set(key, []);
  specDetailKeyMap.get(key).push(e);
});

// All unique keys across spec (table & detail)
const allSpecKeys = new Set([...specTableKeyMap.keys(), ...specDetailKeyMap.keys()]);
const allWorkerKeys = new Set(workerKeyMap.keys());

console.log('\n--- 1. ACTIVE WORKER ENDPOINTS ---');
workerEndpoints.forEach(e => {
  console.log(`Line ${e.line.toString().padStart(4)}: ${e.verb.padEnd(6)} ${e.path}`);
});

console.log('\n--- 2. WORKER ENDPOINTS NOT IN SPEC TABLE ---');
let missingInTableCount = 0;
allWorkerKeys.forEach(key => {
  if (!specTableKeyMap.has(key)) {
    console.log(`[Missing in Spec Table] ${key} (Worker line ${workerKeyMap.get(key)[0].line})`);
    missingInTableCount++;
  }
});

console.log('\n--- 3. WORKER ENDPOINTS NOT IN SPEC DETAILS ---');
let missingInDetailCount = 0;
allWorkerKeys.forEach(key => {
  if (!specDetailKeyMap.has(key)) {
    console.log(`[Missing in Spec Details] ${key} (Worker line ${workerKeyMap.get(key)[0].line})`);
    missingInDetailCount++;
  }
});

console.log('\n--- 4. WORKER ENDPOINTS NOT IN SPEC AT ALL ---');
let missingInSpecCount = 0;
allWorkerKeys.forEach(key => {
  if (!allSpecKeys.has(key)) {
    console.log(`[UNDOCUMENTED IN WORKER] ${key} (Worker line ${workerKeyMap.get(key)[0].line})`);
    missingInSpecCount++;
  }
});

console.log('\n--- 5. SPEC ENDPOINTS NOT IN WORKER (PRUNED/NON-EXISTENT) ---');
let prunedCount = 0;
allSpecKeys.forEach(key => {
  if (!allWorkerKeys.has(key)) {
    const tableLine = specTableKeyMap.has(key) ? specTableKeyMap.get(key)[0].line : 'N/A';
    const detailLine = specDetailKeyMap.has(key) ? specDetailKeyMap.get(key)[0].line : 'N/A';
    console.log(`[PRUNED/NON-EXISTENT IN DOCS] ${key} (Table line: ${tableLine}, Detail line: ${detailLine})`);
    prunedCount++;
  }
});

console.log('\n--- 6. DISCREPANCIES BETWEEN SPEC TABLE & SPEC DETAILS ---');
allSpecKeys.forEach(key => {
  const inTable = specTableKeyMap.has(key);
  const inDetail = specDetailKeyMap.has(key);
  if (inTable && !inDetail) {
    console.log(`[In Table but NOT in Detail] ${key}`);
  } else if (!inTable && inDetail) {
    console.log(`[In Detail but NOT in Table] ${key}`);
  }
});
