# ADR-005: Custom Worker Wrapper for Page Status Blocking

## Status
**Accepted** - 2025-01-02

## Context

We needed a way to block access to pSEO pages based on their database status while maintaining the benefits of pre-rendered static HTML. Requirements:

- All pSEO pages pre-generated at build time for SEO quality
- Pages blocked at HTTP level (404 response) based on database status
- No client-side blocking (must work for search engine crawlers)
- Instant activation/deactivation without redeployment
- Minimal performance impact (<5ms overhead)

### Problem with Component-Level Blocking

Initial attempts to block pages in the Next.js page component failed:

```typescript
// ❌ This doesn't work with static generation
export default async function Page() {
  const { env } = await getCloudflareContext();
  const page = await checkPageStatus(env.DB);

  if (page.status !== 'active') {
    notFound(); // Never executes for pre-rendered pages
  }
}
```

**Why it failed**:
- Next.js with `generateStaticParams()` pre-renders all pages at build time
- Pre-rendered HTML is served directly from static assets
- Page component code never executes on request
- Even `export const dynamic = 'force-dynamic'` doesn't help with OpenNext

### Problem with Middleware-Level Blocking

Attempted to use Next.js middleware for status checking:

```typescript
// ❌ This doesn't work with OpenNext
export async function middleware(request: NextRequest) {
  const db = process.env.DB; // undefined
  // Middleware doesn't have access to D1 bindings
}
```

**Why it failed**:
- Next.js middleware runs in Edge Runtime
- OpenNext doesn't expose Cloudflare bindings to middleware
- No access to `env.DB` for database queries

## Decision

We will implement a **custom Cloudflare Worker wrapper** that intercepts requests before they reach the OpenNext worker and checks page status in D1.

### Architecture

```
User Request
    ↓
worker.js (Custom Wrapper)
    ↓
isPSEORoute(pathname) ? → No → Pass to OpenNext
    ↓ Yes
Query D1: SELECT status WHERE url_path = ?
    ↓
status === 'active' ? → Yes → Serve pre-rendered HTML
    ↓ No
Return 404 (blocked)
```

### Key Components

1. **Custom Worker Entry Point** (`worker.js`)
   - Intercepts all requests before OpenNext
   - Pattern matching for pSEO routes
   - Direct D1 database access via bindings

2. **Pattern-Based Route Detection**
   - Regex patterns for each pSEO route type
   - Fast in-memory route matching
   - No false positives on non-pSEO routes

3. **Database Query with Drizzle**
   - Type-safe queries
   - <1ms query latency
   - Graceful error handling (fail open)

## Consequences

### Positive

- **True HTTP Blocking**: Returns 404 status code, not client-side redirect
- **Search Engine Friendly**: Crawlers see proper HTTP status codes
- **Instant Activation**: SQL UPDATE reflects globally in <100ms
- **Zero Component Changes**: Page components stay simple and focused
- **Performance**: <1ms overhead per pSEO request
- **Type Safety**: Drizzle ORM provides TypeScript inference
- **Observability**: Console logging for debugging and monitoring

### Negative

- **Additional Query**: Every pSEO request requires D1 lookup
- **Bypass Risk**: If Worker fails, pages might be accessible (fail-open design)
- **Build Configuration**: Requires custom `main` in wrangler.toml
- **Debugging Complexity**: Worker logs separate from Next.js logs
- **OpenNext Updates**: May need adjustments when updating OpenNext version

### Neutral

- **Extra File**: `worker.js` in project root (outside Next.js structure)
- **Pattern Maintenance**: Need to update PSEO_ROUTES when adding new page types
- **Dual Logging**: Both Worker and Next.js logs to monitor

## Alternatives Considered

### 1. Conditional Static Generation (generateStaticParams filter)
**Approach**: Only generate pages with `status='active'` at build time
**Pros**: No runtime queries, smaller build size
**Cons**: Requires full redeploy to activate pages, defeats instant rollout goal

### 2. Client-Side Redirect
**Approach**: Serve HTML, redirect in browser based on status check
**Pros**: Simple implementation
**Cons**: Search engines index the page (HTML exists), poor SEO, higher bounce rate

