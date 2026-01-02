# Database Schema

## Overview

TriTrainer uses **Cloudflare D1** (SQLite) as the database with **Drizzle ORM** for type-safe access. The schema is organized into logical modules for authentication, users, programs, pSEO, and integrations.

## Database Technology

- **Engine**: Cloudflare D1 (distributed SQLite)
- **ORM**: Drizzle ORM v0.45.1
- **Dialect**: SQLite
- **Location**: Edge (distributed replicas globally)
- **Size Limit**: 2GB per database

## Schema Modules

### 1. Authentication (`src/lib/db/schema/auth.ts`)

Better Auth tables for session management and magic link authentication.

#### **user_sessions**
User session tokens and metadata.

```sql
CREATE TABLE user_sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  expires_at INTEGER NOT NULL,
  ip_address TEXT,
  user_agent TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_user_sessions_user ON user_sessions(user_id);
CREATE UNIQUE INDEX idx_user_sessions_token ON user_sessions(token);
CREATE INDEX idx_user_sessions_expires ON user_sessions(expires_at);
```

**Fields**:
- `id`: Unique session identifier
- `user_id`: Reference to users table
- `token`: Session token (HTTP-only cookie value)
- `expires_at`: Session expiration timestamp (7 days default)
- `ip_address`: Client IP for security
- `user_agent`: Client browser/device
- `created_at`, `updated_at`: Timestamps

**Indexes**:
- User lookup for session validation
- Token lookup for authentication
- Expiration for cleanup queries

#### **verification**
Magic link tokens for passwordless authentication.

```sql
CREATE TABLE verification (
  id TEXT PRIMARY KEY,
  identifier TEXT NOT NULL,
  value TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_verification_identifier ON verification(identifier);
CREATE INDEX idx_verification_value ON verification(value);
CREATE INDEX idx_verification_expires ON verification(expires_at);
```

**Fields**:
- `id`: Token identifier
- `identifier`: Email address
- `value`: Verification token (sent in magic link)
- `expires_at`: Token expiration (5 minutes default)

**Usage**: Magic links for login

#### **accounts**
OAuth provider accounts (future: Strava, Google).

```sql
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  account_id TEXT NOT NULL,
  provider_id TEXT NOT NULL,
  access_token TEXT,
  refresh_token TEXT,
  access_token_expires_at INTEGER,
  scope TEXT,
  id_token TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_accounts_user ON accounts(user_id);
CREATE UNIQUE INDEX idx_accounts_provider ON accounts(provider_id, account_id);
```

**Fields**:
- `provider_id`: OAuth provider (e.g., "strava", "google")
- `account_id`: Provider-specific user ID
- `access_token`, `refresh_token`: OAuth tokens
- `scope`: OAuth permissions granted

**Future Use**: Strava OAuth integration

### 2. Users (`src/lib/db/schema/users.ts`)

User accounts and athlete profiles.

#### **users**
Core user account table.

```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  email_verified INTEGER DEFAULT 0,
  name TEXT,
  first_name TEXT,
  last_name TEXT,
  image TEXT,
  profile_picture TEXT,
  strava_id TEXT UNIQUE,
  strava_access_token TEXT,
  strava_refresh_token TEXT,
  strava_token_expires_at INTEGER,
  strava_connected INTEGER DEFAULT 0,
  onboarding_completed INTEGER DEFAULT 0,
  notification_token TEXT,
  notification_preferences TEXT DEFAULT '{}',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE UNIQUE INDEX idx_users_email ON users(email);
CREATE UNIQUE INDEX idx_users_strava_id ON users(strava_id);
CREATE INDEX idx_users_created_at ON users(created_at);
```

**Fields**:
- `id`: Unique user identifier (nanoid)
- `email`: User email (primary identifier)
- `email_verified`: Boolean (Better Auth)
- `name`, `first_name`, `last_name`: Display names
- `strava_*`: Strava integration fields
- `onboarding_completed`: Onboarding status
- `notification_preferences`: JSON notification settings

