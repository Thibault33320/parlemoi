# Ressources tierces et licences — ParleMoi

Ce document accompagne le dépôt. Il distingue ce qui appartient à l'auteur de
ce qui provient de tiers, afin qu'aucune revendication ne porte sur des
éléments qui ne lui appartiennent pas.

Licences relevées localement dans les archives des bibliothèques utilisées,
le 6 août 2026.

## 1. Créations originales de l'auteur

Ces éléments sont l'œuvre de l'auteur et font l'objet du dépôt.

| Élément | Emplacement |
|---|---|
| Code source de l'application | `lib/` |
| Tests automatisés | `test/` |
| Outils de fabrication | `tool/` |
| Catalogue de 413 cartes et sa structure | `assets/catalogue.json` |
| 20 pictogrammes vectoriels | `assets/pictograms/` |
| Icônes de l'application | `web/icons/`, `web/favicon.png` |
| Cache hors connexion | généré par `tool/build_service_worker.py` |
| Mode d'emploi illustré | `doc/mode-emploi.html`, `web/mode-emploi.pdf` |
| Documentation technique | `README.md` |

La bibliothèque de 421 pictogrammes ayant servi à construire le catalogue a été
produite pour ce projet. Elle n'est pas issue d'un fonds tiers et ne reprend
aucun symbole Makaton.

## 2. Cadre applicatif

| Ressource | Éditeur | Licence |
|---|---|---|
| Flutter (SDK) | Google | BSD-3-Clause |
| Dart (SDK) | Google | BSD-3-Clause |

## 3. Bibliothèques Dart

Dépendances directes déclarées dans `pubspec.yaml`.

| Bibliothèque | Version | Licence |
|---|---|---|
| `flutter_tts` | 4.2.3 | MIT |
| `flutter_svg` | 2.2.0 | MIT |
| `shared_preferences` | 2.5.3 | BSD-3-Clause |
| `image_picker` | 1.2.3 | Apache-2.0 |
| `record` | 7.1.1 | BSD-3-Clause |
| `audioplayers` | 6.8.1 | MIT |
| `path_provider` | 2.1.6 | BSD-3-Clause |
| `flutter_lints` | 5.0.0 | BSD-3-Clause |

Ces bibliothèques ne sont pas redistribuées sous forme de source dans
l'archive : seule leur déclaration figure dans `pubspec.yaml` et
`pubspec.lock`.

## 4. Polices de caractères

Toutes deux sont embarquées dans l'application, sous forme réduite aux seuls
caractères utilisés. Leur licence autorise cette modification et cette
redistribution, à condition d'en conserver le texte.

| Police | Origine | Licence | Texte conservé |
|---|---|---|---|
| Noto Color Emoji | Google Fonts | SIL Open Font License 1.1 | `assets/fonts/OFL.txt` |
| Roboto | Google Fonts | SIL Open Font License 1.1 | `assets/fonts/OFL-Roboto.txt` |

Les fichiers réduits sont produits par `tool/build_emoji_font.py` et
`tool/build_text_font.py`. Ce sont des œuvres dérivées des polices d'origine :
aucun droit d'auteur n'est revendiqué sur les glyphes eux-mêmes.

## 5. Outils employés pour fabriquer les ressources

Ces outils ne sont pas redistribués avec l'application.

| Outil | Licence | Usage |
|---|---|---|
| fontTools | MIT | Réduction des polices |
| Pillow | MIT-CMU | Dessin des icônes |
| Chrome (mode sans interface) | — | Rendu du mode d'emploi en PDF |

## 6. Portée du dépôt

Le dépôt porte sur les créations listées en section 1. Il ne porte ni sur le
cadre applicatif Flutter, ni sur les bibliothèques tierces, ni sur les polices
de caractères, qui restent la propriété de leurs auteurs respectifs sous les
licences indiquées.
