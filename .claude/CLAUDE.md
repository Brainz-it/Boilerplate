# Boilerplate - Next.js 15 + Cloudflare Workers + D1

Production-ready boilerplate for edge-deployed Next.js applications with programmatic SEO and background job processing.

## Project Context

**Type**: Template/Boilerplate Repository
**Stack**: Next.js 15 (App Router), Cloudflare Workers (OpenNext), D1 Database, Drizzle ORM, Better Auth
**Purpose**: Starting point for building edge-first applications with pSEO and job queue capabilities

## Architecture Overview

```
Request → Cloudflare Edge → worker.js (pSEO check) → OpenNext → Next.js App → D1
                                ↓
                         Cron Trigger → Job Processor → Background Jobs
```

## Available Skills

### Development
- **@skills/fullstack-nextjs.md** - Next.js 15 with App Router, Server Components, SSG
- **@skills/ai-llm-engineer.md** - AI/LLM integration patterns
- **@skills/devops-infra.md** - Cloudflare Workers, D1, deployment

### Code Quality
- **@skills/code-reviewer.md** - Code review and quality assurance
- **@skills/refactorer.md** - Refactoring and technical debt
- **@skills/debugger.md** - Debugging and troubleshooting
- **@skills/qa-engineer.md** - Testing strategy

### Documentation & Security
- **@skills/docs-writer.md** - Technical documentation
- **@skills/security-auditor.md** - Security auditing

### Orchestration
- **@skills/orchestrator.md** - Multi-agent task coordination

## Key Systems

### 1. pSEO Database-Driven Rollout
- Pages check status in D1 before rendering
- `status='active'` → render page
- `status='pending'` → return 404
- Custom worker.js wrapper intercepts requests

### 2. Background Job System
- Database-backed queue (not Cloudflare Queues)
- Optimistic locking for distributed workers
- Cron trigger every minute
- Handler registry pattern

### 3. Authentication (Better Auth)
- Passwordless magic links
- Edge-compatible with D1
- Drizzle adapter

## Database Conventions

**Tables**: snake_case (e.g., `background_jobs`, `pseo_pages`)
**Columns**: snake_case (e.g., `created_at`, `job_type_id`)
**Primary Keys**: TEXT with prefixed IDs (e.g., `jt_`, `job_`)
**Timestamps**: INTEGER as Unix epoch via `unixepoch()`
**JSON**: TEXT columns with JSON stringified data

## File Structure

```
├── docs/
│   ├── adr/           # Architecture Decision Records
│   ├── technical/     # Technical documentation
│   └── guides/        # How-to guides
├── migrations/        # D1 SQL migrations
├── .claude/
│   └── skills/        # Claude Code skills
├── worker.js          # Custom Worker wrapper
├── wrangler.toml      # Cloudflare config
└── README.md
```

## Development Workflow

### Local Setup
```bash
pnpm install
cp .env.example .env.local
npx wrangler d1 create your-db-name
# Update wrangler.toml with database_id
pnpm dev
```

### Deployment
```bash
pnpm build
npx wrangler deploy
```

### Migrations
```bash
for f in migrations/*.sql; do
  npx wrangler d1 execute your-db --remote --file "$f"
done
```

## Code Standards

- TypeScript strict mode
- DRY principles - no duplicate code
- Server Components by default
- Edge-compatible code (no Node.js APIs)
- Drizzle ORM for all database operations

## ADRs Reference

| ADR | Topic |
|-----|-------|
| 001 | Next.js 15 with App Router |
| 002 | Cloudflare Workers Deployment |
| 003 | D1 Database with Drizzle ORM |
| 004 | pSEO Database-Driven Rollout |
| 005 | Custom Worker Wrapper |
| 006 | Better Auth Authentication |
| 007 | Background Job System |