**Drizzle Type**:
```typescript
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
```

#### **athlete_profiles**
Extended athlete information (1:1 with users).

```sql
CREATE TABLE athlete_profiles (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  birth_year INTEGER,
  gender TEXT,
  weight_kg REAL,
  experience_level TEXT NOT NULL,
  triathlon_count INTEGER NOT NULL DEFAULT 0,
  longest_distance TEXT,
  weekly_hours_available INTEGER NOT NULL,
  unavailable_days TEXT NOT NULL DEFAULT '[]',
  pool_access INTEGER NOT NULL DEFAULT 1,
  pool_schedule TEXT,
  home_trainer INTEGER NOT NULL DEFAULT 0,
  outdoor_bike_only INTEGER NOT NULL DEFAULT 0,
  injuries_notes TEXT,
  fc_max INTEGER,
  fc_max_source TEXT,
  fc_rest INTEGER,
  ftp INTEGER,
  ftp_source TEXT,
  css INTEGER,
  run_threshold_pace INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_athlete_profiles_user ON athlete_profiles(user_id);
```

**Fields**:
- `experience_level`: "beginner", "intermediate", "advanced"
- `triathlon_count`: Number of completed triathlons
- `weekly_hours_available`: Training hours per week
- `unavailable_days`: JSON array of unavailable weekdays
- `pool_access`, `pool_schedule`: Swimming constraints
- `fc_max`: Maximum heart rate
- `ftp`: Functional Threshold Power (cycling)
- `css`: Critical Swim Speed
- `run_threshold_pace`: Running threshold pace

**Drizzle Type**:
```typescript
export type AthleteProfile = typeof athleteProfiles.$inferSelect;
```

#### **heart_rate_zones**
User-specific heart rate training zones.

```sql
CREATE TABLE heart_rate_zones (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  zone_number INTEGER NOT NULL,
  name TEXT NOT NULL,
  min_hr INTEGER NOT NULL,
  max_hr INTEGER NOT NULL,
  description TEXT,
  color TEXT,
  source TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_hr_zones_user ON heart_rate_zones(user_id);
CREATE UNIQUE INDEX idx_hr_zones_user_zone ON heart_rate_zones(user_id, zone_number);
```

**Fields**:
- `zone_number`: 1-5 (Z1 recovery to Z5 max)
- `name`: Zone name (e.g., "Endurance", "Threshold")
- `min_hr`, `max_hr`: Heart rate range
- `source`: "calculated", "manual", "test"
- `color`: UI color for zone display

### 3. Programs (`src/lib/db/schema/programs.ts`)

Training programs, weeks, and sessions.

#### **programs**
User's training programs (12-24 week plans).

```sql
CREATE TABLE programs (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  goal_id TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
  template_id TEXT REFERENCES templates(id),
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  total_weeks INTEGER NOT NULL,
  current_week INTEGER NOT NULL DEFAULT 1,
  current_phase TEXT,
  weekly_hours_target REAL,
  customizations TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  last_recalc_at INTEGER,
  recalc_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_programs_user ON programs(user_id);
CREATE INDEX idx_programs_goal ON programs(goal_id);
CREATE INDEX idx_programs_status ON programs(status);
```

**Fields**:
- `goal_id`: Reference to target race/goal
- `template_id`: Base template (if used)
- `current_week`: Active week number (1-24)
- `current_phase`: "base", "build", "peak", "taper", "race"
- `status`: "active", "completed", "cancelled", "paused"
- `customizations`: JSON program adjustments
- `recalc_count`: Number of adaptive recalculations

**Program Phases**:
1. **Base** (30-40%): Aerobic foundation, technique
2. **Build** (30-40%): Intensity, race-specific training
3. **Peak** (15-20%): Maximum load, high intensity
4. **Taper** (5-10%): Recovery, race preparation
5. **Race**: Competition week

#### **program_weeks**
Weekly structure and volume tracking.

