// Caches the app so it opens without a connection.
const CACHE = 'expenses-v1';
const FILES = ['./', 'index.html', 'style.css', 'parser.js', 'app.js', 'manifest.json', 'icon.svg', 'icon-180.png'];
self.addEventListener('install', (e) => e.waitUntil(caches.open(CACHE).then((c) => c.addAll(FILES))));
self.addEventListener('activate', (e) => e.waitUntil(
  caches.keys().then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
));
self.addEventListener('fetch', (e) => e.respondWith(
  fetch(e.request).then((res) => {
    const copy = res.clone();
    caches.open(CACHE).then((c) => c.put(e.request, copy));
    return res;
  }).catch(() => caches.match(e.request))
));
