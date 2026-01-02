# Local Development Setup

Complete guide to set up TriTrainer for local development.

## Prerequisites

### Required Software

- **Node.js**: v20.x or later ([install](https://nodejs.org/))
- **pnpm**: v8.x or later (package manager)
- **Wrangler**: Cloudflare Workers CLI
- **Git**: Version control

### Install pnpm

```bash
npm install -g pnpm
```

### Install Wrangler

```bash
npm install -g wrangler
```

### Cloudflare Account

1. Sign up at [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Verify email address
3. Note your Account ID (Dashboard → Workers & Pages)

## Clone Repository

```bash
git clone https://github.com/your-org/strava_app.git
cd strava_app
```

## Install Dependencies

```bash
pnpm install
```

This installs:
- Next.js 15
- Drizzle ORM
- Better Auth
- Cloudflare Workers types
- Development tools

## Environment Setup

### 1. Create Environment File

```bash
cp .env.example .env.local
```

### 2. Configure Environment Variables

Edit `.env.local`:

```bash
# ============================================================================
# CLOUDFLARE
# ============================================================================
CLOUDFLARE_ACCOUNT_ID=your-account-id
CLOUDFLARE_API_TOKEN=your-api-token

# ============================================================================
# BETTER AUTH
# ============================================================================
# Base URL (use localhost for development)
BETTER_AUTH_URL=http://localhost:3000

# Secret key (min 32 characters)
# Generate with: openssl rand -base64 32
BETTER_AUTH_SECRET=your-secret-key-min-32-chars

# ============================================================================
# EMAIL (Optional for development)
# ============================================================================
# Resend API key (leave empty for dev mode - magic links logged to console)
RESEND_API_KEY=

# Email sender
EMAIL_FROM=TriTrainer <noreply@tritrainer.app>

# ============================================================================
# ENVIRONMENT
# ============================================================================
ENVIRONMENT=development

# ============================================================================
# STRAVA (Optional)
# ============================================================================
STRAVA_CLIENT_ID=
STRAVA_CLIENT_SECRET=
STRAVA_WEBHOOK_VERIFY_TOKEN=
```

### 3. Generate Better Auth Secret

```bash
openssl rand -base64 32
```

Copy output to `BETTER_AUTH_SECRET` in `.env.local`

### 4. Get Cloudflare Account ID

1. Visit [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Click "Workers & Pages"
3. Copy Account ID from right sidebar

## Database Setup

### 1. Create D1 Database

```bash
npx wrangler d1 create triathlon-db
```

**Output**:
```
✅ Successfully created DB 'triathlon-db'

[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
database_id = "xxxx-xxxx-xxxx-xxxx"
```

### 2. Update wrangler.toml

Copy the `database_id` from output and update `wrangler.toml`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
database_id = "xxxx-xxxx-xxxx-xxxx"  # Replace with your ID
```

### 3. Run Migrations

Apply all migrations to your D1 database:

```bash
# Migration 1: Users and auth tables
npx wrangler d1 execute triathlon-db \
  --remote \
  --file migrations/0001_create_users.sql

# Migration 2: Seed data
npx wrangler d1 execute triathlon-db \
  --remote \
  --file migrations/0002_seed_data.sql

# Migration 3: Programs tables
npx wrangler d1 execute triathlon-db \
  --remote \
  --file migrations/0003_create_programs.sql

# Migration 4: Sessions tables
npx wrangler d1 execute triathlon-db \
  --remote \
  --file migrations/0004_create_sessions.sql

# Migration 5: pSEO tables
npx wrangler d1 execute triathlon-db \
  --remote \
  --file migrations/0005_pseo_tables.sql

# Migration 6: pSEO seed data
npx wrangler d1 execute triathlon-db \
  --remote \
  --file migrations/0006_pseo_seed.sql
```

### 4. Verify Database

```bash
# List tables
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "SELECT name FROM sqlite_master WHERE type='table'"

# Check user count
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "SELECT COUNT(*) as count FROM users"

# Check pSEO pages
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "SELECT COUNT(*) as count, status FROM pseo_pages GROUP BY status"
```

## Development Server

### 1. Start Next.js Dev Server

```bash
pnpm dev
```

Server runs at: http://localhost:3000

### 2. Test Database Connection

Visit: http://localhost:3000

If you see the homepage load without errors, database connection is working.

### 3. Test Authentication

1. Navigate to http://localhost:3000/login
2. Enter your email
3. Check terminal for magic link:

```
************************************************************
*  DEV MODE - Magic Link (click to login):
*  http://localhost:3000/api/auth/magic-link/verify?token=xxx
************************************************************
```

4. Click the link in terminal
5. Should redirect to `/dashboard` if successful

## Development Workflow

### Hot Reload

Next.js watches for file changes and auto-reloads:

- Edit files in `src/`
- Browser auto-refreshes
- No server restart needed

### Database Changes

When modifying schema:

1. Edit schema files in `src/lib/db/schema/`
2. Generate migration:

```bash
npx drizzle-kit generate:sqlite --schema=./src/lib/db/schema/*
```

3. Apply migration:

```bash
npx wrangler d1 execute triathlon-db \
  --remote \
  --file drizzle/0007_your_migration.sql
```

### Testing pSEO Pages

**Activate a page**:
```bash
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "UPDATE pseo_pages SET status='active' WHERE url_path='/training-plans/sprint/debutant'"
```

**Test page**:
```bash
curl -I http://localhost:3000/training-plans/sprint/debutant
# Should return 200 OK
```

**Deactivate page**:
```bash
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "UPDATE pseo_pages SET status='pending' WHERE url_path='/training-plans/sprint/debutant'"
```

## Optional: Strava Integration

### 1. Create Strava Application

1. Visit [Strava API Settings](https://www.strava.com/settings/api)
2. Create new application:
   - **Application Name**: TriTrainer Dev
   - **Category**: Training
   - **Website**: http://localhost:3000
   - **Authorization Callback Domain**: localhost

3. Note **Client ID** and **Client Secret**

### 2. Configure Environment

Add to `.env.local`:

```bash
STRAVA_CLIENT_ID=12345
STRAVA_CLIENT_SECRET=abc123...
STRAVA_WEBHOOK_VERIFY_TOKEN=your_random_token
```

### 3. Test OAuth Flow

1. Navigate to http://localhost:3000/profile
2. Click "Connect Strava"
3. Authorize on Strava
4. Should redirect back with connection confirmed

## Troubleshooting

### Port Already in Use

```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution**: Kill process on port 3000

```bash
# macOS/Linux
lsof -ti:3000 | xargs kill -9

# Or use different port
pnpm dev --port 3001
```

### Database Connection Error

```
Error: D1_ERROR: Database binding not found
```

**Solutions**:
1. Verify `wrangler.toml` has correct `database_id`
2. Run migrations (see Database Setup step 3)
3. Check Cloudflare account has D1 database created

### Authentication Not Working

```
Error: BETTER_AUTH_SECRET not configured
```

**Solutions**:
1. Verify `.env.local` exists
2. Check `BETTER_AUTH_SECRET` is set (min 32 chars)
3. Restart dev server after changing `.env.local`

### Magic Link Not Appearing

**Check**:
1. Terminal output for dev mode link
2. `ENVIRONMENT=development` in `.env.local`
3. No `RESEND_API_KEY` set (leaves emails undelivered)

**Force console logging**:
```typescript
// src/lib/auth/better-auth.ts
const isLocalDev = true; // Force dev mode
```

### Build Errors

```
Error: Cannot find module '@opennextjs/cloudflare'
```

**Solution**:
```bash
# Clear node_modules and reinstall
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### TypeScript Errors

```
Error: Property 'DB' does not exist on type 'CloudflareEnv'
```

**Solution**: Restart TypeScript server

**VS Code**: `Cmd+Shift+P` → "TypeScript: Restart TS Server"

## Development Tools

### Drizzle Studio (Database GUI)

```bash
# Coming soon - local D1 support
npx drizzle-kit studio
```

### Wrangler Dev (Full Workers Environment)

```bash
# Alternative to `pnpm dev` - uses Cloudflare runtime
npx wrangler dev
```

**Differences**:
- Uses actual Cloudflare Workers runtime
- Slower hot reload
- More accurate production simulation

### VS Code Extensions

Recommended extensions:

- **ESLint** - Linting
- **Prettier** - Code formatting
- **Tailwind CSS IntelliSense** - CSS utilities
- **Drizzle ORM** - Database schema
- **GitLens** - Git integration

## Next Steps

- [Deployment Guide](./deployment.md) - Deploy to production
- [Migration Guide](./migrations.md) - Database migrations
- [API Documentation](../technical/api-routes.md) - API reference
- [Database Schema](../technical/database-schema.md) - Database structure

## Quick Reference Commands

```bash
# Start development server
pnpm dev

# Run type checking
pnpm typecheck

# Run linter
pnpm lint

# Format code
pnpm format

# Build for production
pnpm build

# Deploy to Cloudflare
npx wrangler deploy

# Database query
npx wrangler d1 execute triathlon-db --remote --command "SELECT * FROM users LIMIT 5"

# View logs
npx wrangler tail
```

## Environment Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `CLOUDFLARE_ACCOUNT_ID` | Yes | - | Cloudflare account ID |
| `BETTER_AUTH_URL` | Yes | - | App base URL |
| `BETTER_AUTH_SECRET` | Yes | - | Auth secret (min 32 chars) |
| `RESEND_API_KEY` | No | - | Email API key (optional in dev) |
| `EMAIL_FROM` | No | TriTrainer | Email sender |
| `ENVIRONMENT` | No | development | Environment mode |
| `STRAVA_CLIENT_ID` | No | - | Strava OAuth client ID |
| `STRAVA_CLIENT_SECRET` | No | - | Strava OAuth secret |

## Support

- **Documentation**: [/docs](/docs)
- **Issues**: GitHub Issues
- **Discord**: [Join community](https://discord.gg/tritrainer)