```sql
CREATE TABLE program_weeks (
  id TEXT PRIMARY KEY,
  program_id TEXT NOT NULL REFERENCES programs(id) ON DELETE CASCADE,
  week_number INTEGER NOT NULL,
  start_date INTEGER NOT NULL,
  end_date INTEGER NOT NULL,
  phase TEXT NOT NULL,
  planned_volume_swim INTEGER NOT NULL DEFAULT 0,
  planned_volume_bike INTEGER NOT NULL DEFAULT 0,
  planned_volume_run INTEGER NOT NULL DEFAULT 0,
  planned_hours REAL NOT NULL DEFAULT 0,
  planned_sessions INTEGER NOT NULL DEFAULT 0,
  actual_volume_swim INTEGER NOT NULL DEFAULT 0,
  actual_volume_bike INTEGER NOT NULL DEFAULT 0,
  actual_volume_run INTEGER NOT NULL DEFAULT 0,
  actual_hours REAL NOT NULL DEFAULT 0,
  actual_sessions INTEGER NOT NULL DEFAULT 0,
  compliance_rate REAL,
  load_score REAL,
  fatigue_indicator TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  recalc_notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_weeks_program ON program_weeks(program_id);
CREATE INDEX idx_weeks_status ON program_weeks(status);
CREATE UNIQUE INDEX idx_weeks_program_number ON program_weeks(program_id, week_number);
```

**Fields**:
- `week_number`: 1-based week index
- `phase`: Training phase for this week
- `planned_volume_*`: Planned volume in meters/km
- `actual_volume_*`: Completed volume (from Strava)
- `compliance_rate`: % of sessions completed
- `load_score`: Training stress score
- `status`: "pending", "in_progress", "completed"

#### **sessions**
Individual training sessions (workouts).

```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  program_week_id TEXT NOT NULL REFERENCES program_weeks(id) ON DELETE CASCADE,
  session_template_id TEXT REFERENCES session_templates(id),
  day_of_week INTEGER NOT NULL,
  scheduled_date INTEGER NOT NULL,
  order_in_day INTEGER NOT NULL DEFAULT 1,
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
  status TEXT NOT NULL DEFAULT 'pending',
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
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE INDEX idx_sessions_week ON sessions(program_week_id);
CREATE INDEX idx_sessions_date ON sessions(scheduled_date);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_sport ON sessions(sport);
CREATE INDEX idx_sessions_strava ON sessions(strava_activity_id);
```

**Fields**:
- `sport`: "swim", "bike", "run", "strength", "brick"
- `session_type`: "endurance", "intervals", "threshold", "recovery"
- `day_of_week`: 0-6 (Sunday-Saturday)
- `hr_zones`, `power_target`, `pace_target`: JSON training zones
- `workout_details`: JSON structured workout
- `status`: "pending", "completed", "skipped", "partial"
- `strava_activity_id`: Linked Strava activity
- `perceived_effort`: 1-10 RPE scale

**JSON Workout Structure**:
```json
{
  "warmup": { "duration": 10, "intensity": "easy" },
  "main": [
    { "type": "interval", "repeat": 6, "duration": 5, "intensity": "z4", "rest": 2 }
  ],
  "cooldown": { "duration": 10, "intensity": "easy" }
}
```

### 4. pSEO (`src/lib/db/schema/pseo.ts`)

Programmatic SEO page metadata and configuration.

#### **pseo_pages**
SEO-optimized content pages.

