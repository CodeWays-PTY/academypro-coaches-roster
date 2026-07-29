const { execSync } = require('child_process');

try {
  const out = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT s.id, s.name, s.code, s.coach_id, COUNT(sp.player_id) as player_count FROM squads s LEFT JOIN squad_players sp ON sp.squad_id = s.id GROUP BY s.id;" --json', { cwd: 'C:\\Development\\academypro\\worker' }).toString();
  console.log('SQUADS SUMMARY:', out);
} catch (e) {
  console.error('ERROR:', e.stdout ? e.stdout.toString() : e.message);
}
