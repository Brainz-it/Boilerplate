# TriTrainer Boilerplate Specification

**Version**: 1.0.0
**Last Updated**: 2025-01-02
**Purpose**: Complete specification for replicating TriTrainer architecture as a boilerplate

## Overview

This document provides a comprehensive specification for creating a production-ready Next.js 15 application deployed to Cloudflare Workers with D1 database, programmatic SEO, and authentication.

**Target Use Cases**:
- SaaS applications with programmatic SEO needs
- Edge-deployed Next.js applications
- Training/coaching platforms
- Content-heavy applications with dynamic user data

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
             └──────► External APIs (Strava, etc.)
```

## Core Features

### 1. Authentication System

**Implementation**: Better Auth with Magic Link plugin

**Key Features**:
- Passwordless authentication (magic links)
- 7-day sessions with auto-refresh
- HTTP-only secure cookies
- Edge-compatible
- Future OAuth ready (Strava, Google)

**Database Tables**:
- `users` - User accounts
- `user_sessions` - Session tokens
- `verification` - Magic link tokens
- `accounts` - OAuth providers (future)

**Configuration**: [`src/lib/auth/better-auth.ts`](../src/lib/auth/better-auth.ts)

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
pending → active → paused → archived
```

**Cluster Types**:
- Training Plans (e.g., `/training-plans/sprint/debutant`)
- Discipline Guides (e.g., `/guides/natation/crawl`)
- Race Preparation (e.g., `/race-prep/ironman/nutrition`)
- Equipment Reviews (e.g., `/equipement/velo/tri-bike`)
- Comparisons (e.g., `/compare/sprint-vs-olympic`)

**Content Structure** (JSON fields):
```typescript
interface PSEOPage {
  llmContent: {
    quickAnswer: string;
    faqs: Array<{ question: string; answer: string }>;
    sections: Array<{ title: string; content: string }>;
    tips: Array<{ title: string; content: string }>;
  };
  schemas: {
    article: SchemaOrg.Article;
    howTo?: SchemaOrg.HowTo;
    faqPage?: SchemaOrg.FAQPage;
  };
  variables: {
    distance?: { name: string; swim: number; bike: number; run: number };
    level?: { name: string; description: string };
    duration?: { weeks: number; hoursPerWeek: { min: number; max: number } };
  };
}
```

**Rollout Strategy**:
| Batch | Pages | Activation | Purpose |
|-------|-------|------------|---------|
| 0 | 5 | Immediate | Core pages |
| 1 | 28 | +3 days | Distance × level combinations |
| 2 | 10 | +7 days | Competition pages |
| 3 | 4 | +14 days | Specialty programs |
| 4 | 5 | +21 days | Profile pages |

