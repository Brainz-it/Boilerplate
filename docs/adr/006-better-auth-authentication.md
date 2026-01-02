# ADR-006: Better Auth for Authentication

## Status
**Accepted** - 2025-01-02

## Context

We needed an authentication solution that:

- Works seamlessly with Cloudflare Workers and D1 database
- Provides passwordless authentication (magic links)
- Integrates with Drizzle ORM for database access
- Supports modern React patterns (hooks, Server Components)
- Handles session management securely at the edge
- Allows future integration with OAuth providers (Strava)
- Remains lightweight and edge-compatible

## Decision

We will use **Better Auth** v1.4.9 as the authentication library with the **magic link plugin** for passwordless authentication.

### Architecture

```
User
  ↓
Email Input → Magic Link Request
  ↓
Better Auth Server (/api/auth/[...all])
  ↓
Generate Token → Store in D1 (verification table)
  ↓
Send Email via Resend
  ↓
User Clicks Link → Verify Token
  ↓
Create Session → Store in D1 (session table)
  ↓
Set Cookie → Redirect to Dashboard
```

### Key Components

1. **Better Auth Core**
   - Type-safe authentication library
   - Edge-compatible (works with Cloudflare Workers)
   - Built-in Drizzle adapter
   - Session management with cookies

2. **Magic Link Plugin**
   - Passwordless authentication
   - 5-minute expiration
   - Email delivery via Resend
   - Dev mode with console logging

3. **React Client**
   - `useSession()` hook for session state
   - `signIn.magicLink()` for authentication
   - `signOut()` for logout
   - Automatic session refresh

## Consequences

### Positive

- **Passwordless UX**: No password management, better security
- **Edge Native**: Works perfectly with Cloudflare Workers and D1
- **Type Safety**: Full TypeScript support with inferred types
- **Developer Experience**: React hooks, simple API, great DX
- **Security**: HTTP-only cookies, CSRF protection, secure tokens
- **Email Integration**: Resend for reliable email delivery
- **Session Management**: Automatic refresh, configurable expiration
- **Future Ready**: Easy to add OAuth providers (Strava, Google)

### Negative

- **Email Dependency**: Requires working email service (Resend)
- **Beta Status**: Better Auth is relatively new (v1.x)
- **Vendor Lock-in**: Switching auth libraries requires migration
- **Dev Experience**: Must check console for magic links in dev mode
- **Email Deliverability**: Potential issues with spam filters

### Neutral

- **Magic Link Only**: No traditional password auth (by design)
- **Session Duration**: 7-day sessions with 24-hour refresh
- **Cookie Strategy**: Session token in HTTP-only cookie
- **Database Schema**: Requires 4 tables (users, sessions, verification, accounts)

## Alternatives Considered

### 1. NextAuth.js (Auth.js)
**Pros**: Most popular, extensive provider support, large community
**Cons**: Not optimized for edge, complex setup, larger bundle size, PostgreSQL-first

**Edge Compatibility**:
- NextAuth.js: Partial edge support, requires adapters
- Better Auth: Built for edge-first, native Cloudflare support

### 2. Clerk
**Pros**: Managed service, excellent UX, built-in UI components
**Cons**: Expensive ($25/month minimum), vendor lock-in, external dependency, requires internet connection

**Cost Comparison** (1000 active users):
- Better Auth: ~$0 (self-hosted, uses existing D1)
- Clerk: $25-99/month (managed service)

### 3. Lucia Auth
**Pros**: Edge-compatible, lightweight, framework-agnostic
**Cons**: More manual setup, less batteries-included, smaller ecosystem

### 4. Custom JWT Implementation
**Pros**: Full control, no dependencies, minimal
**Cons**: Security risks (DIY crypto), missing features (refresh tokens, sessions), maintenance burden

### 5. Supabase Auth
**Pros**: Managed auth, PostgreSQL integration, good documentation
**Cons**: Not edge-native, additional service dependency, PostgreSQL requirement (we use D1)