```sql
CREATE TABLE pseo_pages (
  id TEXT PRIMARY KEY,
  cluster_type TEXT NOT NULL,
  url_path TEXT NOT NULL UNIQUE,
  parent_path TEXT,
  title TEXT NOT NULL,
  meta_description TEXT NOT NULL,
  h1 TEXT NOT NULL,
  primary_keyword TEXT NOT NULL,
  secondary_keywords TEXT,
  quick_answer TEXT,
  intro_text TEXT,
  llm_content TEXT,
  schemas TEXT,
  variables TEXT,
  sitemap_batch INTEGER DEFAULT 1,
  rollout_date INTEGER,
  priority REAL DEFAULT 0.5,
  changefreq TEXT DEFAULT 'monthly',
  status TEXT NOT NULL DEFAULT 'pending',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  published_at INTEGER
);

CREATE INDEX idx_pseo_pages_cluster ON pseo_pages(cluster_type);
CREATE INDEX idx_pseo_pages_status ON pseo_pages(status);
CREATE INDEX idx_pseo_pages_batch ON pseo_pages(sitemap_batch);
CREATE UNIQUE INDEX idx_pseo_pages_url ON pseo_pages(url_path);
```

**Fields**:
- `cluster_type`: "training-plan", "discipline-guide", "race-prep", "equipment"
- `url_path`: Full URL path (e.g., "/training-plans/sprint/debutant")
- `parent_path`: Hierarchical parent (e.g., "/training-plans/sprint")
- `primary_keyword`: Main SEO keyword
- `secondary_keywords`: JSON array of related keywords
- `llm_content`: JSON structured content (FAQs, sections, tips)
- `schemas`: JSON Schema.org structured data
- `variables`: JSON page-specific variables
- `status`: "pending", "active", "paused", "archived"
- `sitemap_batch`: Rollout batch number
- `priority`, `changefreq`: Sitemap settings

**Page Lifecycle**:
1. **pending**: Page generated but blocked (404)
2. **active**: Page accessible and indexable
3. **paused**: Temporarily disabled (maintenance)
4. **archived**: Permanently disabled (deprecated)

**Cluster Types**:
```typescript
const PSEO_CLUSTER_TYPES = {
  TRAINING_PLAN: "training-plan",
  TRAINING_PLAN_LEVEL: "training-plan-level",
  DISCIPLINE_GUIDE: "discipline-guide",
  RACE_PREP: "race-prep",
  EQUIPMENT: "equipment",
  NUTRITION: "nutrition",
};
```

#### **pseo_config**
Global pSEO rollout configuration (singleton table).

```sql
CREATE TABLE pseo_config (
  id INTEGER PRIMARY KEY DEFAULT 1,
  batch_size INTEGER DEFAULT 50,
  days_between_batches INTEGER DEFAULT 3,
  is_paused INTEGER DEFAULT 0,
  default_og_image TEXT,
  site_name TEXT DEFAULT 'TriTrainer',
  base_url TEXT DEFAULT 'https://tritrainer.com',
  updated_at INTEGER NOT NULL
);
```

**Fields**:
- `batch_size`: Pages per rollout batch
- `days_between_batches`: Rollout interval
- `is_paused`: Global rollout pause flag
- `default_og_image`: Default Open Graph image

#### **pseo_links**
Internal linking between pSEO pages.

```sql
CREATE TABLE pseo_links (
  id TEXT PRIMARY KEY,
  source_page_id TEXT NOT NULL REFERENCES pseo_pages(id) ON DELETE CASCADE,
  target_page_id TEXT NOT NULL REFERENCES pseo_pages(id) ON DELETE CASCADE,
  link_type TEXT NOT NULL,
  anchor_text TEXT,
  priority INTEGER DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_pseo_links_source ON pseo_links(source_page_id);
CREATE INDEX idx_pseo_links_target ON pseo_links(target_page_id);
```

**Fields**:
- `link_type`: "related", "parent", "child", "see-also"
- `anchor_text`: Custom link text (optional)
- `priority`: Link ordering for display

## Relationships Diagram

```
users
  ├─> athlete_profiles (1:1)
  ├─> heart_rate_zones (1:many)
  ├─> user_sessions (1:many)
  ├─> accounts (1:many, OAuth)
  ├─> programs (1:many)
  └─> goals (1:many)

programs
  ├─> program_weeks (1:many)
  └─> goal (many:1)

program_weeks
  ├─> sessions (1:many)
  └─> program (many:1)

sessions
  ├─> program_week (many:1)
  ├─> session_template (many:1, optional)
  └─> strava_activity (1:1, via strava_activity_id)

pseo_pages
  ├─> pseo_links (1:many, source)
  ├─> pseo_links (1:many, target)
  └─> parent_page (self-referential via parent_path)
```

