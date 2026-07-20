const { DatabaseSync } = require('node:sqlite');
const fs = require('fs');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'usport.db');
const db = new DatabaseSync(dbPath);

console.log('Seeding athlete ages, positions, and teams...');

// 1. Get all players
const players = db.prepare('SELECT id, age_group, first_name, last_name FROM players').all();

const sqlUpdates = [];

// Specific player maps
const specificPlayers = {
  'OVK-U15-001': { age: 15, position: 'Flanker', team: 'Academy Elite' },
  'OVK-U15-002': { age: 15, position: 'Flanker / No. 8', team: 'Academy Elite' },
  'OVK-U15-003': { age: 15, position: 'Fly-half', team: 'Academy Elite' },
  'OVK-U15-004': { age: 16, position: 'Hooker', team: 'Academy Elite', age_group: 'U16' }, // Move Izaia to U16
  'OVK-U15-007': { age: 16, position: 'Fly-half', team: 'Academy Elite', age_group: 'U16' }, // Move Bibi Achuma to U16
  'OVK-U15-009': { age: 15, position: 'Lock / Second Row', team: 'Academy Elite' }, // Let's make OVK-U15-009 Imaneul Venter (or find Imaneul)
};

const rugbyPositions = [
  'Prop', 'Hooker', 'Lock', 'Flanker', 'No. 8', 
  'Scrum-half', 'Fly-half', 'Center', 'Wing', 'Full-back'
];

const teams = ['Academy Elite', 'Premier Squad', 'Development B'];

// Let's find Imaneul Venter's ID in database
const imaneul = players.find(p => p.first_name.toLowerCase().includes('imaneul') || p.first_name.toLowerCase().includes('venter'));
if (imaneul) {
  specificPlayers[imaneul.id] = { age: 15, position: 'Lock / Second Row', team: 'Academy Elite' };
}

for (const player of players) {
  let age = player.age_group === 'U15' ? 15 : player.age_group === 'U16' ? 16 : 18;
  let position = '';
  let team = '';
  let ageGroup = player.age_group;

  if (specificPlayers[player.id]) {
    const spec = specificPlayers[player.id];
    age = spec.age;
    position = spec.position;
    team = spec.team;
    if (spec.age_group) ageGroup = spec.age_group;
  } else {
    // Generate deterministic values based on player ID hash
    const hash = player.id.split('').reduce((acc, char) => acc + char.charCodeAt(0), 0);
    position = rugbyPositions[hash % rugbyPositions.length];
    team = teams[hash % teams.length];
  }

  // Update locally
  const stmt = db.prepare('UPDATE players SET age = ?, position = ?, team = ?, age_group = ? WHERE id = ?');
  stmt.run(age, position, team, ageGroup, player.id);

  // Collect SQL for migration file
  sqlUpdates.push(`UPDATE players SET age = ${age}, position = '${position.replace(/'/g, "''")}', team = '${team.replace(/'/g, "''")}', age_group = '${ageGroup}' WHERE id = '${player.id}';`);
}

// Write migration file
const migrationDir = path.join(__dirname, '..', 'migrations');
if (!fs.existsSync(migrationDir)) {
  fs.mkdirSync(migrationDir);
}

const migrationContent = `-- Migration: Seed athlete ages, positions, and teams to match roster UI mockup
${sqlUpdates.join('\n')}
`;

fs.writeFileSync(path.join(migrationDir, '0005_seed_player_details.sql'), migrationContent, 'utf8');

console.log('Seeded local SQLite database successfully.');
console.log('Generated migration migrations/0005_seed_player_details.sql.');
