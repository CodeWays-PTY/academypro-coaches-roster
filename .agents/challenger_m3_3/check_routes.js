const fs = require('fs');
const path = require('path');

const workerPath = path.join(__dirname, '../../worker/src/index.ts');
const specPath = path.join(__dirname, '../../API_SPECIFICATION.md');

const workerCode = fs.readFileSync(workerPath, 'utf8');
const specContent = fs.readFileSync(specPath, 'utf8');

// 1. Extract Worker active routes
const routeRegex = /app\.(get|post|put|delete|patch)\s*\(\s*['"]([^'"]+)['"]/g;
let match;
const workerRoutesMap = new Map();
const workerRoutesList = [];

while ((match = routeRegex.exec(workerCode)) !== null) {
  const method = match[1].toUpperCase();
  const routePath = match[2];
  const key = `${method} ${routePath}`;
  if (!workerRoutesMap.has(key)) {
    workerRoutesMap.set(key, { method, path: routePath, line: match.index });
    workerRoutesList.push({ method, path: routePath, key });
  }
}

console.log(`Extracted ${workerRoutesList.length} active routes from worker/src/index.ts.`);

// 2. Extract Overview Table from Section 2 of API_SPECIFICATION.md
const tableRows = [];
const lines = specContent.split('\n');

let inTable = false;
for (let i = 0; i < lines.length; i++) {
  const line = lines[i].trim();
  if (line.includes('| Route | Method |') || line.includes('| Route | HTTP Method |')) {
    inTable = true;
    continue;
  }
  if (inTable && (line.startsWith('| ---') || line.startsWith('|---'))) {
    continue;
  }
  if (inTable && line.startsWith('|')) {
    const parts = line.split('|').map(p => p.trim()).filter((_, idx, arr) => idx > 0 && idx < arr.length - 1);
    if (parts.length >= 3) {
      // Format: | Module | Route | Method | Description |
      let rawRoute = parts[1].replace(/`/g, '').trim();
      let rawMethodsStr = parts[2].replace(/`/g, '').trim();
      
      if (rawRoute.startsWith('/api')) {
        // Split methods by /, OR, commas, spaces
        const methods = rawMethodsStr
          .split(/[\/,]|\bor\b/i)
          .map(m => m.trim().toUpperCase())
          .filter(m => ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].includes(m));
        
        for (const m of methods) {
          const key = `${m} ${rawRoute}`;
          if (!tableRows.some(r => r.key === key)) {
            tableRows.push({ method: m, path: rawRoute, key, rawLine: line });
          }
        }
      }
    }
  } else if (inTable && !line.startsWith('|')) {
    if (line.startsWith('#') || line.startsWith('---')) {
      inTable = false;
    }
  }
}

console.log(`Extracted ${tableRows.length} routes from Overview Table in API_SPECIFICATION.md.`);

// 3. Extract Section 3 Details from API_SPECIFICATION.md
const section3Routes = [];
const sec3Lines = specContent.split('\n');
let sec3Start = false;
let currentMethodStr = null;
let currentRouteLine = null;

for (let i = 0; i < sec3Lines.length; i++) {
  const line = sec3Lines[i].trim();
  if (line.startsWith('## 3. Module Specifications')) {
    sec3Start = true;
    continue;
  }
  if (sec3Start) {
    const methodMatch = line.match(/\*\*\s*Method:?\s*\*\*\s*(.+)/i);
    if (methodMatch) {
      // Strip backticks first
      currentMethodStr = methodMatch[1].replace(/`/g, '').trim();
    }
    const routeMatch = line.match(/\*\*\s*Route:?\s*\*\*\s*(.+)/i);
    if (routeMatch) {
      currentRouteLine = routeMatch[1].trim();
    }

    if (currentMethodStr && currentRouteLine) {
      // Parse methods (e.g. GET, POST, GET / POST, GET or POST)
      const methods = currentMethodStr
        .split(/[\/,]|\bor\b/i)
        .map(m => m.trim().toUpperCase())
        .filter(m => ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'].includes(m));

      // Extract main route and aliases from routeLine
      // e.g. `/api/test-logs` (alias: `/api/dashboard/test-logs`)
      const routePaths = [];
      const backtickMatches = [...currentRouteLine.matchAll(/`(\/api\/[^`\s]+)`/g)];
      if (backtickMatches.length > 0) {
        backtickMatches.forEach(m => routePaths.push(m[1]));
      } else {
        const plainMatches = [...currentRouteLine.matchAll(/(\/api\/[^\s\)]+)/g)];
        plainMatches.forEach(m => routePaths.push(m[1]));
      }

      for (const rPath of routePaths) {
        for (const m of methods) {
          const key = `${m} ${rPath}`;
          if (!section3Routes.some(r => r.key === key)) {
            section3Routes.push({ method: m, path: rPath, key });
          }
        }
      }

      currentMethodStr = null;
      currentRouteLine = null;
    }
  }
}

