const { DatabaseSync } = require('node:sqlite');
const path = require('path');

const dbPath = path.join(__dirname, '..', 'usport.db');
const db = new DatabaseSync(dbPath);

console.log('Seeding additional student and parent users...');

// 1. Insert Student User
db.exec(`
  INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name)
  VALUES ('USR-STUDENT-1', 'OVK', 'student.liam@overkruin.co.za', 'sha256$mockedhash', 'Student', 'Liam', 'Venter')
  ON CONFLICT(id) DO UPDATE SET email=excluded.email;
`);

// 2. Link Student User to Player OVK-U15-001
db.exec(`
  UPDATE players
  SET user_id = 'USR-STUDENT-1'
  WHERE id = 'OVK-U15-001';
`);

// 3. Insert Parent User
db.exec(`
  INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name)
  VALUES ('USR-PARENT-1', 'OVK', 'parent.venter@gmail.com', 'sha256$mockedhash', 'Parent', 'John', 'Venter')
  ON CONFLICT(id) DO UPDATE SET email=excluded.email;
`);

// 4. Link Parent User to Player OVK-U15-001
db.exec(`
  UPDATE players
  SET parent_id = 'USR-PARENT-1',
      parent_name = 'John Venter',
      parent_contact = 'parent.venter@gmail.com'
  WHERE id = 'OVK-U15-001';
`);

// 5. Insert Coach Users for Jan-Albert and JRobertse
db.exec(`
  INSERT OR REPLACE INTO users (id, school_id, email, password_hash, role, first_name, last_name)
  VALUES 
    ('USR-COACH-JAN', 'OVK', 'janmen777@gmail.com', 'sha256$mockedhash', 'Coach', 'Jan-Albert', 'Mentz'),
    ('USR-COACH-JROB', 'OVK', 'jrobertse1@gmail.com', 'sha256$mockedhash', 'Coach', 'J', 'Robertse');
`);

console.log('Successfully seeded additional Student, Parent, and Coach users linked to player OVK-U15-001.');
