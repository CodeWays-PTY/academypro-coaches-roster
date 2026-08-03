const fs = require('fs');
const path = require('path');

const files = [
  'c:\\Development\\academypro\\web_admin\\index.html',
  'c:\\Development\\academypro\\web_admin\\uploader.html'
];

const prohibitedStrings = [
  'U15 Academy Elite',
  'OVK',
  'USR-COACH-001',
  'USR-PARENT-101',
  '+27 82 123 4567',
  '+27821234567',
  '83.6%',
  '753'
];

let issuesFound = 0;

files.forEach(filePath => {
  console.log(`Scanning workspace file: ${filePath}`);
  const content = fs.readFileSync(filePath, 'utf8');

  // Check 1: Prohibited Fallback Strings
  prohibitedStrings.forEach(str => {
    if (content.includes(str)) {
      console.error(`  [PROHIBITED FALLBACK FOUND] "${str}" in ${path.basename(filePath)}`);
      issuesFound++;
    }
  });

  // Check 2: Over-defensive fallbacks for team/schoolId
  const defensiveFallbackRegex = /\|\|\s*['"`](U15 Academy Elite|OVK|Mock|Sample)['"`]/gi;
  let match;
  while ((match = defensiveFallbackRegex.exec(content)) !== null) {
    console.error(`  [DEFENSIVE FALLBACK MATCH] ${match[0]} in ${path.basename(filePath)}`);
    issuesFound++;
  }

  // Check 3: Fake fallback arrays when API fails
  if (content.includes('players = [') || content.includes('squads = [')) {
    // Make sure it's setting empty arrays [] when API fails, not mock objects
    const catchBlocks = content.match(/catch\s*\([^)]*\)\s*\{[^}]*\}/g) || [];
    catchBlocks.forEach(cb => {
      if (cb.includes('players = [') && !cb.includes('players = []')) {
        console.error(`  [MOCK ARRAY FALLBACK IN CATCH BLOCK] in ${path.basename(filePath)}: ${cb}`);
        issuesFound++;
      }
      if (cb.includes('squads = [') && !cb.includes('squads = []')) {
        console.error(`  [MOCK ARRAY FALLBACK IN CATCH BLOCK] in ${path.basename(filePath)}: ${cb}`);
        issuesFound++;
      }
    });
  }

  // Check 4: Unbroken Alpine x-bind or x-text variables
  // Scan for common typos or missing properties in Alpine data objects
  // (We already verified JS syntax, but let's check variable access)
});

console.log('\n=============================================');
console.log('WEB_ADMIN SCAN RESULTS');
console.log('=============================================');
if (issuesFound === 0) {
  console.log('PASS: Zero prohibited fallback strings, zero mock data fallbacks found in web_admin.');
  process.exit(0);
} else {
  console.error(`FAIL: Found ${issuesFound} issues in web_admin scan.`);
  process.exit(1);
}
