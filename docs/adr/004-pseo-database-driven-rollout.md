# ADR-004: pSEO Database-Driven Rollout System

## Status
**Accepted** - 2025-01-02

## Context

We need to generate hundreds of programmatic SEO (pSEO) pages for triathlon training plans. Requirements:

- Generate pages for all combinations (distance × level × language)
- Prevent premature indexing by search engines
- Control rollout timing without redeployments
- Monitor activation progress
- Enable instant page activation/deactivation
- Support A/B testing and gradual rollout

### Problem with Traditional Approach

Standard SSG with Next.js `generateStaticParams()`:
- All pages generated at build time
- All pages immediately accessible (HTTP 200)
- Google crawls and indexes all pages instantly
- No control over rollout timing
- Requires redeploy to add/remove pages

## Decision

We will implement a **database-driven rollout system** that:

1. **Generates all pSEO pages at build time** (for SEO quality)
2. **Stores page metadata in D1** with status field
3. **Blocks pages at Worker level** based on database status
4. **Activates pages via SQL UPDATE** (no redeploy needed)

### Page Lifecycle States

```
pending → active → paused → archived
```

- **pending**: Page exists but returns 404 (not indexed)
- **active**: Page accessible, indexable
- **paused**: Temporarily disabled (maintenance, testing)
- **archived**: Permanently disabled (deprecated content)

### Architecture

```
User Request
    ↓
Worker Wrapper (worker.js)
    ↓
Check pSEO Route? → No → Pass to OpenNext
    ↓ Yes
Query D1 (SELECT status WHERE url_path = ?)
    ↓
status = 'active' ? → Yes → Serve pre-rendered HTML
    ↓ No
Return 404 (blocked)
```

## Consequences

### Positive

- **Zero Redeploy Activation**: Pages activate via `UPDATE pseo_pages SET status='active'`
- **Instant Control**: Database update reflects in <100ms globally
- **Gradual Rollout**: Activate pages in batches (10/day, 50/week, etc.)
- **SEO Quality**: Pre-rendered HTML with full content (not client-side)
- **Monitoring**: Track which pages are active via database queries
- **A/B Testing**: Easily enable/disable page variants
- **Cost Savings**: Pay only for active page reads

### Negative

- **Database Dependency**: Every pSEO request requires D1 query
- **Build Size**: All pages pre-rendered (160+ pages = larger build)
- **Cache Complexity**: Worker-level blocking bypasses Next.js cache
- **Migration Burden**: New pages require database insert

### Neutral

- **Additional Query**: <1ms latency per request (acceptable)
- **Build Time**: ~2 minutes for 160 pages (manageable)

## Alternatives Considered

### 1. Conditional SSG (generateStaticParams with filter)
**Approach**: Only generate pages marked as active
**Pros**: Smaller build size, no extra queries
**Cons**: Requires redeploy to activate pages, slower rollout, build complexity

### 2. Client-Side Blocking
**Approach**: Serve HTML, check status in browser
**Pros**: Simple implementation
**Cons**: Page indexed by Google (HTML exists), poor SEO, higher bounce rate

### 3. Middleware Blocking
**Approach**: Check status in Next.js middleware
**Cons**: Next.js middleware doesn't have access to D1 bindings with OpenNext

### 4. Dynamic Routes Only (no SSG)
**Approach**: Fetch data at request time
**Pros**: No build size issues
**Cons**: Slower TTFB, higher D1 costs, worse SEO

## Implementation Details

### Database Schema

```sql
CREATE TABLE pseo_pages (
  id TEXT PRIMARY KEY,
  url_path TEXT NOT NULL UNIQUE,
  page_type TEXT NOT NULL,
  title TEXT NOT NULL,
  meta_description TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  batch INTEGER,
  created_at INTEGER NOT NULL,
  activated_at INTEGER,

  CHECK (status IN ('pending', 'active', 'paused', 'archived'))
);

CREATE INDEX idx_pseo_pages_status ON pseo_pages(status);
CREATE INDEX idx_pseo_pages_url ON pseo_pages(url_path);
CREATE INDEX idx_pseo_pages_batch ON pseo_pages(batch);
```

### Worker Blocking Logic

```javascript
// worker.js
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
  const result = await drizzle(db)
    .select()
    .from(pseoPages)
    .where(eq(pseoPages.urlPath, pathname))
    .limit(1);

  const page = result[0];
  if (!page || page.status !== 'active') {
    return 'blocked';
  }
  return 'active';
}

// In fetch handler
if (isPSEORoute(url.pathname)) {
  const status = await checkPageStatus(env.DB, url.pathname);
  if (status === 'blocked') {
    return new Response('Not Found', { status: 404 });
  }
}
```

### Rollout Automation (GitHub Actions)

```yaml
name: pSEO Rollout

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM UTC
  workflow_dispatch:

jobs:
  activate-batch:
    runs-on: ubuntu-latest
    steps:
      - name: Activate next batch
        run: |
          npx wrangler d1 execute triathlon-db --remote --command "
            UPDATE pseo_pages
            SET status = 'active', activated_at = unixepoch()
            WHERE status = 'pending'
            AND batch = (
              SELECT MIN(batch) FROM pseo_pages WHERE status = 'pending'
            )
          "
```

### Page Generation

```typescript
// Generate all pages but mark as pending
const pages = generateAllPSEOPages();

for (const page of pages) {
  await db.insert(pseoPages).values({
    id: nanoid(),
    urlPath: page.path,
    pageType: page.type,
    title: page.title,
    metaDescription: page.description,
    status: 'pending',  // Start as pending
    batch: page.batch,  // Rollout batch number
    createdAt: Date.now(),
  });
}
```

## Rollout Strategy

### Batch Schedule

| Batch | Pages | Activation | Target Traffic |
|-------|-------|------------|----------------|
| 0 | 5 | Immediate | Core pages (training-plans) |
| 1 | 28 | +3 days | Generator pages (all distances × levels) |
| 2 | 10 | +7 days | Competition pages |
| 3 | 4 | +14 days | Weakness-focused programs |
| 4 | 5 | +21 days | Athlete profile pages |

### Monitoring Queries

```sql
-- Count pages by status
SELECT status, COUNT(*) as count
FROM pseo_pages
GROUP BY status;

-- Next batch to activate
SELECT batch, COUNT(*) as pages
FROM pseo_pages
WHERE status = 'pending'
GROUP BY batch
ORDER BY batch
LIMIT 1;

-- Recently activated pages
SELECT url_path, activated_at
FROM pseo_pages
WHERE status = 'active'
ORDER BY activated_at DESC
LIMIT 10;
```

## Performance Impact

### Additional Latency per Request
- D1 Query: <1ms
- Status Check Logic: <0.1ms
- **Total Overhead**: ~1ms

### Database Load (10k pSEO requests/day)
- Reads: 10k/day
- Cost: Free (under 5M/day limit)

## SEO Considerations

### For Blocked Pages (404)
- Google sees 404 status code
- Page not indexed
- No duplicate content issues
- Clean activation (404 → 200 when activated)

### For Active Pages
- Pre-rendered HTML with full content
- Fast TTFB (<100ms)
- All meta tags present
- Search engines index normally

## Related ADRs

- [ADR-003: D1 Database with Drizzle ORM](003-d1-database-drizzle-orm.md)
- [ADR-005: Custom Worker Wrapper](005-worker-wrapper-page-blocking.md)

## References

- [Programmatic SEO Best Practices](https://www.contentatscale.ai/blog/programmatic-seo/)
- [Google Search Central - Managing Crawl Budget](https://developers.google.com/search/docs/crawling-indexing/large-site-managing-crawl-budget)
