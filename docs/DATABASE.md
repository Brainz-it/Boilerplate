# Schéma Base de Données - Cloudflare D1

> SQLite edge database pour TriathlonApp

---

## Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              UTILISATEURS                                   │
│  ┌─────────┐    ┌──────────────────┐    ┌────────────────┐                  │
│  │  users  │───▶│ athlete_profiles │    │heart_rate_zones│                  │
│  └────┬────┘    └──────────────────┘    └────────────────┘                  │
│       │                                                                     │
│       ▼                                                                     │
│  ┌─────────┐    ┌──────────────────┐    ┌────────────────┐                  │
│  │  goals  │───▶│    programs      │───▶│ program_weeks  │                  │
│  └─────────┘    └──────────────────┘    └───────┬────────┘                  │
│                                                 │                           │
│                                                 ▼                           │
│                                          ┌────────────┐                     │
│                                          │  sessions  │                     │
│                                          └────────────┘                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                              STRAVA                                         │
│  ┌───────────────────┐                                                      │
│  │ strava_activities │                                                      │
│  └───────────────────┘                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                              TEMPLATES                                      │
│  ┌─────────────┐    ┌───────────────────┐                                   │
│  │  templates  │    │ session_templates │                                   │
│  └─────────────┘    └───────────────────┘                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                              ADMIN & SYSTÈME                                │
│  ┌─────────┐  ┌────────────────┐  ┌─────────────┐  ┌──────────────┐         │
│  │ admins  │  │ admin_sessions │  │ audit_logs  │  │ worker_jobs  │         │
│  └─────────┘  └────────────────┘  └─────────────┘  └──────────────┘         │
├─────────────────────────────────────────────────────────────────────────────┤
│                              PSEO                                           │
│  ┌─────────────┐                                                            │
│  │ pseo_pages  │                                                            │
│  └─────────────┘                                                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Tables

### users

Utilisateurs authentifiés via Strava.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,                              -- nanoid
  strava_id TEXT UNIQUE NOT NULL,                   -- ID Strava athlete
  email TEXT,                                       -- Email Strava (si autorisé)
  first_name TEXT,
  last_name TEXT,
  profile_picture TEXT,                             -- URL avatar Strava
  strava_access_token TEXT,                         -- Token OAuth
  strava_refresh_token TEXT,                        -- Refresh token
  strava_token_expires_at INTEGER,                  -- Timestamp expiration
  onboarding_completed BOOLEAN DEFAULT FALSE,
  notification_token TEXT,                          -- Expo push token
  notification_preferences TEXT DEFAULT '{}',       -- JSON preferences
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

-- Index
CREATE INDEX idx_users_strava_id ON users(strava_id);
CREATE INDEX idx_users_created_at ON users(created_at);
```

### athlete_profiles

Profil athlète enrichi post-onboarding.

```sql
CREATE TABLE athlete_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Données personnelles
  birth_year INTEGER,
  gender TEXT,                                      -- 'M', 'F', 'O'
  weight_kg REAL,

  -- Niveau et expérience
  experience_level TEXT NOT NULL,                   -- 'beginner', 'intermediate', 'advanced'
  triathlon_count INTEGER DEFAULT 0,                -- Nombre triathlons complétés
  longest_distance TEXT,                            -- '70.3', 'ironman', 'olympic', etc.

  -- Disponibilités
  weekly_hours_available INTEGER NOT NULL,          -- Heures dispo par semaine
  unavailable_days TEXT DEFAULT '[]',               -- JSON array [0-6] (0=dimanche)

  -- Contraintes
  pool_access BOOLEAN DEFAULT TRUE,
  pool_schedule TEXT,                               -- JSON créneaux piscine
  home_trainer BOOLEAN DEFAULT FALSE,
  outdoor_bike_only BOOLEAN DEFAULT FALSE,
  injuries_notes TEXT,

  -- Zones physiologiques
  fc_max INTEGER,
  fc_max_source TEXT,                               -- 'strava', 'manual', 'estimated'
  fc_rest INTEGER,
  ftp INTEGER,                                      -- Functional Threshold Power (watts)
  ftp_source TEXT,
  css INTEGER,                                      -- Critical Swim Speed (sec/100m)
  run_threshold_pace INTEGER,                       -- sec/km

  -- Métadonnées
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch()),

  UNIQUE(user_id)
);

