import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/models/communication_card.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  test('toucher une carte prononce sa phrase', () async {
    final controller = await buildController();
    final card = controller.cardById('faim')!;

    await controller.speak(card);

    expect(spokenPhrases, ["J'ai faim"]);
    expect(controller.speakingCardId, isNull,
        reason: 'le retour visuel doit s\'eteindre a la fin de la phrase');
  });

  test('une phrase interrompue n\'eteint pas le retour visuel de la suivante',
      () async {
    final controller = await buildController();
    final premiere = controller.cardById('faim')!;
    final seconde = controller.cardById('soif')!;

    final enCours = controller.speak(premiere);
    final suivante = controller.speak(seconde);
    await Future.wait([enCours, suivante]);

    expect(controller.speakingCardId, isNull);
    expect(spokenPhrases, ["J'ai faim", "J'ai soif"]);
  });

  test('les favoris se rangent et se derangent', () async {
    final controller = await buildController();

    await controller.toggleFavorite('jouer');
    expect(controller.isFavorite('jouer'), isTrue);

    await controller.toggleFavorite('jouer');
    expect(controller.isFavorite('jouer'), isFalse);
  });

  test('desactiver une carte la retire aussi des favoris et des urgences',
      () async {
    final controller = await buildController();

    await controller.setEmergency('jouer', true);
    await controller.toggleFavorite('jouer');
    expect(controller.isFavorite('jouer'), isTrue);
    expect(controller.isEmergency('jouer'), isTrue);

    await controller.setEnabled('jouer', false);

    // Sinon la carte hanterait la page d'accueil sans etre atteignable.
    expect(controller.isEnabled('jouer'), isFalse);
    expect(controller.isFavorite('jouer'), isFalse);
    expect(controller.isEmergency('jouer'), isFalse);
  });

  test('marquer une carte comme urgente l\'active automatiquement', () async {
    final controller = await buildController();
    const id = 'picto_356'; // Appelle les secours

    expect(controller.isEnabled(id), isFalse);
    await controller.setEmergency(id, true);

    expect(controller.isEmergency(id), isTrue);
    expect(controller.isEnabled(id), isTrue);
  });

  test('reordonner une categorie laisse les autres intactes', () async {
    final controller = await buildController();

    final avantEmotions =
        controller.cardsInCategory('emotions').map((c) => c.id).toList();
    final besoinsAvant =
        controller.cardsInCategory('besoins').map((c) => c.id).toList();

    await controller.reorderInCategory('emotions', 0, 2);

    final apresEmotions =
        controller.cardsInCategory('emotions').map((c) => c.id).toList();

    expect(apresEmotions.first, avantEmotions[1]);
    expect(apresEmotions[2], avantEmotions.first);
    expect(apresEmotions.toSet(), avantEmotions.toSet());

    // La memoire du geste de Raphael repose sur cette stabilite.
    expect(controller.cardsInCategory('besoins').map((c) => c.id).toList(),
        besoinsAvant);
  });

  test('un reordonnancement hors limites ne casse rien', () async {
    final controller = await buildController();
    final avant = controller.settings.enabledIds.toList();

    await controller.reorderInCategory('emotions', 99, 0);

    expect(controller.settings.enabledIds, avant);
  });

  test('une carte personnalisee devient utilisable immediatement', () async {
    final controller = await buildController();

    final card = await controller.createCustomCard(
      label: 'MON DOUDOU',
      spokenText: 'Je veux mon doudou',
      emoji: '🧸',
      categoryId: 'besoins',
    );

    expect(controller.isEnabled(card.id), isTrue);
    expect(controller.cardById(card.id), isNotNull);
    expect(controller.cardsInCategory('besoins').map((c) => c.id),
        contains(card.id));

    await controller.speak(card);
    expect(spokenPhrases, contains('Je veux mon doudou'));
  });

  test('modifier une carte personnalisee garde son identifiant', () async {
    final controller = await buildController();
    final card = await controller.createCustomCard(
      label: 'DOUDOU',
      spokenText: 'Doudou',
      emoji: '🧸',
      categoryId: 'besoins',
    );

    await controller.updateCustomCard(
      card.copyWith(label: 'MON DOUDOU', spokenText: 'Je veux mon doudou'),
    );

    final relu = controller.cardById(card.id)!;
    expect(relu.id, card.id);
    expect(relu.spokenText, 'Je veux mon doudou');
    expect(controller.isEnabled(card.id), isTrue);
  });

  test('supprimer une carte personnalisee la retire partout', () async {
    final controller = await buildController();
    final card = await controller.createCustomCard(
      label: 'DOUDOU',
      spokenText: 'Doudou',
      emoji: '🧸',
      categoryId: 'besoins',
    );
    await controller.toggleFavorite(card.id);

    await controller.deleteCustomCard(card.id);

    expect(controller.cardById(card.id), isNull);
    expect(controller.isEnabled(card.id), isFalse);
    expect(controller.isFavorite(card.id), isFalse);
    expect(controller.favoriteCards.map((c) => c.id), isNot(contains(card.id)));
  });

  test('seules les categories non vides sont proposees', () async {
    final controller = await buildController();

    for (final category in controller.visibleCategories) {
      expect(controller.cardsInCategory(category.id), isNotEmpty,
          reason: '${category.id} menerait a un ecran blanc');
    }
  });

  test('le code parents se change et l\'ancien ne fonctionne plus', () async {
    final controller = await buildController();

    expect(controller.checkPin('2580'), isTrue);
    await controller.setPin('4071');

    expect(controller.checkPin('4071'), isTrue);
    expect(controller.checkPin('2580'), isFalse);
  });

  test('la liste des voix ne retient que le francais', () async {
    final controller = await buildController();

    expect(controller.tts.frenchVoices.map((v) => v.locale),
        everyElement(startsWith('fr')));
    expect(controller.tts.frenchVoices, hasLength(2));
  });

  test('un import invalide laisse la configuration en place', () async {
    final controller = await buildController();
    await controller.toggleFavorite('jouer');
    final avant = controller.settings.favoriteIds.toSet();

    final ok = await controller.importBackup('nimporte quoi');

    expect(ok, isFalse);
    expect(controller.settings.favoriteIds, avant);
  });

  test('la reinitialisation efface les cartes personnalisees', () async {
    final controller = await buildController();
    final card = await controller.createCustomCard(
      label: 'DOUDOU',
      spokenText: 'Doudou',
      emoji: '🧸',
      categoryId: 'besoins',
    );

    await controller.resetToDefaults();

    expect(controller.cardById(card.id), isNull);
    expect(controller.settings.pin, '2580');
    expect(controller.settings.enabledIds,
        controller.catalogue.defaultEnabledIds);
  });

  test('les urgences par defaut couvrent la douleur et l\'appel a l\'aide',
      () async {
    final controller = await buildController();
    final phrases =
        controller.emergencyCards.map((c) => c.spokenText.toLowerCase()).join(' | ');

    expect(phrases, contains('mal'));
    expect(phrases, contains('aide'));
    expect(controller.emergencyCards, isNotEmpty);
  });

  test('toutes les cartes urgentes sont bien actives', () async {
    final controller = await buildController();

    for (final card in controller.emergencyCards) {
      expect(controller.isEnabled(card.id), isTrue, reason: card.id);
    }
  });

  test('les favoris affiches sont toujours des cartes actives', () async {
    final controller = await buildController();

    for (final card in controller.favoriteCards) {
      expect(controller.isEnabled(card.id), isTrue, reason: card.id);
    }
  });

  test('une carte historique et sa version bibliotheque ne coexistent pas',
      () async {
    final controller = await buildController();
    final phrases = <String, CommunicationCard>{};

    for (final card in controller.allCards) {
      final cle = card.spokenText.toLowerCase();
      expect(phrases.containsKey(cle), isFalse,
          reason: '${card.id} repete la phrase de ${phrases[cle]?.id}');
      phrases[cle] = card;
    }
  });
}
