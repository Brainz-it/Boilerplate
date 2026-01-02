# API Routes

## Overview

TriTrainer uses Next.js 15 App Router API routes with Cloudflare Workers runtime. All routes are serverless edge functions with access to D1 database.

## Base URL

- **Production**: `https://tritrainer.app/api`
- **Development**: `http://localhost:3000/api`

## Authentication

Most API routes require authentication via Better Auth session cookie:

```http
Cookie: better-auth.session_token=xxx
```

## Routes Structure

```
/api/
├── auth/                    # Authentication endpoints (Better Auth)
│   ├── [...all]/           # Catch-all auth handler
│   └── logout/             # Explicit logout endpoint
├── strava/                  # Strava integration
│   ├── webhook/            # Strava webhook handler
│   └── activities/         # Activity sync
├── program/                 # Training program management
│   ├── create/             # Create new program
│   ├── [id]/               # Program CRUD operations
│   └── recalculate/        # Adaptive recalculation
└── webhook/                 # Generic webhooks
    └── indexnow/           # IndexNow SEO notifications
```

## Authentication Endpoints

### Better Auth Catch-All

**Endpoint**: `/api/auth/[...all]`
**Methods**: `GET`, `POST`
**Authentication**: Public (handles login)

Better Auth automatically handles all authentication routes:

- `/api/auth/sign-in/magic-link` - Request magic link
- `/api/auth/sign-in/magic-link/verify` - Verify magic link token
- `/api/auth/sign-out` - Sign out
- `/api/auth/session` - Get current session
- `/api/auth/get-session` - Get session data

**Implementation**:
```typescript
// src/app/api/auth/[...all]/route.ts
import { createAuth } from '@/lib/auth/better-auth';
import { createDb } from '@/lib/db/drizzle';
import { getCloudflareContext } from '@opennextjs/cloudflare';

export async function GET(request: Request) {
  const { env } = await getCloudflareContext();
  const db = createDb(env.DB);
  const auth = createAuth(env, db);

  return auth.handler(request);
}

export const POST = GET;
```

**Request Magic Link**:
```http
POST /api/auth/sign-in/magic-link
Content-Type: application/json

{
  "email": "user@example.com",
  "callbackURL": "/dashboard"
}
```

**Response**:
```json
{
  "status": "success",
  "data": {
    "message": "Magic link sent to user@example.com"
  }
}
```

**Verify Magic Link**:
```http
GET /api/auth/sign-in/magic-link/verify?token=xxx
```

**Response**: Redirects to `callbackURL` with session cookie set

**Get Session**:
```http
GET /api/auth/session
Cookie: better-auth.session_token=xxx
```

**Response**:
```json
{
  "user": {
    "id": "user_xxx",
    "email": "user@example.com",
    "name": "John Doe",
    "onboardingCompleted": true
  },
  "session": {
    "id": "session_xxx",
    "expiresAt": "2025-01-09T..."
  }
}
```

### Logout

**Endpoint**: `/api/auth/logout`
**Method**: `POST`
**Authentication**: Required

**Implementation**:
```typescript
// src/app/api/auth/logout/route.ts
import { NextResponse } from "next/server";

export async function POST() {
  const response = NextResponse.json({ success: true });

  // Clear session cookie
  response.cookies.set("better-auth.session_token", "", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    path: "/",
    maxAge: 0,
  });

  return response;
}
```

**Request**:
```http
POST /api/auth/logout
Cookie: better-auth.session_token=xxx
```

**Response**:
```json
{
  "success": true
}
```

## Strava Integration

### Webhook Handler

**Endpoint**: `/api/strava/webhook`
**Methods**: `GET` (validation), `POST` (events)
**Authentication**: Strava webhook validation

**Validation (GET)**:
```http
GET /api/strava/webhook?hub.mode=subscribe&hub.challenge=xxx&hub.verify_token=xxx
```

**Response**:
```json
{
  "hub.challenge": "xxx"
}
```

**Event Handling (POST)**:
```http
POST /api/strava/webhook
Content-Type: application/json

{
  "object_type": "activity",
  "object_id": 12345,
  "aspect_type": "create",
  "owner_id": 67890,
  "subscription_id": 1,
  "event_time": 1609459200
}
```

**Response**:
```json
{
  "success": true
}
```

**Event Types**:
- `activity.create` - New activity uploaded
- `activity.update` - Activity modified
- `activity.delete` - Activity deleted
- `athlete.update` - Athlete profile changed

### Activity Sync

**Endpoint**: `/api/strava/activities`
**Method**: `GET`
**Authentication**: Required

**Request**:
```http
GET /api/strava/activities?after=1609459200&limit=50
Cookie: better-auth.session_token=xxx
```

**Query Parameters**:
- `after` - Unix timestamp, activities after this time
- `limit` - Max activities to return (default: 50, max: 200)

**Response**:
```json
{
  "activities": [
    {
      "id": "12345",
      "name": "Morning Run",
      "type": "Run",
      "distance": 5000,
      "moving_time": 1800,
      "elapsed_time": 1900,
      "start_date": "2025-01-02T06:00:00Z",
      "average_heartrate": 145,
      "max_heartrate": 165,
      "average_watts": null,
      "kilojoules": null
    }
  ],
  "synced_at": "2025-01-02T12:00:00Z"
}
```

## Program Management

### Create Program

**Endpoint**: `/api/program/create`
**Method**: `POST`
**Authentication**: Required

