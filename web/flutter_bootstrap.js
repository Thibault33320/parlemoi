{{flutter_js}}
{{flutter_build_config}}

// Volontairement sans `serviceWorkerSettings` : le service worker livré par
// Flutter 3.44 est un simple stub qui se désinscrit lui-même et ne met rien en
// cache. Le laisser s'enregistrer effacerait le nôtre à chaque ouverture, et
// l'application cesserait de fonctionner hors connexion.
_flutter.loader.load();

// Notre cache, produit par tool/build_service_worker.py.
// Sans lui, Raphaël ne peut pas ouvrir l'application au parc, dans la voiture,
// ou partout où le réseau manque — or c'est justement là qu'il en a besoin.
if ('serviceWorker' in navigator) {
  window.addEventListener('load', function () {
    navigator.serviceWorker.register('sw.js').catch(function (error) {
      // Un cache indisponible ne doit pas empêcher l'application de s'ouvrir.
      console.warn('Cache hors ligne indisponible :', error);
    });
  });
}
