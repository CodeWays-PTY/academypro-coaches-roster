const { execSync } = require('child_process');

try {
  const out = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT sp.squad_id, p.id, p.first_name, p.last_name FROM squad_players sp JOIN players p ON p.id = sp.player_id WHERE sp.squad_id = \'sq-u15-elite\' OR sp.squad_id = \'U15\';" --json', { cwd: 'C:\\Development\\academypro\\worker' }).toString();
  console.log('SQUAD PLAYERS OUTPUT:', out);
} catch (e) {
  console.error('ERROR:', e.stdout ? e.stdout.toString() : e.message);
}