**Request**:
```http
POST /api/program/create
Content-Type: application/json
Cookie: better-auth.session_token=xxx

{
  "goalId": "goal_xxx",
  "startDate": "2025-01-06",
  "templateId": "template_xxx",
  "customizations": {
    "weeklyHoursTarget": 10,
    "unavailableDays": [0, 6],
    "poolSchedule": "weekdays"
  }
}
```

**Response**:
```json
{
  "program": {
    "id": "program_xxx",
    "userId": "user_xxx",
    "goalId": "goal_xxx",
    "startDate": "2025-01-06T00:00:00Z",
    "endDate": "2025-04-28T00:00:00Z",
    "totalWeeks": 16,
    "status": "active"
  }
}
```

### Get Program

**Endpoint**: `/api/program/[id]`
**Method**: `GET`
**Authentication**: Required

**Request**:
```http
GET /api/program/program_xxx
Cookie: better-auth.session_token=xxx
```

**Response**:
```json
{
  "program": {
    "id": "program_xxx",
    "userId": "user_xxx",
    "goalId": "goal_xxx",
    "currentWeek": 3,
    "currentPhase": "base",
    "status": "active",
    "weeks": [
      {
        "weekNumber": 1,
        "phase": "base",
        "plannedHours": 8.5,
        "actualHours": 7.2,
        "complianceRate": 0.85,
        "sessions": [...]
      }
    ]
  }
}
```

### Update Program

**Endpoint**: `/api/program/[id]`
**Method**: `PATCH`
**Authentication**: Required

**Request**:
```http
PATCH /api/program/program_xxx
Content-Type: application/json
Cookie: better-auth.session_token=xxx

{
  "status": "paused",
  "customizations": {
    "weeklyHoursTarget": 12
  }
}
```

**Response**:
```json
{
  "program": {
    "id": "program_xxx",
    "status": "paused",
    "updatedAt": "2025-01-02T12:00:00Z"
  }
}
```

### Recalculate Program

**Endpoint**: `/api/program/recalculate`
**Method**: `POST`
**Authentication**: Required

**Request**:
```http
POST /api/program/recalculate
Content-Type: application/json
Cookie: better-auth.session_token=xxx

{
  "programId": "program_xxx",
  "reason": "fatigue",
  "adjustments": {
    "reduceVolume": 20,
    "skipIntensity": true
  }
}
```

**Response**:
```json
{
  "program": {
    "id": "program_xxx",
    "recalcCount": 2,
    "lastRecalcAt": "2025-01-02T12:00:00Z"
  },
  "changesApplied": {
    "volumeReduction": "20%",
    "intensitySessionsPostponed": 3,
    "recoveryDaysAdded": 1
  }
}
```

## Webhooks

### IndexNow

**Endpoint**: `/api/webhook/indexnow`
**Method**: `POST`
**Authentication**: Internal (API key)

**Request**:
```http
POST /api/webhook/indexnow
Content-Type: application/json
X-API-Key: xxx

{
  "urls": [
    "https://tritrainer.app/training-plans/sprint/debutant",
    "https://tritrainer.app/training-plans/olympic/intermediate"
  ]
}
```

**Response**:
```json
{
  "success": true,
  "submitted": 2,
  "searchEngines": ["bing", "yandex"]
}
```

## Error Responses

All API routes return consistent error format:

```json
{
  "error": {
    "code": "UNAUTHORIZED",
    "message": "Session token invalid or expired",
    "details": {}
  }
}
```

**Error Codes**:
- `UNAUTHORIZED` (401) - Invalid/missing authentication
- `FORBIDDEN` (403) - Insufficient permissions
- `NOT_FOUND` (404) - Resource not found
- `VALIDATION_ERROR` (400) - Invalid request data
- `RATE_LIMITED` (429) - Too many requests
- `INTERNAL_ERROR` (500) - Server error

## Rate Limiting

Cloudflare Workers automatic rate limiting:
- **Authenticated endpoints**: 100 requests/minute per user
- **Public endpoints**: 20 requests/minute per IP
- **Webhooks**: 1000 requests/minute (validated signatures)

## CORS

CORS headers for all API routes:

```javascript
{
  "Access-Control-Allow-Origin": baseURL,
  "Access-Control-Allow-Methods": "GET, POST, PATCH, DELETE",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Allow-Credentials": "true"
}
```

## Development Testing

### Using curl

```bash
# Request magic link
curl -X POST http://localhost:3000/api/auth/sign-in/magic-link \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","callbackURL":"/dashboard"}'

# Get session
curl http://localhost:3000/api/auth/session \
  -H "Cookie: better-auth.session_token=xxx"

# Create program
curl -X POST http://localhost:3000/api/program/create \
  -H "Content-Type: application/json" \
  -H "Cookie: better-auth.session_token=xxx" \
  -d '{"goalId":"goal_xxx","startDate":"2025-01-06"}'
```

### Using Postman

1. Import OpenAPI spec (if available)
2. Set environment variable `baseURL` = `http://localhost:3000`
3. Use Postman cookie manager for session tokens
4. Test authentication flow:
   - Request magic link
   - Copy link from console
   - Visit link to get session cookie
   - Use cookie in subsequent requests

## Related Documentation

- [ADR-006: Better Auth for Authentication](../adr/006-better-auth-authentication.md)
- [Component Architecture](./components.md)
- [Database Schema](./database-schema.md)
- [Setup Guide](../guides/setup.md)