## Implementation Details

### Server Configuration (src/lib/auth/better-auth.ts)

```typescript
import { betterAuth } from "better-auth";
import { drizzleAdapter } from "better-auth/adapters/drizzle";
import { magicLink } from "better-auth/plugins";
import { Resend } from "resend";

export function createAuth(env: AuthEnv, drizzleDb: ReturnType<typeof createDb>) {
  return betterAuth({
    baseURL: env.BETTER_AUTH_URL || "http://localhost:3000",
    secret: env.BETTER_AUTH_SECRET,
    basePath: "/api/auth",

    // D1 database integration via Drizzle
    database: drizzleAdapter(drizzleDb, {
      provider: "sqlite",
      schema: {
        user: schema.users,
        session: schema.userSessions,
        verification: schema.verification,
        account: schema.accounts,
      },
    }),

    // Disable email/password (magic link only)
    emailAndPassword: {
      enabled: false,
    },

    // Magic link plugin
    plugins: [
      magicLink({
        sendMagicLink: async ({ email, url }) => {
          // Dev mode: Log to console
          if (isLocalDev) {
            console.log("Magic Link:", url);
            return;
          }

          // Production: Send via Resend
          const resend = new Resend(env.RESEND_API_KEY);
          await resend.emails.send({
            from: "TriTrainer <noreply@tritrainer.app>",
            to: email,
            subject: "Connexion TriTrainer",
            html: emailTemplate(url),
          });
        },
        expiresIn: 300, // 5 minutes
      }),
    ],

    // Session configuration
    session: {
      expiresIn: 60 * 60 * 24 * 7, // 7 days
      updateAge: 60 * 60 * 24, // Update every 24 hours
      cookieCache: {
        enabled: true,
        maxAge: 60 * 5, // 5 minutes
      },
    },

    // User fields
    user: {
      additionalFields: {
        firstName: { type: "string", required: false },
        lastName: { type: "string", required: false },
        stravaId: { type: "string", required: false },
        stravaConnected: { type: "boolean", defaultValue: false },
        onboardingCompleted: { type: "boolean", defaultValue: false },
      },
    },

    // Security
    advanced: {
      useSecureCookies: isProduction,
      cookies: {
        session_token: {
          attributes: {
            httpOnly: true,
            secure: isProduction,
            sameSite: "lax",
            path: "/",
          },
        },
      },
    },
  });
}
```

### React Client (src/lib/auth/client.ts)

```typescript
import { createAuthClient } from "better-auth/react";
import { magicLinkClient } from "better-auth/client/plugins";

export const authClient = createAuthClient({
  baseURL: typeof window !== "undefined" ? window.location.origin : "",
  plugins: [magicLinkClient()],
});

export const {
  signIn,
  signOut,
  useSession,
  getSession,
} = authClient;

export const sendMagicLink = async (email: string, callbackURL?: string) => {
  return authClient.signIn.magicLink({
    email,
    callbackURL: callbackURL || "/dashboard",
  });
};
```

### API Route Handler (src/app/api/auth/[...all]/route.ts)

```typescript
import { createAuth } from "@/lib/auth/better-auth";
import { createDb } from "@/lib/db/drizzle";
import { getCloudflareContext } from "@opennextjs/cloudflare";

export async function GET(request: Request) {
  const { env } = await getCloudflareContext();
  const db = createDb(env.DB);
  const auth = createAuth(env, db);

  return auth.handler(request);
}

export const POST = GET;
```

### Usage in Components

**Client Component (Login Form)**:
```typescript
'use client';
import { useState } from 'react';
import { sendMagicLink } from '@/lib/auth/client';

export function LoginForm() {
  const [email, setEmail] = useState('');
  const [sent, setSent] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    await sendMagicLink(email, '/dashboard');
    setSent(true);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        placeholder="Email"
        required
      />
      <button type="submit">Send Magic Link</button>
      {sent && <p>Check your email!</p>}
    </form>
  );
}
```

