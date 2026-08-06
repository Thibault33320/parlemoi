#!/usr/bin/env python3
"""Prepare le dossier de depot INPI (enveloppe e-Soleau).

Produit un inventaire horodate de tous les fichiers du projet avec leur
empreinte SHA-256, puis une archive unique a deposer. L'empreinte globale
permet de prouver, apres coup, que l'archive deposee est bien celle-ci et
qu'elle n'a pas ete modifiee.

Seuls les fichiers suivis par Git sont pris : les artefacts de compilation
n'ont rien a faire dans un depot et gonfleraient l'archive.

Usage   : python3 tool/build_inpi_dossier.py
Produit : inpi/02_INVENTAIRE_SOURCES.md
          inpi/parlemoi-e-soleau-<AAAA-MM-JJ>.zip
"""

import datetime
import hashlib
import pathlib
import subprocess
import sys
import zipfile

# Le dossier de sortie ne s'inventorie pas lui-meme.
EXCLUS = ("inpi/",)


def fichiers_suivis(racine):
    sortie = subprocess.run(
        ["git", "ls-files"],
        cwd=racine, capture_output=True, text=True, check=True,
    ).stdout
    return sorted(
        chemin for chemin in sortie.splitlines()
        if chemin and not chemin.startswith(EXCLUS)
    )


def empreinte(chemin):
    condensat = hashlib.sha256()
    with open(chemin, "rb") as fichier:
        for bloc in iter(lambda: fichier.read(65536), b""):
            condensat.update(bloc)
    return condensat.hexdigest()


def etat_git(racine):
    def git(*args):
        return subprocess.run(
            ["git", *args], cwd=racine, capture_output=True, text=True
        ).stdout.strip()

    return {
        "commit": git("rev-parse", "HEAD"),
        "date_commit": git("log", "-1", "--format=%cI"),
        "propre": git("status", "--porcelain") == "",
    }


def main():
    racine = pathlib.Path(__file__).resolve().parent.parent
    sortie = racine / "inpi"
    sortie.mkdir(exist_ok=True)

    aujourdhui = datetime.date.today().isoformat()
    horodatage = datetime.datetime.now().astimezone().isoformat(timespec="seconds")
    git = etat_git(racine)

    if not git["propre"]:
        print("ATTENTION : des modifications ne sont pas enregistrees dans Git.")
        print("L'inventaire decrira des fichiers absents de l'historique.\n")

    chemins = fichiers_suivis(racine)
    lignes, total = [], 0
    global_hash = hashlib.sha256()

    for chemin in chemins:
        absolu = racine / chemin
        if not absolu.is_file():
            continue
        condensat = empreinte(absolu)
        taille = absolu.stat().st_size
        total += taille
        lignes.append(f"| `{chemin}` | {taille} | `{condensat}` |")
        # L'empreinte globale couvre les noms ET les contenus : renommer un
        # fichier la fait changer, comme le modifier.
        global_hash.update(chemin.encode())
        global_hash.update(bytes.fromhex(condensat))

    empreinte_globale = global_hash.hexdigest()

    inventaire = sortie / "02_INVENTAIRE_SOURCES.md"
    inventaire.write_text(
        MODELE_INVENTAIRE.format(
            date=aujourdhui,
            horodatage=horodatage,
            commit=git["commit"],
            date_commit=git["date_commit"],
            nombre=len(lignes),
            taille=f"{total / 1024:.0f} Ko",
            empreinte=empreinte_globale,
            tableau="\n".join(lignes),
        ),
        encoding="utf-8",
    )

    archive = sortie / f"parlemoi-e-soleau-{aujourdhui}.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED) as zip_:
        for chemin in chemins:
            absolu = racine / chemin
            if absolu.is_file():
                zip_.write(absolu, f"parlemoi/{chemin}")
        for document in sorted(sortie.glob("*.md")):
            zip_.write(document, f"parlemoi/inpi/{document.name}")

    poids_archive = archive.stat().st_size / 1_048_576
    print(f"Dossier INPI du {aujourdhui}\n")
    print(f"  {len(lignes)} fichiers inventories ({total / 1024:.0f} Ko)")
    print(f"  Empreinte globale SHA-256 :\n    {empreinte_globale}")
    print(f"\n  {inventaire.relative_to(racine)}")
    print(f"  {archive.relative_to(racine)} — {poids_archive:.2f} Mo")

    # Au-dela, l'e-Soleau coute 10 EUR de plus par tranche de 50 Mo.
    if poids_archive > 50:
        print("\n  ATTENTION : au-dela de 50 Mo, le tarif e-Soleau augmente.")
    else:
        print("\n  Sous les 50 Mo : tarif e-Soleau de base.")


MODELE_INVENTAIRE = """# Inventaire des sources — ParleMoi

Document produit automatiquement par `tool/build_inpi_dossier.py`.
Ne pas modifier a la main : toute retouche invaliderait les empreintes.

| | |
|---|---|
| **Date de l'inventaire** | {date} |
| **Horodatage complet** | {horodatage} |
| **Revision Git** | `{commit}` |
| **Date de cette revision** | {date_commit} |
| **Nombre de fichiers** | {nombre} |
| **Taille totale** | {taille} |

## Empreinte globale

```
{empreinte}
```

Cette empreinte SHA-256 couvre l'ensemble des fichiers listes ci-dessous,
noms compris. Elle suffit a demontrer qu'une copie ulterieure du projet est,
ou n'est pas, identique a celle deposee.

## Detail des fichiers

| Fichier | Octets | Empreinte SHA-256 |
|---|---|---|
{tableau}
"""


if __name__ == "__main__":
    sys.exit(main())
