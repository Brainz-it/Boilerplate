# ADR-007: Database-Backed Background Job System

## Status
**Accepted** - 2025-01-02

## Context

Edge applications on Cloudflare Workers face constraints for background processing:

- **30-second CPU time limit** per request
- **No persistent background processes** (serverless)
- **Need visibility** into job status and progress
- **Require retry mechanisms** for failures
- **Must support manual intervention** (pause, resume, cancel)

### Use Cases Requiring Background Jobs

- **CV/Document Processing**: LLM-powered extraction (can take 10-30 seconds)
- **Email Notifications**: Batch sending with rate limiting
- **Event Processing**: Event-driven workflows and subscriptions
- **Data Synchronization**: External API integrations
- **Report Generation**: Heavy computation tasks

## Decision

We implement a **database-backed job queue** with Cloudflare Cron Triggers for polling.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Background Job System                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Job Creation                    Job Processing                            │
│   ────────────                    ──────────────                            │
│                                                                             │
│   ┌─────────────┐                 ┌─────────────────────────┐              │
│   │  API Route  │──────────────►  │    background_jobs      │              │
│   │  (create)   │  INSERT job     │─────────────────────────│              │
│   └─────────────┘                 │ status: pending         │              │
│                                   │ type: cv_processing     │              │
│                                   │ input_data: {...}       │              │
│                                   └───────────┬─────────────┘              │
│                                               │                             │
│   Trigger Methods                             │                             │
│   ───────────────                             ▼                             │
│                                   ┌─────────────────────────┐              │
│   1. Cron Trigger (every 1 min)   │    Job Processor        │              │
│      wrangler.toml:               │─────────────────────────│              │
│      crons = ["* * * * *"]        │ 1. Lock job (optimistic)│              │
│                                   │ 2. Update progress      │              │
│   2. Manual API Call              │ 3. Execute handler      │              │
│      POST /api/jobs/trigger       │ 4. Update status        │              │
│                                   │ 5. Store output         │              │
│   3. Webhook/Event-driven         └───────────┬─────────────┘              │
│      POST /api/jobs/create                    │                             │
│                                               ▼                             │
│                                   ┌─────────────────────────┐              │
│                                   │  background_job_logs    │              │
│                                   │─────────────────────────│              │
│                                   │ stage: text_extraction  │              │
│                                   │ level: info             │              │
│                                   │ duration_ms: 1234       │              │
│                                   └─────────────────────────┘              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Job State Machine

```
                    ┌──────────────┐
                    │   PENDING    │
                    └──────┬───────┘
                           │ lock acquired
                           ▼
                    ┌──────────────┐
            ┌───────│  PROCESSING  │───────┐
            │       └──────────────┘       │
            │              │               │
     success│       needs review     error │
            │              │               │
            ▼              ▼               ▼
     ┌──────────┐  ┌─────────────┐  ┌─────────┐
     │COMPLETED │  │REVIEW_NEEDED│  │ FAILED  │
     └──────────┘  └──────┬──────┘  └────┬────┘
                         │               │
                   approve│         retry │ (if attempts < max)
                         │               │
                         ▼               ▼
                  ┌──────────┐   ┌──────────────┐
                  │COMPLETED │   │   PENDING    │
                  └──────────┘   │ (retry_count++)
                                 └──────────────┘
```

### Key Components

1. **Job Types Configuration** (`background_job_types` table)
   - Defines available job types
   - Configurable retry count, timeout, concurrency
   - Enable/pause individual job types

2. **Job Queue** (`background_jobs` table)
   - Stores job instances with status
   - Optimistic locking via `locked_at` / `locked_by`
   - Priority queue support (1-20 scale)
   - Progress tracking (0-100%)

3. **Job Logs** (`background_job_logs` table)
   - Per-stage logging with timing
   - Error traces and metadata
   - Full audit trail

4. **Worker Configuration** (`worker_config` table)
   - Global enable/pause switch
   - LLM provider settings
   - Processing parameters

## Consequences

### Positive

- **Full Visibility**: Job history, logs, progress in database
- **Reliability**: Automatic retries with configurable backoff
- **Control**: Manual trigger, pause, resume, cancel operations
- **Auditability**: Detailed logs for each processing stage
- **Extensibility**: Easy to add new job types with handler pattern
- **Cost Efficient**: Uses D1 (included with Workers), no extra service
- **Queryable**: Complex queries for filtering, search, analytics

### Negative

- **Polling Required**: Cron-based, not real-time push
- **Cold Start**: First trigger may have 50-100ms latency
- **Database Load**: Frequent status updates and queries
- **Complexity**: More code than simple async/await
- **30s Limit**: Jobs must complete within CPU time limit

