# Triathlon Training App - Architecture Blueprint

Based on production patterns from Hirlya platform (remote.ma).

---

## 1. TECHNOLOGY STACK

### Core Framework & Runtime
| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | Next.js 14 | App Router |
| **React** | React 18.3.1 | Server Components by default |
| **Language** | TypeScript 5 | Strict mode |
| **Runtime** | Cloudflare Workers | Edge Runtime |
| **Package Manager** | pnpm | Monorepo workspace |

### Database & Storage
| Component | Technology | Details |
|-----------|-----------|---------|
| **Database** | Cloudflare D1 | SQLite, local dev + remote prod |
| **ORM** | Raw SQL | D1 prepared statements |
| **Migrations** | SQL files | Manual via wrangler |

### Authentication & External APIs
| Component | Technology | Details |
|-----------|-----------|---------|
| **Auth** | Strava OAuth | Token-based with JWT |
| **Activities** | Strava API | Sync activities, athlete data |
| **JWT** | jose | Edge-compatible tokens |

### Frontend & Styling
| Component | Technology |
|-----------|-----------|
| **UI** | Custom components |
| **Styling** | Tailwind CSS 3.4 |
| **Icons** | Inline SVG |
| **Utilities** | clsx, tailwind-merge |

---

## 2. DEPLOYMENT ARCHITECTURE

```
Internet Traffic
    ↓
Cloudflare Edge Network (300+ data centers)
    ↓
┌────────────────────────────────┐
│  Next.js 14 App (Edge Runtime) │
│  - OpenNext Adapter 1.14.7     │
│  - Wrangler 4.56.0             │
└────────┬───────────────────────┘
         ├─→ D1 Database (SQLite)
         │   └─ triathlon-db
         └─→ External APIs
             └─ Strava API (OAuth, activities)
```

---

## 3. PROJECT STRUCTURE

```
apps/web/
├── src/
│   ├── app/                     # Next.js App Router
│   │   ├── (auth)/              # Auth routes (login)
│   │   ├── (dashboard)/         # Protected routes
│   │   │   ├── dashboard/
│   │   │   ├── activities/
│   │   │   ├── program/
│   │   │   ├── profile/
│   │   │   └── session/[id]/
│   │   ├── onboarding/
│   │   └── api/                 # API routes
│   │       ├── auth/            # Strava OAuth
│   │       ├── strava/          # Activities sync
│   │       ├── onboarding/      # Setup flow
│   │       ├── sessions/        # Training sessions
│   │       ├── program/         # Training program
│   │       └── user/            # User profile
│   │
│   ├── components/
│   │   ├── ui/                  # Base components
│   │   ├── layout/              # AppShell, Nav
│   │   ├── dashboard/           # Dashboard widgets
│   │   ├── program/             # Program views
│   │   └── session/             # Session details
│   │
│   ├── lib/
│   │   ├── api/                 # API context, helpers
│   │   ├── auth/                # JWT, middleware
│   │   ├── db/                  # Database layer
│   │   ├── strava/              # Strava client
│   │   ├── env.ts               # Environment config
│   │   └── utils.ts             # Utilities
│   │
│   ├── hooks/                   # React hooks
│   └── i18n/                    # Internationalization
│
├── migrations/                  # D1 SQL migrations
├── .dev.vars                    # Local secrets (not committed)
├── wrangler.toml                # Cloudflare config
├── open-next.config.ts          # OpenNext config
├── next.config.js               # Next.js config
└── package.json
```

---

## 4. ENVIRONMENT CONFIGURATION

### Development (.dev.vars)
```bash
# Strava OAuth
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
STRAVA_WEBHOOK_VERIFY_TOKEN=random_token

# Auth
JWT_SECRET=minimum_32_characters_secret_key

# App
APP_URL=http://localhost:8788
ENVIRONMENT=development
```

### Production (wrangler secrets)
```bash
wrangler secret put STRAVA_CLIENT_ID
wrangler secret put STRAVA_CLIENT_SECRET
wrangler secret put STRAVA_WEBHOOK_VERIFY_TOKEN
wrangler secret put JWT_SECRET
```

### Wrangler Configuration
```toml
name = "triathlon-app"
main = ".open-next/worker.js"
compatibility_date = "2024-12-01"
compatibility_flags = ["nodejs_compat"]

assets = { directory = ".open-next/assets", binding = "ASSETS" }

[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
database_id = "YOUR_DATABASE_ID"

[vars]
ENVIRONMENT = "development"
APP_URL = "http://localhost:8788"
```

---

## 5. DATABASE ARCHITECTURE

### Core Tables

