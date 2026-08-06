'use strict';

// Fichier produit par tool/build_service_worker.py — ne pas modifier a la main.

const VERSION = '0261c8cabcee';
const CACHE = 'parlemoi-' + VERSION;
const RESSOURCES = [
  "assets/AssetManifest.bin",
  "assets/AssetManifest.bin.json",
  "assets/FontManifest.json",
  "assets/assets/catalogue.json",
  "assets/assets/fonts/NotoColorEmoji.ttf",
  "assets/assets/fonts/Roboto-Black.ttf",
  "assets/assets/fonts/Roboto-Bold.ttf",
  "assets/assets/fonts/Roboto-Regular.ttf",
  "assets/assets/pictograms/aide.svg",
  "assets/assets/pictograms/calin.svg",
  "assets/assets/pictograms/colere.svg",
  "assets/assets/pictograms/content.svg",
  "assets/assets/pictograms/dormir.svg",
  "assets/assets/pictograms/faim.svg",
  "assets/assets/pictograms/jouer.svg",
  "assets/assets/pictograms/maison.svg",
  "assets/assets/pictograms/mal.svg",
  "assets/assets/pictograms/maman.svg",
  "assets/assets/pictograms/papa.svg",
  "assets/assets/pictograms/parc.svg",
  "assets/assets/pictograms/peur.svg",
  "assets/assets/pictograms/pipi.svg",
  "assets/assets/pictograms/popo.svg",
  "assets/assets/pictograms/soif.svg",
  "assets/assets/pictograms/tablette.svg",
  "assets/assets/pictograms/tete.svg",
  "assets/assets/pictograms/triste.svg",
  "assets/assets/pictograms/ventre.svg",
  "assets/fonts/MaterialIcons-Regular.otf",
  "assets/packages/record_web/assets/js/record.worklet.js",
  "assets/shaders/ink_sparkle.frag",
  "assets/shaders/stretch_effect.frag",
  "favicon.png",
  "flutter.js",
  "flutter_bootstrap.js",
  "icons/Icon-192.png",
  "icons/Icon-512.png",
  "icons/Icon-maskable-192.png",
  "icons/Icon-maskable-512.png",
  "index.html",
  "main.dart.js",
  "manifest.json",
  "version.json"
];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // `reload` contourne le cache HTTP du navigateur : sans cela une version
    // perimee pourrait etre figee dans le cache hors ligne.
    await Promise.all(RESSOURCES.map((chemin) =>
      cache.add(new Request(chemin, {cache: 'reload'})).catch(() => {
        // Un fichier manquant ne doit pas faire echouer toute l'installation.
      })
    ));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const noms = await caches.keys();
    await Promise.all(
      noms.filter((nom) => nom.startsWith('parlemoi-') && nom !== CACHE)
          .map((nom) => caches.delete(nom))
    );
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const requete = event.request;
  if (requete.method !== 'GET') return;

  const url = new URL(requete.url);
  if (url.origin !== self.location.origin) return;

  // Une navigation hors ligne doit rouvrir l'application, pas une page d'erreur.
  if (requete.mode === 'navigate') {
    event.respondWith((async () => {
      const cache = await caches.open(CACHE);
      try {
        const reponse = await fetch(requete);
        cache.put('index.html', reponse.clone());
        return reponse;
      } catch (e) {
        return (await cache.match('index.html')) || Response.error();
      }
    })());
    return;
  }

  event.respondWith((async () => {
    const cache = await caches.open(CACHE);
    const enCache = await cache.match(requete, {ignoreSearch: true});
    if (enCache) return enCache;

    const reponse = await fetch(requete);
    // Met en cache au vol ce qui n'etait pas pre-charge, notamment le moteur
    // de rendu : apres la premiere ouverture, tout est disponible hors ligne.
    if (reponse && reponse.status === 200 && reponse.type === 'basic') {
      cache.put(requete, reponse.clone());
    }
    return reponse;
  })());
});
