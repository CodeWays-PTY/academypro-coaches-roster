INSERT INTO events (id, school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, age_group, team, workout_image_path)
VALUES (10, 'OVK', 'High Performance Power & Speed', 'Gym Session', '07:00', '2026-07-26', 60, 'Overkruin Gym Complex', 'High', 1, 'U15', 'Academy Elite', 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800')
ON CONFLICT(id) DO UPDATE SET
  title = excluded.title,
  workout_image_path = excluded.workout_image_path,
  date = excluded.date;

INSERT INTO events (id, school_id, title, event_type, start_time, date, duration_mins, location, intensity, is_important, age_group, team, workout_image_path)
VALUES (11, 'OVK', 'Backline Tactical & Kicking Drills', 'Field Session', '15:30', '2026-07-27', 90, 'Main Field A', 'Medium', 0, 'U15', 'Academy Elite', 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?w=800')
ON CONFLICT(id) DO UPDATE SET
  title = excluded.title,
  workout_image_path = excluded.workout_image_path,
  date = excluded.date;