**Activation Process**:
```sql
UPDATE pseo_pages
SET status = 'active', published_at = unixepoch()
WHERE sitemap_batch = 1;
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

### 3. Database Schema

**Core Modules**:

**Authentication**:
- `users` - User accounts (email, Strava integration)
- `user_sessions` - Session tokens
- `verification` - Magic link tokens
- `accounts` - OAuth providers

**User Profiles**:
- `athlete_profiles` - Extended athlete data (1:1 with users)
- `heart_rate_zones` - Training zones (1:many with users)

**Training Programs**:
- `programs` - Training programs (12-24 weeks)
- `program_weeks` - Weekly structure and volume
- `sessions` - Individual workouts
- `goals` - Target races
- `templates` - Reusable program templates

**pSEO**:
- `pseo_pages` - SEO page metadata
- `pseo_links` - Internal link graph
- `pseo_config` - Rollout settings

**Naming Conventions**:
- Tables: `snake_case`
- Primary keys: `id` (TEXT, nanoid)
- Foreign keys: `{table}_id` (e.g., `user_id`)
- Booleans: INTEGER (0/1)
- Timestamps: INTEGER (Unix seconds)
- JSON: TEXT

**Indexes Strategy**:
- All foreign keys indexed
- Unique constraints on natural keys (email, url_path)
- Composite indexes for common queries
- Date fields for range queries

### 4. API Routes

**Structure**:
```
/api/
├── auth/[...all]        # Better Auth handler
├── auth/logout          # Explicit logout
├── strava/webhook       # Strava events
├── strava/activities    # Activity sync
├── program/create       # Create program
├── program/[id]         # Program CRUD
└── program/recalculate  # Adaptive recalculation
```

**Authentication**: HTTP-only cookie (`better-auth.session_token`)

**Error Format**:
```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Session token invalid or expired",
    "details": {}
  }
}
```

**Rate Limiting**: Cloudflare automatic (100 req/min per user)

## File Structure

```
strava_app/
├── .claude/                    # Claude Code configuration
│   ├── CLAUDE.md              # Project instructions
│   └── skills/                # Specialized skills
│
├── docs/                       # Documentation
│   ├── adr/                   # Architecture Decision Records
│   │   ├── README.md
│   │   ├── 001-nextjs-app-router.md
│   │   ├── 002-cloudflare-workers-deployment.md
│   │   ├── 003-d1-database-drizzle-orm.md
│   │   ├── 004-pseo-database-driven-rollout.md
│   │   ├── 005-worker-wrapper-page-blocking.md
│   │   └── 006-better-auth-authentication.md
│   │
│   ├── technical/             # Technical documentation
│   │   ├── project-structure.md
│   │   ├── database-schema.md
│   │   ├── api-routes.md
│   │   ├── components.md
│   │   └── workflows.md
│   │
│   ├── guides/                # How-to guides
│   │   ├── setup.md
│   │   ├── deployment.md
│   │   └── migrations.md
│   │
│   └── BOILERPLATE_SPEC.md   # This file
│
├── migrations/                 # SQL migration files
│   ├── 0001_create_users.sql
│   ├── 0002_seed_data.sql
│   ├── 0003_create_programs.sql
│   ├── 0004_create_sessions.sql
│   ├── 0005_pseo_tables.sql
│   └── 0006_pseo_seed.sql
│
├── src/
│   ├── app/                   # Next.js 15 App Router
│   │   ├── (landing)/        # Landing pages
│   │   │   └── page.tsx
│   │   │
│   │   ├── (pseo)/           # pSEO pages
│   │   │   └── [...slug]/page.tsx
│   │   │
│   │   ├── dashboard/        # Protected pages
│   │   │   └── page.tsx
│   │   │
│   │   ├── api/              # API routes
│   │   │   ├── auth/
│   │   │   └── strava/
│   │   │
│   │   ├── layout.tsx        # Root layout
│   │   └── globals.css       # Global styles
│   │
│   ├── components/           # React components
│   │   ├── ui/              # Base components
│   │   ├── auth/            # Auth components
│   │   ├── layout/          # Layout components
│   │   └── pseo/            # pSEO components
│   │
│   ├── lib/                  # Utilities
│   │   ├── auth/            # Better Auth
│   │   ├── db/              # Database
│   │   │   └── schema/      # Drizzle schemas
│   │   ├── pseo/            # pSEO utilities
│   │   └── utils/           # General utilities
│   │
│   ├── types/                # TypeScript types
│   │   └── cloudflare.d.ts
│   │
│   └── middleware.ts         # Next.js middleware
│
├── worker.js                  # Custom Cloudflare Worker wrapper
├── wrangler.toml              # Cloudflare configuration
├── next.config.ts             # Next.js configuration
├── drizzle.config.ts          # Drizzle configuration
├── tailwind.config.ts         # Tailwind configuration
├── tsconfig.json              # TypeScript configuration
└── package.json               # Dependencies
```

## Configuration Files

### wrangler.toml

```toml
name = "triathlon-app"
main = "worker.js"  # Custom wrapper, not .open-next/worker.js
compatibility_date = "2024-12-01"

[assets]
directory = ".open-next/assets"