## Type Safety with Drizzle

### Inferring Types

```typescript
import { users, athleteProfiles } from '@/lib/db/schema';

// Infer select type (database → TypeScript)
type User = typeof users.$inferSelect;

// Infer insert type (TypeScript → database)
type NewUser = typeof users.$inferInsert;

// Usage
const user: User = await db.select().from(users).where(eq(users.id, userId));
const newUser: NewUser = {
  id: nanoid(),
  email: 'user@example.com',
  createdAt: new Date(),
  updatedAt: new Date(),
};
```

### Relations

```typescript
import { relations } from 'drizzle-orm';

export const usersRelations = relations(users, ({ one, many }) => ({
  athleteProfile: one(athleteProfiles, {
    fields: [users.id],
    references: [athleteProfiles.userId],
  }),
  programs: many(programs),
  sessions: many(userSessions),
}));
```

## Migration Strategy

### Migration Files

Migrations located in `migrations/`:

```
migrations/
├── 0001_create_users.sql
├── 0002_seed_data.sql
├── 0003_create_programs.sql
├── 0004_create_sessions.sql
├── 0005_pseo_tables.sql
└── 0006_pseo_seed.sql
```

### Applying Migrations

```bash
# Local development (better-sqlite3)
npm run db:migrate:local

# Remote D1
npx wrangler d1 execute triathlon-db --remote --file migrations/0001_create_users.sql
```

### Generate Migrations

```bash
# Generate migration from schema changes
npx drizzle-kit generate:sqlite --schema=./src/lib/db/schema/*
```

## Indexes Strategy

### Primary Indexes
- All `id` fields are primary keys
- Unique constraints on email, strava_id, url_path

### Performance Indexes
- Foreign keys for JOIN operations
- Date fields for range queries
- Status fields for filtering
- Composite indexes for common query patterns

### Index Naming Convention

```
idx_{table}_{field}           # Single field
idx_{table}_{field1}_{field2} # Composite
```

## Data Retention

### Active Data
- Users, profiles, programs: Indefinite
- Sessions (upcoming): 1 year
- Sessions (past): Indefinite (training history)

### Cleanup Queries

```sql
-- Expired sessions (run daily)
DELETE FROM user_sessions WHERE expires_at < unixepoch();

-- Expired verification tokens (run daily)
DELETE FROM verification WHERE expires_at < unixepoch();

-- Old programs (optional, run monthly)
DELETE FROM programs
WHERE status = 'cancelled'
AND updated_at < unixepoch() - (365 * 24 * 60 * 60); -- 1 year old
```

## Performance Considerations

### Query Optimization
- Use indexes for WHERE, JOIN, ORDER BY
- Limit result sets with LIMIT
- Avoid SELECT * (specify columns)
- Use prepared statements (Drizzle handles this)

### Typical Query Times (D1)
- Indexed lookup: <1ms
- Simple JOIN (2 tables): <5ms
- Complex query (3+ tables): <10ms
- Full table scan (10k rows): <50ms

## Backup and Recovery

### Export Database

```bash
# Export to SQL
npx wrangler d1 export triathlon-db --remote --output backup.sql

# Export to local SQLite
npx wrangler d1 export triathlon-db --remote --no-schema --output data.sql
```

### Import/Restore

```bash
# Import SQL file
npx wrangler d1 execute triathlon-db --remote --file backup.sql
```

## Related Documentation

- [ADR-003: D1 Database with Drizzle ORM](../adr/003-d1-database-drizzle-orm.md)
- [ADR-004: pSEO Database-Driven Rollout](../adr/004-pseo-database-driven-rollout.md)
- [ADR-006: Better Auth for Authentication](../adr/006-better-auth-authentication.md)
- [Migration Guide](../guides/migrations.md)
