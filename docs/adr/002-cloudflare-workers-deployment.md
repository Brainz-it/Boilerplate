# ADR-002: Cloudflare Workers Deployment with OpenNext

## Status
**Accepted** - 2025-01-02

## Context

We needed to choose a deployment platform for the Next.js application that provides:

- Global edge network for low latency
- Serverless execution (no server management)
- Affordable pricing for startup scale
- Integration with Cloudflare D1 database
- Support for Next.js App Router
- Custom domain support

## Decision

We will deploy to **Cloudflare Workers** using **OpenNext** adapter (`opennextjs-cloudflare`).

### Architecture

```
User Request
    ↓
Cloudflare Edge Network
    ↓
Custom Worker Wrapper (worker.js)
    ↓
OpenNext Worker (.open-next/worker.js)
    ↓
Next.js Application
    ↓
D1 Database / R2 Storage
```

### Key Components

1. **Cloudflare Workers**
   - Edge runtime (V8 isolates)
   - Global distribution (275+ cities)
   - Sub-50ms cold starts

2. **OpenNext Adapter**
   - Transpiles Next.js to Cloudflare-compatible code
   - Handles routing, caching, and assets
   - Maintains Next.js features on the edge

3. **Static Assets**
   - Served from `.open-next/assets/`
   - Automatic caching and compression
   - CDN distribution

## Consequences

### Positive

- **Performance**: Sub-50ms response times globally
- **Cost**: Free tier includes 100k requests/day, then $5/10M requests
- **Scalability**: Automatically scales to handle traffic spikes
- **D1 Integration**: Native database integration without VPC setup
- **Developer Experience**: Simple deployment with `wrangler deploy`
- **Zero Downtime**: Instant deployments with automatic rollback

### Negative

- **Vendor Lock-in**: Heavily tied to Cloudflare ecosystem
- **Runtime Limitations**: No Node.js APIs (only Web APIs + polyfills)
- **Build Artifacts**: Generated files in `.open-next/` (gitignored)
- **Debugging**: Worker logs less accessible than traditional servers
- **Cold Starts**: Rare but possible V8 isolate initialization delay

### Neutral

- **Learning Curve**: Need to understand Cloudflare Workers concepts
- **OpenNext Abstraction**: Additional layer between Next.js and runtime

## Alternatives Considered

### 1. Vercel
**Pros**: Native Next.js support, excellent DX, zero config
**Cons**: More expensive ($20/month Pro), vendor lock-in, less control

**Cost Comparison** (10M requests/month):
- Cloudflare: $5/month
- Vercel: $20-200/month (depending on features)

### 2. AWS Lambda + CloudFront
**Pros**: Full Node.js runtime, mature ecosystem
**Cons**: Complex setup (VPC, ALB, Lambda, CloudFront), higher latency, more expensive

### 3. Traditional VPS (DigitalOcean, Hetzner)
**Pros**: Full control, predictable pricing
**Cons**: Manual scaling, server management, no global edge network

### 4. Netlify
**Pros**: Good DX, integrated features
**Cons**: Pricing similar to Vercel, less suitable for dynamic apps

## Implementation Details

### Deployment Configuration

```toml
# wrangler.toml
name = "triathlon-app"
main = "worker.js"  # Custom wrapper
compatibility_date = "2024-12-01"

[assets]
directory = ".open-next/assets"

[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
```

### Build Process

```bash
# 1. Build Next.js app
pnpm run build

# 2. OpenNext generates Cloudflare-compatible artifacts
# Output: .open-next/ directory

# 3. Deploy to Workers
npx wrangler deploy
```

### Custom Worker Wrapper

We wrap the OpenNext worker to add custom logic (see ADR-005):

```javascript
// worker.js
import openNextWorker from './.open-next/worker.js';

export default {
  async fetch(request, env, ctx) {
    // Custom logic (page status checks, etc.)
    return openNextWorker.fetch(request, env, ctx);
  },
};
```

## Performance Metrics

- **Cold Start**: <50ms (V8 isolate initialization)
- **Warm Response**: <10ms (cache hit)
- **Global Latency**: <100ms (95th percentile)
- **Build Time**: ~2 minutes (160 pages)

## Cost Analysis

### Free Tier
- 100,000 requests/day
- 10ms CPU time per request
- Perfect for MVP and development

### Production Estimate (1M requests/month)
- Workers: Free (under 100k/day limit)
- D1: Free (under 5M reads)
- **Total**: $0/month

### Scale Estimate (10M requests/month)
- Workers: ~$5/month
- D1: ~$1/month
- **Total**: ~$6/month

## Related ADRs

- [ADR-001: Next.js 15 with App Router](001-nextjs-app-router.md)
- [ADR-003: D1 Database with Drizzle ORM](003-d1-database-drizzle-orm.md)
- [ADR-005: Custom Worker Wrapper](005-worker-wrapper-page-blocking.md)

## References

- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [OpenNext Cloudflare Adapter](https://opennext.js.org/cloudflare)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)
- [Cloudflare Pricing](https://www.cloudflare.com/plans/developer-platform/)
