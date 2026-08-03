const fs = require('fs');
const path = require('path');
const vm = require('vm');

function extractScripts(htmlContent) {
  const scriptRegex = /<script\b[^>]*>([\s\S]*?)<\/script>/gi;
  const scripts = [];
  let match;
  while ((match = scriptRegex.exec(htmlContent)) !== null) {
    // If it has src, skip inline code check (or note it)
    const openTag = match[0].match(/<script\b[^>]*>/i)[0];
    if (!openTag.includes('src=')) {
      scripts.push({
        tag: openTag,
        code: match[1]
      });
    }
  }
  return scripts;
}

const files = [
  'c:\\Development\\academypro\\web_admin\\index.html',
  'c:\\Development\\academypro\\web_admin\\uploader.html'
];

let totalErrors = 0;

files.forEach(file => {
  console.log(`Checking syntax for: ${file}`);
  if (!fs.existsSync(file)) {
    console.error(`File not found: ${file}`);
    totalErrors++;
    return;
  }
  const content = fs.readFileSync(file, 'utf8');
  const scripts = extractScripts(content);
  console.log(`  Found ${scripts.length} inline script tags.`);
  
  scripts.forEach((s, idx) => {
    try {
      // Use vm.Script to check syntax
      new vm.Script(s.code, { filename: `${path.basename(file)}_script_${idx + 1}.js` });
      console.log(`  [PASS] Script ${idx + 1} syntax valid.`);
    } catch (err) {
      console.error(`  [FAIL] Script ${idx + 1} syntax error:`, err.message);
      totalErrors++;
    }
  });
});

if (totalErrors === 0) {
  console.log('\nSUCCESS: All JS inline scripts passed syntax verification.');
  process.exit(0);
} else {
  console.error(`\nFAILED: Found ${totalErrors} JS syntax errors.`);
  process.exit(1);
}
