-- Migration 002: Seed Data
-- Initial data for TriathlonApp

-- Default admin (password should be changed in production)
-- Password hash is for 'changeme123' - CHANGE THIS IN PRODUCTION
-- Using PBKDF2-SHA256 format (compatible with Edge runtime)
INSERT OR IGNORE INTO admins (id, email, password_hash, name, role) VALUES (
  'admin_001',
  'admin@triathlon-app.com',
  '$pbkdf2-sha256$100000$f820a5ac06352af2b9e50be3ddfdaabd$361ca8dbffd98751dbaca5e17ffe67e41a37dd8c13202180fecd572d0f2de92e',
  'Admin',
  'super_admin'
);

-- Default worker jobs
INSERT OR IGNORE INTO worker_jobs (id, name, worker_name, cron_expression, description, is_active) VALUES
  ('job_recalc', 'Recalcul hebdomadaire', 'recalc-weekly', '0 6 * * 1', 'Recalcule les programmes chaque lundi à 6h', 1),
  ('job_strava_batch', 'Sync Strava batch', 'strava-sync', '0 */4 * * *', 'Synchronise les activités Strava toutes les 4h', 1),
  ('job_notif_daily', 'Notifications quotidiennes', 'notifications', '0 7 * * *', 'Envoie les rappels de séance à 7h', 1),
  ('job_pseo_rebuild', 'Rebuild PSEO', 'pseo-builder', '0 3 * * 0', 'Régénère les pages SEO chaque dimanche', 1),
  ('job_cleanup', 'Cleanup logs', 'cleanup', '0 2 1 * *', 'Nettoie les vieux logs chaque 1er du mois', 1);

-- Template Half Ironman 70.3 - Intermediate - 16 weeks
INSERT OR IGNORE INTO templates (id, name, slug, distance_type, experience_level, duration_weeks, weekly_hours_min, weekly_hours_max, description, phases, week_templates, is_active) VALUES (
  'tpl_703_int_16',
  'Half Ironman 70.3 - 16 semaines',
  'half-ironman-16-weeks-intermediate',
  '70.3',
  'intermediate',
  16,
  10,
  14,
  'Programme complet pour préparer un Half Ironman en 16 semaines. Idéal pour les triathlètes ayant déjà une base d''endurance.',
  '[
    {"name": "Base", "weeks": [1,2,3,4], "focus": "Endurance aérobie et technique", "intensity": "low"},
    {"name": "Build 1", "weeks": [5,6,7,8], "focus": "Développement volume", "intensity": "medium"},
    {"name": "Build 2", "weeks": [9,10,11,12], "focus": "Intensité spécifique", "intensity": "high"},
    {"name": "Peak", "weeks": [13,14], "focus": "Affûtage compétition", "intensity": "medium"},
    {"name": "Taper", "weeks": [15,16], "focus": "Récupération et fraîcheur", "intensity": "low"}
  ]',
  '{
    "base": {"swim": 3, "bike": 3, "run": 3, "brick": 0, "rest": 1, "hours": 10},
    "build1": {"swim": 3, "bike": 3, "run": 3, "brick": 1, "rest": 1, "hours": 12},
    "build2": {"swim": 3, "bike": 3, "run": 3, "brick": 1, "rest": 1, "hours": 14},
    "peak": {"swim": 3, "bike": 2, "run": 3, "brick": 1, "rest": 1, "hours": 12},
    "taper": {"swim": 2, "bike": 2, "run": 2, "brick": 0, "rest": 2, "hours": 8}
  }',
  1
);

