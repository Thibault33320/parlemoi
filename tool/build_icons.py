#!/usr/bin/env python3
"""Dessine l'icone de l'application.

Les icones livrees etaient encore le logo Flutter par defaut. Or c'est par
l'icone que Raphael reconnait l'application sur l'ecran d'accueil : elle doit
etre nette, coloree, et ne ressembler a rien d'autre.

Motif : une bulle de parole blanche sur fond bleu, contenant trois pastilles
qui reprennent les couleurs des cartes.

Prerequis : pip install pillow
Usage     : python3 tool/build_icons.py
Produit   : web/icons/*.png, web/favicon.png
"""

import pathlib

from PIL import Image, ImageDraw

BLEU = (74, 144, 226, 255)
BLANC = (255, 255, 255, 255)
PASTILLES = [
    (255, 179, 0, 255),    # jaune des favoris
    (217, 52, 52, 255),    # rouge de l'urgence
    (46, 125, 50, 255),    # vert de la voix enregistree
]

# Un icone « maskable » peut etre rogne en cercle par le systeme : le motif
# doit tenir dans les 80 % centraux pour ne pas se faire couper.
MARGE_MASKABLE = 0.14
MARGE_NORMALE = 0.0


def dessiner(taille, marge_relative, coins_arrondis):
    # Dessine en quadruple resolution puis reduit : les bords obliques de la
    # bulle seraient crenetes autrement.
    echelle = 4
    grand = taille * echelle
    image = Image.new("RGBA", (grand, grand), (0, 0, 0, 0))
    dessin = ImageDraw.Draw(image)

    if coins_arrondis:
        dessin.rounded_rectangle(
            [0, 0, grand - 1, grand - 1], radius=int(grand * 0.22), fill=BLEU
        )
    else:
        dessin.rectangle([0, 0, grand - 1, grand - 1], fill=BLEU)

    marge = grand * marge_relative
    zone = grand - 2 * marge

    # Corps de la bulle.
    bulle_l = marge + zone * 0.13
    bulle_h = marge + zone * 0.20
    bulle_r = marge + zone * 0.87
    bulle_b = marge + zone * 0.66
    dessin.rounded_rectangle(
        [bulle_l, bulle_h, bulle_r, bulle_b],
        radius=int(zone * 0.16),
        fill=BLANC,
    )

    # Pointe de la bulle, vers le bas a gauche.
    pointe = zone * 0.13
    dessin.polygon(
        [
            (marge + zone * 0.30, bulle_b - 2),
            (marge + zone * 0.30 + pointe, bulle_b - 2),
            (marge + zone * 0.27, bulle_b + pointe),
        ],
        fill=BLANC,
    )

    # Trois pastilles : les cartes que l'on touche pour parler.
    rayon = zone * 0.072
    centre_y = (bulle_h + bulle_b) / 2
    for index, couleur in enumerate(PASTILLES):
        centre_x = marge + zone * (0.30 + index * 0.20)
        dessin.ellipse(
            [centre_x - rayon, centre_y - rayon, centre_x + rayon, centre_y + rayon],
            fill=couleur,
        )

    return image.resize((taille, taille), Image.LANCZOS)


def main():
    racine = pathlib.Path(__file__).resolve().parent.parent
    icones = racine / "web" / "icons"
    icones.mkdir(parents=True, exist_ok=True)

    sorties = [
        (icones / "Icon-192.png", 192, MARGE_NORMALE, True),
        (icones / "Icon-512.png", 512, MARGE_NORMALE, True),
        (icones / "Icon-maskable-192.png", 192, MARGE_MASKABLE, False),
        (icones / "Icon-maskable-512.png", 512, MARGE_MASKABLE, False),
        (racine / "web" / "favicon.png", 64, MARGE_NORMALE, True),
    ]

    for chemin, taille, marge, arrondi in sorties:
        dessiner(taille, marge, arrondi).save(chemin, "PNG", optimize=True)
        print(f"  {chemin.relative_to(racine)} — {taille}x{taille}")

    print(f"{len(sorties)} icones ecrites")


if __name__ == "__main__":
    main()
