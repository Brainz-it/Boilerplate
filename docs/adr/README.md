# Architecture Decision Records (ADRs)

This directory contains Architecture Decision Records (ADRs) for the TriTrainer project.

## ADR Index

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](001-nextjs-app-router.md) | Next.js 15 with App Router | Accepted | 2025-01-02 |
| [ADR-002](002-cloudflare-workers-deployment.md) | Cloudflare Workers Deployment with OpenNext | Accepted | 2025-01-02 |
| [ADR-003](003-d1-database-drizzle-orm.md) | D1 Database with Drizzle ORM | Accepted | 2025-01-02 |
| [ADR-004](004-pseo-database-driven-rollout.md) | pSEO Database-Driven Rollout System | Accepted | 2025-01-02 |
| [ADR-005](005-worker-wrapper-page-blocking.md) | Custom Worker Wrapper for Page Status Blocking | Accepted | 2025-01-02 |
| [ADR-006](006-better-auth-authentication.md) | Better Auth for Authentication | Accepted | 2025-01-02 |

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