CREATE INDEX idx_athlete_profiles_user ON athlete_profiles(user_id);
```

### heart_rate_zones

Zones cardiaques par utilisateur (5 zones).

```sql
CREATE TABLE heart_rate_zones (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  zone_number INTEGER NOT NULL,                     -- 1-5
  name TEXT NOT NULL,                               -- 'Recovery', 'Endurance', etc.
  min_hr INTEGER NOT NULL,
  max_hr INTEGER NOT NULL,
  description TEXT,
  color TEXT,                                       -- Hex color pour UI
  source TEXT NOT NULL,                             -- 'strava', 'calculated', 'manual'
  created_at INTEGER DEFAULT (unixepoch()),

  UNIQUE(user_id, zone_number)
);

CREATE INDEX idx_hr_zones_user ON heart_rate_zones(user_id);
```

### goals

Objectifs/événements de l'utilisateur.

```sql
CREATE TABLE goals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Événement
  event_name TEXT NOT NULL,                         -- "Ironman Nice 2025"
  event_date INTEGER NOT NULL,                      -- Timestamp date événement
  event_location TEXT,
  event_url TEXT,

  -- Configuration
  distance_type TEXT NOT NULL,                      -- '70.3', 'ironman'
  target_time INTEGER,                              -- Objectif temps en secondes
  priority TEXT DEFAULT 'primary',                  -- 'primary', 'secondary'

  -- État
  status TEXT DEFAULT 'active',                     -- 'active', 'completed', 'cancelled', 'abandoned'
  completion_time INTEGER,                          -- Temps réel si complété
  completion_notes TEXT,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_goals_user ON goals(user_id);
