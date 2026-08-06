# Dossier INPI — ParleMoi

Ce dossier contient tout ce qu'il faut pour deux démarches distinctes.

> Ces documents ne constituent pas un conseil juridique. Ils rassemblent des
> éléments vérifiables et signalent ce qui ne l'est pas.

## Ce qu'il y a dans ce dossier

| Fichier | À quoi il sert |
|---|---|
| `01_DESCRIPTION_TECHNIQUE.md` | Décrit l'œuvre, ses fonctions et ce qui en fait l'originalité |
| `02_INVENTAIRE_SOURCES.md` | Liste horodatée de tous les fichiers avec leur empreinte — **généré** |
| `03_LICENCES_TIERCES.md` | Sépare ce qui vous appartient de ce qui vient de tiers |
| `04_DOSSIER_MARQUE.md` | Classes, libellés, coût et risques du dépôt de marque |
| `parlemoi-e-soleau-<date>.zip` | L'archive à déposer — **générée** |

Régénérer les deux fichiers générés après toute modification du code :

```bash
python3 tool/build_inpi_dossier.py
```

## Démarche 1 — Enveloppe e-Soleau : dater le travail

**15 €**, jusqu'à 50 Mo, pour 5 ans, renouvelable jusqu'à 20 ans.

Le code est **déjà** protégé par le droit d'auteur, sans aucune formalité, dès
sa création. L'e-Soleau ne crée pas ce droit : il **prouve la date** à laquelle
le travail existait. C'est ce qui compte si quelqu'un revendique un jour la
paternité de l'application.

1. Créer un compte sur **https://procedures.inpi.fr**
2. Portail Soleau → *Déposer une e-Soleau*
3. Choisir **le dépôt avec conservation du fichier** par l'INPI — et non le
   simple calcul d'empreinte, qui vous laisserait la charge de conserver
   l'archive intacte pendant des années
4. Téléverser `parlemoi-e-soleau-<date>.zip`
5. Payer, puis **conserver le récépissé** : il porte l'empreinte numérique et
   la date, c'est lui qui fait preuve

À refaire lors d'une évolution majeure : l'enveloppe date une version, pas le
projet à perpétuité.

## Démarche 2 — Marque : protéger le nom

**190 € pour une classe, 230 € pour deux.** Protection 10 ans.

Voir `04_DOSSIER_MARQUE.md`. Deux points à retenir avant de payer :

- **La recherche d'antériorité est gratuite et n'a pas été faite.** La base de
  l'INPI bloque les consultations automatisées. À faire sur
  **https://data.inpi.fr**, onglet *Marques*.
- **« ParleMoi » est peu distinctif** pour une application qui fait parler.
  C'est le vrai risque de refus. Déposer la marque **avec le logo**
  (semi-figurative) plutôt que le mot seul réduit ce risque.

## Ordre conseillé

1. **Recherche d'antériorité** — gratuite, une demi-heure.
2. **e-Soleau** — 15 €, sans aléa, protège le travail lui-même.
3. **Marque** — seulement ensuite, idéalement après l'avis d'un conseil.

L'e-Soleau protège ce que vous avez construit. La marque protège un nom, qui
peut toujours être changé s'il est refusé.

## Ce sur quoi le dépôt ne porte pas

L'application s'appuie sur le cadre Flutter, des bibliothèques libres et deux
polices de caractères sous licence ouverte. Rien de tout cela ne vous
appartient et le dossier le dit explicitement — voir `03_LICENCES_TIERCES.md`.
Une revendication trop large fragiliserait l'ensemble.
