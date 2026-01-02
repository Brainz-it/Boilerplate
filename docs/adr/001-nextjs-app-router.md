# ADR-001: Next.js 15 with App Router

## Status
**Accepted** - 2025-01-02

## Context

We needed to choose a React framework for building the TriTrainer triathlon training platform. The application requires:

- Server-side rendering (SSR) for SEO
- Static site generation (SSG) for performance
- Dynamic routes for programmatic SEO
- API routes for backend functionality
- Modern React features (Server Components, Server Actions)
- Edge runtime compatibility for Cloudflare Workers

## Decision

We will use **Next.js 15 with the App Router** as the primary framework.

### Key Features Utilized

1. **App Router** (not Pages Router)
   - File-based routing with `app/` directory
   - React Server Components by default
   - Server Actions for mutations
   - Nested layouts and loading states

2. **Rendering Strategies**
   - SSG with `generateStaticParams()` for pSEO pages
   - Server Components for dynamic data fetching
   - `export const dynamic = 'force-dynamic'` where needed

3. **API Routes**
   - Route handlers in `app/api/`
   - Server Actions for form submissions
   - Edge runtime compatible handlers

## Consequences

### Positive

- **SEO Optimized**: Pre-rendered HTML for search engines
- **Performance**: Automatic code splitting and optimization
- **Developer Experience**: TypeScript-first, hot reload, great DX
- **Modern React**: Server Components reduce client-side JavaScript
- **Flexibility**: Mix SSG, SSR, and dynamic rendering as needed
- **Edge Compatible**: Works seamlessly with Cloudflare Workers via OpenNext

### Negative

- **Learning Curve**: App Router is relatively new (different from Pages Router)
- **Build Complexity**: Pre-rendering 160+ pages increases build time
- **Cache Management**: Understanding Next.js caching can be complex
- **Migration Path**: Harder to migrate away from Next.js if needed

### Neutral

- **Framework Lock-in**: Committed to Next.js patterns and conventions
- **Bundle Size**: Next.js adds framework overhead (~105KB shared chunks)

## Alternatives Considered

### 1. Remix
**Pros**: Excellent data loading, web standards-focused
**Cons**: Less mature ecosystem, smaller community, unclear Cloudflare Workers support at the time

### 2. Astro
**Pros**: Multi-framework support, excellent for content sites
**Cons**: Less suited for dynamic applications, smaller ecosystem for React patterns

### 3. Vanilla React + Vite
**Pros**: Full control, minimal framework overhead
**Cons**: Would need to implement SSR/SSG ourselves, losing productivity

### 4. SvelteKit
**Pros**: Excellent performance, great DX
**Cons**: Team unfamiliarity, different ecosystem, smaller job market

## Implementation Details

### File Structure
```
src/
├── app/
│   ├── (landing)/          # Landing page route group
│   ├── (pseo)/             # pSEO pages route group
│   │   └── [...slug]/      # Dynamic catch-all route
│   ├── api/                # API routes
│   ├── dashboard/          # Protected dashboard
│   └── layout.tsx          # Root layout
```

### Configuration
```typescript
// next.config.ts
const nextConfig: NextConfig = {
  output: 'standalone',  // For OpenNext deployment
  // ... other config
}
```

## Related ADRs

- [ADR-002: Cloudflare Workers Deployment](002-cloudflare-workers-deployment.md)
- [ADR-004: pSEO Database-Driven Rollout](004-pseo-database-driven-rollout.md)

## References

- [Next.js 15 Documentation](https://nextjs.org/docs)
- [App Router Migration Guide](https://nextjs.org/docs/app/building-your-application/upgrading/app-router-migration)
- [React Server Components](https://react.dev/reference/rsc/server-components)
