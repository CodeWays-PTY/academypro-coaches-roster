-- Bulk upload U15 roster
INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_001_1785842453281', 'OVK', 'Manieengelbrecht35@gmail.com', '082 438 1998', 'Student', 'Immanuel', 'Engelbrecht') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_001_1785842453281', 'OVK', 'usr_u15_001_1785842453281', 'Immanuel', 'Engelbrecht', '082 438 1998', 'Manieengelbrecht35@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_001_1785842453281') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_002_1785842453282', 'OVK', 'Nthabyjankie@gmail.com', '083 495 2406', 'Student', 'Sello', 'Jantie') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_002_1785842453282', 'OVK', 'usr_u15_002_1785842453282', 'Sello', 'Jantie', '083 495 2406', 'Nthabyjankie@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_002_1785842453282') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_003_1785842453283', 'OVK', 'Wikusdekoker12@gmail.com', '067 787 5916', 'Student', 'Wikus', 'De Koker') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_003_1785842453283', 'OVK', 'usr_u15_003_1785842453283', 'Wikus', 'De Koker', '067 787 5916', 'Wikusdekoker12@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_003_1785842453283') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_004_1785842453284', 'OVK', 'Phatumotlhabane@gmail.com', NULL, 'Student', 'Phatu', 'Motlhabane') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_004_1785842453284', 'OVK', 'usr_u15_004_1785842453284', 'Phatu', 'Motlhabane', NULL, 'Phatumotlhabane@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_004_1785842453284') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_005_1785842453285', 'OVK', 'shayaan.rafiq@dummy.academypro.co.za', '084 208 9276', 'Student', 'Shayaan', 'Rafiq') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_005_1785842453285', 'OVK', 'usr_u15_005_1785842453285', 'Shayaan', 'Rafiq', '084 208 9276', 'shayaan.rafiq@dummy.academypro.co.za', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_005_1785842453285') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_006_1785842453286', 'OVK', 'alexander.coetzer@dummy.academypro.co.za', '069 656 9306', 'Student', 'Alexander', 'Coetzer') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_006_1785842453286', 'OVK', 'usr_u15_006_1785842453286', 'Alexander', 'Coetzer', '069 656 9306', 'alexander.coetzer@dummy.academypro.co.za', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_006_1785842453286') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_007_1785842453287', 'OVK', 'achumabibi5@gmail.com', '0635279367', 'Student', 'Achuma', 'Bibi') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_007_1785842453287', 'OVK', 'usr_u15_007_1785842453287', 'Achuma', 'Bibi', '0635279367', 'achumabibi5@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_007_1785842453287') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_008_1785842453288', 'OVK', 'taylonbradleycartwright@gmail.com', '075 028 7075', 'Student', 'Taylon', 'Cartwright') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_008_1785842453288', 'OVK', 'usr_u15_008_1785842453288', 'Taylon', 'Cartwright', '075 028 7075', 'taylonbradleycartwright@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_008_1785842453288') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_009_1785842453289', 'OVK', 'bokang.maphosa@dummy.academypro.co.za', '079 901 5552', 'Student', 'Bokang', 'Maphosa') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_009_1785842453289', 'OVK', 'usr_u15_009_1785842453289', 'Bokang', 'Maphosa', '079 901 5552', 'bokang.maphosa@dummy.academypro.co.za', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_009_1785842453289') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_010_1785842453290', 'OVK', 'kyle.smith@dummy.academypro.co.za', '083 387 9023', 'Student', 'Kyle', 'Smith') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_010_1785842453290', 'OVK', 'usr_u15_010_1785842453290', 'Kyle', 'Smith', '083 387 9023', 'kyle.smith@dummy.academypro.co.za', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_010_1785842453290') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_011_1785842453291', 'OVK', 'simphiwe.philemon@dummy.academypro.co.za', '082 644 7842', 'Student', 'Simphiwe', 'Philemon') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_011_1785842453291', 'OVK', 'usr_u15_011_1785842453291', 'Simphiwe', 'Philemon', '082 644 7842', 'simphiwe.philemon@dummy.academypro.co.za', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_011_1785842453291') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_012_1785842453292', 'OVK', 'Khumokutumela77@gmail.com', '066 543 1954', 'Student', 'Khumo', 'Kutumela') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_012_1785842453292', 'OVK', 'usr_u15_012_1785842453292', 'Khumo', 'Kutumela', '066 543 1954', 'Khumokutumela77@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_012_1785842453292') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_013_1785842453293', 'OVK', 'Nkwinikaluvani21@gmail.com', '061 083 5809', 'Student', 'Luvani', 'Nkwinika') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_013_1785842453293', 'OVK', 'usr_u15_013_1785842453293', 'Luvani', 'Nkwinika', '061 083 5809', 'Nkwinikaluvani21@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_013_1785842453293') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_014_1785842453294', 'OVK', 'Liammare2011@gmail.com', '079 402 5703', 'Student', 'Liam', 'Maré') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_014_1785842453294', 'OVK', 'usr_u15_014_1785842453294', 'Liam', 'Maré', '079 402 5703', 'Liammare2011@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_014_1785842453294') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_015_1785842453295', 'OVK', 'elkody@icloud.com', NULL, 'Student', 'Kody', 'Langeveldt') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_015_1785842453295', 'OVK', 'usr_u15_015_1785842453295', 'Kody', 'Langeveldt', NULL, 'elkody@icloud.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_015_1785842453295') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_016_1785842453296', 'OVK', 'theo67mosia@gmail.com', '068 569 5251', 'Student', 'Theodore', 'Mosia') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_016_1785842453296', 'OVK', 'usr_u15_016_1785842453296', 'Theodore', 'Mosia', '068 569 5251', 'theo67mosia@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_016_1785842453296') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_017_1785842453298', 'OVK', 'shelton.julies@dummy.academypro.co.za', '066 491 3739', 'Student', 'Shelton', 'Julies') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_017_1785842453298', 'OVK', 'usr_u15_017_1785842453298', 'Shelton', 'Julies', '066 491 3739', 'shelton.julies@dummy.academypro.co.za', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_017_1785842453298') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_018_1785842453299', 'OVK', 'luyandanzotho51@gmail.com', '069 889 4923', 'Student', 'Luyanda', 'Nzotho') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_018_1785842453299', 'OVK', 'usr_u15_018_1785842453299', 'Luyanda', 'Nzotho', '069 889 4923', 'luyandanzotho51@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_018_1785842453299') ON CONFLICT DO NOTHING;

INSERT INTO users (id, school_id, email, phone, role, first_name, last_name) VALUES ('usr_u15_019_1785842453300', 'OVK', 'Siphosihlemasemola69@gmail.com', '0704029838', 'Student', 'Siphosihle', 'Masemola') ON CONFLICT (email) DO UPDATE SET first_name=EXCLUDED.first_name;
INSERT INTO players (id, school_id, user_id, first_name, last_name, phone, email, age_group, team, position, status) VALUES ('plr_u15_019_1785842453300', 'OVK', 'usr_u15_019_1785842453300', 'Siphosihle', 'Masemola', '0704029838', 'Siphosihlemasemola69@gmail.com', 'U15', 'U15', 'Athlete', 'Active');
INSERT INTO squad_players (squad_id, player_id) VALUES ('sq-1785841532380', 'plr_u15_019_1785842453300') ON CONFLICT DO NOTHING;
