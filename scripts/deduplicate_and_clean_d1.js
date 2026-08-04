const fs = require('fs');
const path = require('path');

const cleanPlayers = [
  { idx: '001', fn: 'Immanuel', ln: 'Engelbrecht', em: 'Manieengelbrecht35@gmail.com', ph: '082 438 1998' },
  { idx: '002', fn: 'Sello', ln: 'Jantie', em: 'Nthabyjankie@gmail.com', ph: '083 495 2406' },
  { idx: '003', fn: 'Wikus', ln: 'De Koker', em: 'Wikusdekoker12@gmail.com', ph: '067 787 5916' },
  { idx: '004', fn: 'Phatu', ln: 'Motlhabane', em: 'Phatumotlhabane@gmail.com', ph: null },
  { idx: '005', fn: 'Shayaan', ln: 'Rafiq', em: 'shayaan.rafiq@dummy.academypro.co.za', ph: '084 208 9276' },
  { idx: '006', fn: 'Alexander', ln: 'Coetzer', em: 'alexander.coetzer@dummy.academypro.co.za', ph: '069 656 9306' },
  { idx: '007', fn: 'Achuma', ln: 'Bibi', em: 'achumabibi5@gmail.com', ph: '0635279367' },
  { idx: '008', fn: 'Taylon', ln: 'Cartwright', em: 'taylonbradleycartwright@gmail.com', ph: '075 028 7075' },
  { idx: '009', fn: 'Bokang', ln: 'Maphosa', em: 'bokang.maphosa@dummy.academypro.co.za', ph: '079 901 5552' },
  { idx: '010', fn: 'Kyle', ln: 'Smith', em: 'kyle.smith@dummy.academypro.co.za', ph: '083 387 9023' },
  { idx: '011', fn: 'Simphiwe', ln: 'Philemon', em: 'simphiwe.philemon@dummy.academypro.co.za', ph: '082 644 7842' },
  { idx: '012', fn: 'Khumo', ln: 'Kutumela', em: 'Khumokutumela77@gmail.com', ph: '066 543 1954' },
  { idx: '013', fn: 'Luvani', ln: 'Nkwinika', em: 'Nkwinikaluvani21@gmail.com', ph: '061 083 5809' },
  { idx: '014', fn: 'Liam', ln: 'Maré', em: 'Liammare2011@gmail.com', ph: '079 402 5703' },
  { idx: '015', fn: 'Kody', ln: 'Langeveldt', em: 'elkody@icloud.com', ph: null },
  { idx: '016', fn: 'Theodore', ln: 'Mosia', em: 'theo67mosia@gmail.com', ph: '068 569 5251' },
  { idx: '017', fn: 'Shelton', ln: 'Julies', em: 'shelton.julies@dummy.academypro.co.za', ph: '066 491 3739' },
  { idx: '018', fn: 'Luyanda', ln: 'Nzotho', em: 'luyandanzotho51@gmail.com', ph: '069 889 4923' },
  { idx: '019', fn: 'Siphosihle', ln: 'Masemola', em: 'Siphosihlemasemola69@gmail.com', ph: '0704029838' }
];

const squadId = 'sq-1785841532380';
const squadName = 'U15';

const sqlStatements = [];
sqlStatements.push('-- Deduplicate and clean U15 players and squad memberships');
sqlStatements.push('PRAGMA foreign_keys = OFF;');
sqlStatements.push('');

// 1. Delete all auto-generated duplicates (plr_17858430... and AC-...)
sqlStatements.push("DELETE FROM players WHERE id LIKE 'plr_17858430%' OR id LIKE 'AC-%';");
sqlStatements.push("DELETE FROM users WHERE id LIKE 'usr_17858430%' OR email = 'janmen788@gmail.com';");
sqlStatements.push("DELETE FROM squad_players WHERE player_id LIKE 'plr_17858430%' OR player_id LIKE 'AC-%';");
sqlStatements.push('');

// 2. Ensure all 19 clean players have team = 'U15', age_group = 'U15', school_id = '1'
sqlStatements.push("UPDATE players SET team = 'U15', age_group = 'U15', school_id = '1' WHERE id LIKE 'plr_u15_%';");
sqlStatements.push("UPDATE users SET school_id = '1' WHERE id LIKE 'usr_u15_%';");
sqlStatements.push('');

// 3. Re-assert squad_players for each of the 19 clean players
cleanPlayers.forEach(p => {
  sqlStatements.push(`INSERT OR IGNORE INTO squad_players (squad_id, player_id) SELECT '${squadId}', id FROM players WHERE first_name = '${p.fn.replace(/'/g, "''")}' AND last_name = '${p.ln.replace(/'/g, "''")}';`);
});

const migrationsDir = path.join(__dirname, '..', 'migrations');
fs.writeFileSync(path.join(migrationsDir, '0005_deduplicate_u15_players.sql'), sqlStatements.join('\n'));
console.log('Generated migrations/0005_deduplicate_u15_players.sql');
