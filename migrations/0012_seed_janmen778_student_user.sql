INSERT INTO users (id, school_id, email, password_hash, role, first_name, last_name)
VALUES ('USR-STUDENT-JAN', 'OVK', 'janmen778@gmail.com', NULL, 'Student', 'Jan', 'Mentz')
ON CONFLICT(email) DO UPDATE SET
  id = excluded.id,
  school_id = excluded.school_id,
  role = excluded.role,
  first_name = excluded.first_name,
  last_name = excluded.last_name;

INSERT INTO players (id, school_id, user_id, age_group, first_name, last_name, grade, age, position, team, status, ugroups_active)
VALUES ('OVK-STUDENT-JAN', 'OVK', 'USR-STUDENT-JAN', 'U15', 'Jan', 'Mentz', 10, 16, 'Fly-half', 'Academy Elite', 'Active', 1)
ON CONFLICT(id) DO UPDATE SET
  user_id = excluded.user_id,
  first_name = excluded.first_name,
  last_name = excluded.last_name,
  age_group = excluded.age_group,
  team = excluded.team,
  position = excluded.position;

INSERT INTO academic_logs (player_id, term, grade_percentage, discipline_score)
VALUES 
  ('OVK-STUDENT-JAN', 1, 74.5, 0),
  ('OVK-STUDENT-JAN', 2, 78.0, 0)
ON CONFLICT(player_id, term) DO UPDATE SET
  grade_percentage = excluded.grade_percentage,
  discipline_score = excluded.discipline_score;

INSERT INTO fitness_baselines (player_id, speed_40m, speed_60m, broad_jump, push_ups, pull_ups, squats_40kg, vertical_jump, t_test)
VALUES ('OVK-STUDENT-JAN', 5.35, 7.95, 2.15, 32, 8, 35, 2.85, 9.85)
ON CONFLICT(player_id) DO UPDATE SET
  speed_40m = excluded.speed_40m,
  speed_60m = excluded.speed_60m,
  broad_jump = excluded.broad_jump,
  push_ups = excluded.push_ups,
  pull_ups = excluded.pull_ups,
  squats_40kg = excluded.squats_40kg,
  vertical_jump = excluded.vertical_jump,
  t_test = excluded.t_test;

INSERT INTO fitness_progression (player_id, week, speed_40m, strength_reps, weight, gym_sessions_per_week)
VALUES
  ('OVK-STUDENT-JAN', 0, 5.60, 25, 68.0, 3),
  ('OVK-STUDENT-JAN', 8, 5.45, 29, 70.2, 4),
  ('OVK-STUDENT-JAN', 16, 5.35, 32, 71.5, 4)
ON CONFLICT(player_id, week) DO UPDATE SET
  speed_40m = excluded.speed_40m,
  strength_reps = excluded.strength_reps,
  weight = excluded.weight,
  gym_sessions_per_week = excluded.gym_sessions_per_week;

INSERT INTO match_stats (player_id, match_date, opponent, tackles_made, tackles_missed, carries, metres_gained, errors, penalties, work_rate, overall_rating, auto_score, tackle_percentage, category)
VALUES
  ('OVK-STUDENT-JAN', '2026-07-10', 'Monument Park', 12, 1, 8, 65.0, 0, 1, 5, 5, 88.5, 92.3, 'Elite'),
  ('OVK-STUDENT-JAN', '2026-07-17', 'Waterkloof', 15, 2, 10, 82.0, 1, 0, 5, 5, 91.0, 88.2, 'Elite');

INSERT INTO attendance (player_id, session_type, date, status)
VALUES
  ('OVK-STUDENT-JAN', 'Gym', '2026-07-21', 'Present'),
  ('OVK-STUDENT-JAN', 'Field', '2026-07-22', 'Present'),
  ('OVK-STUDENT-JAN', 'uGroup', '2026-07-23', 'Present')
ON CONFLICT(player_id, session_type, date) DO UPDATE SET
  status = excluded.status;
