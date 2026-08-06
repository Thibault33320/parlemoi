import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/main.dart';
import 'package:parlemoi/models/settings.dart';
import 'package:parlemoi/screens/home_screen.dart';
import 'package:parlemoi/state/app_controller.dart';
import 'package:parlemoi/widgets/communication_tile.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  // Ce fichier couvre le mode grille. Le mode par defaut, une carte par ecran,
  // est teste dans swipe_mode_test.dart.
  Future<AppController> pumpHome(WidgetTester tester) async {
    // `runAsync` est indispensable : le corps d'un `testWidgets` s'execute dans
    // une zone a temps simule, ou la lecture reelle de `assets/catalogue.json`
    // ne se termine jamais et fait expirer le test.
    final controller = (await tester.runAsync(buildController))!;
    await controller.setDisplayMode(DisplayMode.grid);

    await tester.pumpWidget(
      MaterialApp(
        theme: ParleMoiApp.theme,
        home: AppScope(notifier: controller, child: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('l\'ecran enfant s\'ouvre sur des cartes, jamais sur du vide',
      (tester) async {
    await pumpHome(tester);

    expect(find.byType(CommunicationTile), findsWidgets);
    expect(find.text('URGENCE'), findsOneWidget);
  });

  testWidgets('toucher une carte la fait parler', (tester) async {
    final controller = await pumpHome(tester);
    final premiere = controller.favoriteCards.first;

    await tester.tap(find.byType(CommunicationTile).first);
    await tester.pump();

    expect(spokenPhrases, [premiere.spokenText]);
  });

  testWidgets('la carte prononcee est mise en evidence pendant la parole',
      (tester) async {
    final controller = await pumpHome(tester);

    holdSpeech();
    await tester.tap(find.byType(CommunicationTile).first);
    await tester.pump();

    final tuile = tester.widget<CommunicationTile>(
      find.byType(CommunicationTile).first,
    );
    expect(tuile.isSpeaking, isTrue,
        reason: 'Raphael doit voir que sa carte a bien parle');

    releaseSpeech();
    await tester.pumpAndSettle();

    // Le retour visuel doit s'eteindre, sinon la carte resterait allumee et
    // Raphael croirait l'application bloquee.
    expect(controller.speakingCardId, isNull);
  });

  testWidgets('l\'urgence est atteignable en deux touchers', (tester) async {
    final controller = await pumpHome(tester);

    // Toucher 1 : ouvrir.
    await tester.tap(find.text('URGENCE'));
    await tester.pumpAndSettle();
    expect(find.text('BESOINS URGENTS'), findsOneWidget);

    // La grille de l'accueil reste montee derriere le panneau : sans limiter
    // la recherche au panneau, on toucherait une carte non urgente.
    final dansLePanneau = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(CommunicationTile),
    );
    expect(dansLePanneau, findsWidgets);

    // Toucher 2 : parler.
    await tester.tap(dansLePanneau.first);
    await tester.pump();

    expect(spokenPhrases, [controller.emergencyCards.first.spokenText]);
  });

  testWidgets('un toucher simple n\'ouvre pas l\'espace parents',
      (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.lock_rounded));
    await tester.pumpAndSettle();

    // Un enfant qui tape partout ne doit pas tomber sur les reglages.
    expect(find.text('Code parents'), findsNothing);
    expect(find.textContaining('Appui long'), findsOneWidget);
  });

  testWidgets('un appui long demande le code parents', (tester) async {
    await pumpHome(tester);

    await tester.longPress(find.byIcon(Icons.lock_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Code parents'), findsOneWidget);
  });

  testWidgets('un code faux garde l\'espace parents ferme', (tester) async {
    await pumpHome(tester);

    await tester.longPress(find.byIcon(Icons.lock_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '0000');
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Espace parents'), findsNothing);
    expect(find.text('Code incorrect'), findsOneWidget);
  });

  testWidgets('le bon code ouvre l\'espace parents', (tester) async {
    await pumpHome(tester);

    await tester.longPress(find.byIcon(Icons.lock_rounded));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2580');
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Espace parents'), findsOneWidget);
  });

  testWidgets('changer de categorie change les cartes affichees',
      (tester) async {
    final controller = await pumpHome(tester);
    final categorie = controller.visibleCategories.first;

    await tester.tap(find.text(categorie.name));
    await tester.pumpAndSettle();

    final affichees = tester
        .widgetList<CommunicationTile>(find.byType(CommunicationTile))
        .map((t) => t.card.categoryId)
        .toSet();

    expect(affichees, {categorie.id});
  });

  testWidgets('un appui long sur une carte ne modifie pas les favoris',
      (tester) async {
    final controller = await pumpHome(tester);
    final avant = controller.settings.favoriteIds.toSet();

    await tester.longPress(find.byType(CommunicationTile).first);
    await tester.pumpAndSettle();

    // Un appui long involontaire reorganiserait la page d'accueil de Raphael.
    expect(controller.settings.favoriteIds, avant);
  });

  testWidgets('le reglage 3 colonnes est applique a la grille', (tester) async {
    final controller = await pumpHome(tester);

    await controller.setColumns(3);
    await tester.pumpAndSettle();

    final grille = tester.widget<GridView>(find.byType(GridView).first);
    final delegate =
        grille.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
  });

  testWidgets('masquer les textes retire les libelles des cartes',
      (tester) async {
    final controller = await pumpHome(tester);
    final premiere = controller.favoriteCards.first;

    expect(find.text(premiere.label), findsOneWidget);

    await controller.setShowLabels(false);
    await tester.pumpAndSettle();

    expect(find.text(premiere.label), findsNothing);
    expect(find.byType(CommunicationTile), findsWidgets);
  });
}
