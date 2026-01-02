# Deployment Guide

Complete guide to deploy TriTrainer to Cloudflare Workers production environment.

## Prerequisites

- Completed [Local Setup](./setup.md)
- Cloudflare account with payment method (for production tier)
- Custom domain (optional but recommended)
- Resend account for email (production magic links)

## Pre-Deployment Checklist

- [ ] All tests passing locally
- [ ] Database migrations tested
- [ ] Environment variables configured
- [ ] Custom domain DNS configured (if using)
- [ ] Email service configured (Resend)
- [ ] Strava webhook configured (if using)

## Environment Setup

### 1. Production Environment Variables

Set secrets in Cloudflare:

```bash
# Better Auth secret
npx wrangler secret put BETTER_AUTH_SECRET
# Paste your secret (min 32 chars)

# Resend API key
npx wrangler secret put RESEND_API_KEY
# Paste your Resend API key

# Strava secrets (if using)
npx wrangler secret put STRAVA_CLIENT_SECRET
npx wrangler secret put STRAVA_WEBHOOK_VERIFY_TOKEN
```

### 2. Update wrangler.toml

```toml
name = "triathlon-app"
main = "worker.js"
compatibility_date = "2024-12-01"

[assets]
directory = ".open-next/assets"

# Production database
[[d1_databases]]
binding = "DB"
database_name = "triathlon-db"
database_id = "your-production-db-id"

# Environment variables (non-secret)
[vars]
BETTER_AUTH_URL = "https://tritrainer.app"
EMAIL_FROM = "TriTrainer <noreply@tritrainer.app>"
ENVIRONMENT = "production"
STRAVA_CLIENT_ID = "12345"  # If using Strava

# Production routes
routes = [
  { pattern = "tritrainer.app/*", zone_name = "tritrainer.app" },
  { pattern = "www.tritrainer.app/*", zone_name = "tritrainer.app" }
]
```

## Database Migration

### 1. Create Production Database

```bash
npx wrangler d1 create triathlon-db-prod
```

Note the `database_id` and update `wrangler.toml`.

### 2. Run Production Migrations

```bash
# Apply all migrations
for migration in migrations/*.sql; do
  npx wrangler d1 execute triathlon-db \
    --remote \
    --file "$migration"
done
```

### 3. Verify Production Database

```bash
# Check tables
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "SELECT name FROM sqlite_master WHERE type='table'"

# Verify pSEO pages
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "SELECT status, COUNT(*) FROM pseo_pages GROUP BY status"
```

## Domain Configuration

### 1. Add Domain to Cloudflare

