# Project Structure

## Overview

TriTrainer is a Next.js 15 application deployed to Cloudflare Workers using OpenNext, with D1 (SQLite) database and Drizzle ORM.

## Root Directory

```
strava_app/
├── .claude/                    # Claude Code configuration and skills
├── .open-next/                 # Generated OpenNext build artifacts (gitignored)
├── docs/                       # Project documentation
├── drizzle/                    # Database configuration and migrations
├── migrations/                 # SQL migration files
├── public/                     # Static assets
├── src/                        # Application source code
├── worker.js                   # Custom Cloudflare Worker wrapper
├── next.config.ts              # Next.js configuration
├── wrangler.toml               # Cloudflare Workers configuration
├── drizzle.config.ts           # Drizzle ORM configuration
├── tailwind.config.ts          # Tailwind CSS configuration
└── tsconfig.json               # TypeScript configuration
```

## Documentation Structure (`docs/`)

```
docs/
├── adr/                        # Architecture Decision Records
│   ├── README.md              # ADR index and template
│   ├── 001-nextjs-app-router.md
│   ├── 002-cloudflare-workers-deployment.md
│   ├── 003-d1-database-drizzle-orm.md
│   ├── 004-pseo-database-driven-rollout.md
│   ├── 005-worker-wrapper-page-blocking.md
│   └── 006-better-auth-authentication.md
├── technical/                  # Technical documentation
│   ├── project-structure.md   # This file
│   ├── database-schema.md     # Database tables and relationships
│   ├── api-routes.md          # API endpoint documentation
│   ├── components.md          # Component architecture
│   └── workflows.md           # Development workflows
└── guides/                     # How-to guides
    ├── setup.md               # Local development setup
    ├── deployment.md          # Deployment guide
    └── migrations.md          # Database migration guide
```

## Source Code Structure (`src/`)

```
src/
├── app/                        # Next.js 15 App Router
│   ├── (landing)/             # Landing page route group
│   │   ├── page.tsx           # Homepage (/)
│   │   └── layout.tsx         # Landing layout
│   │
│   ├── (pseo)/                # pSEO pages route group
│   │   ├── [...slug]/         # Dynamic catch-all route
│   │   │   └── page.tsx       # pSEO page renderer
│   │   ├── [locale]/          # Localized pSEO routes
│   │   │   └── training-plans/
│   │   ├── generateur/        # Generator pages (static params)
│   │   ├── competition/       # Competition pages (static params)
│   │   ├── profil/            # Profile pages (static params)
│   │   ├── programme/         # Program pages (static params)
│   │   └── training-plans/    # Training plan pages (static params)
│   │
│   ├── dashboard/             # Protected dashboard
│   │   ├── page.tsx           # Dashboard home
│   │   └── layout.tsx         # Dashboard layout
│   │
│   ├── profile/               # User profile
│   │   └── page.tsx
│   │
│   ├── onboarding/            # User onboarding flow
│   │   └── page.tsx
│   │
│   ├── login/                 # Authentication
│   │   └── page.tsx
│   │
│   ├── api/                   # API routes
│   │   ├── auth/              # Authentication endpoints
│   │   │   ├── [...all]/      # Better Auth handler
│   │   │   └── logout/        # Logout endpoint
│   │   ├── strava/            # Strava integration
│   │   └── webhook/           # Webhook handlers
│   │
│   ├── layout.tsx             # Root layout
│   ├── globals.css            # Global styles
│   └── not-found.tsx          # 404 page
│
├── components/                # React components
│   ├── ui/                    # Base UI components
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── card.tsx
│   │   └── ...
│   ├── auth/                  # Authentication components
│   │   ├── login-form.tsx
│   │   └── logout-button.tsx
│   ├── layout/                # Layout components
│   │   ├── header.tsx
│   │   ├── footer.tsx
│   │   └── navigation.tsx
│   ├── pseo/                  # pSEO components
│   │   ├── page-hero.tsx
│   │   └── breadcrumbs.tsx
│   └── dashboard/             # Dashboard components
│       ├── calendar.tsx
│       └── activity-card.tsx
│
├── lib/                       # Utility libraries
│   ├── auth/                  # Authentication
│   │   ├── better-auth.ts     # Better Auth configuration
│   │   ├── client.ts          # React client
│   │   ├── jwt.ts             # JWT utilities
│   │   └── middleware.ts      # Auth middleware helpers
│   │
│   ├── db/                    # Database
│   │   ├── schema/            # Drizzle schemas
│   │   │   ├── users.ts       # User tables
│   │   │   ├── programs.ts    # Training programs
│   │   │   ├── sessions.ts    # Training sessions
│   │   │   ├── pseo.ts        # pSEO metadata
│   │   │   └── index.ts       # Schema exports
│   │   ├── index.ts           # Database client
│   │   └── drizzle.ts         # Drizzle initialization
│   │
│   ├── api/                   # API utilities
│   │   ├── context.ts         # API context (env, db)
│   │   └── response.ts        # Response helpers
│   │
│   ├── pseo/                  # pSEO utilities
│   │   ├── generator.ts       # Page generation
│   │   ├── metadata.ts        # SEO metadata
│   │   ├── page-status.ts     # Status checking
│   │   └── routes.ts          # Route configuration
│   │
│   ├── strava/                # Strava integration
│   │   ├── client.ts          # Strava API client
│   │   └── webhook.ts         # Webhook handling
│   │
│   └── utils/                 # Utilities
│       ├── cn.ts              # Class name utility
│       ├── date.ts            # Date formatting
│       └── validation.ts      # Input validation
│
├── types/                     # TypeScript types
│   ├── cloudflare.d.ts        # Cloudflare environment types
│   ├── auth.d.ts              # Auth types
│   └── pseo.d.ts              # pSEO types
│
└── middleware.ts              # Next.js middleware (auth routing)
```

