const { execSync } = require('child_process');

try {
  const jsonStr = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT id, first_name, last_name, email, school_id, age_group, team FROM players WHERE LOWER(first_name) LIKE \'%jan%\' OR LOWER(last_name) LIKE \'%robertse%\' OR LOWER(first_name) LIKE \'%justin%\';" --json', { encoding: 'utf8' });
  console.log(jsonStr);
} catch (e) {
  console.error(e);
}
