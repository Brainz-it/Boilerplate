# ADR-003: D1 Database with Drizzle ORM

## Status
**Accepted** - 2025-01-02

## Context

We needed a database solution that:

- Integrates natively with Cloudflare Workers
- Provides SQL capabilities for complex queries
- Offers type-safe database access
- Supports schema migrations
- Scales with application growth
- Remains cost-effective at startup scale

## Decision

We will use **Cloudflare D1** (SQLite) as the database, with **Drizzle ORM** for type-safe database access.

### Architecture

```
Application Code
    ↓
Drizzle ORM (Type-safe queries)
    ↓
D1 Binding (env.DB)
    ↓
Cloudflare D1 (SQLite)
    ↓
Distributed SQLite Replicas
```

## Consequences

### Positive

- **Zero Latency**: Database runs on same edge location as Worker
- **Type Safety**: Drizzle provides full TypeScript inference
- **SQL Capabilities**: Full SQLite feature set (joins, transactions, etc.)
- **Cost**: Free tier includes 5M reads/day, then $0.001/100k reads
- **Developer Experience**: Drizzle Studio for database management
- **Schema Migrations**: Version-controlled SQL migrations
- **No Connection Pool**: Direct bindings, no connection management

### Negative

- **Vendor Lock-in**: D1 is Cloudflare-specific
- **SQLite Limitations**: No stored procedures, limited concurrency
- **Write Performance**: Single-writer architecture (though read replicas exist)
- **Database Size**: 2GB limit per database (current plan)
- **Beta Status**: D1 is still evolving (though production-ready)

### Neutral

- **SQL Dialect**: SQLite syntax (slightly different from PostgreSQL/MySQL)
- **Migration Management**: Manual SQL migration files

## Alternatives Considered

### 1. PostgreSQL (Neon, Supabase, PlanetScale)
**Pros**: Full-featured, mature ecosystem, horizontal scaling
**Cons**: Higher latency (not edge-native), more expensive, connection pooling complexity

**Latency Comparison**:
- D1: <1ms (same edge node)
- Neon: 50-200ms (regional database)

### 2. Cloudflare KV
**Pros**: Even simpler key-value store
**Cons**: No SQL, no complex queries, eventual consistency, harder to model relationships

### 3. Cloudflare Durable Objects
**Pros**: Strong consistency, stateful
**Cons**: Complex programming model, overkill for this use case, more expensive

### 4. PrismaClient on Workers
**Pros**: Popular ORM, great DX
**Cons**: Large bundle size (~1MB), slow cold starts, doesn't support D1 well

## Implementation Details

### Schema Definition (Drizzle)

```typescript
// src/lib/db/schema/users.ts
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: text('id').primaryKey(),
  email: text('email').notNull().unique(),
  name: text('name').notNull(),
  createdAt: integer('created_at', { mode: 'timestamp' }).notNull(),
});
```

### Type-Safe Queries

```typescript
import { drizzle } from 'drizzle-orm/d1';
import { users } from './schema/users';
import { eq } from 'drizzle-orm';

const db = drizzle(env.DB);

// Fully typed query
const user = await db
  .select()
  .from(users)
  .where(eq(users.email, 'user@example.com'))
  .limit(1);
```

### Migration System

```sql
-- migrations/0001_create_users.sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_users_email ON users(email);
```

```bash
# Apply migration
npx wrangler d1 execute triathlon-db \
  --remote \
  --file migrations/0001_create_users.sql
```

### Database Access Patterns

1. **Local Development**: `better-sqlite3`
   ```typescript
   const db = drizzle(new Database('local.db'));
   ```

2. **Production**: D1 Binding
   ```typescript
   const db = drizzle(env.DB);
   ```

3. **Type-Safe Client**
   ```typescript
   export function getDatabase(d1: D1Database) {
     return {
       drizzle: drizzle(d1),
       // Add helper methods
     };
   }
   ```

## Schema Organization

```
src/lib/db/
├── schema/
│   ├── users.ts           # User accounts
│   ├── programs.ts        # Training programs
│   ├── sessions.ts        # Training sessions
│   ├── pseo.ts           # pSEO pages metadata
│   └── index.ts          # Export all schemas
├── index.ts              # Database client
└── migrations.ts         # Migration utilities

migrations/
├── 0001_create_users.sql
├── 0002_seed_data.sql
├── 0003_create_programs.sql
├── 0004_create_sessions.sql
├── 0005_pseo_tables.sql
└── 0006_pseo_seed.sql
```

## Performance Characteristics

### Read Performance
- Single row: <1ms
- Complex join (3 tables): <5ms
- Full table scan (10k rows): <50ms

### Write Performance
- Single insert: <2ms
- Batch insert (100 rows): <10ms
- Transaction (10 operations): <15ms

### Limitations
- Max query time: 30 seconds
- Max database size: 2GB (current tier)
- Max statement size: 1MB

## Cost Analysis

### Free Tier (per database)
- 5M reads/day
- 100k writes/day
- 1GB storage

### Production Pricing
- Reads: $0.001 per 100k
- Writes: $1.00 per 1M
- Storage: $0.75/GB/month

### Estimated Costs (100k users)
- Reads (10M/day): ~$2/month
- Writes (100k/day): ~$3/month
- Storage (500MB): ~$0.38/month
- **Total**: ~$5.38/month

## Migration Strategy

If we need to migrate away from D1 in the future:

1. **Database Export**: D1 → SQLite file
2. **SQLite → PostgreSQL**: Use `pgloader` or custom scripts
3. **Schema Migration**: Drizzle supports multiple databases
4. **Application Changes**: Minimal (Drizzle abstracts differences)

## Related ADRs

- [ADR-002: Cloudflare Workers Deployment](002-cloudflare-workers-deployment.md)
- [ADR-004: pSEO Database-Driven Rollout](004-pseo-database-driven-rollout.md)
- [ADR-005: Custom Worker Wrapper](005-worker-wrapper-page-blocking.md)

## References

- [Cloudflare D1 Documentation](https://developers.cloudflare.com/d1/)
- [Drizzle ORM](https://orm.drizzle.team/)
- [D1 Pricing](https://developers.cloudflare.com/d1/platform/pricing/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