console.log(`Extracted ${section3Routes.length} routes from Section 3 Details in API_SPECIFICATION.md.`);

// 4. Verification Check
console.log('\n========================================');
console.log('100% ROUTE CROSS-REFERENCE CHECK RESULTS');
console.log('========================================\n');

let failed = false;

// Check 1: Worker -> Table
const missingInTable = [];
for (const wRoute of workerRoutesList) {
  if (!tableRows.some(t => t.key === wRoute.key)) {
    missingInTable.push(wRoute.key);
  }
}

if (missingInTable.length > 0) {
  console.error(`❌ Worker routes MISSING in Overview Table (${missingInTable.length}):`);
  missingInTable.forEach(r => console.error(`   - ${r}`));
  failed = true;
} else {
  console.log(`✅ All ${workerRoutesList.length} Worker active routes exist in Overview Table.`);
}

// Check 2: Worker -> Section 3 Details
const missingInSec3 = [];
for (const wRoute of workerRoutesList) {
  if (!section3Routes.some(s => s.key === wRoute.key)) {
    missingInSec3.push(wRoute.key);
  }
}

if (missingInSec3.length > 0) {
  console.error(`❌ Worker routes MISSING in Section 3 Details (${missingInSec3.length}):`);
  missingInSec3.forEach(r => console.error(`   - ${r}`));
  failed = true;
} else {
  console.log(`✅ All ${workerRoutesList.length} Worker active routes exist in Section 3 Details.`);
}

// Check 3: Table -> Worker (Pruned / Non-existent routes)
const extraInTable = [];
for (const tRoute of tableRows) {
  if (!workerRoutesMap.has(tRoute.key)) {
    extraInTable.push(tRoute.key);
  }
}

if (extraInTable.length > 0) {
  console.error(`❌ Non-existent / Pruned routes STILL IN Overview Table (${extraInTable.length}):`);
  extraInTable.forEach(r => console.error(`   - ${r}`));
  failed = true;
} else {
  console.log(`✅ Strictly 0 pruned or non-existent routes remain in Overview Table.`);
}

// Check 4: Section 3 -> Worker (Pruned / Non-existent routes)
const extraInSec3 = [];
for (const sRoute of section3Routes) {
  if (!workerRoutesMap.has(sRoute.key)) {
    extraInSec3.push(sRoute.key);
  }
}

if (extraInSec3.length > 0) {
  console.error(`❌ Non-existent / Pruned routes STILL IN Section 3 Details (${extraInSec3.length}):`);
  extraInSec3.forEach(r => console.error(`   - ${r}`));
  failed = true;
} else {
  console.log(`✅ Strictly 0 pruned or non-existent routes remain in Section 3 Details.`);
}

// Check 5: Discrepancy between Table and Section 3
const tableKeys = new Set(tableRows.map(r => r.key));
const sec3Keys = new Set(section3Routes.map(r => r.key));
const tableNotSec3 = [...tableKeys].filter(k => !sec3Keys.has(k));
const sec3NotTable = [...sec3Keys].filter(k => !tableKeys.has(k));

if (tableNotSec3.length > 0 || sec3NotTable.length > 0) {
  console.error(`❌ Inconsistencies between Overview Table and Section 3 Details:`);
  if (tableNotSec3.length > 0) console.error(`   - In Table but not Section 3: ${tableNotSec3.join(', ')}`);
  if (sec3NotTable.length > 0) console.error(`   - In Section 3 but not Table: ${sec3NotTable.join(', ')}`);
  failed = true;
} else {
  console.log(`✅ Perfect 1:1 match between Overview Table and Section 3 Details.`);
}

console.log('\n========================================');
console.log(`FINAL CROSS-CHECK VERDICT: ${failed ? 'FAIL' : 'PASS'}`);
console.log('========================================\n');
