#!/usr/bin/env python3
"""Embarque la police de texte, reduite a l'alphabet francais.

CanvasKit n'a acces a aucune police systeme : sur le web il va chercher Roboto
chez Google a chaque ouverture. Hors connexion la requete echoue et les libelles
des cartes risquent de ne pas s'afficher — sur un appareil neuf, Raphael se
retrouverait devant des cartes sans texte.

La police source est variable : on en extrait trois graisses fixes, car Flutter
associe de maniere fiable `fontWeight` a une graisse declaree dans le pubspec,
alors qu'un axe variable demanderait un `FontVariation` sur chaque style.

Prerequis : pip install fonttools brotli
Usage     : python3 tool/build_text_font.py "<Roboto[wdth,wght].ttf>"
Produit   : assets/fonts/Roboto-{Regular,Bold,Black}.ttf

Police source : https://github.com/google/fonts/tree/main/ofl/roboto
(SIL Open Font License 1.1). La licence doit rester dans assets/fonts/.
"""

import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

# Sous-ensemble « latin » de Google Fonts : couvre le francais accentue, la
# ponctuation courante, l'euro et les symboles usuels. Un parent qui saisit une
# carte personnalisee ne doit pas tomber sur un carre vide.
UNICODES = (
    "U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,"
    "U+0300-036F,U+0192,U+2000-206F,U+2074,U+20AC,U+2122,U+2191,U+2193,"
    "U+2212,U+2215,U+FEFF,U+FFFD"
)

GRAISSES = [("Regular", 400), ("Bold", 700), ("Black", 900)]


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)

    source = pathlib.Path(sys.argv[1])
    racine = pathlib.Path(__file__).resolve().parent.parent
    dossier = racine / "assets" / "fonts"
    dossier.mkdir(parents=True, exist_ok=True)

    total = 0
    for nom, poids in GRAISSES:
        variable = TTFont(source)
        fixe = instancer.instantiateVariableFont(
            variable, {"wght": poids, "wdth": 100}, inplace=True
        )

        intermediaire = dossier / f".Roboto-{nom}-complet.ttf"
        fixe.save(intermediaire)

        cible = dossier / f"Roboto-{nom}.ttf"
        subset.main([
            str(intermediaire),
            f"--unicodes={UNICODES}",
            f"--output-file={cible}",
            "--layout-features=*",
            "--drop-tables+=DSIG",
        ])
        intermediaire.unlink()

        poids_ko = cible.stat().st_size / 1024
        total += poids_ko
        print(f"  Roboto-{nom:8s} (wght {poids}) — {poids_ko:.0f} Ko")

    print(f"{len(GRAISSES)} graisses ecrites, {total:.0f} Ko au total")


if __name__ == "__main__":
    main()
