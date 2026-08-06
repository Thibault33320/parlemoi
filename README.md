# ParleMoi

Application de communication alternative et augmentée (CAA) pour Raphaël,
9 ans, autiste avec SYNGAP1, non verbal.

Raphaël ne lit pas seul mais reconnaît les images. Il touche une carte,
l'application prononce la phrase à sa place.

**En ligne : https://thibault33320.github.io/parlemoi/**

**Mode d'emploi à imprimer ou à envoyer :
[mode-emploi.pdf](https://thibault33320.github.io/parlemoi/mode-emploi.pdf)**
— 9 pages illustrées, destinées aux parents et aux accompagnants. Source :
[`doc/mode-emploi.html`](doc/mode-emploi.html), rendu en PDF par Chrome
(`--headless --print-to-pdf`).

## Installer sur iPhone ou Android

Aucun compte, aucun magasin d'applications, aucun câble.

1. Ouvrir **https://thibault33320.github.io/parlemoi/** — sur iPhone avec
   **Safari** (Chrome iOS ne sait pas installer), sur Android avec Chrome.
2. iPhone : bouton **Partager** (le carré avec la flèche) → **Sur l'écran
   d'accueil**. Android : menu **⋮** → **Installer l'application**.
3. L'icône ParleMoi apparaît sur l'écran d'accueil. L'application s'ouvre en
   plein écran, sans barre de navigateur.

**Elle fonctionne ensuite sans connexion** : moteur de rendu, polices,
pictogrammes et catalogue sont mis en cache au premier lancement. Il faut
simplement l'avoir ouverte une fois avec du réseau.

## Ce que fait l'application

### Côté enfant

- **Une carte par écran.** On glisse vers le haut pour passer à la suivante,
  comme dans les Reels — le geste que Raphaël maîtrise déjà. Un repère
  « 3 / 12 » et des chevrons indiquent qu'il reste des cartes.
- Toute la surface de la carte déclenche la parole — pas de petit bouton à viser.
- Retour visuel pendant que la carte parle (la carte grossit et s'entoure).
- Bouton **URGENCE** permanent : deux touchers maximum pour dire « j'ai mal ».
- Catégories en bandeau, favoris en premier.
- Fonctionne sans connexion.
- Aucun réglage n'est modifiable depuis l'écran de Raphaël.

Le parent peut basculer en mode grille (2 ou 3 colonnes) pour proposer un choix
entre plusieurs cartes visibles en même temps.

### Côté parent

À la première ouverture, un écran de bienvenue demande le **prénom de
l'enfant** et un **code parents** — les deux seules choses que l'application ne
peut pas deviner. Tout le reste est déjà configuré.

L'espace parents s'ouvre ensuite par un **appui long** sur le cadenas, puis ce
code. Il se change dans l'onglet Affichage.

- **Cartes** — activer/désactiver parmi 413 cartes, favoris, urgences,
  réordonner, créer ses propres cartes.
- **Photo et voix** — remplacer le pictogramme par une photo (appareil ou
  galerie) et enregistrer sa propre voix à la place de la synthèse. Disponible
  sur n'importe quelle carte, pas seulement les cartes créées.
- **Voix** — choix de la voix française du système, vitesse, hauteur, volume.
- **Affichage** — colonnes, masquage des textes, code PIN.
- **Sauvegarde** — export/import par presse-papier, réinitialisation.

## Le catalogue

413 cartes réparties en 17 catégories, dans `assets/catalogue.json`.

39 cartes seulement sont actives au premier lancement : afficher les 413 d'un
coup rendrait l'application inutilisable. Le parent en active davantage au
rythme de Raphaël.

Le catalogue est fabriqué à partir de la bibliothèque de 421 pictogrammes
fournie séparément :

```bash
python3 tool/build_catalogue.py <dossier_bibliotheque>
```

Le script écarte les doublons et **conserve les 20 cartes historiques avec leur
identifiant et leur dessin vectoriel d'origine**. C'est délibéré : ces
identifiants sont déjà enregistrés dans les favoris sur l'appareil de Raphaël,
et il a appris à reconnaître ces dessins-là à ces positions-là.

> Les pictogrammes sont une création originale pour ce projet. Ce ne sont **pas**
> des symboles Makaton officiels et ils ne doivent pas être présentés comme tels.

## Développer

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome     # web
flutter run               # appareil connecté
```

### Construire

```bash
# Web — les deux options sont indispensables :
#   --base-href : sinon tous les assets tombent en 404
#   --no-web-resources-cdn : sinon le moteur de rendu (7 Mo) est téléchargé
#     chez Google, et l'application ne démarre pas du tout hors connexion
flutter build web --release --base-href /parlemoi/ --no-web-resources-cdn
python3 tool/build_service_worker.py      # cache hors ligne

# Android — nécessite le SDK Android installé localement
flutter build apk --release
```

**Sans SDK Android installé**, chaque push sur `main` en construit un :
onglet [Actions](https://github.com/Thibault33320/parlemoi/actions) → dernier
run → section « Artifacts » → `parlemoi-apk-…`. Décompresser le `.zip`, envoyer
l'`.apk` sur le téléphone et l'ouvrir (autoriser l'installation depuis cette
source). Conservé 30 jours.

### Publier

Automatique. Chaque push sur `main` déclenche
[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) : analyse, tests,
build web, puis publication. Aucune manipulation manuelle.

La publication passe par `actions/deploy-pages`, le mécanisme officiel de
GitHub, et non par un envoi sur une branche `gh-pages`. Cette seconde méthode
déclenchait un workflow « pages build and deployment » distinct, dont l'étape
de déploiement a fini par échouer de façon répétée sans journal consultable
sans authentification. Avec un seul mécanisme, un échec de publication est
visible dans ce workflow.

## Structure

```
lib/
  main.dart                       démarrage et écran d'erreur de secours
  models/
    communication_card.dart       carte, catégorie
    settings.dart                 réglages, photos et voix par carte
  services/
    catalogue_service.dart        chargement du catalogue embarqué
    storage_service.dart          persistance locale, export/import, migration v1
    tts_service.dart              synthèse vocale française
    media_service.dart            appareil photo, micro, lecture audio
  state/
    app_controller.dart           état partagé
  screens/
    home_screen.dart              écran de Raphaël
    parent_screen.dart            espace parents
  widgets/
    communication_tile.dart       carte tactile
    media_editor.dart             encarts photo et enregistrement
tool/
  build_catalogue.py              fabrication de assets/catalogue.json
```

## Décisions à connaître

**Les emoji sont rendus par Flutter, pas par les SVG.** Les pictogrammes de la
bibliothèque sont des emoji dessinés dans des balises `<text>` SVG. `flutter_svg`
les rendrait via des polices couleur système non garanties — Raphaël verrait des
cadres vides. L'emoji est donc affiché comme du texte Flutter.

**La police emoji est embarquée.** Sans elle, Flutter Web télécharge les emoji
couleur depuis un CDN Google : hors connexion, 393 cartes deviendraient des
carrés vides. `tool/build_emoji_font.py` réduit Noto Color Emoji aux seuls
emoji utilisés — 4,8 Mo → 462 Ko :

```bash
pip install fonttools brotli
python3 tool/build_emoji_font.py <Noto-COLRv1.ttf>
```

Le script **échoue volontairement** si le sous-ensemble perd ses ligatures : sans
la table `ccmp`, « 👩‍🏫 » s'afficherait en « femme + école » et « 1️⃣ » en simple
chiffre. Ce défaut est invisible à la compilation et ne se voit qu'à l'écran.

**Photos et voix sont stockées en base64 dans les réglages.** Une sauvegarde
exportée emporte ainsi les photos et les enregistrements, et se réinstalle telle
quelle sur un autre appareil. Les photos sont réduites à 640 px et les
enregistrements plafonnés à 10 secondes pour que les sauvegardes restent légères.

**Rien n'est chargé depuis Internet au démarrage.** Flutter Web va par défaut
chercher son moteur de rendu et ses polices chez Google : hors connexion,
l'application ne s'ouvre pas du tout. Trois mesures ensemble corrigent cela —
`--no-web-resources-cdn`, les polices embarquées (Roboto et Noto Color Emoji,
réduites au strict nécessaire), et le service worker de
[`tool/build_service_worker.py`](tool/build_service_worker.py). Flutter 3.44 ne
livre plus qu'un service worker factice qui se désinscrit lui-même ; le nôtre
pré-charge la coquille et met le reste en cache au premier affichage.

Vérification : charger la page, couper le serveur, recharger. L'application doit
s'ouvrir normalement, texte et pictogrammes compris.

**L'ordre des cartes est explicite et stable.** Raphaël retrouve une carte par
mémoire du geste, sans la lire. Réordonner une catégorie ne déplace aucune carte
des autres catégories.

**Un geste, une carte.** Le défilement est piloté à la main
([`card_pager.dart`](lib/widgets/card_pager.dart)) au lieu d'être laissé à
l'inertie d'un `PageView`. Avec la physique par défaut, une impulsion vive
faisait défiler quatre cartes d'un coup : Raphaël se retrouvait ailleurs et
perdait ce qu'il voulait dire. La carte suit le doigt, mais ne peut jamais
s'éloigner de plus d'une position.

**Le PIN n'est pas une sécurité forte.** Il empêche une modification
accidentelle, rien de plus.

## Limites connues

- **iOS** : nécessite Xcode complet (App Store). Avec seulement les Command Line
  Tools, `flutter run` échoue sur `xcrun: error: unable to find utility "xcdevice"`.
- **Pas de synchronisation** entre appareils. Les données restent sur l'appareil ;
  l'export/import sert à les transporter.
- **Enregistrement vocal sur le web** : dépend du navigateur. Fiable sur
  Chrome et Safari récents, à vérifier ailleurs.

---

ParleMoi aide à communiquer mais ne remplace pas l'évaluation d'un orthophoniste,
d'un ergothérapeute ou d'un professionnel de santé.
