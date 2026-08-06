import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/main.dart';
import 'package:parlemoi/models/settings.dart';
import 'package:parlemoi/screens/home_screen.dart';
import 'package:parlemoi/state/app_controller.dart';
import 'package:parlemoi/widgets/card_pager.dart';
import 'package:parlemoi/widgets/communication_tile.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  Future<AppController> pumpHome(WidgetTester tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await tester.pumpWidget(
      MaterialApp(
        theme: ParleMoiApp.theme,
        home: AppScope(notifier: controller, child: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('le defilement vertical est le mode par defaut', (tester) async {
    final controller = await pumpHome(tester);

    expect(controller.settings.displayMode, DisplayMode.swipe);
    expect(find.byType(CardPager), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('une seule carte est visible a la fois', (tester) async {
    await pumpHome(tester);

    // Une seule chose a regarder, une cible qui occupe tout l'ecran.
    expect(find.byType(CardPictogram), findsOneWidget);
  });

  testWidgets('glisser vers le haut passe a la carte suivante', (tester) async {
    final controller = await pumpHome(tester);
    final favoris = controller.favoriteCards;
    expect(favoris.length, greaterThan(1));

    expect(find.text(favoris[0].label), findsOneWidget);
    expect(find.text('1 / ${favoris.length}'), findsOneWidget);

    await tester.fling(find.byType(PageView), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();

    expect(find.text(favoris[1].label), findsOneWidget);
    expect(find.text(favoris[0].label), findsNothing);
    expect(find.text('2 / ${favoris.length}'), findsOneWidget);
  });

  testWidgets('un geste vif n\'emporte quand meme qu\'une seule carte',
      (tester) async {
    final controller = await pumpHome(tester);
    final favoris = controller.favoriteCards;
    expect(favoris.length, greaterThan(2));

    // Impulsion volontairement violente : Raphael ne doit pas se retrouver
    // plusieurs cartes plus loin et perdre ce qu'il voulait dire.
    await tester.fling(find.byType(PageView), const Offset(0, -600), 8000);
    await tester.pumpAndSettle();

    expect(find.text('2 / ${favoris.length}'), findsOneWidget);
    expect(find.text(favoris[1].label), findsOneWidget);
  });

  testWidgets('glisser vers le bas revient a la carte precedente',
      (tester) async {
    final controller = await pumpHome(tester);
    final favoris = controller.favoriteCards;

    await tester.fling(find.byType(PageView), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(0, 400), 1200);
    await tester.pumpAndSettle();

    expect(find.text(favoris[0].label), findsOneWidget);
    expect(find.text('1 / ${favoris.length}'), findsOneWidget);
  });

  testWidgets('toucher la carte plein ecran la fait parler', (tester) async {
    final controller = await pumpHome(tester);
    final premiere = controller.favoriteCards.first;

    await tester.tap(find.byType(CardPictogram));
    await tester.pump();

    expect(spokenPhrases, [premiere.spokenText]);
  });

  testWidgets('la carte glissee est bien celle qui parle', (tester) async {
    final controller = await pumpHome(tester);
    final favoris = controller.favoriteCards;

    await tester.fling(find.byType(PageView), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CardPictogram));
    await tester.pump();

    expect(spokenPhrases, [favoris[1].spokenText]);
  });

  testWidgets('changer de categorie repart de la premiere carte',
      (tester) async {
    final controller = await pumpHome(tester);

    await tester.fling(find.byType(PageView), const Offset(0, -400), 1200);
    await tester.pumpAndSettle();
    expect(find.textContaining('2 / '), findsOneWidget);

    final categorie = controller.visibleCategories.first;
    await tester.tap(find.text(categorie.name));
    await tester.pumpAndSettle();

    // Rester a la position precedente n'aurait aucun sens dans une autre liste.
    expect(find.textContaining('1 / '), findsOneWidget);
    final affichee = tester
        .widget<CardPictogram>(find.byType(CardPictogram))
        .card;
    expect(affichee.categoryId, categorie.id);
  });

  testWidgets('l\'urgence reste joignable en deux touchers depuis le swipe',
      (tester) async {
    final controller = await pumpHome(tester);

    await tester.tap(find.text('URGENCE'));
    await tester.pumpAndSettle();

    final dansLePanneau = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(CommunicationTile),
    );
    await tester.tap(dansLePanneau.first);
    await tester.pump();

    expect(spokenPhrases, [controller.emergencyCards.first.spokenText]);
  });

  testWidgets('le parent peut revenir a la grille', (tester) async {
    final controller = await pumpHome(tester);

    await controller.setDisplayMode(DisplayMode.grid);
    await tester.pumpAndSettle();

    expect(find.byType(CardPager), findsNothing);
    expect(find.byType(CommunicationTile), findsWidgets);
  });

  testWidgets('le mode choisi survit a un redemarrage', (tester) async {
    final controller = await pumpHome(tester);
    await controller.setDisplayMode(DisplayMode.grid);

    final relu = (await tester.runAsync(
      () => buildController(resetPrefs: false),
    ))!;

    expect(relu.settings.displayMode, DisplayMode.grid);
  });

  testWidgets('masquer les textes agrandit le pictogramme sans le supprimer',
      (tester) async {
    final controller = await pumpHome(tester);
    final premiere = controller.favoriteCards.first;

    expect(find.text(premiere.label), findsOneWidget);

    await controller.setShowLabels(false);
    await tester.pumpAndSettle();

    expect(find.text(premiere.label), findsNothing);
    expect(find.byType(CardPictogram), findsOneWidget);
  });
}
