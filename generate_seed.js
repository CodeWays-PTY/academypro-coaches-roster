const xlsx = require('xlsx');
const fs = require('fs');
const path = require('path');

const excelPath = 'C:\\Users\\janalbert.mentz\\Downloads\\uSport_Player_Tracker_v4.xlsx';
const outputSqlPath = 'C:\\development\\usport-player-tracker\\migrations\\0002_seed_data.sql';

function parseNumber(val) {
  if (val === undefined || val === null || val === '') return 'NULL';
  if (typeof val === 'string') {
    val = val.trim();
    if (val === '-' || val === 'N/T' || val === 'dash') return 'NULL';
    val = val.replace(',', '.'); // Handle European decimal commas
  }
  const num = parseFloat(val);
  return isNaN(num) ? 'NULL' : num;
}

function parseInteger(val) {
  if (val === undefined || val === null || val === '') return 'NULL';
  if (typeof val === 'string') {
    val = val.trim();
    if (val === '-' || val === 'N/T' || val === 'dash') return 'NULL';
  }
  const num = parseInt(val, 10);
  return isNaN(num) ? 'NULL' : num;
}

function parseString(val) {
  if (val === undefined || val === null || val === '') return 'NULL';
  const str = String(val).trim().replace(/'/g, "''"); // Escape single quotes for SQL
  return `'${str}'`;
}

function start() {
  console.log(`Loading Excel file from: ${excelPath}`);
  const wb = xlsx.readFile(excelPath);

  const sqlStatements = [];

  // Disable constraints for bulk seeding speed
  sqlStatements.push('-- Disable foreign keys for seeding speed');
  sqlStatements.push('PRAGMA foreign_keys = OFF;');
  sqlStatements.push('');

  sqlStatements.push("INSERT INTO schools (id, name, code, logo_url) VALUES ('1', 'Hoërskool Overkruin', 'OVK', 'https://images.example.com/ovk-logo.png') ON CONFLICT DO NOTHING;");
  sqlStatements.push('');

  // 2. Seed Sports
  sqlStatements.push('-- Seed Sports');
  const rugbyConfig = JSON.stringify({
    sport: "Rugby",
    fields: [
      { key: "tackles_made", label: "Tackles Made", type: "counter" },
      { key: "tackles_missed", label: "Tackles Missed", type: "counter" },
      { key: "carries", label: "Carries", type: "counter" },
      { key: "metres_gained", label: "Metres Gained", type: "numeric" },
      { key: "errors", label: "Errors", type: "counter" },
      { key: "penalties", label: "Penalties", type: "counter" },
      { key: "work_rate", label: "Work Rate", type: "rating_1_5" },
      { key: "overall_rating", label: "Overall Rating", type: "rating_1_5" }
    ]
  });
  sqlStatements.push(`INSERT INTO sports (id, name, config_json) VALUES ('rugby', 'Rugby', '${rugbyConfig.replace(/'/g, "''")}') ON CONFLICT DO NOTHING;`);
  sqlStatements.push('');

  // 3. Seed Users (Coach)
  sqlStatements.push('-- Seed Coach User');
  sqlStatements.push("INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name) VALUES ('USR-COACH-1', '1', 'coach.ross@overkruin.co.za', NULL, 'Coach', 'Ross', 'Venter') ON CONFLICT DO NOTHING;");
  sqlStatements.push('');

  sqlStatements.push('-- Seed Student User');
  sqlStatements.push("INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name) VALUES ('USR-STUDENT-1', '1', 'student@overkruin.co.za', NULL, 'Student', 'Liam', 'Venter') ON CONFLICT DO NOTHING;");
  sqlStatements.push('');

  sqlStatements.push('-- Seed Parent User');
  sqlStatements.push("INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name) VALUES ('PAR-OVK-001', '1', 'parent@overkruin.co.za', NULL, 'Parent', 'Gerrit', 'Venter') ON CONFLICT DO NOTHING;");
  sqlStatements.push('');

  // 4. Parse Player Register Sheet
  const registerSheet = wb.Sheets['Player Register'];
  const registerRows = xlsx.utils.sheet_to_json(registerSheet, { header: 1 });
  
  const playersMap = new Map();
  const playerInserts = [];

  console.log(`Parsing Player Register rows: ${registerRows.length}`);
  
  // Counters to compute standard normalized IDs (e.g. OVK-U15-001)
  const ageGroupCounters = {
    U14: 0,
    U15: 0,
    U16: 0
  };

  // Row index 3 starts player details (Excel row 4)
  for (let i = 3; i < registerRows.length; i++) {
    const row = registerRows[i];
    if (!row || !row[0]) continue; // Skip empty rows

    const rawId = String(row[0]).trim();
    const ageGroup = String(row[1]).trim();
    
    if (!ageGroupCounters[ageGroup] && ageGroupCounters[ageGroup] !== 0) {
      ageGroupCounters[ageGroup] = 0;
    }
    ageGroupCounters[ageGroup]++;
    
    // Normalize Player ID to format OVK-U15-001
    const normalizedId = `OVK-${ageGroup}-${String(ageGroupCounters[ageGroup]).padStart(3, '0')}`;

    const firstName = row[2] || '';
    const lastName = row[3] || '';
    const grade = parseInteger(row[4]);
    const age = parseInteger(row[5]);
    const position = parseString(row[6]);
    const team = parseString(row[7]);
    const status = row[9] || 'Active';
    const parentName = parseString(row[10]);
    const parentId = parseString(row[12]);
    const uGroupsActive = (row[13] && String(row[13]).trim().toLowerCase() === 'yes') ? 1 : 0;
    const notes = parseString(row[14]);

    playersMap.set(normalizedId, {
      id: normalizedId,
      rawId: rawId,
      firstName,
      lastName,
      ageGroup
    });

    // Save mapping from original rawId to normalizedId for debug/checks
    playersMap.set(rawId, {
      id: normalizedId,
      rawId: rawId,
      firstName,
      lastName,
      ageGroup
    });

    playerInserts.push(
      `INSERT INTO players (id, school_id, age_group, first_name, last_name, grade, age, position, team, status, parent_name, parent_id, ugroups_active, notes) ` +
      `VALUES ('${normalizedId}', '1', '${ageGroup}', '${firstName.replace(/'/g, "''")}', '${lastName.replace(/'/g, "''")}', ${grade}, ${age}, ${position}, ${team}, '${status}', ${parentName}, ${parentId}, ${uGroupsActive}, ${notes});`
    );
  }

  sqlStatements.push('-- Seed Players');
  sqlStatements.push(...playerInserts);
  sqlStatements.push('');

  sqlStatements.push('-- Link Student User to Player');
  sqlStatements.push("UPDATE players SET user_id = 'USR-STUDENT-1' WHERE id = 'OVK-U15-001';");
  sqlStatements.push('');

  // Helper to resolve raw or standard player ID to normalized standard ID
  function resolvePlayerId(id, ageGroup) {
    if (!id) return null;
    id = String(id).trim();
    if (playersMap.has(id)) {
      return playersMap.get(id).id;
    }
    // Try building format directly if it is like OVK-U15-001
    if (id.startsWith('OVK-U') || id.startsWith('OVK-U15-') || id.startsWith('OVK-U16-') || id.startsWith('OVK-U14-')) {
      return id;
    }
    return null;
  }

  // 5. Parse Fitness Tests Sheet (June 2025 Baseline)
  const fitnessSheet = wb.Sheets['Fitness Tests'];
  const fitnessRows = xlsx.utils.sheet_to_json(fitnessSheet, { header: 1 });
  
  const fitnessInserts = [];
  console.log(`Parsing Fitness Tests rows: ${fitnessRows.length}`);

  // Row 5 starts headers, Row 6 is divider "--- U15 ---", data starts at index 6 (Excel row 7)
  for (let i = 6; i < fitnessRows.length; i++) {
    const row = fitnessRows[i];
    if (!row || !row[0]) continue;
    if (String(row[0]).startsWith('---')) continue; // Skip U15/U16 header separators

    const rawId = row[0];
    const ageGroup = row[1];
    const normalizedId = resolvePlayerId(rawId, ageGroup);

    if (!normalizedId) {
      console.log(`Warning: Baseline player ID '${rawId}' (AgeGroup: ${ageGroup}) not matched in register.`);
      continue;
    }

    const speed40m = parseNumber(row[3]);
    const speed60m = parseNumber(row[4]);
    const broadJump = parseNumber(row[5]);
    const pushUps = parseInteger(row[6]);
    const pullUps = parseInteger(row[7]);
    const squats40kg = parseInteger(row[8]);
    const verticalJump = parseNumber(row[9]);
    const tTest = parseNumber(row[10]);

    fitnessInserts.push(
      `INSERT INTO fitness_baselines (player_id, speed_40m, speed_60m, broad_jump, push_ups, pull_ups, squats_40kg, vertical_jump, t_test) ` +
      `VALUES ('${normalizedId}', ${speed40m}, ${speed60m}, ${broadJump}, ${pushUps}, ${pullUps}, ${squats40kg}, ${verticalJump}, ${tTest});`
    );
  }

  sqlStatements.push('-- Seed Fitness Baselines');
  sqlStatements.push(...fitnessInserts);
  sqlStatements.push('');

  // 6. Parse Academic & Life Sheet (School Grades)
  const academicSheet = wb.Sheets['Academic & Life'];
  const academicRows = xlsx.utils.sheet_to_json(academicSheet, { header: 1 });
  
  const academicInserts = [];
  console.log(`Parsing Academic & Life rows: ${academicRows.length}`);

  // Excel Row 4 (index 3) starts details
  for (let i = 3; i < academicRows.length; i++) {
    const row = academicRows[i];
    if (!row || !row[0]) continue;

    const rawId = row[0];
    const ageGroup = row[1];
    const normalizedId = resolvePlayerId(rawId, ageGroup);

    if (!normalizedId) {
      console.log(`Warning: Academic player ID '${rawId}' (AgeGroup: ${ageGroup}) not matched in register.`);
      continue;
    }

    // Capture Term 1 - 4
    for (let term = 1; term <= 4; term++) {
      const colIndex = 2 + term; // Term 1 is index 3, Term 2 is index 4, etc.
      const grade = parseNumber(row[colIndex]);
      const disciplineScore = parseInteger(row[11 + term]); // T1 discipline index 12, etc.

      // Only insert if grade or discipline is logged
      if (grade !== 'NULL' || disciplineScore !== 'NULL') {
        const dScore = disciplineScore === 'NULL' ? 0 : disciplineScore;
        academicInserts.push(
          `INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score) ` +
          `VALUES ('${normalizedId}', ${term}, ${grade}, ${dScore});`
        );
      }
    }
  }

  sqlStatements.push('-- Seed Academic Logs');
  sqlStatements.push(...academicInserts);
  sqlStatements.push('');

  // Re-enable constraints
  sqlStatements.push('-- Re-enable foreign keys');
  sqlStatements.push('PRAGMA foreign_keys = ON;');
  sqlStatements.push('');

  // Write to SQL file
  fs.writeFileSync(outputSqlPath, sqlStatements.join('\n'));
  console.log(`SQL Seeding Migration successfully generated at: ${outputSqlPath}`);
}

start();
