-- Migration 003: Personal Records and Training Zones
-- Additional tables for training personalization

-- Personal records table - stores athlete best times
CREATE TABLE IF NOT EXISTS personal_records (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport TEXT NOT NULL,
  distance TEXT NOT NULL,
  time_seconds INTEGER NOT NULL,
  source TEXT NOT NULL,
  strava_activity_id TEXT,
  activity_date INTEGER,
  notes TEXT,
  verified INTEGER DEFAULT 0,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch()),
  UNIQUE(user_id, sport, distance)
);

CREATE INDEX IF NOT EXISTS idx_pr_user ON personal_records(user_id);
CREATE INDEX IF NOT EXISTS idx_pr_sport ON personal_records(sport);

-- Training zones table - stores calculated pace/power zones
CREATE TABLE IF NOT EXISTS training_zones (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sport TEXT NOT NULL,
  based_on TEXT NOT NULL,
  zone_number INTEGER NOT NULL,
  zone_name TEXT NOT NULL,
  min_value INTEGER NOT NULL,
  max_value INTEGER NOT NULL,
  unit TEXT NOT NULL,
  description TEXT,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch()),
  UNIQUE(user_id, sport, zone_number)
);

CREATE INDEX IF NOT EXISTS idx_tz_user ON training_zones(user_id);
