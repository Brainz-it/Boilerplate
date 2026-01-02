-- Migration 001: Initial Schema
-- TriathlonApp Database Schema for Cloudflare D1

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  strava_id TEXT UNIQUE NOT NULL,
  email TEXT,
  first_name TEXT,
  last_name TEXT,
  profile_picture TEXT,
  strava_access_token TEXT,
  strava_refresh_token TEXT,
  strava_token_expires_at INTEGER,
  onboarding_completed INTEGER DEFAULT 0,
  notification_token TEXT,
  notification_preferences TEXT DEFAULT '{}',
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_users_strava_id ON users(strava_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- Athlete profiles table
CREATE TABLE IF NOT EXISTS athlete_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  birth_year INTEGER,
  gender TEXT,
  weight_kg REAL,
  experience_level TEXT NOT NULL,
  triathlon_count INTEGER DEFAULT 0,
  longest_distance TEXT,
  weekly_hours_available INTEGER NOT NULL,
  unavailable_days TEXT DEFAULT '[]',
  pool_access INTEGER DEFAULT 1,
  pool_schedule TEXT,
  home_trainer INTEGER DEFAULT 0,
  outdoor_bike_only INTEGER DEFAULT 0,
  injuries_notes TEXT,
  fc_max INTEGER,
  fc_max_source TEXT,
  fc_rest INTEGER,
  ftp INTEGER,
  ftp_source TEXT,
  css INTEGER,
  run_threshold_pace INTEGER,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch()),
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_athlete_profiles_user ON athlete_profiles(user_id);

-- Heart rate zones table
CREATE TABLE IF NOT EXISTS heart_rate_zones (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  zone_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  min_hr INTEGER NOT NULL,
  max_hr INTEGER NOT NULL,
  description TEXT,
  color TEXT,
  source TEXT NOT NULL,
  created_at INTEGER DEFAULT (unixepoch()),
  UNIQUE(user_id, zone_number)
);

CREATE INDEX IF NOT EXISTS idx_hr_zones_user ON heart_rate_zones(user_id);

-- Goals table
CREATE TABLE IF NOT EXISTS goals (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event_name TEXT NOT NULL,
  event_date INTEGER NOT NULL,
  event_location TEXT,
  event_url TEXT,
  distance_type TEXT NOT NULL,
  target_time INTEGER,
  priority TEXT DEFAULT 'primary',
  status TEXT DEFAULT 'active',
  completion_time INTEGER,
  completion_notes TEXT,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_goals_user ON goals(user_id);
CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);
CREATE INDEX IF NOT EXISTS idx_goals_event_date ON goals(event_date);

-- Templates table
CREATE TABLE IF NOT EXISTS templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  distance_type TEXT NOT NULL,
  experience_level TEXT NOT NULL,
  duration_weeks INTEGER NOT NULL,
  weekly_hours_min INTEGER NOT NULL,
  weekly_hours_max INTEGER NOT NULL,
  description TEXT,
  phases TEXT NOT NULL,
  week_templates TEXT NOT NULL,
  is_active INTEGER DEFAULT 1,
  version INTEGER DEFAULT 1,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_templates_distance ON templates(distance_type);
CREATE INDEX IF NOT EXISTS idx_templates_level ON templates(experience_level);
CREATE INDEX IF NOT EXISTS idx_templates_active ON templates(is_active);

