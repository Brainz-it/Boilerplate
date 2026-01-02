# Boilerplate Specification

**Version**: 1.0.0
**Last Updated**: 2025-01-02
**Purpose**: Complete specification for edge-deployed Next.js applications

## Overview

This boilerplate provides a production-ready foundation for building Next.js 15 applications deployed to Cloudflare Workers with D1 database, programmatic SEO, and passwordless authentication.

**Target Use Cases**:
- SaaS applications with programmatic SEO needs
- Edge-deployed Next.js applications
- Content-heavy applications with dynamic user data
- Applications requiring low-latency global distribution

## Architecture Summary

### Technology Stack

| Layer | Technology | Version | Rationale |
|-------|------------|---------|-----------|
| **Framework** | Next.js | 15.x | App Router, Server Components, edge compatibility |
| **Runtime** | Cloudflare Workers | - | Global edge network, <50ms latency |
| **Adapter** | OpenNext | 1.14.7+ | Next.js → Cloudflare Workers transpilation |
| **Database** | Cloudflare D1 | - | Edge SQLite, <1ms queries, $0-5/month |
| **ORM** | Drizzle | 0.45.1+ | Type-safe, edge-compatible, minimal overhead |
| **Auth** | Better Auth | 1.4.9+ | Passwordless, edge-native, D1 integration |
| **Email** | Resend | - | Deliverability, DX, free tier (3k/month) |
| **Language** | TypeScript | 5.x | Type safety, IDE support |
| **Styling** | Tailwind CSS | 3.x | Utility-first, performance |

### Deployment Architecture

```
┌─────────────┐
│   User      │
└──────┬──────┘
       │
       ▼
┌────────────────────────────────────┐
│  Cloudflare Edge Network           │
│  (275+ locations)                  │
└────────────┬───────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│  worker.js (Custom Wrapper)        │
│  • pSEO status checking            │
│  • D1 query (<1ms)                 │
│  • Return 404 if blocked           │
└────────────┬───────────────────────┘
             │
             ▼
┌────────────────────────────────────┐
│  OpenNext Worker                   │
│  • Routing                         │
│  • SSR/SSG                         │
│  • API handlers                    │
└────────────┬───────────────────────┘
             │
             ├──────► D1 Database (SQLite)
             ├──────► R2 Storage (Assets)
             └──────► External APIs
```

## Core Features

### 1. Authentication System

**Implementation**: Better Auth with Magic Link plugin

**Key Features**:
- Passwordless authentication (magic links)
- 7-day sessions with auto-refresh
- HTTP-only secure cookies
- Edge-compatible
- OAuth ready (Google, GitHub, etc.)

**Database Tables**:
- `users` - User accounts
- `user_sessions` - Session tokens
- `verification` - Magic link tokens
- `accounts` - OAuth providers

**Email Flow**:
1. User enters email
2. Generate secure token (5-min expiry)
3. Send email via Resend
4. User clicks link → verify token → create session
5. Set HTTP-only cookie → redirect to dashboard

**Dev Mode**: Magic links logged to console (no email sent)

### 2. Programmatic SEO System

**Implementation**: Database-driven page rollout with Worker-level blocking

**Key Features**:
- Pre-rendered HTML for SEO quality
- Database-controlled activation (instant, no redeploy)
- Worker-level HTTP 404 blocking
- Gradual rollout via batches
- Internal linking graph

**Database Tables**:
- `pseo_pages` - Page metadata and content
- `pseo_links` - Internal link relationships
- `pseo_config` - Rollout configuration

**Page Lifecycle**:
```
pending → active → blocked → retired
```

**Content Structure** (JSON fields):
```typescript
interface PSEOPage {
  llmContent: {
    quickAnswer: string;
    faqs: Array<{ question: string; answer: string }>;
    sections: Array<{ title: string; content: string }>;
  };
  schemas: {
    article: SchemaOrg.Article;
    howTo?: SchemaOrg.HowTo;
    faqPage?: SchemaOrg.FAQPage;
  };
  variables: Record<string, unknown>; // Domain-specific
}
```

**Worker Blocking Logic**: [`worker.js`](../worker.js)
```javascript
if (isPSEORoute(pathname)) {
  const status = await checkPageStatus(env.DB, pathname);
  if (status === 'blocked') {
    return new Response('Not Found', { status: 404 });
  }
}
```

### 3. Background Job System

**Implementation**: Database-backed job queue with cron triggers

**Key Features**:
- Optimistic locking for distributed workers
- Handler registry pattern
- Progress tracking and stages
- Configurable retries and timeouts
- Audit logging

**Database Tables**:
- `background_job_types` - Job type configurations
- `background_jobs` - Job queue
- `background_job_logs` - Audit trail
- `worker_config` - Global settings

**Job Lifecycle**:
```
pending → processing → completed/failed/review_needed
```

### 4. Database Schema

**Core Tables**:

**Authentication**:
- `users` - User accounts
- `user_sessions` - Session tokens
- `verification` - Magic link tokens
- `accounts` - OAuth providers

**pSEO**:
- `pseo_pages` - SEO page metadata
- `pseo_links` - Internal link graph
- `pseo_config` - Rollout settings

**Background Jobs**:
- `background_job_types` - Job configurations
- `background_jobs` - Job queue
- `background_job_logs` - Audit logs
- `worker_config` - Global settings

**Naming Conventions**:
- Tables: `snake_case`
- Primary keys: `id` (TEXT, nanoid)
- Foreign keys: `{table}_id` (e.g., `user_id`)
- Booleans: INTEGER (0/1)
- Timestamps: INTEGER (Unix seconds)
- JSON: TEXT

## File Structure

