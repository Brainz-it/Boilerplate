# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) for the Next.js + Cloudflare Workers + D1 boilerplate.

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](001-nextjs-app-router.md) | Next.js 15 with App Router | Accepted | 2025-01-02 |
| [ADR-002](002-cloudflare-workers-deployment.md) | Cloudflare Workers Deployment with OpenNext | Accepted | 2025-01-02 |
| [ADR-003](003-d1-database-drizzle-orm.md) | D1 Database with Drizzle ORM | Accepted | 2025-01-02 |
| [ADR-004](004-pseo-database-driven-rollout.md) | pSEO Database-Driven Rollout System | Accepted | 2025-01-02 |
| [ADR-005](005-worker-wrapper-page-blocking.md) | Custom Worker Wrapper for Page Status Blocking | Accepted | 2025-01-02 |
| [ADR-006](006-better-auth-authentication.md) | Better Auth for Authentication | Accepted | 2025-01-02 |
| [ADR-007](007-background-job-system.md) | Database-Backed Background Job System | Accepted | 2025-01-02 |

## Migrations

| Migration | Description |
|-----------|-------------|
| 0001_initial.sql | Core tables (users, profiles, audit, admin) |
| 0002_seed_data.sql | Initial seed data |
| 0003_pseo_tables.sql | pSEO system tables |
| 0004_auth.sql | Better Auth tables |
| 0005_background_jobs.sql | Background job system |

## ADR Template

Each ADR follows this structure:

```markdown
# ADR-XXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
What is the issue we're addressing?

## Decision
What did we decide to do?

## Consequences
What are the impacts of this decision?

## Alternatives Considered
What other options did we evaluate?
```

## Creating a New ADR

1. Copy the template
2. Number sequentially (next available number)
3. Fill in all sections
4. Update this README index
5. Commit with message: `docs(adr): add ADR-XXX [title]`
