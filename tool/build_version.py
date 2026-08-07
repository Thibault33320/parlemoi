#!/usr/bin/env python3
"""Recopie le numero de version du pubspec dans le code Dart.

Sans cela, l'application n'a aucun moyen d'afficher sa propre version, et un
parent ne peut pas verifier qu'une mise a jour a bien ete prise en compte.

Le fichier produit est versionne. Un test verifie qu'il correspond toujours au
pubspec : oublier de le regenerer fait echouer la suite de tests plutot que de
laisser un numero faux s'afficher.

Usage   : python3 tool/build_version.py
Produit : lib/version.dart
"""

import pathlib
import re
import sys


MODELE = '''// Fichier produit par tool/build_version.py — ne pas modifier a la main.
//
// Relancer `python3 tool/build_version.py` apres avoir change la version dans
// pubspec.yaml. Un test echoue si les deux divergent.

/// Version affichee dans l'espace parents, telle qu'elle figure au pubspec.
const appVersion = '{version}';

/// Numero de construction, qui augmente a chaque publication.
const appBuildNumber = '{build}';
'''


def lire_version(racine):
    pubspec = (racine / "pubspec.yaml").read_text(encoding="utf-8")
    trouve = re.search(r"^version:\s*([\d.]+)\+(\d+)\s*$", pubspec, re.M)
    if not trouve:
        sys.exit("Version introuvable dans pubspec.yaml (format attendu : 1.2.3+4)")
    return trouve.group(1), trouve.group(2)


def main():
    racine = pathlib.Path(__file__).resolve().parent.parent
    version, build = lire_version(racine)

    cible = racine / "lib" / "version.dart"
    cible.write_text(MODELE.format(version=version, build=build), encoding="utf-8")

    print(f"{cible.relative_to(racine)} — version {version}+{build}")


if __name__ == "__main__":
    main()
