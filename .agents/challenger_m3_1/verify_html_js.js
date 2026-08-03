const fs = require('fs');
const path = require('path');

const files = [
  'c:/Development/academypro/web_admin/index.html',
  'c:/Development/academypro/web_admin/uploader.html'
];

let totalErrors = 0;

files.forEach(f => {
  console.log(`Checking ${f}...`);
  if (!fs.existsSync(f)) {
    console.error(`File not found: ${f}`);
    totalErrors++;
    return;
  }
  const content = fs.readFileSync(f, 'utf8');
  
  // Check basic HTML closing tags matching
  const hasHtml = content.includes('<!DOCTYPE html>') && content.includes('</html>');
  if (!hasHtml) {
    console.error(`[FAIL] ${f} missing DOCTYPE or closing html tag`);
    totalErrors++;
  }

  // Extract inline script blocks
  const scriptRegex = /<script(?:\s+[^>]*?)?>([\s\S]*?)<\/script>/gi;
  let match;
  let scriptIndex = 0;
  while ((match = scriptRegex.exec(content)) !== null) {
    const fullTag = match[0];
    const scriptCode = match[1].trim();
    scriptIndex++;
    
    // Ignore external scripts without inline code
    if (!scriptCode && fullTag.includes('src=')) {
      continue;
    }
    
    if (scriptCode) {
      try {
        new Function(scriptCode);
        console.log(`  [PASS] Inline script #${scriptIndex} is valid JS syntax.`);
      } catch (err) {
        console.error(`  [FAIL] Inline script #${scriptIndex} syntax error:`, err.message);
        totalErrors++;
      }
    }
  }
});

if (totalErrors === 0) {
  console.log('\nVERIFICATION SUCCESS: All HTML/JS files are syntactically valid!');
  process.exit(0);
} else {
  console.error(`\nVERIFICATION FAILURE: Found ${totalErrors} errors.`);
  process.exit(1);
}
