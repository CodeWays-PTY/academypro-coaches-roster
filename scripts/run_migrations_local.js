const { DatabaseSync } = require('node:sqlite');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'usport.db');
const schemaPath = path.join(__dirname, '..', 'migrations', '0001_initialize_schema.sql');
const seedPath = path.join(__dirname, '..', 'migrations', '0002_seed_data.sql');

function runSqlFile(db, filePath) {
  console.log(`Executing SQL file: ${filePath}`);
  const sql = fs.readFileSync(filePath, 'utf8');
  
  // SQLite allows executing multiple statements if using exec()
  // DatabaseSync has an exec method that executes a string of statements
  db.exec(sql);
  console.log(`Finished executing ${path.basename(filePath)}`);
}

function start() {
  console.log(`Opening local SQLite database at: ${dbPath}`);
  
  // Clean old db if exists for fresh run
  if (fs.existsSync(dbPath)) {
    console.log('Removing old database file...');
    fs.unlinkSync(dbPath);
  }

  const db = new DatabaseSync(dbPath);
  
  try {
    runSqlFile(db, schemaPath);
    runSqlFile(db, seedPath);
    console.log('SUCCESS: Local SQLite database initialized and seeded successfully.');
    
    // Verify by running a quick count
    const stmt = db.prepare('SELECT COUNT(*) as count FROM players');
    const result = stmt.get();
    console.log(`Verified: ${result.count} players successfully loaded into D1/SQLite.`);
  } catch (err) {
    console.error(`Migration failed: ${err.message}`);
    process.exit(1);
  }
}

start();
