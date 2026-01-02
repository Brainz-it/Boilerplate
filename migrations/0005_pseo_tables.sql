-- Migration: pSEO Tables
-- Description: Create tables for programmatic SEO (pSEO) content management
-- Date: 2024-12-31

-- ============================================================================
-- pSEO PAGES TABLE
-- Main table for storing all pSEO page content and metadata
-- ============================================================================

CREATE TABLE IF NOT EXISTS pseo_pages (
  id TEXT PRIMARY KEY,

  -- Cluster & URL
  cluster_type TEXT NOT NULL,
  url_path TEXT NOT NULL UNIQUE,
  parent_path TEXT,

  -- SEO Metadata
  title TEXT NOT NULL,
  meta_description TEXT NOT NULL,
  h1 TEXT NOT NULL,
  primary_keyword TEXT NOT NULL,
  secondary_keywords TEXT, -- JSON array

  -- Content
  quick_answer TEXT,
  intro_text TEXT,
  llm_content TEXT, -- JSON: { faqs, sections, tables, tips }

  -- Structured Data (Schema.org)
  schemas TEXT, -- JSON: Article, HowTo, FAQPage, etc.

  -- Page Variables (for template rendering)
  variables TEXT, -- JSON: { distance, level, weeks, volume, etc. }

  -- Sitemap & Rollout
  sitemap_batch INTEGER DEFAULT 1,
  rollout_date INTEGER,
  priority REAL DEFAULT 0.5,
  changefreq TEXT DEFAULT 'monthly',

  -- Status
  status TEXT NOT NULL DEFAULT 'pending',

  -- Timestamps
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  published_at INTEGER
);

-- Indexes for pseo_pages
CREATE INDEX IF NOT EXISTS idx_pseo_pages_cluster ON pseo_pages(cluster_type);
CREATE INDEX IF NOT EXISTS idx_pseo_pages_status ON pseo_pages(status);
CREATE INDEX IF NOT EXISTS idx_pseo_pages_batch ON pseo_pages(sitemap_batch);
CREATE INDEX IF NOT EXISTS idx_pseo_pages_parent ON pseo_pages(parent_path);
CREATE UNIQUE INDEX IF NOT EXISTS idx_pseo_pages_url ON pseo_pages(url_path);

-- ============================================================================
-- pSEO CONFIGURATION TABLE
-- Global settings for pSEO rollout and defaults
-- ============================================================================

CREATE TABLE IF NOT EXISTS pseo_config (
  id INTEGER PRIMARY KEY DEFAULT 1,

  -- Rollout Settings
  batch_size INTEGER DEFAULT 50,
  days_between_batches INTEGER DEFAULT 3,
  is_paused INTEGER DEFAULT 0,

  -- Default SEO
  default_og_image TEXT,
  site_name TEXT DEFAULT 'TriTrainer',
  base_url TEXT DEFAULT 'https://tritrainer.com',

  -- Timestamps
  updated_at INTEGER NOT NULL
);

-- Insert default config
INSERT OR IGNORE INTO pseo_config (id, updated_at) VALUES (1, strftime('%s', 'now'));

-- ============================================================================
-- pSEO INTERNAL LINKS TABLE
-- For managing related pages and internal link structure
-- ============================================================================

CREATE TABLE IF NOT EXISTS pseo_links (
  id TEXT PRIMARY KEY,

  source_page_id TEXT NOT NULL REFERENCES pseo_pages(id) ON DELETE CASCADE,
  target_page_id TEXT NOT NULL REFERENCES pseo_pages(id) ON DELETE CASCADE,

  link_type TEXT NOT NULL, -- related, parent, child, see-also
  anchor_text TEXT,
  priority INTEGER DEFAULT 0,

  created_at INTEGER NOT NULL
);

-- Indexes for pseo_links
CREATE INDEX IF NOT EXISTS idx_pseo_links_source ON pseo_links(source_page_id);
CREATE INDEX IF NOT EXISTS idx_pseo_links_target ON pseo_links(target_page_id);

-- ============================================================================
-- SAMPLE DATA: Seed initial pSEO pages for training plans
-- ============================================================================

-- Training Plans Pillar Page
INSERT OR IGNORE INTO pseo_pages (
  id, cluster_type, url_path, title, meta_description, h1, primary_keyword,
  secondary_keywords, quick_answer, status, created_at, updated_at, priority, changefreq
) VALUES (
  'pseo_training_plans_pillar',
  'training-plan',
  '/training-plans',
  'Plans Entrainement Triathlon | Sprint, Olympic, 70.3, Ironman',
  'Decouvrez nos plans entrainement triathlon adaptes a votre niveau. Sprint, Olympic, Half Ironman, Ironman - programmes complets de 12 a 30 semaines.',
  'Plans Entrainement Triathlon',
  'plan entrainement triathlon',
  '["programme triathlon", "entrainement triathlon debutant", "plan ironman", "preparation triathlon"]',
  'Choisissez votre distance (Sprint, Olympic, 70.3 ou Ironman) et votre niveau pour obtenir un plan personnalise de 12 a 30 semaines.',
  'active',
  strftime('%s', 'now'),
  strftime('%s', 'now'),
  1.0,
  'weekly'
);

