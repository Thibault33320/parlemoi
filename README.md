# ParleMoi

Application de communication alternative et augmentée (CAA) pour Raphaël,
9 ans, autiste avec SYNGAP1, non verbal.

Raphaël ne lit pas seul mais reconnaît les images. Il touche une carte,
l'application prononce la phrase à sa place.

**En ligne : https://thibault33320.github.io/parlemoi/**

## Ce que fait l'application

### Côté enfant

- Grandes cartes tactiles, 2 ou 3 colonnes au choix du parent.
- Toute la surface de la carte déclenche la parole — pas de petit bouton à viser.
- Retour visuel pendant que la carte parle (la carte grossit et s'entoure).
- Bouton **URGENCE** permanent : deux touchers maximum pour dire « j'ai mal ».
- Catégories en bandeau, favoris en premier.
- Fonctionne sans connexion.
- Aucun réglage n'est modifiable depuis l'écran de Raphaël.

### Côté parent

L'espace parents s'ouvre par un **appui long** sur le cadenas, puis un code
PIN. Le code par défaut est `2580` et se change dans l'onglet Affichage.

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
# Web — le base-href est indispensable, sinon les assets tombent en 404
flutter build web --release --base-href /parlemoi/

# Android
flutter build apk --release
```

### Publier

Automatique. Chaque push sur `main` déclenche
[`.github/workflows/deploy.yml`](.github/workflows/deploy.yml) : analyse, tests,
build web, puis publication sur la branche `gh-pages`. Aucune manipulation
manuelle.

La branche `gh-pages` ne contient que le site construit et est réécrite à
chaque publication — n'y committez rien à la main.

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

**L'ordre des cartes est explicite et stable.** Raphaël retrouve une carte par
mémoire du geste, sans la lire. Réordonner une catégorie ne déplace aucune carte
des autres catégories.

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