### Neutral

- **Not Event-Driven**: Trade-off for simplicity over Queues/DO
- **Single Region Primary**: D1 replication handles reads globally

## Alternatives Considered

### 1. Cloudflare Queues
**Pros**: Native queue service, at-least-once delivery, push model
**Cons**: Additional service, less visibility, separate billing, no UI
**Rejected**: Database approach provides better control and visibility

### 2. Cloudflare Durable Objects
**Pros**: Stateful execution, WebSocket support, strong consistency
**Cons**: Complex programming model, single-region primary, higher cost
**Rejected**: Overkill for job queue, adds unnecessary complexity

### 3. External Queue (SQS, RabbitMQ, Redis)
**Pros**: Battle-tested, feature-rich, high throughput
**Cons**: Additional latency, separate service, authentication, cost
**Rejected**: Want to stay within Cloudflare ecosystem for simplicity

### 4. Simple Cron Without Queue
**Pros**: Simple, predictable, no state management
**Cons**: No immediate processing, fixed intervals, no retry logic
**Rejected**: Need job tracking, retries, and manual trigger capability

## Implementation Details

### Database Schema

```sql
-- Job Types Configuration
CREATE TABLE background_job_types (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  handler_name TEXT NOT NULL,
  max_retries INTEGER NOT NULL DEFAULT 3,
  retry_delay_ms INTEGER NOT NULL DEFAULT 60000,
  timeout_ms INTEGER NOT NULL DEFAULT 300000,
  max_concurrent INTEGER NOT NULL DEFAULT 5,
  stages_config TEXT, -- JSON array of stage names
  cron_schedule TEXT, -- Optional cron expression
  is_enabled INTEGER NOT NULL DEFAULT 1,
  is_paused INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Job Queue
CREATE TABLE background_jobs (
  id TEXT PRIMARY KEY,
  job_type_id TEXT NOT NULL REFERENCES background_job_types(id),
  status TEXT NOT NULL DEFAULT 'pending',
  priority INTEGER NOT NULL DEFAULT 10,
  progress INTEGER NOT NULL DEFAULT 0,
  current_stage TEXT,
  input_data TEXT, -- JSON
  output_data TEXT, -- JSON
  error_message TEXT,
  reference_type TEXT, -- polymorphic: 'user', 'profile', etc.
  reference_id TEXT,   -- ID of related entity
  locked_at INTEGER,
  locked_by TEXT,
  scheduled_for INTEGER,
  started_at INTEGER,
  completed_at INTEGER,
  retry_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,

  CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'review_needed', 'cancelled')),
  CHECK (priority BETWEEN 1 AND 20),
  CHECK (progress BETWEEN 0 AND 100)
);

CREATE INDEX idx_jobs_status ON background_jobs(status);
CREATE INDEX idx_jobs_priority_status ON background_jobs(priority DESC, status, created_at);
CREATE INDEX idx_jobs_locked ON background_jobs(locked_at, locked_by);
CREATE INDEX idx_jobs_reference ON background_jobs(reference_type, reference_id);
CREATE INDEX idx_jobs_scheduled ON background_jobs(scheduled_for);

-- Job Logs (Audit Trail)
CREATE TABLE background_job_logs (
  id TEXT PRIMARY KEY,
  job_id TEXT NOT NULL REFERENCES background_jobs(id) ON DELETE CASCADE,
  level TEXT NOT NULL DEFAULT 'info',
  stage TEXT,
  message TEXT NOT NULL,
  details TEXT, -- JSON
  duration_ms INTEGER,
  created_at INTEGER NOT NULL,

  CHECK (level IN ('debug', 'info', 'warning', 'error'))
);

CREATE INDEX idx_job_logs_job ON background_job_logs(job_id, created_at);
CREATE INDEX idx_job_logs_level ON background_job_logs(level);

-- Global Worker Configuration
CREATE TABLE worker_config (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  description TEXT,
  updated_at INTEGER NOT NULL
);
```

### Job Handler Pattern

```typescript
// src/lib/jobs/handlers/types.ts
export interface JobHandler {
  (
    job: BackgroundJob,
    db: DatabaseClient,
    env: CloudflareEnv,
    log: (message: string, level?: LogLevel, details?: any) => Promise<void>
  ): Promise<JobResult>;
}

export interface JobResult {
  success: boolean;
  output?: any;
  error?: string;
  needsReview?: boolean;
}

// src/lib/jobs/handlers/registry.ts
export const jobHandlers: Record<string, JobHandler> = {
  cv_processing: handleCVProcessing,
  email_notification: handleEmailNotification,
  data_sync: handleDataSync,
};
```

