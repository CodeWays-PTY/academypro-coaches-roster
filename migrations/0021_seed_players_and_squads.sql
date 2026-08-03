-- Migration: 0021_seed_players_and_squads.sql
-- Description: Seed real players for School 1 and link them to squad_players

PRAGMA foreign_keys = OFF;

-- Ensure U15 Squad exists for School 1
INSERT INTO squads (id, school_id, coach_id, name, code, age_group, description)
VALUES ('sq_u15', '1', 'USR-COACH-JAN777', 'U15 Squad', 'U15', 'U15', 'Academy Development XV')
ON CONFLICT(id) DO UPDATE SET school_id = '1', code = 'U15', age_group = 'U15';

-- Seed U15 Players
INSERT INTO players (id, school_id, age_group, first_name, last_name, position, team, status) VALUES
('OVK-U15-001', '1', 'U15', 'Liam', 'Venter', 'Fly-half', 'U15 Squad', 'Active'),
('OVK-U15-002', '1', 'U15', 'Alex', 'Meyer', 'Scrum-half', 'U15 Squad', 'Active'),
('OVK-U15-003', '1', 'U15', 'Simpixe', 'F', 'Prop', 'U15 Squad', 'Active'),
('OVK-U15-004', '1', 'U15', 'Izaia', 'Kriel', 'Hooker', 'U15 Squad', 'Active'),
('OVK-U15-005', '1', 'U15', 'Lemmer', 'Andre', 'Lock', 'U15 Squad', 'Active'),
('OVK-U15-006', '1', 'U15', 'Phatu', 'Nkosi', 'Flanker', 'U15 Squad', 'Active'),
('OVK-U15-007', '1', 'U15', 'Bibi', 'Achuma', 'Eightman', 'U15 Squad', 'Active'),
('OVK-U15-008', '1', 'U15', 'Kyle', 'Smith', 'Inside Centre', 'U15 Squad', 'Active'),
('OVK-U15-009', '1', 'U15', 'Simposhile', 'Masemola', 'Outside Centre', 'U15 Squad', 'Active'),
('OVK-U15-010', '1', 'U15', 'Semanga', 'Zulu', 'Wing', 'U15 Squad', 'Active'),
('OVK-U15-011', '1', 'U15', 'Shaihan', 'Khan', 'Fullback', 'U15 Squad', 'Active'),
('OVK-U15-012', '1', 'U15', 'Khumo', 'Mokoena', 'Utility Back', 'U15 Squad', 'Active'),
('OVK-U15-013', '1', 'U15', 'Kalimamba', 'Banda', 'Lock', 'U15 Squad', 'Active'),
('OVK-U15-014', '1', 'U15', 'Nhala', 'Dlamini', 'Flanker', 'U15 Squad', 'Active'),
('OVK-U15-015', '1', 'U15', 'Luhanda', 'Botha', 'Prop', 'U15 Squad', 'Active'),
('OVK-U15-016', '1', 'U15', 'Theodore', 'Coetzee', 'Hooker', 'U15 Squad', 'Active'),
('OVK-U15-017', '1', 'U15', 'Sharlton', 'Van Zyl', 'Wing', 'U15 Squad', 'Active'),
('OVK-U15-018', '1', 'U15', 'TK', 'Mabena', 'Scrum-half', 'U15 Squad', 'Active'),
('OVK-U15-019', '1', 'U15', 'Imaneul', 'Joubert', 'Fly-half', 'U15 Squad', 'Active'),
('OVK-U15-020', '1', 'U15', 'Taylon', 'Nel', 'Centre', 'U15 Squad', 'Active'),
('OVK-U15-021', '1', 'U15', 'Pharel', 'Mbatha', 'Wing', 'U15 Squad', 'Active'),
('OVK-U15-022', '1', 'U15', 'Kodi', 'Smit', 'Lock', 'U15 Squad', 'Active'),
('OVK-U15-023', '1', 'U15', 'Rembo', 'Fourie', 'Flanker', 'U15 Squad', 'Active'),
('OVK-U15-024', '1', 'U15', 'Luvani', 'Steyn', 'Prop', 'U15 Squad', 'Active')
ON CONFLICT(id) DO UPDATE SET school_id = '1', age_group = 'U15', status = 'Active';

-- Seed U16 Squad & Players
INSERT INTO squads (id, school_id, coach_id, name, code, age_group, description)
VALUES ('sq_u16', '1', 'USR-COACH-JAN777', 'U16 Squad', 'U16', 'U16', 'Academy U16 Squad')
ON CONFLICT(id) DO UPDATE SET school_id = '1', code = 'U16', age_group = 'U16';

INSERT INTO players (id, school_id, age_group, first_name, last_name, position, team, status) VALUES
('OVK-U16-001', '1', 'U16', 'Jikijela', 'Nxumalo', 'Prop', 'U16 Squad', 'Active'),
('OVK-U16-002', '1', 'U16', 'Mongani', 'Tulani', 'Hooker', 'U16 Squad', 'Active'),
('OVK-U16-003', '1', 'U16', 'Simpiwe', 'Mhlongo', 'Fly-half', 'U16 Squad', 'Active'),
('OVK-U16-004', '1', 'U16', 'Ambeza', 'Khumalo', 'Centre', 'U16 Squad', 'Active'),
('OVK-U16-005', '1', 'U16', 'Happy', 'Sithole', 'Wing', 'U16 Squad', 'Active'),
('OVK-U16-006', '1', 'U16', 'Rea', 'Molefe', 'Fullback', 'U16 Squad', 'Active')
ON CONFLICT(id) DO UPDATE SET school_id = '1', age_group = 'U16', status = 'Active';

-- Seed U14 Squad & Players
INSERT INTO squads (id, school_id, coach_id, name, code, age_group, description)
VALUES ('sq_u14', '1', 'USR-COACH-JAN777', 'U14 Squad', 'U14', 'U14', 'Academy U14 Junior Squad')
ON CONFLICT(id) DO UPDATE SET school_id = '1', code = 'U14', age_group = 'U14';

INSERT INTO players (id, school_id, age_group, first_name, last_name, position, team, status) VALUES
('OVK-U14-001', '1', 'U14', 'Aziel', 'Du Plessis', 'Scrum-half', 'U14 Squad', 'Active'),
('OVK-U14-002', '1', 'U14', 'Tyral', 'Pillay', 'Fly-half', 'U14 Squad', 'Active'),
('OVK-U14-003', '1', 'U14', 'Liam', 'Marais', 'Flanker', 'U14 Squad', 'Active'),
('OVK-U14-004', '1', 'U14', 'Wikus', 'Grobler', 'Lock', 'U14 Squad', 'Active'),
('OVK-U14-005', '1', 'U14', 'Heinrich', 'Visser', 'Prop', 'U14 Squad', 'Active')
ON CONFLICT(id) DO UPDATE SET school_id = '1', age_group = 'U14', status = 'Active';

-- Link Players to Squads in squad_players junction table
INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT 'sq_u15', id FROM players WHERE age_group = 'U15' AND school_id = '1';

INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT 'sq_u16', id FROM players WHERE age_group = 'U16' AND school_id = '1';

INSERT OR IGNORE INTO squad_players (squad_id, player_id)
SELECT 'sq_u14', id FROM players WHERE age_group = 'U14' AND school_id = '1';

PRAGMA foreign_keys = ON;
