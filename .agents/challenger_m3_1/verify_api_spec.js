const fs = require('fs');

const mdPath = 'c:/Development/academypro/API_SPECIFICATION.md';
const content = fs.readFileSync(mdPath, 'utf8');
const lines = content.split('\n');

let codeBlockOpen = false;
let openBlockLang = '';
let lineNum = 0;
let errors = [];

lines.forEach((line) => {
  lineNum++;
  if (line.trim().startsWith('```')) {
    if (!codeBlockOpen) {
      codeBlockOpen = true;
      openBlockLang = line.trim().substring(3);
    } else {
      codeBlockOpen = false;
      openBlockLang = '';
    }
  }
});

if (codeBlockOpen) {
  errors.push(`Unclosed code block starting with language '${openBlockLang}' at EOF`);
}

// Check JSON code blocks inside markdown for syntax validity
const jsonBlockRegex = /```json\s*([\s\S]*?)```/g;
let match;
let blockIndex = 0;
while ((match = jsonBlockRegex.exec(content)) !== null) {
  blockIndex++;
  const jsonStr = match[1].trim();
  try {
    JSON.parse(jsonStr);
    console.log(`[PASS] JSON code block #${blockIndex} is valid JSON.`);
  } catch (err) {
    errors.push(`JSON code block #${blockIndex} invalid JSON syntax: ${err.message}`);
  }
}

if (errors.length === 0) {
  console.log('\nVERIFICATION SUCCESS: API_SPECIFICATION.md Markdown structure & JSON blocks are valid!');
  process.exit(0);
} else {
  console.error('\nVERIFICATION FAILURE in API_SPECIFICATION.md:');
  errors.forEach(e => console.error(' - ' + e));
  process.exit(1);
}
