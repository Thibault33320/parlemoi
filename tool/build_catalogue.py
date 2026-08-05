#!/usr/bin/env python3
"""Fusionne la bibliotheque de 421 pictogrammes avec les 20 cartes historiques.

Les 20 cartes d'origine gardent leur identifiant et leur dessin vectoriel :
Raphael les connait deja, changer leur apparence ou leur position lui ferait
perdre ses reperes. Les doublons correspondants de la bibliotheque sont
supprimes pour qu'un meme concept n'existe qu'une seule fois.

Usage : python3 tool/build_catalogue.py <dossier_bibliotheque>
Produit : assets/catalogue.json
"""

import json
import pathlib
import re
import sys
import unicodedata

# Les 20 cartes historiques. Leur `remplace` designe le pictogramme de la
# bibliotheque qui fait double emploi et doit donc etre retire.
CARTES_HISTORIQUES = [
    # id, libelle, phrase, categorie, niveau, urgence, remplace
    ("faim", "J'AI FAIM", "J'ai faim", "besoins", 1, False, "picto_021"),
    ("soif", "J'AI SOIF", "J'ai soif", "besoins", 1, False, "picto_022"),
    ("pipi", "JE VEUX FAIRE PIPI", "Je veux faire pipi", "besoins", 1, True, "picto_023"),
    ("popo", "JE VEUX FAIRE POPO", "Je veux faire popo", "besoins", 1, True, "picto_024"),
    ("dormir", "JE VEUX DORMIR", "Je veux dormir", "besoins", 1, False, "picto_025"),
    ("calin", "JE VEUX UN CÂLIN", "Je veux un câlin", "besoins", 1, False, "picto_040"),
    ("aide", "AIDE-MOI", "Aide-moi", "essentiels", 1, True, "picto_005"),
    ("mal", "J'AI MAL", "J'ai mal", "douleur", 1, True, "picto_061"),
    ("ventre", "J'AI MAL AU VENTRE", "J'ai mal au ventre", "douleur", 2, True, "picto_068"),
    ("tete", "J'AI MAL À LA TÊTE", "J'ai mal à la tête", "douleur", 2, True, "picto_064"),
    ("peur", "J'AI PEUR", "J'ai peur", "emotions", 1, True, "picto_044"),
    ("content", "JE SUIS CONTENT", "Je suis content", "emotions", 1, False, "picto_041"),
    ("triste", "JE SUIS TRISTE", "Je suis triste", "emotions", 1, False, "picto_042"),
    ("colere", "JE SUIS EN COLÈRE", "Je suis en colère", "emotions", 1, False, "picto_043"),
    ("parc", "JE VEUX ALLER AU PARC", "Je veux aller au parc", "lieux_transports", 1, False, "picto_296"),
    ("jouer", "JE VEUX JOUER", "Je veux jouer", "actions", 1, False, "picto_140"),
    ("tablette", "JE VEUX LA TABLETTE", "Je veux la tablette", "loisirs", 1, False, "picto_230"),
    ("maison", "JE VEUX RENTRER À LA MAISON", "Je veux rentrer à la maison", "maison", 1, False, "picto_216"),
    ("papa", "JE VEUX PAPA", "Je veux papa", "famille", 1, False, "picto_107"),
    ("maman", "JE VEUX MAMAN", "Je veux maman", "famille", 1, False, "picto_106"),
]

# Emoji de secours pour les cartes historiques, utilise si le SVG manque.
EMOJI_HISTORIQUE = {
    "faim": "🍽️", "soif": "🥤", "pipi": "🚽", "popo": "🚻", "dormir": "🛏️",
    "calin": "🤗", "aide": "🙋", "mal": "🤕", "ventre": "🤰", "tete": "🧠",
    "peur": "😨", "content": "😊", "triste": "😢", "colere": "😠", "parc": "🌳",
    "jouer": "🧩", "tablette": "📱", "maison": "🏠", "papa": "👨", "maman": "👩",
}

# Cartes actives a la premiere ouverture. Volontairement restreint : montrer
# 421 cartes d'un coup rendrait l'application inutilisable pour Raphael.
ACTIVES_PAR_DEFAUT = [
    "faim", "soif", "pipi", "popo", "dormir", "calin", "aide", "mal",
    "ventre", "tete", "peur", "content", "triste", "colere", "parc",
    "jouer", "tablette", "maison", "papa", "maman",
    "picto_001", "picto_002", "picto_003", "picto_004", "picto_006",
    "picto_007", "picto_008", "picto_009", "picto_010", "picto_011",
    "picto_012", "picto_013", "picto_014", "picto_015", "picto_016",
    "picto_017", "picto_018", "picto_019", "picto_020",
]

# Acces urgence : deux touchers maximum, jamais plus.
URGENCES_PAR_DEFAUT = [
    "mal", "aide", "pipi", "popo", "picto_062", "picto_353",
    "picto_352", "picto_370",
]

