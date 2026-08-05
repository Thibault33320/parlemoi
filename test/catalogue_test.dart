import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('le catalogue embarque se charge et contient les 17 categories', () async {
    final catalogue = await loadCatalogue();

    expect(catalogue.categories, hasLength(17));
    expect(catalogue.cards.length, greaterThan(400));
    expect(catalogue.licence, contains('Makaton'));
  });

  test('aucune carte ne parle deux fois la meme phrase', () async {
    final catalogue = await loadCatalogue();
    final phrases = catalogue.cards.map((c) => c.spokenText.toLowerCase()).toList();

    expect(phrases.toSet(), hasLength(phrases.length),
        reason: 'un doublon rendrait deux cartes indiscernables a l\'oreille');
  });

  test('chaque identifiant est unique', () async {
    final catalogue = await loadCatalogue();
    final ids = catalogue.cards.map((c) => c.id).toList();

    expect(ids.toSet(), hasLength(ids.length));
  });

  test('les cartes historiques gardent leur identifiant et leur dessin', () async {
    final catalogue = await loadCatalogue();

    // Ces identifiants sont deja enregistres dans les favoris de Raphael :
    // les renommer effacerait sa page d'accueil.
    const historiques = [
      'faim', 'soif', 'pipi', 'popo', 'dormir', 'calin', 'aide', 'mal',
      'ventre', 'tete', 'peur', 'content', 'triste', 'colere', 'parc',
      'jouer', 'tablette', 'maison', 'papa', 'maman',
    ];

    for (final id in historiques) {
      final card = catalogue.byId(id);
      expect(card, isNotNull, reason: '$id a disparu du catalogue');
      expect(card!.assetPath, isNotNull, reason: '$id a perdu son dessin');
    }
  });

  test('toute carte a soit un dessin soit un emoji affichable', () async {
    final catalogue = await loadCatalogue();

    for (final card in catalogue.cards) {
      expect(
        card.assetPath != null || card.emoji.isNotEmpty,
        isTrue,
        reason: '${card.id} s\'afficherait comme une case vide',
      );
    }
  });

  test('chaque carte appartient a une categorie declaree', () async {
    final catalogue = await loadCatalogue();
    final known = catalogue.categories.map((c) => c.id).toSet();

    for (final card in catalogue.cards) {
      expect(known, contains(card.categoryId), reason: 'carte ${card.id}');
    }
  });

  test('les cartes actives et urgences par defaut existent toutes', () async {
    final catalogue = await loadCatalogue();

    for (final id in catalogue.defaultEnabledIds) {
      expect(catalogue.byId(id), isNotNull, reason: 'active inconnue : $id');
    }
    for (final id in catalogue.defaultEmergencyIds) {
      expect(catalogue.byId(id), isNotNull, reason: 'urgence inconnue : $id');
    }
  });

  test('le vocabulaire prioritaire est actif des la premiere ouverture', () async {
    final catalogue = await loadCatalogue();
    final actives = catalogue.defaultEnabledIds
        .map((id) => catalogue.byId(id)!.spokenText.toLowerCase())
        .join(' | ');

    // Liste demandee explicitement pour Raphael.
    for (final attendu in [
      'faim', 'soif', 'dormir', 'pipi', 'popo', 'parc', 'mal',
      'oui', 'non', 'encore', 'fini', 'aide', 'pause', 'papa',
    ]) {
      expect(actives, contains(attendu), reason: '« $attendu » manque au demarrage');
    }
  });

  test('le nombre de cartes actives reste petit au premier lancement', () async {
    final catalogue = await loadCatalogue();

    // Montrer les 413 cartes d'un coup rendrait l'application inutilisable.
    expect(catalogue.defaultEnabledIds.length, lessThan(60));
  });
}
