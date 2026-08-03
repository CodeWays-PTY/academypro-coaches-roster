const fs = require('fs');
const path = require('path');

const activeEndpoints = JSON.parse(fs.readFileSync(path.join(__dirname, 'active_endpoints.json')));
const specTableRoutes = JSON.parse(fs.readFileSync(path.join(__dirname, 'spec_table_routes.json')));
const specDetailRoutes = JSON.parse(fs.readFileSync(path.join(__dirname, 'spec_detail_routes.json')));

// Helper to normalize route key
function routeKey(method, route) {
  return `${method.toUpperCase()} ${route}`;
}

// Set of all active worker endpoints
const activeSet = new Set(activeEndpoints.map(e => routeKey(e.method, e.route)));
const tableSet = new Set(specTableRoutes.map(e => routeKey(e.method, e.route)));
const detailSet = new Set(specDetailRoutes.map(e => routeKey(e.method, e.route)));

// All documented routes in spec (either table or detail)
const allSpecSet = new Set([...tableSet, ...detailSet]);

console.log('====================================================');
console.log('100% ROUTE CROSS-REFERENCE VERIFICATION REPORT');
console.log('====================================================\n');

console.log(`Active Backend Endpoints in worker/src/index.ts: ${activeEndpoints.length}`);
console.log(`Documented Routes in API_SPECIFICATION.md (Table): ${tableSet.size}`);
console.log(`Documented Routes in API_SPECIFICATION.md (Detail): ${detailSet.size}`);
console.log(`Unique Documented Routes in API_SPECIFICATION.md (Combined): ${allSpecSet.size}\n`);

// 1. Check if 100% of Active Backend Routes are documented
console.log('--- TASK 1 & 2: Active Backend Routes vs API_SPECIFICATION.md ---');
const undocumentedInTable = [];
const undocumentedInDetail = [];
const undocumentedAnywhere = [];

activeEndpoints.forEach(e => {
  const key = routeKey(e.method, e.route);
  const inTable = tableSet.has(key);
  const inDetail = detailSet.has(key);

  if (!inTable) undocumentedInTable.push({ ...e, key });
  if (!inDetail) undocumentedInDetail.push({ ...e, key });
  if (!inTable && !inDetail) undocumentedAnywhere.push({ ...e, key });
});

console.log(`\nActive routes missing from Overview Table (${undocumentedInTable.length}):`);
undocumentedInTable.forEach(e => console.log(`  Line ${e.line}: ${e.key}`));

console.log(`\nActive routes missing from Detail Sections (${undocumentedInDetail.length}):`);
undocumentedInDetail.forEach(e => console.log(`  Line ${e.line}: ${e.key}`));

console.log(`\nActive routes COMPLETELY UNDOCUMENTED (${undocumentedAnywhere.length}):`);
undocumentedAnywhere.forEach(e => console.log(`  Line ${e.line}: ${e.key}`));

// 2. Check for Pruned or Non-Existent Routes in API_SPECIFICATION.md
console.log('\n--- TASK 3: Pruned or Non-Existent Routes in API_SPECIFICATION.md ---');
const prunedRoutesInTable = [];
const prunedRoutesInDetail = [];
const prunedRoutesAnywhere = [];

specTableRoutes.forEach(e => {
  const key = routeKey(e.method, e.route);
  if (!activeSet.has(key)) {
    prunedRoutesInTable.push({ ...e, key });
  }
});

specDetailRoutes.forEach(e => {
  const key = routeKey(e.method, e.route);
  if (!activeSet.has(key)) {
    prunedRoutesInDetail.push({ ...e, key });
  }
});

allSpecSet.forEach(key => {
  if (!activeSet.has(key)) {
    prunedRoutesAnywhere.push(key);
  }
});

console.log(`\nDocumented Table routes NOT present in worker code (${prunedRoutesInTable.length}):`);
prunedRoutesInTable.forEach(e => console.log(`  Line ${e.line}: ${e.key}`));

console.log(`\nDocumented Detail routes NOT present in worker code (${prunedRoutesInDetail.length}):`);
prunedRoutesInDetail.forEach(e => console.log(`  Line ${e.line}: ${e.key} (Section: ${e.section})`));

console.log(`\nTotal Pruned / Non-Existent Routes remaining in API_SPECIFICATION.md (${prunedRoutesAnywhere.length}):`);
prunedRoutesAnywhere.forEach(k => console.log(`  - ${k}`));

// 3. Discrepancies between Table and Detail sections in spec
console.log('\n--- DISCREPANCIES WITHIN API_SPECIFICATION.md (Table vs Detail) ---');
const tableOnly = [...tableSet].filter(k => !detailSet.has(k));
const detailOnly = [...detailSet].filter(k => !tableSet.has(k));

console.log(`In Table but missing in Detail sections (${tableOnly.length}):`);
tableOnly.forEach(k => console.log(`  - ${k}`));

console.log(`In Detail sections but missing in Table (${detailOnly.length}):`);
detailOnly.forEach(k => console.log(`  - ${k}`));

// VERDICT DETERMINATION
const pass = (undocumentedAnywhere.length === 0) && (prunedRoutesAnywhere.length === 0) && (undocumentedInTable.length === 0) && (undocumentedInDetail.length === 0);
console.log('\n====================================================');
console.log(`VERDICT: ${pass ? 'PASS' : 'FAIL'}`);
console.log('====================================================');
