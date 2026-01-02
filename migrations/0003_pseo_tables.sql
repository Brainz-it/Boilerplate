-- Migration 003: pSEO Tables
-- Tables for programmatic SEO (pSEO) content management
-- Rename from 0005 to 0003 for cleaner sequence

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
  variables TEXT, -- JSON: domain-specific variables

  -- Sitemap & Rollout
  sitemap_batch INTEGER DEFAULT 1,
  rollout_date INTEGER,
  priority REAL DEFAULT 0.5,
  changefreq TEXT DEFAULT 'monthly',

  -- Status: pending, active, blocked, retired
  status TEXT NOT NULL DEFAULT 'pending',

  -- Timestamps
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
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
  site_name TEXT DEFAULT 'Your Site Name',
  base_url TEXT DEFAULT 'https://example.com',

  -- Timestamps
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

-- Insert default config
INSERT OR IGNORE INTO pseo_config (id, updated_at) VALUES (1, unixepoch());

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

  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

-- Indexes for pseo_links
CREATE INDEX IF NOT EXISTS idx_pseo_links_source ON pseo_links(source_page_id);
CREATE INDEX IF NOT EXISTS idx_pseo_links_target ON pseo_links(target_page_id);