**Server Component (Protected Page)**:
```typescript
import { getSession } from '@/lib/auth';
import { redirect } from 'next/navigation';

export default async function DashboardPage() {
  const session = await getSession();

  if (!session) {
    redirect('/login');
  }

  return <div>Welcome, {session.user.email}</div>;
}
```

**Client Hook (Session State)**:
```typescript
'use client';
import { useSession } from '@/lib/auth/client';

export function UserProfile() {
  const { data: session, isPending } = useSession();

  if (isPending) return <div>Loading...</div>;
  if (!session) return <div>Not logged in</div>;

  return <div>Hello, {session.user.email}</div>;
}
```

### Middleware Protection

```typescript
// src/middleware.ts
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const protectedPaths = ['/dashboard', '/profile', '/program'];

export function middleware(request: NextRequest) {
  const sessionToken = request.cookies.get('better-auth.session_token');
  const isProtectedPath = protectedPaths.some(path =>
    request.nextUrl.pathname.startsWith(path)
  );

  if (isProtectedPath && !sessionToken) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/dashboard/:path*', '/profile/:path*', '/program/:path*'],
};
```

## Database Schema

Better Auth requires these tables:

```sql
-- Users table
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  emailVerified INTEGER NOT NULL DEFAULT 0,
  name TEXT,
  firstName TEXT,
  lastName TEXT,
  profilePicture TEXT,
  stravaId TEXT,
  stravaConnected INTEGER DEFAULT 0,
  onboardingCompleted INTEGER DEFAULT 0,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL
);

-- Sessions table
CREATE TABLE userSessions (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  expiresAt INTEGER NOT NULL,
  token TEXT NOT NULL UNIQUE,
  ipAddress TEXT,
  userAgent TEXT,
  FOREIGN KEY (userId) REFERENCES users(id)
);

-- Verification tokens (for magic links)
CREATE TABLE verification (
  id TEXT PRIMARY KEY,
  identifier TEXT NOT NULL,
  value TEXT NOT NULL,
  expiresAt INTEGER NOT NULL
);

-- OAuth accounts (for future Strava integration)
CREATE TABLE accounts (
  id TEXT PRIMARY KEY,
  userId TEXT NOT NULL,
  accountId TEXT NOT NULL,
  providerId TEXT NOT NULL,
  accessToken TEXT,
  refreshToken TEXT,
  expiresAt INTEGER,
  FOREIGN KEY (userId) REFERENCES users(id)
);
```

## Environment Variables

```bash
# Required
BETTER_AUTH_URL=https://tritrainer.app
BETTER_AUTH_SECRET=your-secret-key-min-32-chars

# Email (Production only)
RESEND_API_KEY=re_xxxxxx
EMAIL_FROM=TriTrainer <noreply@tritrainer.app>

# Environment
ENVIRONMENT=production
```

## Security Considerations

### Session Security
- **HTTP-Only Cookies**: Prevents XSS attacks accessing tokens
- **Secure Flag**: HTTPS-only in production
- **SameSite=Lax**: CSRF protection
- **7-Day Expiration**: Balance security and UX

### Magic Link Security
- **5-Minute Expiration**: Short window to prevent replay attacks
- **One-Time Use**: Tokens invalidated after use
- **Cryptographically Random**: Secure token generation
- **HTTPS Only**: Production magic links use HTTPS

### Token Storage
- **D1 Database**: Tokens stored server-side, not client
- **Automatic Cleanup**: Expired tokens removed automatically
- **Indexed Queries**: Fast token verification

## Email Integration (Resend)

### Why Resend
- **Deliverability**: High inbox placement rate
- **Developer Experience**: Simple API, great docs
- **Pricing**: Free tier includes 3,000 emails/month
- **Edge Compatible**: Works from Cloudflare Workers
- **React Email**: Support for JSX email templates (future)