## Database Structure (`drizzle/` and `migrations/`)

```
drizzle/
└── config.ts                  # Drizzle configuration

migrations/
├── 0001_create_users.sql      # User authentication tables
├── 0002_seed_data.sql         # Initial data
├── 0003_create_programs.sql   # Training programs
├── 0004_create_sessions.sql   # Training sessions
├── 0005_pseo_tables.sql       # pSEO metadata tables
└── 0006_pseo_seed.sql         # pSEO page seed data
```

## Claude Code Configuration (`.claude/`)

```
.claude/
├── CLAUDE.md                  # Project-specific instructions
└── skills/                    # Specialized AI skills
    ├── fullstack-nextjs.md
    ├── ai-llm-engineer.md
    ├── devops-infra.md
    ├── code-reviewer.md
    ├── refactorer.md
    ├── debugger.md
    ├── qa-engineer.md
    ├── docs-writer.md
    ├── security-auditor.md
    └── orchestrator.md
```

## Public Assets (`public/`)

```
public/
├── images/                    # Static images
│   ├── logo.svg
│   └── hero.png
├── fonts/                     # Custom fonts (if any)
└── favicon.ico
```

## Configuration Files

### Cloudflare Workers (`wrangler.toml`)
```toml
name = "triathlon-app"
main = "worker.js"             # Custom Worker wrapper
compatibility_date = "2024-12-01"

[assets]
directory = ".open-next/assets"

[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
database_id = "..."
```

### Next.js (`next.config.ts`)
```typescript
const nextConfig: NextConfig = {
  output: 'standalone',        # For OpenNext
  // ... other config
};
```

### Drizzle ORM (`drizzle.config.ts`)
```typescript
export default {
  schema: './src/lib/db/schema/*',
  out: './drizzle',
  dialect: 'sqlite',
  driver: 'd1',
};
```

## Build Artifacts (`.open-next/` - Gitignored)

Generated by OpenNext during build:

