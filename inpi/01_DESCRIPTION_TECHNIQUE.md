# ParleMoi — description technique de l'œuvre

Document destiné à accompagner un dépôt e-Soleau à l'INPI.

| | |
|---|---|
| **Titre** | ParleMoi |
| **Nature** | Logiciel — application de communication alternative et augmentée (CAA) |
| **Auteur** | Thibault Le Moine |
| **Plateformes** | Android, iOS, Web (application installable), macOS, Windows, Linux |
| **Langage** | Dart — cadre applicatif Flutter |
| **Adresse publique** | https://thibault33320.github.io/parlemoi/ |
| **Dépôt de code** | github.com/Thibault33320/parlemoi |

## 1. Objet

ParleMoi permet à un enfant non verbal de s'exprimer en touchant des cartes
illustrées. Chaque carte prononce une phrase française à sa place.

L'application a été conçue pour un enfant de 9 ans, autiste avec syndrome
SYNGAP1, non verbal, qui ne lit pas seul mais reconnaît les images et maîtrise
le défilement vertical tactile. Elle est utilisable par tout enfant présentant
des besoins de communication comparables : le prénom affiché et l'intégralité
du vocabulaire sont paramétrables.

## 2. Fonctionnalités

### Interface de l'enfant

- Un pictogramme par écran, occupant toute la surface disponible.
- Passage d'une carte à l'autre par glissement vertical du bas vers le haut.
- Toute la surface de la carte déclenche la parole.
- Retour visuel synchronisé pendant l'énoncé : agrandissement, contour coloré
  et animation de l'icône sonore.
- Bandeau de catégories, favoris présentés en premier.
- Accès permanent à un panneau d'urgence atteignable en deux touchers.
- Mode grille alternatif, à deux ou trois colonnes, pour présenter un choix.
- Aucun réglage n'est modifiable depuis cette interface.

### Interface parentale

Protégée par un code numérique choisi à la première ouverture, et accessible
par un appui long — un toucher simple n'ouvre pas la demande de code.

- Activation et désactivation individuelle de 413 cartes.
- Gestion des favoris, des cartes d'urgence et de l'ordre d'affichage.
- Création de cartes personnalisées.
- Remplacement du pictogramme de n'importe quelle carte par une photographie
  prise à l'appareil ou importée.
- Enregistrement de la voix d'un proche en substitution de la synthèse vocale,
  sur n'importe quelle carte.
- Sélection de la voix de synthèse française, du débit, de la hauteur et du
  volume.
- Export et import de la configuration complète, médias inclus.

## 3. Éléments originaux

Les choix suivants constituent l'apport propre de l'auteur et ne découlent
d'aucune contrainte technique.

**Catalogue fusionné à identifiants stables.** Le catalogue de 413 cartes
réparties en 17 catégories résulte d'une fusion raisonnée entre une
bibliothèque de 421 pictogrammes et un ensemble antérieur de 20 cartes. Les
règles de fusion — conservation des identifiants et des dessins antérieurs,
élimination des doublons par comparaison des phrases énoncées après
normalisation typographique — sont propres au projet et implémentées dans
`tool/build_catalogue.py`.

**Un geste, une carte.** Le défilement n'est pas confié à l'inertie du composant
standard, qui fait défiler plusieurs cartes sur un geste vif. Il est piloté
explicitement : la carte suit le doigt mais ne peut jamais s'éloigner de plus
d'une position du point de départ. Ce choix répond au constat qu'un enfant qui
se retrouve plusieurs cartes plus loin perd le fil de ce qu'il voulait dire.

**Priorité d'affichage et de restitution en trois niveaux.** Une carte affiche,
dans cet ordre, la photographie du parent, puis son dessin vectoriel, puis son
emoji. Elle restitue la voix enregistrée si elle existe, sinon la synthèse
vocale. Les médias ajoutés sont stockés séparément des cartes, ce qui permet de
personnaliser aussi les cartes fournies et non seulement celles créées.

**Sauvegarde portable intégrale.** Photographies et enregistrements sont
encodés dans la sauvegarde elle-même, ce qui permet de transférer une
configuration complète d'un appareil à un autre par simple copie de texte, sans
serveur ni compte.

**Stabilité des positions comme exigence de conception.** Réordonner une
catégorie ne déplace aucune carte des autres catégories. Cette contrainte
traverse le modèle de données : l'ordre est une liste explicite et non un tri
calculé.

**Autonomie hors connexion complète.** Le moteur de rendu, les polices de
caractères et l'ensemble des ressources sont embarqués et mis en cache par un
service worker écrit pour le projet. L'application démarre et fonctionne sans
aucun accès réseau, y compris à sa toute première utilisation après
installation.

## 4. Architecture

```
lib/
  main.dart                     démarrage, thème, aiguillage
  models/
    communication_card.dart     carte et catégorie
    settings.dart               réglages, médias par carte
  services/
    catalogue_service.dart      chargement du catalogue embarqué
    storage_service.dart        persistance, export/import, migrations
    tts_service.dart            synthèse vocale française
    media_service.dart          appareil photo, micro, lecture audio
  state/
    app_controller.dart         état partagé de l'application
  screens/
    setup_screen.dart           première ouverture
    home_screen.dart            interface de l'enfant
    parent_screen.dart          interface parentale
  widgets/
    card_pager.dart             défilement une carte par geste
    communication_tile.dart     carte tactile
    media_editor.dart           photographie et enregistrement
tool/
  build_catalogue.py            fabrication du catalogue
  build_emoji_font.py           réduction de la police d'emoji
  build_text_font.py            réduction de la police de texte
  build_service_worker.py       cache hors connexion
  build_icons.py                icônes de l'application
  build_inpi_dossier.py         inventaire et archive de dépôt
```

Le fonctionnement est couvert par 98 tests automatisés portant sur le
catalogue, la persistance, les migrations, la restitution vocale, les gestes,
la personnalisation et la première ouverture.

## 5. Ressources

**Créations originales du projet :** les 20 pictogrammes vectoriels dessinés
pour l'application, le catalogue et sa structure, les icônes de l'application,
l'intégralité du code source et le mode d'emploi.

**Ressources tierces**, sous licences libres permettant l'usage et la
redistribution, détaillées dans `03_LICENCES_TIERCES.md`. Aucune revendication
n'est portée sur ces éléments.

Les pictogrammes ne sont pas des symboles Makaton et ne sont présentés comme
tels à aucun endroit du logiciel ni de sa documentation.

## 6. Avertissement porté par le logiciel

ParleMoi aide à communiquer mais ne remplace pas l'évaluation d'un
orthophoniste, d'un ergothérapeute ou d'un professionnel de santé. Cette mention
figure dans le mode d'emploi. Le logiciel n'est pas présenté comme un
dispositif médical.