CREATE INDEX idx_goals_status ON goals(status);
CREATE INDEX idx_goals_event_date ON goals(event_date);
```

### templates

Templates de programmes par distance et niveau.

```sql
CREATE TABLE templates (
  id TEXT PRIMARY KEY,

  -- Identification
  name TEXT NOT NULL,                               -- "Ironman 24 semaines - Intermédiaire"
  slug TEXT UNIQUE NOT NULL,
  distance_type TEXT NOT NULL,                      -- '70.3', 'ironman'
  experience_level TEXT NOT NULL,                   -- 'beginner', 'intermediate', 'advanced'

  -- Configuration
  duration_weeks INTEGER NOT NULL,
  weekly_hours_min INTEGER NOT NULL,
  weekly_hours_max INTEGER NOT NULL,

  -- Contenu
  description TEXT,
  phases TEXT NOT NULL,                             -- JSON structure phases
  /*
  phases = [
    { "name": "Base", "weeks": [1,2,3,4,5,6], "focus": "Endurance aérobie", "intensity": "low" },
    { "name": "Build 1", "weeks": [7,8,9,10,11,12], "focus": "Volume", "intensity": "medium" },
    ...
  ]
  */

  week_templates TEXT NOT NULL,                     -- JSON template par semaine type
  /*
  week_templates = {
    "base": { "swim": 3, "bike": 3, "run": 3, "brick": 0, "rest": 1, "hours": 10 },
    "build": { "swim": 3, "bike": 3, "run": 3, "brick": 1, "rest": 1, "hours": 14 },
    ...
  }
  */

  -- État
  is_active BOOLEAN DEFAULT TRUE,
  version INTEGER DEFAULT 1,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_templates_distance ON templates(distance_type);
CREATE INDEX idx_templates_level ON templates(experience_level);
CREATE INDEX idx_templates_active ON templates(is_active);
```

### session_templates

Bibliothèque de séances types.

```sql
CREATE TABLE session_templates (
  id TEXT PRIMARY KEY,

  -- Identification
  code TEXT UNIQUE NOT NULL,                        -- 'SWIM_INTER', 'BIKE_TEMPO', etc.
  sport TEXT NOT NULL,                              -- 'swim', 'bike', 'run', 'brick'
  session_type TEXT NOT NULL,                       -- 'endurance', 'intervals', 'tempo', etc.

  -- Contenu
  title TEXT NOT NULL,
  description TEXT,
  objective TEXT NOT NULL,                          -- Objectif pédagogique
  tips TEXT,                                        -- JSON array de conseils

  -- Configuration
  base_duration INTEGER NOT NULL,                   -- Durée base en minutes
  duration_scaling TEXT,                            -- JSON règles scaling
  difficulty_level INTEGER DEFAULT 3,               -- 1-5

  -- Zones
  hr_zones TEXT,                                    -- JSON zones par phase
  /*
  hr_zones = {
    "warmup": { "zone": 1, "duration_pct": 15 },
    "main": { "zone": 3, "duration_pct": 70 },
    "cooldown": { "zone": 1, "duration_pct": 15 }
  }
  */

  power_zones TEXT,                                 -- JSON zones puissance vélo
  pace_zones TEXT,                                  -- JSON zones allure course

  -- Structure
  workout_structure TEXT NOT NULL,                  -- JSON détail séance
  /*
  workout_structure = {
    "warmup": { "description": "400m souple", "duration": 10 },
    "main_sets": [
      { "reps": 10, "distance": 100, "rest": 20, "intensity": "threshold" }
    ],
    "cooldown": { "description": "200m souple", "duration": 5 }
  }
  */

  -- Métadonnées
  tags TEXT,                                        -- JSON array tags
  suitable_for TEXT DEFAULT '["all"]',              -- JSON niveaux compatibles

  is_active BOOLEAN DEFAULT TRUE,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_session_tpl_sport ON session_templates(sport);
CREATE INDEX idx_session_tpl_type ON session_templates(session_type);
CREATE INDEX idx_session_tpl_code ON session_templates(code);
```

### programs

Programmes générés pour les utilisateurs.

```sql
CREATE TABLE programs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_id TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  template_id TEXT REFERENCES templates(id),

  -- Configuration
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  total_weeks INTEGER NOT NULL,

  -- Progression
  current_week INTEGER DEFAULT 1,
  current_phase TEXT,

  -- Personnalisation appliquée
  weekly_hours_target REAL,
  customizations TEXT,                              -- JSON ajustements appliqués

  -- État
  status TEXT DEFAULT 'active',                     -- 'active', 'paused', 'completed', 'cancelled'

  -- Recalcul
  last_recalc_at INTEGER,
  recalc_count INTEGER DEFAULT 0,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_programs_user ON programs(user_id);
CREATE INDEX idx_programs_goal ON programs(goal_id);
CREATE INDEX idx_programs_status ON programs(status);
```

### program_weeks

Semaines d'un programme avec volumes planifiés et réalisés.

```sql
CREATE TABLE program_weeks (
  id TEXT PRIMARY KEY,
  program_id TEXT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,

  -- Position
  week_number INTEGER NOT NULL,
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  phase TEXT NOT NULL,                              -- 'base', 'build1', 'build2', 'peak', 'taper'

  -- Volumes planifiés
  planned_volume_swim INTEGER DEFAULT 0,            -- mètres
  planned_volume_bike INTEGER DEFAULT 0,            -- km
  planned_volume_run INTEGER DEFAULT 0,             -- km
  planned_hours REAL DEFAULT 0,
  planned_sessions INTEGER DEFAULT 0,

  -- Volumes réalisés
  actual_volume_swim INTEGER DEFAULT 0,
  actual_volume_bike INTEGER DEFAULT 0,
  actual_volume_run INTEGER DEFAULT 0,
  actual_hours REAL DEFAULT 0,
  actual_sessions INTEGER DEFAULT 0,

  -- Analyse
  compliance_rate REAL,                             -- 0-100
  load_score REAL,                                  -- TSS ou équivalent
  fatigue_indicator TEXT,                           -- 'low', 'normal', 'high', 'critical'

  -- État
  status TEXT DEFAULT 'pending',                    -- 'pending', 'current', 'completed'
  recalc_notes TEXT,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch()),

  UNIQUE(program_id, week_number)
);

CREATE INDEX idx_weeks_program ON program_weeks(program_id);
CREATE INDEX idx_weeks_status ON program_weeks(status);
CREATE INDEX idx_weeks_dates ON program_weeks(start_date, end_date);
```

### sessions

Séances planifiées dans le programme.

```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  program_week_id TEXT NOT NULL REFERENCES program_weeks(id) ON DELETE CASCADE,
  session_template_id TEXT REFERENCES session_templates(id),

  -- Planification
  day_of_week INTEGER NOT NULL,                     -- 1=lundi, 7=dimanche
  scheduled_date INTEGER NOT NULL,
  order_in_day INTEGER DEFAULT 1,                   -- Si plusieurs séances/jour

  -- Type
  sport TEXT NOT NULL,                              -- 'swim', 'bike', 'run', 'brick', 'rest', 'strength'
  session_type TEXT,

  -- Contenu
  title TEXT NOT NULL,
  description TEXT,
  objective TEXT,
  tips TEXT,                                        -- JSON array

  -- Cibles
  duration_planned INTEGER,                         -- minutes
  distance_planned INTEGER,                         -- mètres (swim) ou km*100 (bike/run)
  hr_zones TEXT,                                    -- JSON zones par phase
  power_target TEXT,                                -- JSON cibles puissance
  pace_target TEXT,                                 -- JSON cibles allure

  -- Détail séance
  workout_details TEXT,                             -- JSON structure complète
  /*
  workout_details = {
    "warmup": { "duration": 15, "description": "Échauffement progressif", "hr_zone": 1 },
    "main": [
      { "type": "interval", "reps": 5, "work": "5min", "rest": "2min", "hr_zone": 4 }
    ],
    "cooldown": { "duration": 10, "description": "Retour calme", "hr_zone": 1 }
  }
  */

  -- Réalisation
  status TEXT DEFAULT 'pending',                    -- 'pending', 'completed', 'skipped', 'partial'
  strava_activity_id TEXT,

  -- Données réelles (si complétée)
  actual_duration INTEGER,
  actual_distance INTEGER,
  actual_avg_hr INTEGER,
  actual_max_hr INTEGER,
  actual_avg_power INTEGER,
  actual_tss REAL,

  -- Feedback
  perceived_effort INTEGER,                         -- RPE 1-10
  completion_notes TEXT,
  completed_at INTEGER,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_sessions_week ON sessions(program_week_id);
CREATE INDEX idx_sessions_date ON sessions(scheduled_date);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_sport ON sessions(sport);
CREATE INDEX idx_sessions_strava ON sessions(strava_activity_id);
```

### strava_activities

Activités synchronisées depuis Strava.

```sql
CREATE TABLE strava_activities (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  strava_id TEXT UNIQUE NOT NULL,

  -- Identification
  sport_type TEXT NOT NULL,                         -- 'Swim', 'Ride', 'Run', 'VirtualRide', etc.
  name TEXT,
  description TEXT,

  -- Timing
  start_date INTEGER NOT NULL,
  start_date_local TEXT,
  timezone TEXT,
  elapsed_time INTEGER,                             -- secondes totales
  moving_time INTEGER,                              -- secondes en mouvement

  -- Distance et vitesse
  distance REAL,                                    -- mètres
  average_speed REAL,                               -- m/s
  max_speed REAL,

  -- Cardiaque
  average_heartrate REAL,
  max_heartrate REAL,
  has_heartrate BOOLEAN DEFAULT FALSE,

  -- Puissance (vélo)
  average_watts REAL,
  max_watts REAL,
  weighted_average_watts REAL,
  kilojoules REAL,
  device_watts BOOLEAN DEFAULT FALSE,

  -- Autres métriques
  total_elevation_gain REAL,
  elev_high REAL,
  elev_low REAL,
  average_cadence REAL,
  suffer_score INTEGER,
  calories INTEGER,

  -- Métadonnées
  gear_id TEXT,
  trainer BOOLEAN DEFAULT FALSE,
  commute BOOLEAN DEFAULT FALSE,

  -- Données brutes
  raw_data TEXT,                                    -- JSON complet Strava

  -- Sync
  synced_at INTEGER DEFAULT (unixepoch()),

  UNIQUE(user_id, strava_id)
);

CREATE INDEX idx_strava_user ON strava_activities(user_id);
CREATE INDEX idx_strava_date ON strava_activities(start_date);
CREATE INDEX idx_strava_sport ON strava_activities(sport_type);
CREATE INDEX idx_strava_strava_id ON strava_activities(strava_id);
```

### audit_logs

Logs d'audit avec triggers pour workers.

```sql
CREATE TABLE audit_logs (
  id TEXT PRIMARY KEY,
  timestamp INTEGER DEFAULT (unixepoch()),

  -- Événement
  event_type TEXT NOT NULL,                         -- 'user.created', 'program.generated', etc.
  event_category TEXT,                              -- 'auth', 'program', 'strava', 'admin', 'system'

  -- Entité concernée
  entity_type TEXT,                                 -- 'user', 'program', 'session', etc.
  entity_id TEXT,

  -- Acteur
  actor_type TEXT NOT NULL,                         -- 'user', 'admin', 'system', 'worker'
  actor_id TEXT,

  -- Données
  payload TEXT,                                     -- JSON données événement
  changes TEXT,                                     -- JSON before/after si modification

  -- Worker trigger
  trigger_worker TEXT,                              -- Nom du worker à déclencher
  worker_status TEXT,                               -- 'pending', 'queued', 'completed', 'failed'
  worker_triggered_at INTEGER,
  worker_completed_at INTEGER,
  worker_result TEXT,                               -- JSON résultat worker
  worker_error TEXT,

  -- Contexte
  ip_address TEXT,
  user_agent TEXT,
  request_id TEXT
);

CREATE INDEX idx_audit_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_audit_event ON audit_logs(event_type);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_actor ON audit_logs(actor_type, actor_id);
CREATE INDEX idx_audit_worker ON audit_logs(trigger_worker, worker_status);
```

### admins

Administrateurs back-office.

```sql
CREATE TABLE admins (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,                      -- bcrypt hash

  -- Profil
  name TEXT NOT NULL,
  role TEXT DEFAULT 'admin',                        -- 'admin', 'super_admin'
  avatar TEXT,

  -- État
  is_active BOOLEAN DEFAULT TRUE,
  last_login_at INTEGER,
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until INTEGER,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE UNIQUE INDEX idx_admins_email ON admins(email);
```

### admin_sessions

Sessions d'authentification admin.

```sql
CREATE TABLE admin_sessions (
  id TEXT PRIMARY KEY,                              -- Session token
  admin_id TEXT NOT NULL REFERENCES admins(id) ON DELETE CASCADE,

  expires_at INTEGER NOT NULL,

  -- Contexte
  ip_address TEXT,
  user_agent TEXT,

  created_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_admin_sessions_admin ON admin_sessions(admin_id);
CREATE INDEX idx_admin_sessions_expires ON admin_sessions(expires_at);
```

### worker_jobs

Jobs configurables depuis le back-office.

```sql
CREATE TABLE worker_jobs (
  id TEXT PRIMARY KEY,

  -- Identification
  name TEXT NOT NULL,                               -- Nom affiché
  worker_name TEXT NOT NULL,                        -- Nom technique du worker
  description TEXT,

  -- Planification
  cron_expression TEXT,                             -- "0 6 * * 1" = lundi 6h
  timezone TEXT DEFAULT 'Europe/Paris',

  -- Configuration
  config TEXT DEFAULT '{}',                         -- JSON paramètres
  timeout_ms INTEGER DEFAULT 30000,
  retry_count INTEGER DEFAULT 3,

  -- État
  is_active BOOLEAN DEFAULT TRUE,

  -- Dernière exécution
  last_run_at INTEGER,
  last_run_status TEXT,                             -- 'success', 'failure', 'timeout'
  last_run_duration_ms INTEGER,
  last_run_result TEXT,                             -- JSON
  last_error TEXT,

  -- Stats
  total_runs INTEGER DEFAULT 0,
  successful_runs INTEGER DEFAULT 0,
  failed_runs INTEGER DEFAULT 0,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_jobs_worker ON worker_jobs(worker_name);
CREATE INDEX idx_jobs_active ON worker_jobs(is_active);
```

### pseo_pages

Pages générées pour le SEO programmatique.

```sql
CREATE TABLE pseo_pages (
  id TEXT PRIMARY KEY,

  -- URL
  slug TEXT UNIQUE NOT NULL,                        -- "ironman-nice-2025"
  path TEXT NOT NULL,                               -- "/triathlon/ironman-nice-2025"

  -- Type
  page_type TEXT NOT NULL,                          -- 'distance', 'event', 'program', 'session', 'guide'

  -- SEO
  title TEXT NOT NULL,
  meta_description TEXT,
  meta_keywords TEXT,
  canonical_url TEXT,

  -- Contenu
  content TEXT NOT NULL,                            -- JSON structured content
  /*
  content = {
    "hero": { "title": "...", "subtitle": "..." },
    "sections": [
      { "type": "intro", "content": "..." },
      { "type": "program_overview", "data": {...} },
      ...
    ]
  }
  */

  -- Relations
  related_template_id TEXT REFERENCES templates(id),
  related_session_ids TEXT,                         -- JSON array

  -- État
  is_published BOOLEAN DEFAULT TRUE,
  last_generated_at INTEGER,
  generation_version INTEGER DEFAULT 1,

  -- Stats
  view_count INTEGER DEFAULT 0,

  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX idx_pseo_slug ON pseo_pages(slug);
CREATE INDEX idx_pseo_type ON pseo_pages(page_type);
CREATE INDEX idx_pseo_published ON pseo_pages(is_published);
```

---

## Migrations

### Migration 001 - Initial

```sql
-- migrations/001_initial.sql

-- Exécuter dans l'ordre les CREATE TABLE ci-dessus

-- Données initiales

-- Admin par défaut (à changer en prod)
INSERT INTO admins (id, email, password_hash, name, role) VALUES (
  'admin_001',
  'admin@triathlon-app.com',
  '$2b$10$...', -- bcrypt de 'changeme'
  'Admin',
  'super_admin'
);

-- Zones FC par défaut (template)
-- Seront copiées pour chaque user avec ses valeurs

-- Jobs par défaut
INSERT INTO worker_jobs (id, name, worker_name, cron_expression, description, is_active) VALUES
  ('job_recalc', 'Recalcul hebdomadaire', 'recalc-weekly', '0 6 * * 1', 'Recalcule les programmes chaque lundi à 6h', true),
  ('job_strava_batch', 'Sync Strava batch', 'strava-sync', '0 */4 * * *', 'Synchronise les activités Strava toutes les 4h', true),
  ('job_notif_daily', 'Notifications quotidiennes', 'notifications', '0 7 * * *', 'Envoie les rappels de séance à 7h', true),
  ('job_pseo_rebuild', 'Rebuild PSEO', 'pseo-builder', '0 3 * * 0', 'Régénère les pages SEO chaque dimanche', true),
  ('job_cleanup', 'Cleanup logs', 'cleanup', '0 2 1 * *', 'Nettoie les vieux logs chaque 1er du mois', true);
```

### Migration 002 - Seed templates

```sql
-- migrations/002_seed_templates.sql

-- Template Half Ironman 70.3 - Intermédiaire - 16 semaines
INSERT INTO templates (id, name, slug, distance_type, experience_level, duration_weeks, weekly_hours_min, weekly_hours_max, description, phases, week_templates, is_active) VALUES (
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
  true
);

-- Template Ironman - Intermédiaire - 24 semaines
INSERT INTO templates (id, name, slug, distance_type, experience_level, duration_weeks, weekly_hours_min, weekly_hours_max, description, phases, week_templates, is_active) VALUES (
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
  true
);
```

---

## Requêtes courantes

### Récupérer le programme actif d'un utilisateur

```sql
SELECT
  p.*,
  g.event_name,
  g.event_date,
  g.distance_type,
  t.name as template_name
FROM programs p
JOIN goals g ON p.goal_id = g.id
LEFT JOIN templates t ON p.template_id = t.id
WHERE p.user_id = ? AND p.status = 'active'
ORDER BY p.created_at DESC
LIMIT 1;
```

### Séances de la semaine courante

```sql
SELECT s.*
FROM sessions s
JOIN program_weeks pw ON s.program_week_id = pw.id
JOIN programs p ON pw.program_id = p.id
WHERE p.user_id = ?
  AND p.status = 'active'
  AND pw.status = 'current'
ORDER BY s.scheduled_date, s.order_in_day;
```

### Calcul compliance semaine

```sql
SELECT
  pw.id,
  pw.week_number,
  COUNT(CASE WHEN s.status = 'completed' THEN 1 END) * 100.0 / COUNT(*) as compliance_rate,
  SUM(CASE WHEN s.status = 'completed' THEN s.actual_duration ELSE 0 END) as actual_minutes,
  SUM(s.duration_planned) as planned_minutes
FROM program_weeks pw
JOIN sessions s ON s.program_week_id = pw.id
WHERE pw.id = ?
GROUP BY pw.id;
```

### Activités Strava non matchées

```sql
SELECT sa.*
FROM strava_activities sa
LEFT JOIN sessions s ON s.strava_activity_id = sa.strava_id
WHERE sa.user_id = ?
  AND s.id IS NULL
  AND sa.start_date >= ?
ORDER BY sa.start_date DESC;
```