```sql
-- Users (from Strava OAuth)
users (
  id, strava_id, email, first_name, last_name, profile_picture,
  strava_access_token, strava_refresh_token, strava_token_expires_at,
  onboarding_completed, notification_preferences,
  created_at, updated_at
)

-- Athlete Profile
athlete_profiles (
  id, user_id,
  birth_year, gender, weight_kg,
  experience_level, triathlon_count, longest_distance,
  weekly_hours_available, unavailable_days,
  pool_access, home_trainer, injuries_notes,
  fc_max, fc_max_source, fc_rest,
  ftp, ftp_source, css, run_threshold_pace,
  created_at, updated_at
)

-- Training Goals
goals (
  id, user_id,
  event_name, event_date, event_location, event_url,
  distance_type, target_time, priority, status,
  created_at, updated_at
)

-- Training Programs
programs (
  id, user_id, goal_id, template_id,
  start_date, end_date, total_weeks,
  current_week, current_phase, weekly_hours_target, status,
  created_at, updated_at
)

-- Training Sessions
sessions (
  id, program_week_id, sport, session_type, title, description,
  scheduled_date, duration_planned, distance_planned,
  workout_details, objective, tips, target_zones,
  status, strava_activity_id,
  actual_duration, actual_distance, actual_avg_hr, actual_tss,
  perceived_effort, completion_notes, completed_at,
  created_at, updated_at
)

-- Strava Activities
strava_activities (
  id, user_id, strava_id, sport_type, name,
  start_date, elapsed_time, moving_time, distance,
  average_speed, max_speed, average_heartrate, max_heartrate,
  average_watts, total_elevation_gain, calories,
  synced_at
)

-- Heart Rate Zones
heart_rate_zones (
  id, user_id, zone_number, name,
  min_hr, max_hr, description, color, source,
  created_at
)
```

### Indexing Strategy
```sql
-- User queries
CREATE INDEX idx_users_strava_id ON users(strava_id);

-- Profile queries
CREATE INDEX idx_athlete_profiles_user_id ON athlete_profiles(user_id);

-- Program queries
CREATE INDEX idx_programs_user_id ON programs(user_id);
CREATE INDEX idx_programs_status ON programs(status);

-- Session queries
CREATE INDEX idx_sessions_program_week ON sessions(program_week_id);
CREATE INDEX idx_sessions_status ON sessions(status);
CREATE INDEX idx_sessions_scheduled ON sessions(scheduled_date);

-- Activity queries
CREATE INDEX idx_strava_activities_user ON strava_activities(user_id);
CREATE INDEX idx_strava_activities_date ON strava_activities(start_date);
```

---

## 6. AUTHENTICATION FLOW

### Strava OAuth Flow

```
1. User clicks "Connect with Strava" on /login
   ↓
2. GET /api/auth/strava
   → Redirect to Strava authorization URL
   ↓
3. User authorizes on Strava
   → Redirect to /api/auth/strava/callback?code=...
   ↓
4. GET /api/auth/strava/callback
   → Exchange code for tokens
   → Create/update user in D1
   → Generate JWT token
   → Set HTTP-only cookie
   → Redirect to /onboarding (new) or /dashboard (existing)
```

### JWT Token Structure
```typescript
{
  sub: "usr_12345",      // User ID
  stravaId: "12345678",  // Strava athlete ID
  iat: 1703123456,       // Issued at
  exp: 1703728256        // Expires (7 days)
}
```

### Cookie Configuration
```typescript
{
  name: 'auth_token',
  httpOnly: true,
  secure: ENVIRONMENT === 'production',
  sameSite: 'lax',
  maxAge: 60 * 60 * 24 * 30,  // 30 days
  path: '/'
}
```

---

## 7. API DESIGN PATTERNS

### Standard Response Format
```typescript
// Success
{ success: true, data: T }

// Error
{ error: { code: string, message: string } }
```

### API Context Helper
```typescript
// src/lib/api/context.ts
export async function getApiContext(): Promise<ApiContext | null> {
  const ctx = await getCloudflareContext();
  const env = ctx?.env as CloudflareEnv;

  // Get auth token from cookies
  const token = cookies().get('auth_token')?.value;
  if (!token) return null;

  // Verify JWT
  const payload = await verifyToken(token, env.JWT_SECRET);
  if (!payload) return null;

  // Return context with DB access
  return {
    userId: payload.sub,
    stravaId: payload.stravaId,
    db: getDatabase(env.DB),
  };
}
```

### Route Handler Pattern
```typescript
// API route example
export async function GET() {
  const ctx = await getApiContext();
  if (!ctx) {
    return Response.json(
      { error: { code: 'unauthorized', message: 'Authentication required' } },
      { status: 401 }
    );
  }

  try {
    const data = await ctx.db.getSomeData(ctx.userId);
    return Response.json({ success: true, data });
  } catch (error) {
    console.error('Error:', error);
    return Response.json(
      { error: { code: 'internal_error', message: 'Something went wrong' } },
      { status: 500 }
    );
  }
}
```

