/**
 * Custom Cloudflare Worker wrapper for OpenNext
 *
 * This wrapper intercepts requests to pSEO pages and checks their status
 * in the D1 database before serving the pre-rendered static HTML.
 */

import openNextWorker from './.open-next/worker.js';
import { drizzle } from 'drizzle-orm/d1';
import { eq } from 'drizzle-orm';
import { pseoPages } from './src/lib/db/schema/pseo.js';

// Pattern to match pSEO routes
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
  console.log('[Worker] Checking page status:', pathname);

  const drizzleDb = drizzle(db);

  try {
    const result = await drizzleDb
      .select()
      .from(pseoPages)
      .where(eq(pseoPages.urlPath, pathname))
      .limit(1);

    const page = result[0];

    console.log('[Worker] Page query result:', {
      found: !!page,
      status: page?.status,
      title: page?.title,
    });

    if (!page) {
      return 'not-found';
    }

    if (page.status === 'active') {
      return 'active';
    }

    // pending, paused, archived
    return 'blocked';
  } catch (error) {
    console.error('[Worker] Database error:', error);
    // On error, allow the request through (fail open)
    return 'active';
  }
}

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    console.log('[Worker] === Request Start ===');
    console.log('[Worker] Path:', url.pathname);

    // Check if this is a pSEO route
    if (isPSEORoute(url.pathname)) {
      console.log('[Worker] pSEO route detected');

      const status = await checkPageStatus(env.DB, url.pathname);

      console.log('[Worker] Page status:', status);

      if (status === 'blocked') {
        console.log('[Worker] ❌ Blocking pending/paused/archived page');
        return new Response('Not Found', {
          status: 404,
          headers: { 'Content-Type': 'text/plain' },
        });
      }

      if (status === 'not-found') {
        console.log('[Worker] ⚠️  Page not in database - allowing through');
      }

      console.log('[Worker] ✅ Page is active - passing to OpenNext');
    }

    // Pass request to OpenNext worker
    return openNextWorker.fetch(request, env, ctx);
  },
};
