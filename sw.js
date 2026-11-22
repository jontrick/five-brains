// 5 Brains service worker — bump VERSION on every deploy to refresh the cache.
const VERSION = 'fb-1.11.0';
const SHELL = ['./', './index.html', './manifest.json', './icons/icon-180.png', './icons/icon-192.png', './icons/icon-512.png',
  'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2'];

self.addEventListener('install', e => {
  e.waitUntil(caches.open(VERSION).then(c => Promise.all(SHELL.map(u => c.add(u).catch(() => {})))).then(() => self.skipWaiting()));
});
self.addEventListener('activate', e => {
  e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== VERSION).map(k => caches.delete(k)))).then(() => self.clients.claim()));
});
self.addEventListener('fetch', e => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET') return;                       // API writes go straight to network
  if (u.hostname.endsWith('supabase.co') || u.hostname.endsWith('workers.dev') || u.hostname.endsWith('open-meteo.com') || u.hostname.endsWith('tile.openstreetmap.org')) return;
  // App shell: network first (so deploys land), fall back to cache offline.
  // Same-origin files revalidate every time (ETag, cheap) instead of trusting
  // GitHub Pages' 10-minute max-age — otherwise a push can take 10 min to land.
  const req = u.origin === self.location.origin ? new Request(e.request, { cache: 'no-cache' }) : e.request;
  e.respondWith(
    fetch(req).then(r => { const cp = r.clone(); caches.open(VERSION).then(c => c.put(e.request, cp)); return r; })
      .catch(() => caches.match(e.request).then(r => r || (e.request.mode === 'navigate' ? caches.match('./index.html') : Response.error())))
  );
});
