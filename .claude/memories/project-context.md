# Project Context - Boilerplate

## Overview
Production-ready boilerplate for building edge-deployed Next.js applications with Cloudflare Workers, D1, and pSEO capabilities.

## Tech Stack
- **Runtime**: Cloudflare Workers (edge)
- **Framework**: Next.js 15 with App Router
- **Adapter**: OpenNext for Workers transpilation
- **Database**: D1 (SQLite at edge) with Drizzle ORM
- **Auth**: Better Auth with magic links
- **Email**: Resend for transactional emails

## Key Architectural Decisions
1. Database-driven pSEO rollout (not file-based)
2. Custom worker.js wrapper for pre-Next.js request interception
3. Database-backed job queue (not Cloudflare Queues)
4. Optimistic locking for distributed job processing
5. Edge-first design with <50ms latency target

## Important Patterns

### pSEO Page Status Check
```typescript
// worker.js intercepts before OpenNext
if (isPSEORoute(pathname)) {
  const status = await checkPageStatus(env.DB, pathname);
  if (status === 'blocked') return new Response('Not Found', { status: 404 });
}
```

### Job Processing
```typescript
// Cron trigger calls processJobs
const pendingJobs = await db.select().from(background_jobs)
  .where(eq(status, 'pending'))
  .limit(batchSize);

// Optimistic lock with WHERE condition
await db.update(background_jobs)
  .set({ status: 'processing', locked_at: now, locked_by: workerId })
  .where(and(eq(id, job.id), eq(status, 'pending')));
```

## Session Notes
- Documentation complete with 7 ADRs
- GitHub repo: https://github.com/Brainz-it/Boilerplate
- Topics: nextjs, cloudflare-workers, d1-database, drizzle-orm, better-auth, typescript, boilerplate, edge-computing, programmatic-seo, serverless, background-jobs, tailwindcss