-- Session templates table
CREATE TABLE IF NOT EXISTS session_templates (
  id TEXT PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  sport TEXT NOT NULL,
  session_type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  objective TEXT NOT NULL,
  tips TEXT,
  base_duration INTEGER NOT NULL,
  duration_scaling TEXT,
  difficulty_level INTEGER DEFAULT 3,
  hr_zones TEXT,
  power_zones TEXT,
  pace_zones TEXT,
  workout_structure TEXT NOT NULL,
  tags TEXT,
  suitable_for TEXT DEFAULT '["all"]',
  is_active INTEGER DEFAULT 1,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_session_tpl_sport ON session_templates(sport);
CREATE INDEX IF NOT EXISTS idx_session_tpl_type ON session_templates(session_type);
CREATE INDEX IF NOT EXISTS idx_session_tpl_code ON session_templates(code);

-- Programs table
CREATE TABLE IF NOT EXISTS programs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_id TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  template_id TEXT REFERENCES templates(id),
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  total_weeks INTEGER NOT NULL,
  current_week INTEGER DEFAULT 1,
  current_phase TEXT,
  weekly_hours_target REAL,
  customizations TEXT,
  status TEXT DEFAULT 'active',
  last_recalc_at INTEGER,
  recalc_count INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_programs_user ON programs(user_id);
CREATE INDEX IF NOT EXISTS idx_programs_goal ON programs(goal_id);
CREATE INDEX IF NOT EXISTS idx_programs_status ON programs(status);

-- Program weeks table
CREATE TABLE IF NOT EXISTS program_weeks (
  id TEXT PRIMARY KEY,
  program_id TEXT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  week_number INTEGER NOT NULL,
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  phase TEXT NOT NULL,
  planned_volume_swim INTEGER DEFAULT 0,
  planned_volume_bike INTEGER DEFAULT 0,
  planned_volume_run INTEGER DEFAULT 0,
  planned_hours REAL DEFAULT 0,
  planned_sessions INTEGER DEFAULT 0,
  actual_volume_swim INTEGER DEFAULT 0,
  actual_volume_bike INTEGER DEFAULT 0,
  actual_volume_run INTEGER DEFAULT 0,
  actual_hours REAL DEFAULT 0,
  actual_sessions INTEGER DEFAULT 0,
  compliance_rate REAL,
  load_score REAL,
  fatigue_indicator TEXT,
  status TEXT DEFAULT 'pending',
  recalc_notes TEXT,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch()),
  UNIQUE(program_id, week_number)
);

CREATE INDEX IF NOT EXISTS idx_weeks_program ON program_weeks(program_id);
CREATE INDEX IF NOT EXISTS idx_weeks_status ON program_weeks(status);
CREATE INDEX IF NOT EXISTS idx_weeks_dates ON program_weeks(start_date, end_date);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,
  program_week_id TEXT NOT NULL REFERENCES program_weeks(id) ON DELETE CASCADE,
  session_template_id TEXT REFERENCES session_templates(id),
  day_of_week INTEGER NOT NULL,
  scheduled_date INTEGER NOT NULL,
  order_in_day INTEGER DEFAULT 1,
  sport TEXT NOT NULL,
  session_type TEXT,
  title TEXT NOT NULL,
  description TEXT,
  objective TEXT,
  tips TEXT,
  duration_planned INTEGER,
  distance_planned INTEGER,
  hr_zones TEXT,
  power_target TEXT,
  pace_target TEXT,
  workout_details TEXT,
  status TEXT DEFAULT 'pending',
  strava_activity_id TEXT,
  actual_duration INTEGER,
  actual_distance INTEGER,
  actual_avg_hr INTEGER,
  actual_max_hr INTEGER,
  actual_avg_power INTEGER,
  actual_tss REAL,
  perceived_effort INTEGER,
  completion_notes TEXT,
  completed_at INTEGER,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_sessions_week ON sessions(program_week_id);
