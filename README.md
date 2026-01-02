# Next.js 15 + Cloudflare Workers + D1 Boilerplate

Production-ready boilerplate for building edge-deployed Next.js applications with programmatic SEO and passwordless authentication.

## Stack

| Technology | Purpose | Why |
|------------|---------|-----|
| **Next.js 15** | Framework | App Router, Server Components, SSG |
| **Cloudflare Workers** | Runtime | Global edge, <50ms latency, $0-5/month |
| **OpenNext** | Adapter | Next.js → Workers transpilation |
| **D1** | Database | Edge SQLite, <1ms queries |
| **Drizzle ORM** | ORM | Type-safe, edge-compatible |
| **Better Auth** | Auth | Passwordless, magic links, edge-native |
| **Resend** | Email | Reliable delivery, great DX |

## Features

- **Edge-First**: Deployed globally on Cloudflare's 275+ locations
- **Database-Driven pSEO**: Activate pages instantly without redeployment
- **Passwordless Auth**: Magic links via email
- **Type-Safe**: Full TypeScript with Drizzle ORM inference
- **Cost-Effective**: Free tier covers startup scale ($0-6/month)

## Documentation

### Architecture Decision Records (ADRs)

| ADR | Title |
|-----|-------|
| [001](docs/adr/001-nextjs-app-router.md) | Next.js 15 with App Router |
| [002](docs/adr/002-cloudflare-workers-deployment.md) | Cloudflare Workers Deployment |
| [003](docs/adr/003-d1-database-drizzle-orm.md) | D1 Database with Drizzle ORM |
| [004](docs/adr/004-pseo-database-driven-rollout.md) | pSEO Database-Driven Rollout |
| [005](docs/adr/005-worker-wrapper-page-blocking.md) | Custom Worker Wrapper |
| [006](docs/adr/006-better-auth-authentication.md) | Better Auth Authentication |

### Technical Documentation

- [Project Structure](docs/technical/project-structure.md)
- [Database Schema](docs/technical/database-schema.md)
- [API Routes](docs/technical/api-routes.md)

### Guides

- [Local Setup](docs/guides/setup.md)
- [Deployment](docs/guides/deployment.md)

### Full Specification

- [**Boilerplate Specification**](docs/BOILERPLATE_SPEC.md) - Complete reference

## Quick Start

### Prerequisites

```bash
node -v  # 20+
pnpm -v  # 8+
```

### Setup

```bash
# Clone/copy this boilerplate
cd your-project-name

# Install dependencies
pnpm install

# Create environment file
cp .env.example .env.local

# Create D1 database
npx wrangler d1 create your-db-name
# Update wrangler.toml with database_id

# Run migrations
for f in migrations/*.sql; do
  npx wrangler d1 execute your-db --remote --file "$f"
done

# Start development
pnpm dev
```

### Deploy

```bash
# Build
pnpm build

# Deploy to Cloudflare
npx wrangler deploy
```

## Architecture

```
User Request
    ↓
Cloudflare Edge (275+ locations)
    ↓
worker.js (Custom Wrapper)
    ↓ pSEO check: D1 query (<1ms)
    ↓
OpenNext Worker
    ↓
Next.js App
    ↓
D1 Database
```

## Key Patterns

### 1. Worker Wrapper for pSEO Blocking

```javascript
// worker.js
if (isPSEORoute(pathname)) {
  const status = await checkPageStatus(env.DB, pathname);
  if (status === 'blocked') {
    return new Response('Not Found', { status: 404 });
  }
}
return openNextWorker.fetch(request, env, ctx);
```

### 2. Database-Driven Page Activation

```sql
-- Instantly activate pages (no redeploy)
UPDATE pseo_pages
SET status = 'active', published_at = unixepoch()
WHERE sitemap_batch = 1;
```

### 3. Edge-Native Authentication

```typescript
// Better Auth with D1
const auth = betterAuth({
  database: drizzleAdapter(db, { provider: 'sqlite' }),
  plugins: [magicLink({ /* ... */ })],
});
```

## Cost Estimate

### Free Tier (startup)
- Workers: 100k requests/day
- D1: 5M reads/day
- Resend: 3k emails/month
- **Total: $0/month**

### Growth (10k users)
- Workers: $5/month
- D1: $1/month
- Resend: $0-20/month
- **Total: ~$6-26/month**

## File Structure

```
boilerplate/
├── docs/                   # All documentation
│   ├── adr/               # Architecture decisions
│   ├── technical/         # Technical docs
│   ├── guides/            # How-to guides
│   └── BOILERPLATE_SPEC.md
├── migrations/             # SQL migrations
├── .claude/               # Claude Code config
├── worker.js              # Custom Worker wrapper
├── wrangler.toml          # Cloudflare config
└── README.md              # This file
```

## Customization Checklist

- [ ] Update `wrangler.toml` with your app name
- [ ] Create D1 database and update `database_id`
- [ ] Configure environment variables
- [ ] Customize database schema for your domain
- [ ] Update pSEO clusters for your content
- [ ] Configure email sender in Resend
- [ ] Setup custom domain

## License

MIT

## Credits

Based on [TriTrainer](https://tritrainer.app) architecture.