1. Visit [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Click "Add a Site"
3. Enter your domain: `tritrainer.app`
4. Select Free plan (or higher)
5. Copy nameservers

### 2. Update Domain Registrar

1. Log in to your domain registrar
2. Update nameservers to Cloudflare's:
   ```
   ns1.cloudflare.com
   ns2.cloudflare.com
   ```
3. Wait for DNS propagation (up to 48 hours, usually <1 hour)

### 3. Configure DNS Records

In Cloudflare DNS:

**A Record** (if using Cloudflare Workers):
```
Type: A
Name: @
Content: 192.0.2.1
Proxy: Enabled (orange cloud)
```

**CNAME Record** (www redirect):
```
Type: CNAME
Name: www
Content: tritrainer.app
Proxy: Enabled (orange cloud)
```

### 4. SSL/TLS Configuration

1. Go to SSL/TLS settings
2. Set mode to "Full (strict)"
3. Enable "Always Use HTTPS"
4. Enable "Automatic HTTPS Rewrites"

## Email Configuration (Resend)

### 1. Sign Up for Resend

1. Visit [resend.com](https://resend.com)
2. Create account
3. Verify email

### 2. Add Domain

1. Go to "Domains" → "Add Domain"
2. Enter: `tritrainer.app`
3. Add DNS records to Cloudflare:

**SPF Record**:
```
Type: TXT
Name: @
Content: v=spf1 include:_spf.resend.com ~all
```

**DKIM Record**:
```
Type: TXT
Name: resend._domainkey
Content: (provided by Resend)
```

**DMARC Record**:
```
Type: TXT
Name: _dmarc
Content: v=DMARC1; p=none; rua=mailto:dmarc@tritrainer.app
```

### 3. Verify Domain

1. Click "Verify" in Resend dashboard
2. Wait for DNS propagation (5-30 minutes)
3. Domain status should show "Verified"

### 4. Get API Key

1. Go to "API Keys"
2. Click "Create API Key"
3. Name: "Production"
4. Copy key and save as secret:

```bash
npx wrangler secret put RESEND_API_KEY
# Paste API key
```

## Build and Deploy

### 1. Build Application

```bash
# Install dependencies
pnpm install

# Build Next.js app
pnpm build
```

This generates `.open-next/` directory with:
- `worker.js` - OpenNext Worker
- `assets/` - Static files
- `server-functions/` - SSR functions

### 2. Deploy to Cloudflare

```bash
npx wrangler deploy
```

**Output**:
```
✨ Compiled Worker successfully
🌎 Deploying...
✅ Deployed to:
   https://triathlon-app.your-subdomain.workers.dev
   https://tritrainer.app
```

### 3. Verify Deployment

```bash
# Check homepage
curl -I https://tritrainer.app

# Check API
curl https://tritrainer.app/api/auth/session

# Check pSEO page (should be 404 if pending)
curl -I https://tritrainer.app/generateur/xs-debutant
```

## pSEO Rollout

### 1. Activate Initial Batch

```bash
# Activate batch 0 (core pages)
npx wrangler d1 execute triathlon-db \
  --remote \
  --command "
    UPDATE pseo_pages
    SET status = 'active', published_at = unixepoch()
    WHERE sitemap_batch = 0
  "
```

### 2. Verify Activation

```bash
# Check activated pages
curl -I https://tritrainer.app/training-plans
# Should return 200 OK

# Check pending pages
curl -I https://tritrainer.app/generateur/xs-debutant
# Should return 404 Not Found
```

### 3. Submit to Search Engines

```bash
# Submit sitemap
curl -X POST "https://www.google.com/ping?sitemap=https://tritrainer.app/sitemap.xml"

# IndexNow (Bing, Yandex)
curl -X POST https://api.indexnow.org/indexnow \
  -H "Content-Type: application/json" \
  -d '{
    "host": "tritrainer.app",
    "key": "your-indexnow-key",
    "urlList": ["https://tritrainer.app/training-plans"]
  }'
```

## Strava Integration (Optional)

### 1. Update Strava App Settings

1. Visit [Strava API Settings](https://www.strava.com/settings/api)
2. Update application:
   - **Website**: https://tritrainer.app
   - **Authorization Callback Domain**: tritrainer.app

### 2. Configure Webhook

```bash
# Subscribe to webhooks
curl -X POST https://www.strava.com/api/v3/push_subscriptions \
  -F client_id=YOUR_CLIENT_ID \
  -F client_secret=YOUR_CLIENT_SECRET \
  -F callback_url=https://tritrainer.app/api/strava/webhook \
  -F verify_token=YOUR_VERIFY_TOKEN
```

### 3. Verify Webhook

```bash
# List subscriptions
curl -G https://www.strava.com/api/v3/push_subscriptions \
  -d client_id=YOUR_CLIENT_ID \
  -d client_secret=YOUR_CLIENT_SECRET
```

## Monitoring and Logs

### 1. View Live Logs

```bash
# Tail production logs
npx wrangler tail

# Filter for errors
npx wrangler tail --format json | grep -i error

# Filter for pSEO blocking
npx wrangler tail --format json | grep "Worker.*Blocking"
```

### 2. Check Analytics

1. Visit [Cloudflare Dashboard](https://dash.cloudflare.com/)
2. Go to Workers & Pages → triathlon-app
3. View metrics:
   - Requests per minute
   - Error rate
   - Response time (P50, P99)
   - CPU time

### 3. Setup Alerts

**Error Rate Alert**:
1. Go to Notifications
2. Create notification
3. Condition: Error rate > 5%
4. Action: Email

**D1 Database Alert**:
1. Go to D1 dashboard
2. Enable notifications
3. Alert on query errors

## Continuous Deployment

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Cloudflare

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      deployments: write

    steps:
      - uses: actions/checkout@v4

      - uses: pnpm/action-setup@v2
        with:
          version: 8

      - uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: pnpm

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build application
        run: pnpm build

      - name: Deploy to Cloudflare
        uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

### Setup Secrets

1. Go to GitHub repository → Settings → Secrets
2. Add secrets:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`

## Performance Optimization

### 1. Enable Caching

In `wrangler.toml`:

```toml
[cache]
# Cache static assets
cache_control = "public, max-age=31536000, immutable"
```

### 2. Optimize Images

Use Cloudflare Images:

```toml
[[r2_buckets]]
binding = "IMAGES"
bucket_name = "tritrainer-images"
```

### 3. Enable Auto Minify

In Cloudflare dashboard:
1. Go to Speed → Optimization
2. Enable Auto Minify (JavaScript, CSS, HTML)
3. Enable Brotli compression

## Security

### 1. Configure Security Headers

In `worker.js`:

```javascript
response.headers.set('X-Frame-Options', 'DENY');
response.headers.set('X-Content-Type-Options', 'nosniff');
response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
response.headers.set('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
```

### 2. Enable Bot Protection

1. Go to Security → Bots
2. Enable "Bot Fight Mode"
3. Configure challenge pages

### 3. Setup Rate Limiting

1. Go to Security → WAF
2. Create rate limiting rule:
   - Path: `/api/*`
   - Requests: 100/minute
   - Action: Block

## Rollback Procedure

### 1. List Deployments

```bash
npx wrangler deployments list
```

### 2. Rollback to Previous Version

```bash
npx wrangler rollback --message "Rollback due to issue"
```

### 3. Rollback Database (if needed)

```bash
# Export current database
npx wrangler d1 export triathlon-db --remote --output backup.sql

# Restore from backup
npx wrangler d1 execute triathlon-db --remote --file backup-previous.sql
```

## Post-Deployment Checklist

- [ ] Homepage loads (https://tritrainer.app)
- [ ] Authentication works (magic link email received)
- [ ] Dashboard accessible after login
- [ ] pSEO pages return correct status (active = 200, pending = 404)
- [ ] Strava OAuth works (if configured)
- [ ] Email delivery working (Resend)
- [ ] Analytics tracking
- [ ] Error monitoring active
- [ ] Sitemap submitted to Google
- [ ] DNS propagated fully

## Troubleshooting

### 502 Bad Gateway

**Cause**: Worker error or timeout

**Solution**:
```bash
# Check logs
npx wrangler tail --format json

# Verify worker deployment
npx wrangler deployments list
```

### Database Connection Error

**Cause**: Wrong `database_id` in `wrangler.toml`

**Solution**:
1. Verify database exists: `npx wrangler d1 list`
2. Update `database_id` in `wrangler.toml`
3. Redeploy: `npx wrangler deploy`

### Email Not Sending

**Cause**: Resend not configured or domain not verified

**Solution**:
1. Check Resend domain status
2. Verify DNS records in Cloudflare
3. Test API key: `npx wrangler secret list`

## Cost Estimation

**Monthly costs (10k active users, 1M requests/month)**:

| Service | Tier | Cost |
|---------|------|------|
| Cloudflare Workers | Free → Paid | $0-5 |
| D1 Database | Free → Paid | $0-2 |
| Resend | Free (3k emails) | $0 |
| Custom Domain | - | $12/year |
| **Total** | | **~$7/month** |

**Free Tier Limits**:
- Workers: 100k requests/day
- D1: 5M reads/day, 100k writes/day
- Resend: 3,000 emails/month

## Support and Resources

- **Documentation**: [/docs](/docs)
- **Cloudflare Status**: [cloudflarestatus.com](https://www.cloudflarestatus.com/)
- **Resend Status**: [status.resend.com](https://status.resend.com/)
- **Community**: Discord channel

## Next Steps

- [Monitoring Guide](./monitoring.md) - Setup monitoring
- [Scaling Guide](./scaling.md) - Scale to 100k+ users
- [Backup Guide](./backup.md) - Database backups
- [Incident Response](./incidents.md) - Handle incidents
