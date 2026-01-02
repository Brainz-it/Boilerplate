-- Migration: Background Job System
-- Description: Database-backed job queue with cron trigger support
-- Date: 2025-01-02

-- ============================================================================
-- JOB TYPES CONFIGURATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS background_job_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  handler_name TEXT NOT NULL,
  max_retries INTEGER NOT NULL DEFAULT 3,
  retry_delay_ms INTEGER NOT NULL DEFAULT 60000,
  timeout_ms INTEGER NOT NULL DEFAULT 300000,
  max_concurrent INTEGER NOT NULL DEFAULT 5,
  stages_config TEXT, -- JSON array of stage names for UI/logging
  cron_schedule TEXT, -- Optional: specific cron for this type
  is_enabled INTEGER NOT NULL DEFAULT 1,
  is_paused INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

-- ============================================================================
-- JOB QUEUE
-- ============================================================================

CREATE TABLE IF NOT EXISTS background_jobs (
  id TEXT PRIMARY KEY,
  job_type_id TEXT NOT NULL REFERENCES background_job_types(id),
  status TEXT NOT NULL DEFAULT 'pending',
  priority INTEGER NOT NULL DEFAULT 10,
  progress INTEGER NOT NULL DEFAULT 0,
  current_stage TEXT,
  input_data TEXT, -- JSON input payload
  output_data TEXT, -- JSON output result
  error_message TEXT,
  reference_type TEXT, -- Polymorphic: 'user', 'profile', 'document', etc.
  reference_id TEXT,   -- ID of related entity
  locked_at INTEGER,   -- Timestamp when locked
  locked_by TEXT,      -- Worker ID that locked
  scheduled_for INTEGER, -- Optional: delay processing until this time
  started_at INTEGER,
  completed_at INTEGER,
  retry_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch()),

  CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'review_needed', 'cancelled')),
  CHECK (priority BETWEEN 1 AND 20),
  CHECK (progress BETWEEN 0 AND 100)
);

-- Indexes for job queue performance
CREATE INDEX IF NOT EXISTS idx_jobs_status ON background_jobs(status);
CREATE INDEX IF NOT EXISTS idx_jobs_priority_status ON background_jobs(priority DESC, status, created_at);
CREATE INDEX IF NOT EXISTS idx_jobs_locked ON background_jobs(locked_at, locked_by);
CREATE INDEX IF NOT EXISTS idx_jobs_reference ON background_jobs(reference_type, reference_id);
CREATE INDEX IF NOT EXISTS idx_jobs_scheduled ON background_jobs(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_jobs_type_status ON background_jobs(job_type_id, status);
CREATE INDEX IF NOT EXISTS idx_jobs_created ON background_jobs(created_at);

-- ============================================================================
-- JOB LOGS (Audit Trail)
-- ============================================================================

CREATE TABLE IF NOT EXISTS background_job_logs (
  id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL REFERENCES background_jobs(id) ON DELETE CASCADE,
  level TEXT NOT NULL DEFAULT 'info',
  stage TEXT,
  message TEXT NOT NULL,
  details TEXT, -- JSON metadata
  duration_ms INTEGER, -- Duration of this step
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),

  CHECK (level IN ('debug', 'info', 'warning', 'error'))
);

CREATE INDEX IF NOT EXISTS idx_job_logs_job ON background_job_logs(job_id, created_at);
CREATE INDEX IF NOT EXISTS idx_job_logs_level ON background_job_logs(level);

-- ============================================================================
-- WORKER CONFIGURATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS worker_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

-- ============================================================================
-- SEED DEFAULT JOB TYPES
-- ============================================================================

-- Example: Document/CV Processing Job Type
INSERT OR IGNORE INTO background_job_types (
  id, name, description, handler_name,
  max_retries, retry_delay_ms, timeout_ms, max_concurrent,
  stages_config, is_enabled, created_at, updated_at
) VALUES (
  'jt_doc_processing',
  'document_processing',
  'Process uploaded documents (PDF extraction, LLM analysis)',
  'handleDocumentProcessing',
  3, 60000, 300000, 5,
  '["upload_validation", "text_extraction", "llm_processing", "validation", "storage"]',
  1, unixepoch(), unixepoch()
);

-- Example: Email Notification Job Type
INSERT OR IGNORE INTO background_job_types (
  id, name, description, handler_name,
  max_retries, retry_delay_ms, timeout_ms, max_concurrent,
  stages_config, is_enabled, created_at, updated_at
) VALUES (
  'jt_email_notification',
  'email_notification',
  'Send email notifications via Resend',
  'handleEmailNotification',
  3, 30000, 60000, 10,
  '["template_rendering", "sending", "confirmation"]',
  1, unixepoch(), unixepoch()
);

-- Example: Data Sync Job Type
INSERT OR IGNORE INTO background_job_types (
  id, name, description, handler_name,
  max_retries, retry_delay_ms, timeout_ms, max_concurrent,
  stages_config, is_enabled, created_at, updated_at
) VALUES (
  'jt_data_sync',
  'data_sync',
  'Synchronize data with external APIs',
  'handleDataSync',
  5, 120000, 600000, 3,
  '["fetch_external", "transform", "update_local", "verify"]',
  1, unixepoch(), unixepoch()
);

-- ============================================================================
-- SEED DEFAULT WORKER CONFIG
-- ============================================================================

INSERT OR IGNORE INTO worker_config (key, value, description, updated_at)
VALUES
  ('worker_enabled', 'true', 'Master switch to enable/disable job processing', unixepoch()),
  ('default_batch_size', '10', 'Default number of jobs to process per cron cycle', unixepoch()),
  ('lock_timeout_ms', '300000', 'Default lock timeout in milliseconds (5 minutes)', unixepoch()),
  ('llm_provider', 'openai', 'LLM provider: openai or anthropic', unixepoch()),
  ('openai_model', 'gpt-4o-mini', 'OpenAI model for LLM processing', unixepoch()),
  ('anthropic_model', 'claude-3-haiku-20240307', 'Anthropic model for LLM processing', unixepoch());

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- View: Active jobs summary by type
CREATE VIEW IF NOT EXISTS v_job_summary AS
SELECT
  bt.name as job_type,
  bj.status,
  COUNT(*) as count,
  AVG(bj.progress) as avg_progress,
  MIN(bj.created_at) as oldest_created
FROM background_jobs bj
JOIN background_job_types bt ON bj.job_type_id = bt.id
GROUP BY bt.name, bj.status;

-- View: Recent job activity (last 24 hours)
CREATE VIEW IF NOT EXISTS v_recent_jobs AS
SELECT
  bj.id,
  bt.name as job_type,
  bj.status,
  bj.priority,
  bj.progress,
  bj.current_stage,
  bj.retry_count,
  bj.error_message,
  bj.created_at,
  bj.completed_at,
  (bj.completed_at - bj.started_at) as duration_ms
FROM background_jobs bj
JOIN background_job_types bt ON bj.job_type_id = bt.id
WHERE bj.created_at > unixepoch() - 86400
ORDER BY bj.created_at DESC;
