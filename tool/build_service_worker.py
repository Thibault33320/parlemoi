#!/usr/bin/env python3
"""Produit le cache hors ligne de la version web.

Flutter 3.44 ne livre plus qu'un service worker factice qui se desinscrit
lui-meme : sans ce script, l'application ne s'ouvre pas sans reseau. Or
Raphaël en a justement besoin au parc, en voiture, a l'ecole.

Deux niveaux :
  - une liste courte pre-chargee des l'installation (coquille et pictogrammes,
    environ 4 Mo) ;
  - une mise en cache au vol de tout le reste, dont le moteur de rendu, qui
    pese 7 Mo et dont le navigateur ne telecharge qu'une variante sur quatre.

A lancer apres `flutter build web`.
Usage : python3 tool/build_service_worker.py [dossier_build]
"""

import hashlib
import json
import pathlib
import sys

# Jamais demande par l'application au demarrage : les inclure gonflerait
# l'installation de plusieurs megaoctets pour rien.
EXCLUSIONS = {
    "flutter_service_worker.js",
    "sw.js",
    ".last_build_id",
    "assets/NOTICES",
    # Le mode d'emploi se telecharge, il n'a pas a peser 500 Ko dans le cache
    # de chaque telephone.
    "mode-emploi.pdf",
}
EXTENSIONS_EXCLUES = {".symbols", ".map"}

# Le navigateur ne charge qu'une variante du moteur de rendu selon la
# plateforme. On les laisse toutes au cache au vol plutot que d'en imposer
# une au telechargement initial.
PREFIXES_EXCLUS = ("canvaskit/",)


def a_precharger(chemin_relatif, fichier):
    if chemin_relatif in EXCLUSIONS:
        return False
    if fichier.suffix in EXTENSIONS_EXCLUES:
        return False
    return not chemin_relatif.startswith(PREFIXES_EXCLUS)


def main():
    racine = pathlib.Path(__file__).resolve().parent.parent
    build = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else racine / "build" / "web"

    if not (build / "index.html").exists():
        sys.exit(f"Aucun build web dans {build}. Lancez d'abord `flutter build web`.")

    ressources = []
    empreinte = hashlib.sha256()

    for fichier in sorted(build.rglob("*")):
        if not fichier.is_file():
            continue
        relatif = fichier.relative_to(build).as_posix()
        if not a_precharger(relatif, fichier):
            continue
        ressources.append(relatif)
        empreinte.update(relatif.encode())
        empreinte.update(fichier.read_bytes())

    version = empreinte.hexdigest()[:12]
    (build / "sw.js").write_text(
        MODELE.replace("__VERSION__", version).replace(
            "__RESSOURCES__", json.dumps(ressources, indent=2)
        ),
        encoding="utf-8",
    )

    poids = sum((build / r).stat().st_size for r in ressources) / 1_048_576
    print(f"sw.js ecrit — version {version}")
    print(f"  {len(ressources)} fichiers pre-charges ({poids:.1f} Mo)")
    print("  le moteur de rendu sera mis en cache au premier affichage")


MODELE = r"""'use strict';

// Fichier produit par tool/build_service_worker.py — ne pas modifier a la main.

const VERSION = '__VERSION__';
const CACHE = 'parlemoi-' + VERSION;
const RESSOURCES = __RESSOURCES__;

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
"""


if __name__ == "__main__":
    main()
