const { execSync } = require('child_process');

try {
  const jsonStr = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT * FROM events;" --json', { encoding: 'utf8' });
  console.log('--- D1 EVENTS TABLE ---');
  console.log(jsonStr);
} catch (e) {
  console.error(e);
}
