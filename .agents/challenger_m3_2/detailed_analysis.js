const fs = require('fs');
const path = require('path');

const workerPath = path.join(__dirname, '..', '..', 'worker', 'src', 'index.ts');
const specPath = path.join(__dirname, '..', '..', 'API_SPECIFICATION.md');

const workerCode = fs.readFileSync(workerPath, 'utf-8');
const specCode = fs.readFileSync(specPath, 'utf-8');

// 1. EXTRACT WORKER ROUTES
const workerLines = workerCode.split('\n');
const workerRoutes = [];

workerLines.forEach((line, idx) => {
  const match = line.match(/app\.(get|post|put|delete|patch|use)\s*\(\s*['"`]([^'"`]+)['"`]/);
  if (match) {
    const method = match[1].toUpperCase();
    const route = match[2];
    workerRoutes.push({
      line: idx + 1,
      method,
      route,
      code: line.trim()
    });
  }
});

// Separate middleware app.use from actual API endpoints
const activeEndpoints = workerRoutes.filter(r => r.method !== 'USE');
const middlewareRoutes = workerRoutes.filter(r => r.method === 'USE');

// 2. PARSE API_SPECIFICATION.md OVERVIEW TABLE (Section 2)
const specTableRoutes = [];
const specLines = specCode.split('\n');

let inTable = false;
specLines.forEach((line, idx) => {
  if (line.includes('| Module | Route | Method | Description |')) {
    inTable = true;
    return;
  }
  if (inTable && line.startsWith('---')) return;
  if (inTable && line.trim() === '') {
    inTable = false;
    return;
  }
  if (inTable) {
    const parts = line.split('|').map(s => s.trim());
    if (parts.length >= 4) {
      const rawRoute = parts[2].replace(/`/g, '');
      const rawMethod = parts[3].replace(/`/g, '');
      if (rawRoute && rawMethod && rawRoute !== 'Route' && !rawRoute.startsWith('---')) {
        const methods = rawMethod.split(/[\/,]/).map(m => m.trim().toUpperCase()).filter(Boolean);
        methods.forEach(m => {
          specTableRoutes.push({
            line: idx + 1,
            method: m,
            route: rawRoute,
            raw: line.trim()
          });
        });
      }
    }
  }
});

// 3. PARSE API_SPECIFICATION.md DETAIL SECTIONS (Section 3)
const specDetailRoutes = [];

// Split spec into sections by '#### '
const sections = specCode.split(/(?=^####\s+)/m);

sections.forEach((sec, secIdx) => {
  if (!sec.startsWith('####')) return;
  const secLines = sec.split('\n');
  const title = secLines[0].trim();
  
  let methodLine = '';
  let routeLine = '';
  let lineNum = 0;

  secLines.forEach((l, lIdx) => {
    if (l.includes('**Method:**')) methodLine = l;
    if (l.includes('**Route:**')) {
      routeLine = l;
      // find line number in original file
      lineNum = specLines.findIndex(sl => sl.trim() === l.trim()) + 1;
    }
  });

  if (routeLine) {
    // Extract route paths (might contain 'or' or comma)
    const routeMatches = routeLine.match(/`([^`]+)`/g);
    let routes = [];
    if (routeMatches) {
      routes = routeMatches.map(r => r.replace(/`/g, '').trim());
    } else {
      // plain text parse
      const clean = routeLine.replace(/\*\s*\*\*Route:\*\*\s*/, '').trim();
      routes = clean.split(/\s+or\s+/).map(r => r.trim());
    }

    // Extract methods (might contain 'or' e.g. DELETE or POST)
    let methods = [];
    if (methodLine) {
      const cleanMethod = methodLine.replace(/\*\s*\*\*Method:\*\*\s*/, '').replace(/`/g, '').trim();
      methods = cleanMethod.split(/\s+or\s+|\//).map(m => m.trim().toUpperCase()).filter(Boolean);
    }

    routes.forEach(r => {
      // Split routes if ' or ' was inside backticks e.g. `/api/a` or `/api/b`
      const subRoutes = r.split(/\s+or\s+/);
      subRoutes.forEach(sr => {
        methods.forEach(m => {
          specDetailRoutes.push({
            section: title,
            line: lineNum,
            method: m,
            route: sr,
            rawRoute: routeLine,
            rawMethod: methodLine
          });
        });
      });
    });
  }
});

console.log('=== WORKER ACTIVE ENDPOINTS (' + activeEndpoints.length + ') ===');
activeEndpoints.forEach(e => console.log(`  Line ${e.line.toString().padStart(4)}: ${e.method.padEnd(6)} ${e.route}`));

console.log('\n=== SPEC OVERVIEW TABLE ROUTES (' + specTableRoutes.length + ') ===');
specTableRoutes.forEach(e => console.log(`  Line ${e.line.toString().padStart(4)}: ${e.method.padEnd(6)} ${e.route}`));

console.log('\n=== SPEC DETAIL SECTION ROUTES (' + specDetailRoutes.length + ') ===');
specDetailRoutes.forEach(e => console.log(`  Line ${e.line.toString().padStart(4)}: ${e.method.padEnd(6)} ${e.route} (Section: ${e.section})`));

// Write JSON dumps for auditing
fs.writeFileSync(path.join(__dirname, 'active_endpoints.json'), JSON.stringify(activeEndpoints, null, 2));
fs.writeFileSync(path.join(__dirname, 'spec_table_routes.json'), JSON.stringify(specTableRoutes, null, 2));
fs.writeFileSync(path.join(__dirname, 'spec_detail_routes.json'), JSON.stringify(specDetailRoutes, null, 2));
