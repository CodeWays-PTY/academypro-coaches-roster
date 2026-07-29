const { execSync } = require('child_process');

try {
  const out = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT COUNT(*) as count FROM squad_players WHERE squad_id = \'sq-u15-elite\' OR squad_id = \'U15\';" --json', { cwd: 'C:\\Development\\academypro\\worker' }).toString();
  console.log('OUTPUT:', out);
} catch (e) {
  console.error('ERROR:', e.stdout ? e.stdout.toString() : e.message);
}
