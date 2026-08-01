const { execSync } = require('child_process');

try {
  const tablesJson = execSync('npx wrangler d1 execute academypro-d1 --remote --command="SELECT name FROM sqlite_master WHERE type=\'table\';" --json', { encoding: 'utf8' });
  const tables = JSON.parse(tablesJson)[0].results.map(r => r.name);
  console.log('--- D1 TABLES ---');
  console.log(tables);

  for (const t of tables) {
    if (t.startsWith('_') || t.startsWith('d1_')) continue;
    console.log(`\n--- TABLE SCHEMA: ${t} ---`);
    const schemaJson = execSync(`npx wrangler d1 execute academypro-d1 --remote --command="PRAGMA table_info(${t});" --json`, { encoding: 'utf8' });
    const cols = JSON.parse(schemaJson)[0].results;
    console.log(cols.map(c => `${c.name} (${c.type})`).join(', '));
  }
} catch (e) {
  console.error(e);
}