CATEGORIES = [
    ("essentiels", "Essentiels", "⭐", "FFFDF0E0"),
    ("besoins", "Besoins", "🍽️", "FFDDF2FF"),
    ("emotions", "Émotions", "😊", "FFFFE9F3"),
    ("douleur", "Douleur", "🤕", "FFFFDCDC"),
    ("securite_sante", "Sécurité", "🆘", "FFFFD9CC"),
    ("actions", "Actions", "🏃", "FFE2F5E5"),
    ("aliments", "Aliments", "🍎", "FFFFF1C7"),
    ("loisirs", "Loisirs", "🎨", "FFFFEED4"),
    ("ecole", "École", "🏫", "FFE0EBFF"),
    ("temps", "Temps", "🕐", "FFE7E1FF"),
    ("descriptions", "Descriptions", "🔎", "FFECECEC"),
    ("lieux_transports", "Lieux", "🌳", "FFE3F5D8"),
    ("animaux_nature", "Nature", "🐶", "FFD8F5E8"),
    ("sensoriel", "Sensoriel", "✋", "FFF3E1FF"),
    ("famille", "Famille", "👨‍👩‍👦", "FFFFE0EF"),
    ("hygiene", "Hygiène", "🪥", "FFDDF7F7"),
    ("maison", "Maison", "🏠", "FFFFE8D5"),
]


def normalise(texte):
    """Reduit une phrase a sa forme comparable, sans accents ni ponctuation."""
    decompose = unicodedata.normalize("NFD", texte.lower())
    sans_accents = "".join(c for c in decompose if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z]", "", sans_accents)


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)

    source = pathlib.Path(sys.argv[1])
    racine = pathlib.Path(__file__).resolve().parent.parent
    brut = json.loads((source / "catalogue.json").read_text(encoding="utf-8"))

    a_retirer = {ligne[6] for ligne in CARTES_HISTORIQUES}
    couleur_par_categorie = {c[0]: c[3] for c in CATEGORIES}

    cartes = []
    for id_carte, libelle, phrase, categorie, niveau, urgence, _ in CARTES_HISTORIQUES:
        svg = racine / "assets" / "pictograms" / f"{id_carte}.svg"
        cartes.append({
            "id": id_carte,
            "categorie": categorie,
            "libelle": libelle,
            "phrase": phrase,
            "emoji": EMOJI_HISTORIQUE[id_carte],
            "asset": f"assets/pictograms/{id_carte}.svg" if svg.exists() else None,
            "niveau": niveau,
            "urgence": urgence,
            "couleur": couleur_par_categorie[categorie],
        })

    connues = {normalise(c["phrase"]) for c in cartes}
    ignores_doublon = 0
    for picto in brut["pictograms"]:
        if picto["id"] in a_retirer:
            ignores_doublon += 1
            continue
        # Filet de securite : la bibliotheque contient quelques phrases repetees
        # d'une categorie a l'autre. Une phrase = une carte.
        cle = normalise(picto["speech"])
        if cle in connues:
            ignores_doublon += 1
            continue
        connues.add(cle)
        cartes.append({
            "id": picto["id"],
            "categorie": picto["category"],
            "libelle": picto["label"],
            "phrase": picto["speech"],
            "emoji": picto["icon"],
            "asset": None,
            "niveau": picto["level"],
            "urgence": picto["id"] in URGENCES_PAR_DEFAUT,
            "couleur": couleur_par_categorie[picto["category"]],
        })

    ids = {c["id"] for c in cartes}
    manquantes = [i for i in ACTIVES_PAR_DEFAUT + URGENCES_PAR_DEFAUT if i not in ids]
    if manquantes:
        sys.exit(f"Identifiants introuvables dans le catalogue : {manquantes}")

    sortie = {
        "version": 2,
        "langue": "fr-FR",
        "makatonOfficiel": False,
        "licence": brut["license"],
        "categories": [
            {"id": i, "nom": n, "emoji": e, "couleur": c} for i, n, e, c in CATEGORIES
        ],
        "activesParDefaut": ACTIVES_PAR_DEFAUT,
        "urgencesParDefaut": URGENCES_PAR_DEFAUT,
        "cartes": cartes,
    }

    cible = racine / "assets" / "catalogue.json"
    cible.write_text(
        json.dumps(sortie, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )

    avec_svg = sum(1 for c in cartes if c["asset"])
    print(f"{len(cartes)} cartes ecrites dans {cible.relative_to(racine)}")
    print(f"  dont {avec_svg} avec dessin vectoriel, {len(cartes) - avec_svg} en emoji")
    print(f"  {ignores_doublon} doublons ecartes")
    print(f"  {len(ACTIVES_PAR_DEFAUT)} cartes actives au premier lancement")


if __name__ == "__main__":
    main()