```
.open-next/
├── worker.js                  # OpenNext Worker (wrapped by worker.js)
├── server-functions/          # Server function handlers
│   └── default/
├── assets/                    # Static assets
│   └── _next/static/
├── cache/                     # Pre-rendered pages cache
└── dynamodb-provider/         # Cache provider (adapted for D1)
```

## Import Aliases

Configured in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "paths": {
      "@/*": ["./src/*"]
    }
  }
}
```

**Usage**:
```typescript
// Instead of: import { Button } from '../../components/ui/button'
import { Button } from '@/components/ui/button';

// Instead of: import { createDb } from '../../../lib/db'
import { createDb } from '@/lib/db';
```

## Route Groups Explained

### (landing) - Landing Pages
- **Purpose**: Public marketing pages
- **Layout**: Landing-specific layout (no auth required)
- **Examples**: `/` (homepage)

### (pseo) - Programmatic SEO Pages
- **Purpose**: Auto-generated SEO pages
- **Layout**: pSEO layout with breadcrumbs
- **Dynamic Routes**: `[...slug]` catch-all for flexible routing
- **Examples**: `/generateur/xs-debutant`, `/competition/ironman-nice`

### dashboard/ - Protected Pages
- **Purpose**: Authenticated user pages
- **Layout**: Dashboard layout with navigation
- **Protection**: Middleware checks for session
- **Examples**: `/dashboard`, `/profile`

## Key Files Reference

| File | Purpose |
|------|---------|
| `worker.js` | Custom Cloudflare Worker - blocks pending pSEO pages |
| `src/middleware.ts` | Next.js middleware - auth routing |
| `src/app/(pseo)/[...slug]/page.tsx` | pSEO page renderer |
| `src/lib/auth/better-auth.ts` | Better Auth configuration |
| `src/lib/db/index.ts` | Database client initialization |
| `src/lib/pseo/generator.ts` | pSEO page generation |
| `migrations/*.sql` | Database migrations |
| `drizzle.config.ts` | Drizzle ORM configuration |
| `wrangler.toml` | Cloudflare Workers configuration |

## Environment-Specific Files

### Development
- `.env.local` - Local environment variables
- `local.db` - Local SQLite database (if using better-sqlite3)
- `node_modules/` - Dependencies

### Production
- D1 database (remote)
- Environment variables in Cloudflare dashboard
- Deployed Worker on Cloudflare edge

## Naming Conventions

### Files
- **Components**: PascalCase (`UserProfile.tsx`)
- **Utilities**: camelCase (`formatDate.ts`)
- **Pages**: lowercase (`page.tsx`, `layout.tsx`)
- **Types**: camelCase with `.d.ts` (`auth.d.ts`)

### Directories
- **Route segments**: lowercase, kebab-case (`training-plans/`)
- **Route groups**: lowercase, parentheses (`(landing)/`)
- **Component folders**: PascalCase (`UserProfile/`)
- **Utility folders**: lowercase (`utils/`)

### Variables and Functions
- **Variables**: camelCase (`userName`, `isLoggedIn`)
- **Constants**: UPPER_SNAKE_CASE (`PSEO_ROUTES`, `API_BASE_URL`)
- **Functions**: camelCase (`getUserData`, `sendMagicLink`)
- **React Components**: PascalCase (`LoginForm`, `UserProfile`)
- **Types/Interfaces**: PascalCase (`User`, `SessionData`)

## Git Strategy

### Branches
- `main` - Production branch (deployed)
- `feature/*` - Feature branches
- `fix/*` - Bug fix branches

### Ignored Files (`.gitignore`)
```
.open-next/
node_modules/
.env.local
*.db
.DS_Store
```

## Related Documentation

- [Database Schema](./database-schema.md)
- [API Routes](./api-routes.md)
- [Component Architecture](./components.md)
- [Setup Guide](../guides/setup.md)
- [Deployment Guide](../guides/deployment.md)