[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
database_id = "your-database-id"

[vars]
BETTER_AUTH_URL = "https://tritrainer.app"
EMAIL_FROM = "TriTrainer <noreply@tritrainer.app>"
ENVIRONMENT = "production"
```

### next.config.ts

```typescript
const nextConfig: NextConfig = {
  output: 'standalone',  // Required for OpenNext
  // ... other config
};
```

### drizzle.config.ts

```typescript
export default {
  schema: './src/lib/db/schema/*',
  out: './drizzle',
  dialect: 'sqlite',
  driver: 'd1',
};
```

## Environment Variables

### Development (`.env.local`)

```bash
# Cloudflare
CLOUDFLARE_ACCOUNT_ID=your-account-id

# Better Auth
BETTER_AUTH_URL=http://localhost:3000
BETTER_AUTH_SECRET=min-32-char-secret

# Email (optional in dev)
RESEND_API_KEY=
EMAIL_FROM=TriTrainer <noreply@tritrainer.app>

# Environment
ENVIRONMENT=development

# Strava (optional)
STRAVA_CLIENT_ID=
STRAVA_CLIENT_SECRET=
```

### Production (Cloudflare Secrets)

```bash
# Set via Wrangler
npx wrangler secret put BETTER_AUTH_SECRET
npx wrangler secret put RESEND_API_KEY
npx wrangler secret put STRAVA_CLIENT_SECRET
```

## Implementation Checklist

### Initial Setup

- [ ] Install Node.js 20+, pnpm, Wrangler
- [ ] Create Cloudflare account
- [ ] Clone/create repository
- [ ] Install dependencies (`pnpm install`)
- [ ] Create `.env.local` with required variables
- [ ] Generate Better Auth secret

### Database Setup

- [ ] Create D1 database (`npx wrangler d1 create`)
- [ ] Update `wrangler.toml` with `database_id`
- [ ] Create migration files in `migrations/`
- [ ] Apply migrations (`npx wrangler d1 execute`)
- [ ] Verify tables exist

### Authentication Setup

- [ ] Configure Better Auth in `src/lib/auth/better-auth.ts`
- [ ] Create auth API routes
- [ ] Implement login/logout pages
- [ ] Test magic link flow locally
- [ ] Setup Resend account (production)
- [ ] Verify DNS records for email domain

### pSEO Setup

- [ ] Create `pseo_pages` table with schema
- [ ] Implement Worker wrapper (`worker.js`)
- [ ] Create pSEO page component (`[...slug]/page.tsx`)
- [ ] Generate seed data for pages
- [ ] Test page activation/blocking
- [ ] Configure rollout batches

### Deployment Setup

- [ ] Configure custom domain in Cloudflare
- [ ] Update DNS nameservers
- [ ] Setup SSL/TLS (Full strict)
- [ ] Configure production secrets
- [ ] Build application (`pnpm build`)
- [ ] Deploy to Cloudflare (`npx wrangler deploy`)
- [ ] Verify deployment

### Post-Deployment

- [ ] Test authentication flow
- [ ] Activate initial pSEO batch
- [ ] Submit sitemap to search engines
- [ ] Configure monitoring/alerts
- [ ] Setup GitHub Actions CI/CD
- [ ] Configure backup strategy

## Key Design Patterns

### 1. Worker Wrapper Pattern

**Problem**: Need to block pages without executing Next.js code
**Solution**: Custom Worker intercepts before OpenNext

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

**Problem**: Need to activate pages without redeployment
**Solution**: Status field in database controls accessibility

```sql
-- Activate pages instantly
UPDATE pseo_pages
SET status = 'active', published_at = unixepoch()
WHERE sitemap_batch = 1;

-- Reflects globally in <100ms (D1 replication)
```

### 3. Type-Safe Database Access

**Problem**: Runtime errors from database queries
**Solution**: Drizzle ORM with TypeScript inference

```typescript
// Schema definition
export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  email: text('email').notNull().unique(),
});

// Type inference
type User = typeof users.$inferSelect;  // Automatic types
type NewUser = typeof users.$inferInsert;

// Type-safe query
const user: User = await db
  .select()
  .from(users)
  .where(eq(users.id, userId));
