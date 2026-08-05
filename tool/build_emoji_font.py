#!/usr/bin/env python3
"""Reduit Noto Color Emoji aux seuls emoji utilises par le catalogue.

Sans police embarquee, Flutter Web va chercher les emoji couleur sur un CDN
Google : hors connexion, Raphael ne verrait que des carres vides a la place de
393 pictogrammes. La police complete pese 4,8 Mo, ce qui est excessif pour un
telephone ; ce script n'en garde que ce dont l'application se sert.

Prerequis : pip install fonttools brotli
Usage     : python3 tool/build_emoji_font.py <Noto-COLRv1.ttf>
Produit   : assets/fonts/NotoColorEmoji.ttf

Police source : https://github.com/googlefonts/noto-emoji (SIL Open Font
License 1.1). La licence doit rester dans assets/fonts/OFL.txt.
"""

import json
import pathlib
import sys

from fontTools import subset
from fontTools.ttLib import TTFont


def verifier_ligatures(police):
    """Echoue si la police produite ne sait plus composer les emoji.

    Une police amputee de ses ligatures passe inapercue a la compilation et
    ne se voit qu'a l'ecran, carte par carte.
    """
    table = TTFont(police)["GSUB"].table
    ligatures = sum(
        sum(len(v) for v in st.ligatures.values())
        for lookup in table.LookupList.Lookup
        for st in lookup.SubTable
        if getattr(st, "ligatures", None)
    )
    if ligatures == 0:
        sys.exit(
            "Aucune ligature conservee : les emoji composes se decomposeraient "
            "a l'affichage. Verifiez l'option --layout-features."
        )
    print(f"{ligatures} ligatures conservees")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)

    source = pathlib.Path(sys.argv[1])
    racine = pathlib.Path(__file__).resolve().parent.parent
    catalogue = json.loads(
        (racine / "assets" / "catalogue.json").read_text(encoding="utf-8")
    )

    # Les emoji des cartes et ceux des onglets de categories.
    utilises = {carte["emoji"] for carte in catalogue["cartes"]}
    utilises |= {categorie["emoji"] for categorie in catalogue["categories"]}

    # Quelques emoji proposes a la creation d'une carte personnalisee mais
    # absents du catalogue : sans eux, le parent choisirait un carre vide.
    utilises |= set(
        "😀😢😡😨🤕🍽️🥤🛏️🚽🧸🎵📺🚗🏫🌳🐶🛁👕💊🤗"
        "👋❤️✅❌⏸️🆘📞🧩⚽🍫"
    )

    texte = "".join(sorted(utilises))
    cible = racine / "assets" / "fonts" / "NotoColorEmoji.ttf"
    cible.parent.mkdir(parents=True, exist_ok=True)

    subset.main([
        str(source),
        f"--text={texte}",
        f"--output-file={cible}",
        # Indispensable. Les emoji composes sont assembles par la table `ccmp` :
        # sans elle, « 👩‍🏫 » s'affiche en « femme + ecole » et « 1️⃣ » en simple
        # chiffre. La syntaxe `+ccmp` ne suffit pas, il faut tout conserver.
        "--layout-features=*",
        "--notdef-outline",
        "--recalc-bounds",
        "--drop-tables+=DSIG",
    ])

    verifier_ligatures(cible)

    poids_source = source.stat().st_size / 1_048_576
    poids_cible = cible.stat().st_size / 1_048_576
    print(f"{len(utilises)} emoji conserves")
    print(f"{poids_source:.1f} Mo -> {poids_cible:.2f} Mo "
          f"({cible.relative_to(racine)})")


if __name__ == "__main__":
    main()
