# Database Conventions

## Table Naming
- Use **snake_case** for all table names
- Prefix system tables: `background_job_`, `pseo_`, `auth_`
- Examples: `background_jobs`, `background_job_types`, `pseo_pages`

## Column Naming
- Use **snake_case** for all columns
- Standard columns: `id`, `created_at`, `updated_at`
- Foreign keys: `{table_singular}_id` (e.g., `job_type_id`)
- Status columns: TEXT with CHECK constraint for valid values

## Primary Keys
- Use TEXT type with prefixed IDs
- Prefixes by table:
  - Job types: `jt_` (e.g., `jt_doc_processing`)
  - Jobs: `job_` (e.g., `job_abc123`)
  - Pages: `page_` (e.g., `page_xyz789`)
  - Users: `user_` (e.g., `user_123abc`)

## Timestamps
- Store as INTEGER (Unix epoch seconds)
- Use `unixepoch()` for defaults
- Pattern: `created_at INTEGER NOT NULL DEFAULT (unixepoch())`

## JSON Data
- Store as TEXT columns
- Use `input_data`, `output_data`, `stages_config` naming
- Always validate JSON structure in application layer

## Status Enums
- Use TEXT with CHECK constraints
- Job statuses: `pending`, `processing`, `completed`, `failed`, `review_needed`, `cancelled`
- Page statuses: `pending`, `active`, `blocked`, `retired`

## Indexes
- Always index foreign keys
- Composite indexes for common query patterns
- Example: `idx_jobs_priority_status ON background_jobs(priority DESC, status, created_at)`

## Example Table
```sql
CREATE TABLE IF NOT EXISTS example_items (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL DEFAULT 'pending',
  data TEXT, -- JSON
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
  CHECK (status IN ('pending', 'active', 'archived'))
);

CREATE INDEX IF NOT EXISTS idx_example_user ON example_items(user_id);
CREATE INDEX IF NOT EXISTS idx_example_status ON example_items(status);
```