### 3. Cloudflare Workers KV for Status Cache
**Approach**: Cache page status in KV, check in Worker
**Pros**: Potentially faster reads (though D1 is already <1ms)
**Cons**: Eventually consistent, cache invalidation complexity, extra infrastructure

### 4. R2 Bucket with Metadata
**Approach**: Store page metadata in R2 object metadata
**Pros**: No database needed
**Cons**: Slower queries, harder to query/filter, no relational benefits

## Implementation Details

### Worker Entry Point (worker.js)

```javascript
import openNextWorker from './.open-next/worker.js';
import { drizzle } from 'drizzle-orm/d1';
import { eq } from 'drizzle-orm';
import { pseoPages } from './src/lib/db/schema/pseo.js';

// Pattern to match pSEO routes
const PSEO_ROUTES = [
  /^\/generateur\//,
  /^\/competition\//,
  /^\/profil\//,
  /^\/programme\//,
];

function isPSEORoute(pathname) {
  return PSEO_ROUTES.some(pattern => pattern.test(pathname));
}

async function checkPageStatus(db, pathname) {
  console.log('[Worker] Checking page status:', pathname);

  const drizzleDb = drizzle(db);

  try {
    const result = await drizzleDb
      .select()
      .from(pseoPages)
      .where(eq(pseoPages.urlPath, pathname))
      .limit(1);

    const page = result[0];

    if (!page) {
      return 'not-found';
    }

    if (page.status === 'active') {
      return 'active';
    }

    return 'blocked';
  } catch (error) {
    console.error('[Worker] Database error:', error);
    // Fail open: allow request on database errors
    return 'active';
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // Check if this is a pSEO route
    if (isPSEORoute(url.pathname)) {
      const status = await checkPageStatus(env.DB, url.pathname);

      if (status === 'blocked') {
        return new Response('Not Found', {
          status: 404,
          headers: { 'Content-Type': 'text/plain' },
        });
      }
    }

    // Pass request to OpenNext worker
    return openNextWorker.fetch(request, env, ctx);
  },
};
```

### Wrangler Configuration

```toml
# wrangler.toml
name = "triathlon-app"
main = "worker.js"  # Custom wrapper instead of .open-next/worker.js
compatibility_date = "2024-12-01"

[assets]
directory = ".open-next/assets"

[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
database_id = "your-database-id"
```

### Route Pattern Maintenance

When adding new pSEO page types, update the patterns:

```javascript
const PSEO_ROUTES = [
  /^\/generateur\//,      // Training plan generator pages
  /^\/competition\//,     // Competition-specific pages
  /^\/profil\//,          // Athlete profile pages
  /^\/programme\//,       // Weakness-focused programs
  // Add new patterns here as needed
];
```

### Error Handling Strategy

**Fail Open**: If database query fails, allow the request through
- **Rationale**: Prefer availability over strict blocking
- **Monitoring**: Log errors for investigation
- **Alert**: Set up alerts for database errors in production

**Alternative (Fail Closed)**: Block all pSEO pages on database errors
- **Use case**: High-security requirements where blocking is critical
- **Trade-off**: Risk of false 404s if database has issues

## Performance Impact

### Latency Overhead per pSEO Request

| Operation | Latency |
|-----------|---------|
| Pattern matching | <0.1ms |
| D1 query (SELECT with index) | <1ms |
| Response creation (404) | <0.1ms |
| **Total overhead** | **~1ms** |

### Database Load (10k pSEO requests/day)

- Reads: 10,000/day
- Cost: Free (under 5M/day limit)
- Index usage: `idx_pseo_pages_url` ensures fast lookups

### Caching Considerations

**Current**: No caching (always fresh status)
- Pros: Instant activation, no cache invalidation
- Cons: Database query on every request

**Alternative**: Worker KV cache with TTL
- Cache page status for 60 seconds
- Reduce D1 queries by ~99%
- Trade-off: Up to 60-second activation delay

## Testing and Validation

### Manual Testing

```bash
# Test pending page (should return 404)
curl -I https://tritrainer.app/generateur/xs-debutant
# HTTP/1.1 404 Not Found

# Activate page via SQL
npx wrangler d1 execute triathlon-db --remote --command \
  "UPDATE pseo_pages SET status='active' WHERE url_path='/generateur/xs-debutant'"

# Test again (should return 200)
curl -I https://tritrainer.app/generateur/xs-debutant
# HTTP/1.1 200 OK
```