-- Template Ironman - Intermediate - 24 weeks
INSERT OR IGNORE INTO templates (id, name, slug, distance_type, experience_level, duration_weeks, weekly_hours_min, weekly_hours_max, description, phases, week_templates, is_active) VALUES (
  'tpl_im_int_24',
  'Ironman - 24 semaines',
  'ironman-24-weeks-intermediate',
  'ironman',
  'intermediate',
  24,
  14,
  20,
  'Programme complet Ironman sur 24 semaines. Préparation progressive avec focus sur l''endurance longue distance.',
  '[
    {"name": "Base", "weeks": [1,2,3,4,5,6], "focus": "Fondation aérobie", "intensity": "low"},
    {"name": "Build 1", "weeks": [7,8,9,10,11,12], "focus": "Développement volume", "intensity": "medium"},
    {"name": "Build 2", "weeks": [13,14,15,16,17,18], "focus": "Spécificité Ironman", "intensity": "high"},
    {"name": "Peak", "weeks": [19,20,21,22], "focus": "Simulation race", "intensity": "medium"},
    {"name": "Taper", "weeks": [23,24], "focus": "Affûtage final", "intensity": "low"}
  ]',
  '{
    "base": {"swim": 3, "bike": 3, "run": 3, "brick": 0, "rest": 1, "hours": 12},
    "build1": {"swim": 4, "bike": 3, "run": 3, "brick": 1, "rest": 1, "hours": 16},
    "build2": {"swim": 4, "bike": 3, "run": 3, "brick": 1, "rest": 1, "hours": 18},
    "peak": {"swim": 3, "bike": 3, "run": 3, "brick": 1, "rest": 1, "hours": 16},
    "taper": {"swim": 2, "bike": 2, "run": 2, "brick": 0, "rest": 2, "hours": 10}
  }',
  1
);

-- Sample session templates
INSERT OR IGNORE INTO session_templates (id, code, sport, session_type, title, objective, base_duration, workout_structure, is_active) VALUES
  ('st_swim_tech', 'SWIM_TECH', 'swim', 'technique', 'Natation Technique', 'Améliorer l''efficacité du mouvement et la position dans l''eau', 60, '{"warmup": {"description": "400m souple variée", "duration": 10}, "mainSets": [{"type": "drill", "description": "Éducatifs techniques", "duration": 30}], "cooldown": {"description": "200m souple", "duration": 5}}', 1),
  ('st_swim_endo', 'SWIM_ENDO', 'swim', 'endurance', 'Natation Endurance', 'Développer l''endurance aérobie et la régularité', 75, '{"warmup": {"description": "400m progressif", "duration": 10}, "mainSets": [{"type": "steady", "description": "Séries continues Z2", "duration": 45}], "cooldown": {"description": "200m souple", "duration": 5}}', 1),
  ('st_swim_inter', 'SWIM_INTER', 'swim', 'intervals', 'Natation Intervalles', 'Travailler le seuil et la vitesse', 60, '{"warmup": {"description": "400m", "duration": 10}, "mainSets": [{"type": "interval", "reps": 10, "distance": 100, "rest": 20, "intensity": "threshold"}], "cooldown": {"description": "200m", "duration": 5}}', 1),
  ('st_bike_endo', 'BIKE_ENDO', 'bike', 'endurance', 'Vélo Endurance', 'Construire la base aérobie', 120, '{"warmup": {"description": "15min progressif", "duration": 15}, "mainSets": [{"type": "steady", "description": "Z2 constant", "duration": 90}], "cooldown": {"description": "Retour calme", "duration": 15}}', 1),
  ('st_bike_tempo', 'BIKE_TEMPO', 'bike', 'tempo', 'Vélo Tempo', 'Développer l''endurance au seuil', 90, '{"warmup": {"description": "15min progressif", "duration": 15}, "mainSets": [{"type": "steady", "description": "Sweet spot 88-93% FTP", "duration": 60}], "cooldown": {"description": "Retour calme", "duration": 15}}', 1),
  ('st_run_endo', 'RUN_ENDO', 'run', 'endurance', 'Course Endurance', 'Base aérobie en course à pied', 60, '{"warmup": {"description": "10min footing léger", "duration": 10}, "mainSets": [{"type": "steady", "description": "Allure Z2", "duration": 40}], "cooldown": {"description": "Retour calme + étirements", "duration": 10}}', 1),
  ('st_run_inter', 'RUN_INTER', 'run', 'intervals', 'Course Intervalles', 'Développer la VMA', 50, '{"warmup": {"description": "15min footing progressif", "duration": 15}, "mainSets": [{"type": "interval", "reps": 6, "distance": 1000, "rest": 120, "intensity": "95-100% VMA"}], "cooldown": {"description": "10min retour calme", "duration": 10}}', 1),
  ('st_brick_short', 'BRICK_SHORT', 'brick', 'brick_short', 'Enchaînement Court', 'Adaptation aux transitions', 90, '{"warmup": {"description": "Préparation matériel", "duration": 5}, "mainSets": [{"type": "multi", "parts": [{"sport": "bike", "duration": 60, "description": "Vélo tempo"}, {"sport": "run", "duration": 20, "description": "Course progressive"}]}], "cooldown": {"description": "Récupération", "duration": 5}}', 1);