-- Sprint Distance Hub Page
INSERT OR IGNORE INTO pseo_pages (
  id, cluster_type, url_path, parent_path, title, meta_description, h1, primary_keyword,
  secondary_keywords, variables, status, created_at, updated_at, priority
) VALUES (
  'pseo_sprint_hub',
  'training-plan',
  '/training-plans/sprint',
  '/training-plans',
  'Plan Entrainement Sprint Triathlon 12 Semaines | TriTrainer',
  'Plan sprint triathlon complet: 750m natation, 20km velo, 5km course. Programme 12 semaines pour debutants et intermediaires.',
  'Plan Entrainement Sprint Triathlon',
  'plan sprint triathlon',
  '["entrainement sprint triathlon", "preparation sprint triathlon", "programme triathlon 12 semaines"]',
  '{"distance": {"name": "Sprint", "slug": "sprint", "swim": 750, "bike": 20, "run": 5}, "duration": {"weeks": 12, "hoursPerWeek": {"min": 4, "max": 8}}}',
  'active',
  strftime('%s', 'now'),
  strftime('%s', 'now'),
  0.9
);

-- Olympic Distance Hub Page
INSERT OR IGNORE INTO pseo_pages (
  id, cluster_type, url_path, parent_path, title, meta_description, h1, primary_keyword,
  secondary_keywords, variables, status, created_at, updated_at, priority
) VALUES (
  'pseo_olympic_hub',
  'training-plan',
  '/training-plans/olympic',
  '/training-plans',
  'Plan Entrainement Triathlon Olympic 16 Semaines | TriTrainer',
  'Plan triathlon Olympic complet: 1.5km natation, 40km velo, 10km course. Programme 16 semaines pour intermediaires.',
  'Plan Entrainement Triathlon Olympic',
  'plan triathlon olympic',
  '["entrainement triathlon olympic", "preparation triathlon olympic", "programme triathlon 16 semaines"]',
  '{"distance": {"name": "Olympic", "slug": "olympic", "swim": 1500, "bike": 40, "run": 10}, "duration": {"weeks": 16, "hoursPerWeek": {"min": 8, "max": 12}}}',
  'active',
  strftime('%s', 'now'),
  strftime('%s', 'now'),
  0.9
);

-- Half Ironman Distance Hub Page
INSERT OR IGNORE INTO pseo_pages (
  id, cluster_type, url_path, parent_path, title, meta_description, h1, primary_keyword,
  secondary_keywords, variables, status, created_at, updated_at, priority
) VALUES (
  'pseo_70.3_hub',
  'training-plan',
  '/training-plans/half-ironman',
  '/training-plans',
  'Plan Entrainement Half Ironman 70.3 | 20 Semaines | TriTrainer',
  'Plan Half Ironman 70.3 complet: 1.9km natation, 90km velo, 21.1km course. Programme 20 semaines pour athletes confirmes.',
  'Plan Entrainement Half Ironman 70.3',
  'plan half ironman',
  '["entrainement 70.3", "preparation half ironman", "programme ironman 70.3"]',
  '{"distance": {"name": "70.3", "slug": "half-ironman", "swim": 1900, "bike": 90, "run": 21.1}, "duration": {"weeks": 20, "hoursPerWeek": {"min": 10, "max": 15}}}',
  'active',
  strftime('%s', 'now'),
  strftime('%s', 'now'),
  0.9
);

-- Ironman Distance Hub Page
INSERT OR IGNORE INTO pseo_pages (
  id, cluster_type, url_path, parent_path, title, meta_description, h1, primary_keyword,
  secondary_keywords, variables, status, created_at, updated_at, priority
) VALUES (
  'pseo_ironman_hub',
  'training-plan',
  '/training-plans/ironman',
  '/training-plans',
  'Plan Entrainement Ironman 140.6 | 30 Semaines | TriTrainer',
  'Plan Ironman complet: 3.8km natation, 180km velo, 42.2km marathon. Programme 30 semaines pour athletes experimentes.',
  'Plan Entrainement Ironman 140.6',
  'plan entrainement ironman',
  '["preparation ironman", "programme ironman 30 semaines", "entrainement ironman 140.6"]',
  '{"distance": {"name": "Ironman", "slug": "ironman", "swim": 3800, "bike": 180, "run": 42.2}, "duration": {"weeks": 30, "hoursPerWeek": {"min": 15, "max": 20}}}',
  'active',
  strftime('%s', 'now'),
  strftime('%s', 'now'),
  0.9
);

-- Create internal links between pages
INSERT OR IGNORE INTO pseo_links (id, source_page_id, target_page_id, link_type, anchor_text, priority, created_at)
VALUES
  ('link_pillar_sprint', 'pseo_training_plans_pillar', 'pseo_sprint_hub', 'child', 'Plan Sprint', 1, strftime('%s', 'now')),
  ('link_pillar_olympic', 'pseo_training_plans_pillar', 'pseo_olympic_hub', 'child', 'Plan Olympic', 2, strftime('%s', 'now')),
  ('link_pillar_70.3', 'pseo_training_plans_pillar', 'pseo_70.3_hub', 'child', 'Plan 70.3', 3, strftime('%s', 'now')),
  ('link_pillar_ironman', 'pseo_training_plans_pillar', 'pseo_ironman_hub', 'child', 'Plan Ironman', 4, strftime('%s', 'now')),
  ('link_sprint_olympic', 'pseo_sprint_hub', 'pseo_olympic_hub', 'related', 'Passer au Olympic', 1, strftime('%s', 'now')),
  ('link_olympic_70.3', 'pseo_olympic_hub', 'pseo_70.3_hub', 'related', 'Passer au 70.3', 1, strftime('%s', 'now')),
  ('link_70.3_ironman', 'pseo_70.3_hub', 'pseo_ironman_hub', 'related', 'Passer a l''Ironman', 1, strftime('%s', 'now'));