```

### 4. Edge-Native Authentication

**Problem**: Traditional auth libraries don't work on Workers
**Solution**: Better Auth built for edge with D1 adapter

```typescript
export function createAuth(env: AuthEnv, db: ReturnType<typeof createDb>) {
  return betterAuth({
    database: drizzleAdapter(db, { provider: 'sqlite' }),
    plugins: [magicLink({ /* ... */ })],
  });
}
```

## Performance Characteristics

### Response Times (P95)

| Operation | Latency | Notes |
|-----------|---------|-------|
| Static page (cache hit) | <10ms | Edge cache |
| Dynamic page (SSR) | <100ms | Worker execution + D1 query |
| API request (authenticated) | <50ms | Session check + query |
| pSEO status check | <1ms | Indexed D1 query |
| Database query (indexed) | <1ms | D1 edge replica |
| Database query (complex) | <10ms | Joins, aggregations |

### Cold Start

| Component | Time | Frequency |
|-----------|------|-----------|
| Worker initialization | <50ms | First request after deploy |
| Better Auth init | ~10ms | Per cold start |
| Drizzle adapter | ~5ms | Per cold start |

### Scale Limits

| Resource | Free Tier | Paid Tier | Notes |
|----------|-----------|-----------|-------|
| Worker requests | 100k/day | Unlimited | $5/10M requests |
| D1 reads | 5M/day | Unlimited | $0.001/100k reads |
| D1 writes | 100k/day | Unlimited | $1/1M writes |
| D1 storage | 500MB | 10GB | $0.75/GB/month |
| Email (Resend) | 3k/month | Unlimited | $20/50k emails |

## Cost Estimation

### Startup Scale (1k active users, 100k requests/month)

| Service | Cost |
|---------|------|
| Cloudflare Workers | $0 (free tier) |
| D1 Database | $0 (free tier) |
| Resend | $0 (free tier) |
| Custom Domain | $12/year |
| **Total** | **~$1/month** |

### Growth Scale (10k users, 1M requests/month)

| Service | Cost |
|---------|------|
| Cloudflare Workers | $5 |
| D1 Database | $1 |
| Resend | $0-20 |
| Custom Domain | $12/year |
| **Total** | **~$6-26/month** |

## Security Considerations

### Authentication
- HTTP-only cookies (prevents XSS)
- Secure flag in production (HTTPS only)
- SameSite=Lax (CSRF protection)
- 7-day expiration with refresh
- Magic links expire in 5 minutes

### Database
- Parameterized queries (Drizzle)
- No raw SQL from user input
- Foreign key constraints
- Unique constraints on sensitive fields

### Headers
```javascript
X-Frame-Options: DENY
X-Content-Type-Options: nosniff
Referrer-Policy: strict-origin-when-cross-origin
Permissions-Policy: geolocation=(), microphone=(), camera=()
```

### Rate Limiting
- Cloudflare automatic (per IP/user)
- WAF rules for API endpoints
- Bot protection enabled

## Migration from Other Platforms

### From Vercel

**Database**: Postgres/Supabase → D1 (SQLite)
- Export data as SQL
- Convert to SQLite syntax
- Import to D1

**Auth**: NextAuth → Better Auth
- Export users table
- Migrate to Better Auth schema
- Users re-authenticate

**Edge**: Vercel Edge → Cloudflare Workers
- Already edge-compatible
- Minor runtime API differences

### From Traditional VPS

**Architecture**: Monolith → Serverless
- Refactor to App Router
- Separate API routes
- Move to D1 database

**Deployment**: Manual → CI/CD
- GitHub Actions workflow
- Automatic deploys on push
- Instant rollbacks

## Troubleshooting Guide

### Build Errors

**Error**: `Cannot find module '@opennextjs/cloudflare'`
**Fix**: `rm -rf node_modules pnpm-lock.yaml && pnpm install`

**Error**: TypeScript errors in schema files
**Fix**: Restart TS server, verify imports

### Runtime Errors

**Error**: `D1_ERROR: Database binding not found`
**Fix**: Check `wrangler.toml` has correct `database_id`

**Error**: Session not persisting
**Fix**: Verify `BETTER_AUTH_SECRET` set, cookies enabled

### Deployment Issues

**Error**: 502 Bad Gateway
**Fix**: Check Worker logs (`npx wrangler tail`)

**Error**: Pages return 404 (should be 200)
**Fix**: Verify page status in database, check Worker blocking logic

## Testing Strategy

### Unit Tests
- Utility functions
- Database queries
- Auth helpers

### Integration Tests
- API endpoints
- Authentication flow
- pSEO page rendering

### E2E Tests
- User registration
- Login flow
- Program creation
- Strava integration

### Performance Tests
- Load testing (10k concurrent users)
- Database query performance
- Cold start latency

## Monitoring and Observability

### Metrics to Track

**Application**:
- Request rate (requests/minute)
- Error rate (4xx, 5xx)
- Response time (P50, P95, P99)
- Cold start frequency

**Database**:
- Query latency
- Query count (reads vs writes)
- Error rate
- Storage usage

**Authentication**:
- Login success rate
- Magic link delivery rate
- Session creation rate
- Active sessions

**pSEO**:
- Active pages count
- Blocked requests (404s)
- Activation rate (pages/day)

### Alerting Rules

- Error rate > 5%
- Response time P95 > 500ms
- Database errors > 0
- Email delivery failures > 10%

## Future Enhancements

### Planned Features

- [ ] Strava OAuth integration
- [ ] Multi-factor authentication (TOTP)
- [ ] Role-based access control (RBAC)
- [ ] Real-time program updates (WebSockets)
- [ ] Mobile app (React Native)
- [ ] AI training recommendations
- [ ] Team coaching features
- [ ] Payment integration (Stripe)

### Technical Debt

- [ ] Add comprehensive test coverage (>80%)
- [ ] Implement request tracing
- [ ] Setup error tracking (Sentry)
- [ ] Add performance monitoring (Web Vitals)
- [ ] Implement feature flags
- [ ] Add database backup automation

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

### Guides
- [Setup Guide](./guides/setup.md)
- [Deployment Guide](./guides/deployment.md)
- [Technical Docs](./technical/)

## License

MIT License - See LICENSE file for details

## Support

- **GitHub**: [github.com/your-org/strava_app](https://github.com/your-org/strava_app)
- **Discord**: [discord.gg/tritrainer](https://discord.gg/tritrainer)
- **Email**: support@tritrainer.app

---

**Maintained by**: TriTrainer Team
**Last Review**: 2025-01-02
**Next Review**: 2025-04-02 (quarterly)
