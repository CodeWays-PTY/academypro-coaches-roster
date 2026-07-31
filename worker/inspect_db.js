const { execSync } = require('child_process');

try {
  const squadsJson = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT id, name, code, school_id, coach_id FROM squads;" --json', { encoding: 'utf8' });
  console.log('--- SQUADS ---');
  console.log(squadsJson);
  
  const playersJson = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT id, first_name, last_name, email, school_id, age_group, team FROM players;" --json', { encoding: 'utf8' });
  console.log('--- PLAYERS ---');
  console.log(playersJson);

  const spJson = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT * FROM squad_players;" --json', { encoding: 'utf8' });
  console.log('--- SQUAD_PLAYERS ---');
  console.log(spJson);
} catch (e) {
  console.error('Error:', e.message);
}
