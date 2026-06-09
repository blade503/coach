/* Service worker — Mon coach perte de poids (PWA)
   Cache la coquille de l'app pour un lancement rapide et un usage hors-ligne.
   Les appels à Supabase (données) passent toujours par le réseau. */
const CACHE = "coach-v1";
const SHELL = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icon-192.png",
  "./icon-512.png",
  "./apple-touch-icon.png"
];

self.addEventListener("install", e => {
  e.waitUntil(
    caches.open(CACHE).then(c => c.addAll(SHELL)).then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", e => {
  e.waitUntil(
    caches.keys()
      .then(keys => Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", e => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  // Ne jamais mettre en cache les données dynamiques Supabase
  if (url.hostname.endsWith("supabase.co")) return;
  // Réseau d'abord, puis cache (et copie en cache pour la prochaine fois)
  e.respondWith(
    fetch(req).then(res => {
      const copy = res.clone();
      caches.open(CACHE).then(c => c.put(req, copy)).catch(() => {});
      return res;
    }).catch(() => caches.match(req).then(m => m || caches.match("./index.html")))
  );
});
