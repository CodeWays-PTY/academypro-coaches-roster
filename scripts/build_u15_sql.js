const fs = require('fs');
const path = require('path');

const rawData = `Immanuel Engelbrecht	Manieengelbrecht35@gmail.com	082 438 1998
Sello Jantie	Nthabyjankie@gmail.com	083 495 2406
Wikus De Koker	Wikusdekoker12@gmail.com	067 787 5916
Phatu Motlhabane	Phatumotlhabane@gmail.com	-
Shayaan Rafiq	@icloud.com	084 208 9276
Alexander Coetzer	-	069 656 9306
Achuma Bibi	achumabibi5@gmail.com	635279367
Taylon Cartwright	taylonbradleycartwright@gmail.com	075 028 7075
Bokang Maphosa	-	079 901 5552
Kyle Smith	-	083 387 9023
Simphiwe Philemon	-	082 644 7842
Khumo Kutumela	Khumokutumela77@gmail.com	066 543 1954
Luvani Nkwinika	Nkwinikaluvani21@gmail.com	061 083 5809
Liam Maré	Liammare2011@gmail.com	079 402 5703
Kody Langeveldt	elkody@icloud.com	-
Theodore Mosia	theo67mosia@gmail.com	068 569 5251
Shelton Julies	-	066 491 3739
Luyanda Nzotho	luyandanzotho51@gmail.com	069 889 4923
Siphosihle Masemola	Siphosihlemasemola69@gmail.com	704029838`;

const squadId = 'sq-1785841532380';
const squadName = 'U15';
const ageGroup = 'U15';
const schoolId = '1';

const lines = rawData.trim().split('\n');
const sqlStatements = [];
sqlStatements.push('-- Bulk upload U15 roster');

lines.forEach((line, idx) => {
  const parts = line.split('\t').map(s => s.trim());
  const fullName = parts[0];
  let email = parts[1];
  let phone = parts[2];

  const nameParts = fullName.split(' ');
  const firstName = nameParts[0];
  const lastName = nameParts.slice(1).join(' ') || '';

  if (!email || email === '-' || email === '@icloud.com' || !email.includes('@') || email.startsWith('@')) {
    const slug = fullName.toLowerCase().replace(/[^a-z0-9]/g, '.');
    email = `${slug}@dummy.academypro.co.za`;
  }

  if (phone === '-' || !phone) {
    phone = null;
  } else if (!phone.startsWith('0') && !phone.startsWith('+')) {
    phone = '0' + phone;
  }

  const timestamp = Date.now() + idx;
  const userId = `usr_u15_${String(idx+1).padStart(3, '0')}_${timestamp}`;
  const playerId = `plr_u15_${String(idx+1).padStart(3, '0')}_${timestamp}`;

  const escFn = firstName.replace(/'/g, "''");
  const escLn = lastName.replace(/'/g, "''");
  const escEm = email.replace(/'/g, "''");
  const escPh = phone ? `'${phone.replace(/'/g, "''")}'` : 'NULL';

  sqlStatements.push(`INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('${userId}', '${schoolId}', '${escEm}', ${escPh}, 'Student', '${escFn}', '${escLn}') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;`);

  sqlStatements.push(`INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('${playerId}', '${schoolId}', '${userId}', '${escFn}', '${escLn}', ${escPh}, '${escEm}', '${ageGroup}', '${squadName}', 'Athlete', 'Active');`);

  sqlStatements.push(`INSERT INTO squad_players (squad_id, player_id) VALUES ('${squadId}', '${playerId}') ON CONFLICT DO NOTHING;`);
  sqlStatements.push('');
});

const migrationsDir = path.join(__dirname, '..', 'migrations');
if (!fs.existsSync(migrationsDir)) {
  fs.mkdirSync(migrationsDir, { recursive: true });
}

fs.writeFileSync(path.join(migrationsDir, '0003_seed_u15_roster.sql'), sqlStatements.join('\n'));
console.log('Successfully generated migrations/0003_seed_u15_roster.sql with ' + lines.length + ' players');
