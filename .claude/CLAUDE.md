# TriTrainer Project Configuration

This file contains project-specific instructions for Claude Code when working on the TriTrainer triathlon training application.

## Project Context

**Domain**: tritrainer.app
**Stack**: Next.js 15, Cloudflare Workers (OpenNext), D1 Database, Drizzle ORM
**Purpose**: AI-powered triathlon training platform with programmatic SEO

## Available Skills

The following specialized skills are available for this project:

### Development Skills
- **@skills/fullstack-nextjs.md** - Next.js fullstack development expertise
- **@skills/ai-llm-engineer.md** - AI/LLM integration and prompt engineering
- **@skills/devops-infra.md** - Cloudflare Workers, deployment, infrastructure

### Code Quality Skills
- **@skills/code-reviewer.md** - Code review and quality assurance
- **@skills/refactorer.md** - Code refactoring and technical debt reduction
- **@skills/debugger.md** - Debugging and troubleshooting
- **@skills/qa-engineer.md** - Testing strategy and quality engineering

### Documentation & Security
- **@skills/docs-writer.md** - Technical documentation
- **@skills/security-auditor.md** - Security auditing and vulnerability assessment

### Orchestration
- **@skills/orchestrator.md** - Multi-agent task coordination

## Project-Specific Guidelines

### pSEO System
- All pSEO pages must check status in D1 database before rendering
- Only pages with `status='active'` should be accessible
- Pages with `status='pending'` should return 404
- Rollout managed via GitHub Actions workflow

### Database
- Use Drizzle ORM for all database operations
- D1 binding available as `process.env.DB` in Cloudflare Workers
- Local development uses SQLite with better-sqlite3

### Deployment
- Production: Cloudflare Workers via `wrangler deploy`
- Database: D1 remote via `wrangler d1`
- Domain: tritrainer.app (configured with custom routes)

### Code Standards
- TypeScript strict mode
- No duplicate code - use DRY principles
- Component-based architecture with Brutal UI design system
- Server components by default, client components only when needed

## Current Task Context

Working on pSEO rollout system with database-driven page activation to prevent premature indexing of pending pages.