CREATE INDEX IF NOT EXISTS idx_sessions_date ON sessions(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON sessions(status);
CREATE INDEX IF NOT EXISTS idx_sessions_sport ON sessions(sport);
CREATE INDEX IF NOT EXISTS idx_sessions_strava ON sessions(strava_activity_id);

-- Strava activities table
CREATE TABLE IF NOT EXISTS strava_activities (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  strava_id TEXT UNIQUE NOT NULL,
  sport_type TEXT NOT NULL,
  name TEXT,
  description TEXT,
  start_date INTEGER NOT NULL,
  start_date_local TEXT,
  timezone TEXT,
  elapsed_time INTEGER,
  moving_time INTEGER,
  distance REAL,
  average_speed REAL,
  max_speed REAL,
  average_heartrate REAL,
  max_heartrate REAL,
  has_heartrate INTEGER DEFAULT 0,
  average_watts REAL,
  max_watts REAL,
  weighted_average_watts REAL,
  kilojoules REAL,
  device_watts INTEGER DEFAULT 0,
  total_elevation_gain REAL,
  elev_high REAL,
  elev_low REAL,
  average_cadence REAL,
  suffer_score INTEGER,
  calories INTEGER,
  gear_id TEXT,
  trainer INTEGER DEFAULT 0,
  commute INTEGER DEFAULT 0,
  raw_data TEXT,
  synced_at INTEGER DEFAULT (unixepoch()),
  UNIQUE(user_id, strava_id)
);

CREATE INDEX IF NOT EXISTS idx_strava_user ON strava_activities(user_id);
CREATE INDEX IF NOT EXISTS idx_strava_date ON strava_activities(start_date);
CREATE INDEX IF NOT EXISTS idx_strava_sport ON strava_activities(sport_type);
CREATE INDEX IF NOT EXISTS idx_strava_strava_id ON strava_activities(strava_id);

-- Audit logs table
CREATE TABLE IF NOT EXISTS audit_logs (
  id TEXT PRIMARY KEY,
  timestamp INTEGER DEFAULT (unixepoch()),
  event_type TEXT NOT NULL,
  event_category TEXT,
  entity_type TEXT,
  entity_id TEXT,
  actor_type TEXT NOT NULL,
  actor_id TEXT,
  payload TEXT,
  changes TEXT,
  trigger_worker TEXT,
  worker_status TEXT,
  worker_triggered_at INTEGER,
  worker_completed_at INTEGER,
  worker_result TEXT,
  worker_error TEXT,
  ip_address TEXT,
  user_agent TEXT,
  request_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON audit_logs(timestamp);
CREATE INDEX IF NOT EXISTS idx_audit_event ON audit_logs(event_type);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_actor ON audit_logs(actor_type, actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_worker ON audit_logs(trigger_worker, worker_status);

-- Admins table
CREATE TABLE IF NOT EXISTS admins (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'admin',
  avatar TEXT,
  is_active INTEGER DEFAULT 1,
  last_login_at INTEGER,
  failed_login_attempts INTEGER DEFAULT 0,
  locked_until INTEGER,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_admins_email ON admins(email);

-- Admin sessions table
CREATE TABLE IF NOT EXISTS admin_sessions (
  id TEXT PRIMARY KEY,
  admin_id TEXT NOT NULL REFERENCES admins(id) ON DELETE CASCADE,
  expires_at INTEGER NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_admin_sessions_admin ON admin_sessions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_expires ON admin_sessions(expires_at);

-- Worker jobs table
CREATE TABLE IF NOT EXISTS worker_jobs (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  worker_name TEXT NOT NULL,
  description TEXT,
  cron_expression TEXT,
  timezone TEXT DEFAULT 'Europe/Paris',
  config TEXT DEFAULT '{}',
  timeout_ms INTEGER DEFAULT 30000,
  retry_count INTEGER DEFAULT 3,
  is_active INTEGER DEFAULT 1,
  last_run_at INTEGER,
  last_run_status TEXT,
  last_run_duration_ms INTEGER,
  last_run_result TEXT,
  last_error TEXT,
  total_runs INTEGER DEFAULT 0,
  successful_runs INTEGER DEFAULT 0,
  failed_runs INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_jobs_worker ON worker_jobs(worker_name);
CREATE INDEX IF NOT EXISTS idx_jobs_active ON worker_jobs(is_active);

-- PSEO pages table
CREATE TABLE IF NOT EXISTS pseo_pages (
  id TEXT PRIMARY KEY,
  slug TEXT UNIQUE NOT NULL,
  path TEXT NOT NULL,
  page_type TEXT NOT NULL,
  title TEXT NOT NULL,
  meta_description TEXT,
  meta_keywords TEXT,
  canonical_url TEXT,
  content TEXT NOT NULL,
  related_template_id TEXT REFERENCES templates(id),
  related_session_ids TEXT,
  is_published INTEGER DEFAULT 1,
  last_generated_at INTEGER,
  generation_version INTEGER DEFAULT 1,
  view_count INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_pseo_slug ON pseo_pages(slug);
CREATE INDEX IF NOT EXISTS idx_pseo_type ON pseo_pages(page_type);
CREATE INDEX IF NOT EXISTS idx_pseo_published ON pseo_pages(is_published);
