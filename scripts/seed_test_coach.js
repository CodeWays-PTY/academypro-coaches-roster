const { DatabaseSync } = require('node:sqlite');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'usport.db');
const db = new DatabaseSync(dbPath);

console.log('Seeding user account for janmen777@gmail.com...');
try {
  const stmt = db.prepare(`
    INSERT OR REPLACE INTO users (id, school_id, email, password_hash, role, first_name, last_name)
    VALUES ('USR-COACH-2', 'OVK', 'janmen777@gmail.com', 'sha256$mockedhash', 'Coach', 'Jan', 'Mentz')
  `);
  stmt.run();
  console.log('Successfully seeded user account locally.');
} catch (err) {
  console.error('Failed to seed user account:', err.message);
}