### Example Handler Implementation

```typescript
// src/lib/jobs/handlers/cv-processing.ts
export async function handleCVProcessing(
  job: BackgroundJob,
  db: DatabaseClient,
  env: CloudflareEnv,
  log: LogFunction
): Promise<JobResult> {
  const input = JSON.parse(job.inputData || '{}');

  try {
    // Stage 1: Text Extraction (10%)
    await log('Starting text extraction', 'info');
    await updateJobProgress(db, job.id, 10, 'text_extraction');
    const text = await extractTextFromPDF(env.R2, input.fileUrl);
    await log(`Extracted ${text.length} characters`, 'info');

    // Stage 2: LLM Processing (10% → 80%)
    await updateJobProgress(db, job.id, 40, 'llm_processing');
    await log('Sending to LLM for analysis', 'info');
    const structured = await processWithLLM(text, env);
    await log('LLM processing complete', 'info');

    // Stage 3: Validation & Storage (80% → 100%)
    await updateJobProgress(db, job.id, 80, 'validation');
    await log('Validating and storing results', 'info');
    await storeResults(db, job.referenceId, structured);

    return {
      success: true,
      output: { structured, extractedLength: text.length },
    };

  } catch (error) {
    await log(`Processing failed: ${error.message}`, 'error', {
      stack: error.stack,
    });

    return {
      success: false,
      error: error.message,
    };
  }
}
```

### Job Processor (Cron Handler)

```typescript
// src/lib/jobs/processor.ts
export async function processJobs(
  db: DatabaseClient,
  env: CloudflareEnv
): Promise<{ processed: number; errors: number }> {
  const workerId = `worker_${crypto.randomUUID().slice(0, 8)}`;
  let processed = 0;
  let errors = 0;

  // Check if worker is enabled
  const config = await getWorkerConfig(db);
  if (!config.worker_enabled) {
    console.log('[JobProcessor] Worker is disabled');
    return { processed: 0, errors: 0 };
  }

  // Get enabled job types
  const jobTypes = await getEnabledJobTypes(db);

  for (const jobType of jobTypes) {
    // Get pending jobs for this type
    const pendingJobs = await getPendingJobs(db, jobType.id, jobType.maxConcurrent);

    for (const job of pendingJobs) {
      // Try to lock the job
      const locked = await lockJob(db, job.id, workerId, jobType.timeoutMs);

      if (!locked) {
        continue; // Another worker got it
      }

      try {
        // Get handler
        const handler = jobHandlers[jobType.handlerName];
        if (!handler) {
          throw new Error(`No handler for ${jobType.handlerName}`);
        }

        // Create log function
        const log = createJobLogger(db, job.id);

        // Execute handler
        const result = await handler(job, db, env, log);

        if (result.success) {
          await completeJob(db, job.id, result.output);
          processed++;
        } else if (result.needsReview) {
          await markForReview(db, job.id, result.error);
          processed++;
        } else {
          // Check retry count
          if (job.retryCount < jobType.maxRetries) {
            await scheduleRetry(db, job.id, jobType.retryDelayMs);
          } else {
            await failJob(db, job.id, result.error);
          }
          errors++;
        }

      } catch (error) {
        await failJob(db, job.id, error.message);
        errors++;
      }
    }
  }

  return { processed, errors };
}
```

### Optimistic Locking

```typescript
// src/lib/jobs/queries.ts
export async function lockJob(
  db: DatabaseClient,
  jobId: string,
  workerId: string,
  timeoutMs: number
): Promise<boolean> {
  const now = Date.now();
  const lockExpiry = now - timeoutMs; // Jobs locked longer than timeout can be reclaimed

  const result = await db.drizzle
    .update(backgroundJobs)
    .set({
      status: 'processing',
      lockedAt: now,
      lockedBy: workerId,
      startedAt: now,
    })
    .where(
      and(
        eq(backgroundJobs.id, jobId),
        eq(backgroundJobs.status, 'pending'),
        or(
          isNull(backgroundJobs.lockedAt),
          lt(backgroundJobs.lockedAt, lockExpiry)
        )
      )
    )
    .returning();

  return result.length > 0;
}
```

### Wrangler Configuration

```toml
# wrangler.toml
[triggers]
crons = ["* * * * *"]  # Every minute

# In worker entry point
export default {
  async fetch(request, env, ctx) {
    // Handle HTTP requests
    return openNextWorker.fetch(request, env, ctx);
  },

  async scheduled(event, env, ctx) {
    // Cron trigger - process jobs
    const db = createDb(env.DB);
    const result = await processJobs(db, env);
    console.log(`[Cron] Processed: ${result.processed}, Errors: ${result.errors}`);
  },
};
```