### Email Template

Custom HTML template with:
- TriTrainer branding (orange gradient)
- Clear call-to-action button
- Expiration notice (5 minutes)
- Security disclaimer
- Mobile-responsive design

### Local Development

In development mode:
- Magic links logged to console (no email sent)
- Click link directly from terminal
- Faster iteration, no email service needed

```
[Magic Link] Sending magic link to: user@example.com
[Magic Link] URL: http://localhost:3000/api/auth/magic-link/verify?token=xxx

************************************************************
*  DEV MODE - Magic Link (click to login):
*  http://localhost:3000/api/auth/magic-link/verify?token=xxx
************************************************************
```

## Future Enhancements

### Strava OAuth Integration

Better Auth accounts table is ready for OAuth:

```typescript
// Future: Add Strava provider
import { strava } from "better-auth/providers";

plugins: [
  magicLink({ /* ... */ }),
  strava({
    clientId: env.STRAVA_CLIENT_ID,
    clientSecret: env.STRAVA_CLIENT_SECRET,
    scope: ["read", "activity:read_all"],
  }),
]
```

### Multi-Factor Authentication

```typescript
// Future: Add TOTP plugin
import { totp } from "better-auth/plugins";

plugins: [
  magicLink({ /* ... */ }),
  totp(),
]
```

### Role-Based Access Control

```typescript
// Future: Add RBAC plugin
import { rbac } from "better-auth/plugins";

plugins: [
  magicLink({ /* ... */ }),
  rbac({
    roles: ["user", "coach", "admin"],
  }),
]
```

## Monitoring and Analytics

### Key Metrics

1. **Magic Link Success Rate**
   - Links sent vs successful logins
   - Track email deliverability issues

2. **Session Duration**
   - Average session length
   - Re-authentication frequency

3. **Failed Login Attempts**
   - Invalid tokens
   - Expired links
   - Email not found

### Database Queries

```sql
-- Active sessions count
SELECT COUNT(*) FROM userSessions
WHERE expiresAt > unixepoch();

-- Daily signups
SELECT DATE(createdAt, 'unixepoch') as date, COUNT(*) as signups
FROM users
GROUP BY date
ORDER BY date DESC
LIMIT 30;

-- Expired verification tokens (cleanup candidates)
SELECT COUNT(*) FROM verification
WHERE expiresAt < unixepoch();
```

## Performance Characteristics

### Session Verification
- Cookie check: <0.1ms (HTTP-only cookie)
- Database query: <1ms (indexed session lookup)
- Total overhead: ~1ms per request

### Magic Link Generation
- Token generation: <1ms
- Database insert: <2ms
- Email send (Resend): 100-500ms
- Total: ~500ms

### Cold Start Impact
- Better Auth init: ~10ms
- Drizzle adapter: ~5ms
- Total overhead: ~15ms (acceptable for Workers)

## Migration Strategy

If we need to migrate away from Better Auth:

1. **Export User Data**: D1 → SQLite file → PostgreSQL
2. **Session Migration**: Users need to re-authenticate
3. **Schema Compatibility**: Standard users/sessions tables
4. **Token Format**: Standard JWT if needed

## Related ADRs

- [ADR-003: D1 Database with Drizzle ORM](003-d1-database-drizzle-orm.md)
- [ADR-002: Cloudflare Workers Deployment](002-cloudflare-workers-deployment.md)

## References

- [Better Auth Documentation](https://www.better-auth.com/docs)
- [Better Auth GitHub](https://github.com/better-auth/better-auth)
- [Magic Link Plugin](https://www.better-auth.com/docs/plugins/magic-link)
- [Drizzle Adapter](https://www.better-auth.com/docs/adapters/drizzle)
- [Resend Documentation](https://resend.com/docs)
- [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