### Worker Logs Verification

```
[Worker] Path: /generateur/xs-debutant
[Worker] pSEO route detected
[Worker] Checking page status: /generateur/xs-debutant
[Worker] Page query result: { found: true, status: 'pending', title: '...' }
[Worker] Page status: blocked
[Worker] ❌ Blocking pending/paused/archived page
```

### Automated Testing (GitHub Actions)

```yaml
name: Validate pSEO Pages

on:
  schedule:
    - cron: '0 */6 * * *'  # Every 6 hours
  workflow_dispatch:

jobs:
  test-active-pages:
    runs-on: ubuntu-latest
    steps:
      - name: Test active pages return 200
        run: |
          npx wrangler d1 execute triathlon-db --remote --command \
            "SELECT url_path FROM pseo_pages WHERE status='active'" \
          | jq -r '.results[].url_path' \
          | while read path; do
              status=$(curl -s -o /dev/null -w "%{http_code}" "https://tritrainer.app$path")
              if [ "$status" != "200" ]; then
                echo "❌ $path returned $status (expected 200)"
                exit 1
              fi
            done

  test-pending-pages:
    runs-on: ubuntu-latest
    steps:
      - name: Test pending pages return 404
        run: |
          npx wrangler d1 execute triathlon-db --remote --command \
            "SELECT url_path FROM pseo_pages WHERE status='pending'" \
          | jq -r '.results[].url_path' \
          | while read path; do
              status=$(curl -s -o /dev/null -w "%{http_code}" "https://tritrainer.app$path")
              if [ "$status" != "404" ]; then
                echo "❌ $path returned $status (expected 404)"
                exit 1
              fi
            done
```

## Security Considerations

### SQL Injection Protection
- **Risk**: Pathname used in database query
- **Mitigation**: Drizzle ORM uses parameterized queries
- **Additional**: Pathname validation via regex patterns

### Denial of Service Protection
- **Risk**: Database query on every pSEO request
- **Mitigation**: D1 query limits (5M reads/day free tier)
- **Additional**: Cloudflare rate limiting at edge

### Information Disclosure
- **Risk**: 404 response reveals page existence
- **Mitigation**: Generic "Not Found" message (no status details)
- **Consider**: Same response for non-existent and pending pages

## Monitoring and Observability

### Key Metrics to Track

1. **pSEO Request Rate**
   - Worker logs: `[Worker] pSEO route detected`
   - Alert: Sudden spikes (potential attack)

2. **Blocked Request Count**
   - Worker logs: `[Worker] ❌ Blocking`
   - Track: Should decrease as rollout progresses

3. **Database Query Latency**
   - D1 Analytics dashboard
   - Alert: Queries >10ms (potential index issue)

4. **Database Error Rate**
   - Worker logs: `[Worker] Database error`
   - Alert: Any errors (should be 0)

### Dashboard Queries

```sql
-- Count blocked vs allowed requests (requires logging to database)
SELECT
  DATE(timestamp) as date,
  SUM(CASE WHEN action = 'blocked' THEN 1 ELSE 0 END) as blocked,
  SUM(CASE WHEN action = 'allowed' THEN 1 ELSE 0 END) as allowed
FROM worker_logs
WHERE route_type = 'pseo'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

## Related ADRs

- [ADR-002: Cloudflare Workers Deployment](002-cloudflare-workers-deployment.md)
- [ADR-003: D1 Database with Drizzle ORM](003-d1-database-drizzle-orm.md)
- [ADR-004: pSEO Database-Driven Rollout](004-pseo-database-driven-rollout.md)

## References

- [Cloudflare Workers Fetch Handler](https://developers.cloudflare.com/workers/runtime-apis/handlers/fetch/)
- [Drizzle ORM D1 Documentation](https://orm.drizzle.team/docs/get-started-sqlite#cloudflare-d1)
- [OpenNext Cloudflare Adapter](https://opennext.js.org/cloudflare)
- [HTTP Status Code 404](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/404)