### API Routes

```typescript
// Job Management API
GET  /api/jobs               // List jobs with filters
GET  /api/jobs/[id]          // Job details + logs
POST /api/jobs               // Create new job
POST /api/jobs/[id]/retry    // Retry failed job
POST /api/jobs/[id]/cancel   // Cancel pending job
DELETE /api/jobs/[id]        // Delete job

// Worker Control API
POST /api/jobs/trigger       // Manual trigger (admin only)
GET  /api/worker/config      // Get worker config
PUT  /api/worker/config      // Update worker config
```

## Job Types Examples

### Built-in Job Types

| Type | Handler | Input | Output | Use Case |
|------|---------|-------|--------|----------|
| `cv_processing` | `handleCVProcessing` | `{ fileUrl, profileId }` | `{ structured, metrics }` | PDF CV analysis |
| `email_notification` | `handleEmailNotification` | `{ to, template, data }` | `{ messageId }` | Send email |
| `data_sync` | `handleDataSync` | `{ source, destination }` | `{ synced, errors }` | External API sync |

### Adding New Job Types

1. Create handler in `src/lib/jobs/handlers/`
2. Register in `registry.ts`
3. Insert job type in `background_job_types` table
4. Create jobs via API or programmatically

```sql
-- Add new job type
INSERT INTO background_job_types (
  id, name, description, handler_name,
  max_retries, retry_delay_ms, timeout_ms, max_concurrent,
  is_enabled, created_at, updated_at
) VALUES (
  'jt_report_gen',
  'report_generation',
  'Generate PDF reports',
  'handleReportGeneration',
  2, 120000, 600000, 2,
  1, unixepoch(), unixepoch()
);
```

## Monitoring & Operations

### Key Queries

```sql
-- Active jobs count by status
SELECT status, COUNT(*) as count
FROM background_jobs
GROUP BY status;

-- Jobs stuck in processing (potential timeout)
SELECT * FROM background_jobs
WHERE status = 'processing'
AND locked_at < unixepoch() - 300;

-- Failed jobs by type (last 24h)
SELECT job_type_id, COUNT(*) as failures
FROM background_jobs
WHERE status = 'failed'
AND created_at > unixepoch() - 86400
GROUP BY job_type_id;

-- Average processing time by type
SELECT
  bt.name,
  AVG(bj.completed_at - bj.started_at) as avg_duration_ms
FROM background_jobs bj
JOIN background_job_types bt ON bj.job_type_id = bt.id
WHERE bj.status = 'completed'
GROUP BY bt.name;
```

### Alerts to Configure

- Job failure rate > 10%
- Jobs stuck in processing > 5 minutes
- Queue depth > 100 pending jobs
- Worker disabled unexpectedly

## Performance Considerations

### Scalability

- **Concurrent jobs**: Limited per type (configurable)
- **Batch processing**: Process multiple jobs per cron invocation
- **Priority queue**: High-priority jobs processed first
- **Lock timeout**: Prevents deadlocks from crashed workers

### Database Load

- **Indexes**: Optimized for status, priority, locking queries
- **Cleanup**: Archive/delete old completed jobs
- **Pagination**: Limit job fetching per cycle

### Edge Runtime

- **30s limit**: Jobs must complete within CPU time
- **Cold start**: ~50ms overhead on first invocation
- **Memory**: 128MB limit (sufficient for most jobs)

## Security

### Authentication

- Job management APIs require admin authentication
- Worker config changes require super_admin role
- Job creation may be public or authenticated (configurable)

### Input Validation

- Validate `inputData` JSON structure
- Sanitize error messages (no secrets in logs)
- Rate limit job creation endpoints

### Secrets

- API keys in environment variables (not database)
- Never log full API responses with sensitive data
- Use Wrangler secrets for production

## Related ADRs

- [ADR-003: D1 Database with Drizzle ORM](003-d1-database-drizzle-orm.md)
- [ADR-005: Custom Worker Wrapper](005-worker-wrapper-page-blocking.md)

## References

- [Cloudflare Workers Cron Triggers](https://developers.cloudflare.com/workers/configuration/cron-triggers/)
- [Job Queue Design Patterns](https://docs.temporal.io/concepts/what-is-a-workflow/)
- [Background Jobs Best Practices](https://github.blog/2022-06-08-job-queues-design-patterns/)
- [Optimistic Locking Pattern](https://www.martinfowler.com/eaaCatalog/optimisticOfflineLock.html)
