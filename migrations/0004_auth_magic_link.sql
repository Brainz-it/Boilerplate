-- Migration 004: Magic Link Authentication with Better Auth
-- Makes Strava optional and adds email-based authentication

-- =============================================================================
-- STEP 1: Recreate users table with strava_id as optional
-- =============================================================================

-- Create new users table with nullable strava_id
CREATE TABLE IF NOT EXISTS users_new (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  email_verified INTEGER DEFAULT 0,
  name TEXT,
  first_name TEXT,
  last_name TEXT,
  image TEXT,
  profile_picture TEXT,
  -- Strava fields (now optional)
  strava_id TEXT UNIQUE,
  strava_access_token TEXT,
  strava_refresh_token TEXT,
  strava_token_expires_at INTEGER,
  strava_connected INTEGER DEFAULT 0,
  -- App-specific fields
  onboarding_completed INTEGER DEFAULT 0,
  notification_token TEXT,
  notification_preferences TEXT DEFAULT '{}',
  -- Timestamps
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

-- Copy data from old users table if it exists
INSERT OR IGNORE INTO users_new (
  id, email, email_verified, name, first_name, last_name,
  profile_picture, image, strava_id, strava_access_token,
  strava_refresh_token, strava_token_expires_at, strava_connected,
  onboarding_completed, notification_token, notification_preferences,
  created_at, updated_at
)
SELECT
  id,
  COALESCE(email, strava_id || '@strava.local'),
  0,
  COALESCE(first_name || ' ' || last_name, first_name, last_name),
  first_name,
  last_name,
  profile_picture,
  profile_picture,
  strava_id,
  strava_access_token,
  strava_refresh_token,
  strava_token_expires_at,
  1,
  onboarding_completed,
  notification_token,
  notification_preferences,
  created_at,
  updated_at
FROM users;

-- Drop old table and rename new one
DROP TABLE IF EXISTS users;
ALTER TABLE users_new RENAME TO users;

-- Recreate indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_strava_id ON users(strava_id);
CREATE INDEX IF NOT EXISTS idx_users_created_at ON users(created_at);

-- =============================================================================
-- STEP 2: Create Better Auth sessions table (user_sessions to avoid conflict)
-- =============================================================================

CREATE TABLE IF NOT EXISTS user_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at INTEGER NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(token);
CREATE INDEX IF NOT EXISTS idx_user_sessions_expires ON user_sessions(expires_at);

-- =============================================================================
-- STEP 3: Create verification table for magic links
-- =============================================================================

CREATE TABLE IF NOT EXISTS verification (
  id TEXT PRIMARY KEY,
  identifier TEXT NOT NULL,
  value TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_verification_identifier ON verification(identifier);
CREATE INDEX IF NOT EXISTS idx_verification_value ON verification(value);
CREATE INDEX IF NOT EXISTS idx_verification_expires ON verification(expires_at);

-- =============================================================================
-- STEP 4: Create accounts table for OAuth providers (Strava, etc.)
-- =============================================================================

CREATE TABLE IF NOT EXISTS accounts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  account_id TEXT NOT NULL,
  provider_id TEXT NOT NULL,
  access_token TEXT,
  refresh_token TEXT,
  access_token_expires_at INTEGER,
  scope TEXT,
  id_token TEXT,
  created_at INTEGER DEFAULT (unixepoch()),
  updated_at INTEGER DEFAULT (unixepoch()),
  UNIQUE(provider_id, account_id)
);

CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_provider ON accounts(provider_id, account_id);