---

## 8. CLOUDFLARE CONTEXT ACCESS

### OpenNext Pattern
```typescript
import { getCloudflareContext } from '@opennextjs/cloudflare';

interface CloudflareEnv extends Record<string, unknown> {
  DB: D1Database;
  JWT_SECRET: string;
  STRAVA_CLIENT_ID: string;
  STRAVA_CLIENT_SECRET: string;
  // ... other bindings
}

export async function getEnv(): Promise<CloudflareEnv> {
  try {
    const ctx = await getCloudflareContext();
    return ctx?.env as CloudflareEnv;
  } catch {
    // Fallback for non-Cloudflare environments
    return {
      JWT_SECRET: process.env.JWT_SECRET,
      // ...
    } as CloudflareEnv;
  }
}
```

---

## 9. BUILD & DEPLOYMENT

### Scripts
```json
{
  "dev": "next dev",
  "dev:wrangler": "wrangler dev --remote",
  "build": "next build",
  "build:worker": "pnpm build && npx @opennextjs/cloudflare build --skipNextBuild",
  "preview": "pnpm build:worker && wrangler dev",
  "deploy": "pnpm build:worker && npx wrangler deploy",
  "db:migrate": "wrangler d1 migrations apply triathlon-db --local",
  "db:migrate:remote": "wrangler d1 migrations apply triathlon-db --remote"
}
```

### Deployment Workflow
```bash
# 1. Local development
pnpm dev                    # Next.js dev server (no D1)
pnpm preview               # Full Cloudflare stack locally

# 2. Database migrations
pnpm db:migrate            # Apply to local D1
pnpm db:migrate:remote     # Apply to production D1

# 3. Deploy to production
pnpm deploy                # Build + deploy to Cloudflare
```

### Next.js Configuration
```javascript
// next.config.js
const nextConfig = {
  output: 'standalone',           // Required for OpenNext
  eslint: { ignoreDuringBuilds: true },
  experimental: {
    serverActions: {
      allowedOrigins: ['localhost:3000'],
    },
  },
  images: {
    remotePatterns: [
      { protocol: 'https', hostname: '*.strava.com' },
    ],
  },
  transpilePackages: ['@triathlon-app/shared'],
};
```

---

## 10. EDGE RUNTIME CONSTRAINTS

### Limitations
- **No Node.js APIs**: `fs`, `path`, `process` unavailable
- **CPU Time**: 30-second limit per request
- **Memory**: 128MB per execution
- **Worker Size**: 3MB compressed
- **No native modules**: Pure JavaScript/WASM only

### Mitigations
- Use `jose` instead of `jsonwebtoken` (Edge-compatible)
- Stream large files instead of buffering
- Use background jobs for long operations
- Design for eventual consistency

---

## 11. LOCAL DEVELOPMENT

### Setup
```bash
# 1. Install dependencies
pnpm install

# 2. Create local secrets
cp .env.example .dev.vars
# Edit .dev.vars with your API keys

# 3. Create local D1 database
wrangler d1 create triathlon-db --local

# 4. Apply migrations
pnpm db:migrate

# 5. Start development
pnpm preview    # Full stack with D1
# OR
pnpm dev        # Next.js only (no D1)
```

### Ports
- `pnpm dev`: http://localhost:3000
- `pnpm preview`: http://localhost:8787

---

## 12. KEY FILES REFERENCE

| File | Purpose |
|------|---------|
| `wrangler.toml` | Cloudflare Worker configuration |
| `open-next.config.ts` | OpenNext adapter config |
| `next.config.js` | Next.js configuration |
| `.dev.vars` | Local development secrets |
| `src/lib/env.ts` | Environment access helper |
| `src/lib/api/context.ts` | API authentication context |
| `src/lib/db/index.ts` | Database access layer |
| `migrations/*.sql` | Database schema migrations |

---

## 13. PRODUCTION CHECKLIST

- [ ] Set all wrangler secrets
- [ ] Create production D1 database
- [ ] Apply migrations to production
- [ ] Configure custom domain
- [ ] Set up Strava webhook (optional)
- [ ] Test OAuth flow end-to-end
- [ ] Verify D1 bindings work
- [ ] Monitor Cloudflare dashboard

---

## References

- [OpenNext Cloudflare Docs](https://opennext.js.org/cloudflare)
- [Cloudflare D1 Docs](https://developers.cloudflare.com/d1/)
- [Strava API Docs](https://developers.strava.com/)
- [Next.js App Router](https://nextjs.org/docs/app)