```
boilerplate/
├── .claude/                    # Claude Code configuration
│   ├── CLAUDE.md              # Project instructions
│   ├── memories/              # Persistent context
│   └── skills/                # Specialized skills
│
├── docs/                       # Documentation
│   ├── adr/                   # Architecture Decision Records
│   ├── technical/             # Technical documentation
│   ├── guides/                # How-to guides
│   └── BOILERPLATE_SPEC.md   # This file
│
├── migrations/                 # SQL migration files
│   ├── 0001_initial.sql       # Core tables
│   ├── 0002_seed_data.sql     # Seed data
│   ├── 0003_pseo_tables.sql   # pSEO tables
│   ├── 0004_auth.sql          # Auth tables
│   └── 0005_background_jobs.sql # Job system
│
├── worker.js                  # Custom Cloudflare Worker wrapper
├── wrangler.toml              # Cloudflare configuration
└── README.md
```

## Configuration

### wrangler.toml

```toml
name = "your-app-name"
main = "worker.js"
compatibility_date = "2024-12-01"

[assets]
directory = ".open-next/assets"

[[d1_databases]]
binding = "DB"
database_name = "your-db-name"
database_id = "YOUR_DATABASE_ID"

[vars]
APP_URL = "https://your-domain.com"
ENVIRONMENT = "production"
```

### Environment Variables

**Development** (`.env.local`):
```bash
CLOUDFLARE_ACCOUNT_ID=your-account-id
BETTER_AUTH_URL=http://localhost:3000
BETTER_AUTH_SECRET=min-32-char-secret
RESEND_API_KEY=
EMAIL_FROM=Your App <noreply@your-domain.com>
ENVIRONMENT=development
```

**Production** (Cloudflare Secrets):
```bash
npx wrangler secret put BETTER_AUTH_SECRET
npx wrangler secret put RESEND_API_KEY
```

## Implementation Checklist

### Initial Setup

- [ ] Install Node.js 20+, pnpm, Wrangler
- [ ] Create Cloudflare account
- [ ] Clone repository
- [ ] Install dependencies (`pnpm install`)
- [ ] Create `.env.local`
- [ ] Generate Better Auth secret

### Database Setup

- [ ] Create D1 database (`npx wrangler d1 create`)
- [ ] Update `wrangler.toml` with `database_id`
- [ ] Apply migrations
- [ ] Verify tables exist

### Authentication Setup

- [ ] Configure Better Auth
- [ ] Create auth API routes
- [ ] Implement login/logout pages
- [ ] Test magic link flow locally
- [ ] Setup Resend account (production)

### pSEO Setup

- [ ] Implement Worker wrapper (`worker.js`)
- [ ] Create pSEO page component
- [ ] Generate seed data for pages
- [ ] Test page activation/blocking
- [ ] Configure rollout batches

### Deployment

- [ ] Configure custom domain
- [ ] Setup SSL/TLS
- [ ] Configure production secrets
- [ ] Build application
- [ ] Deploy to Cloudflare
- [ ] Verify deployment

## Key Design Patterns

### 1. Worker Wrapper Pattern

Custom Worker intercepts before OpenNext for pre-routing logic.

```javascript
export default {
  async fetch(request, env, ctx) {
    if (isPSEORoute(url.pathname)) {
      const status = await checkPageStatus(env.DB, url.pathname);
      if (status === 'blocked') {
        return new Response('Not Found', { status: 404 });
      }
    }
    return openNextWorker.fetch(request, env, ctx);
  },
};
```

### 2. Database-Driven Rollout

Status field in database controls accessibility without redeployment.

```sql
UPDATE pseo_pages
SET status = 'active', published_at = unixepoch()
WHERE sitemap_batch = 1;
```

### 3. Optimistic Locking

Prevents duplicate job processing in distributed workers.

```sql
UPDATE background_jobs
SET status = 'processing', locked_at = ?, locked_by = ?
WHERE id = ? AND status = 'pending';
```

## Performance Characteristics

### Response Times (P95)

| Operation | Latency |
|-----------|---------|
| Static page (cache hit) | <10ms |
| Dynamic page (SSR) | <100ms |
| API request (authenticated) | <50ms |
| pSEO status check | <1ms |
| Database query (indexed) | <1ms |

### Cost Estimation

**Startup Scale** (1k users, 100k requests/month):
- Cloudflare Workers: $0 (free tier)
- D1 Database: $0 (free tier)
- Resend: $0 (free tier)
- **Total**: ~$0-1/month

**Growth Scale** (10k users, 1M requests/month):
- Cloudflare Workers: $5
- D1 Database: $1
- Resend: $0-20
- **Total**: ~$6-26/month

## References

### Documentation
- [Next.js 15 Docs](https://nextjs.org/docs)
- [Cloudflare Workers](https://developers.cloudflare.com/workers/)
- [Drizzle ORM](https://orm.drizzle.team/)
- [Better Auth](https://www.better-auth.com/docs)
- [Resend](https://resend.com/docs)

### ADRs
- [ADR-001: Next.js 15 with App Router](./adr/001-nextjs-app-router.md)
- [ADR-002: Cloudflare Workers Deployment](./adr/002-cloudflare-workers-deployment.md)
- [ADR-003: D1 Database with Drizzle ORM](./adr/003-d1-database-drizzle-orm.md)
- [ADR-004: pSEO Database-Driven Rollout](./adr/004-pseo-database-driven-rollout.md)
- [ADR-005: Custom Worker Wrapper](./adr/005-worker-wrapper-page-blocking.md)
- [ADR-006: Better Auth](./adr/006-better-auth-authentication.md)
- [ADR-007: Background Job System](./adr/007-background-job-system.md)

## License

MIT License
