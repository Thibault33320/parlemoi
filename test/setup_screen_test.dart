import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/main.dart';
import 'package:parlemoi/screens/home_screen.dart';
import 'package:parlemoi/screens/setup_screen.dart';
import 'package:parlemoi/services/storage_service.dart';
import 'package:parlemoi/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  /// Reproduit l'aiguillage de l'application : bienvenue, puis ecran enfant.
  Future<AppController> pumpApp(WidgetTester tester, AppController c) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ParleMoiApp.theme,
        home: AppScope(
          notifier: c,
          child: Builder(
            builder: (context) => AppScope.of(context).needsSetup
                ? const SetupScreen()
                : const HomeScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return c;
  }

  testWidgets('une installation neuve ouvre l\'ecran de bienvenue',
      (tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await pumpApp(tester, controller);

    expect(controller.needsSetup, isTrue);
    expect(find.text('Bienvenue dans ParleMoi'), findsOneWidget);
    expect(find.text('Commencer'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('un code trop court est refusé', (tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField).at(1), '12');
    await tester.enterText(find.byType(TextField).at(2), '12');
    await tester.ensureVisible(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('au moins 4 chiffres'), findsOneWidget);
    expect(controller.needsSetup, isTrue);
  });

  testWidgets('deux codes différents sont refusés', (tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField).at(1), '1234');
    await tester.enterText(find.byType(TextField).at(2), '5678');
    await tester.ensureVisible(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.textContaining('pas identiques'), findsOneWidget);
    expect(controller.needsSetup, isTrue);
  });

  testWidgets('prénom et code enregistrés ouvrent l\'écran de l\'enfant',
      (tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField).at(0), 'Louise');
    await tester.enterText(find.byType(TextField).at(1), '4071');
    await tester.enterText(find.byType(TextField).at(2), '4071');
    await tester.ensureVisible(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('PARLEMOI • LOUISE'), findsOneWidget);
    expect(controller.checkPin('4071'), isTrue);

    // Le code fourni par defaut ne doit plus ouvrir quoi que ce soit.
    expect(controller.checkPin('2580'), isFalse);
  });

  testWidgets('le prénom peut rester vide', (tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField).at(1), '4071');
    await tester.enterText(find.byType(TextField).at(2), '4071');
    await tester.ensureVisible(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('PARLEMOI'), findsOneWidget);
  });

  testWidgets('la mise en place ne se redemande pas au redémarrage',
      (tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await pumpApp(tester, controller);

    await tester.enterText(find.byType(TextField).at(1), '4071');
    await tester.enterText(find.byType(TextField).at(2), '4071');
    await tester.ensureVisible(find.text('Commencer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    final relu = (await tester.runAsync(
      () => buildController(resetPrefs: false),
    ))!;

    expect(relu.needsSetup, isFalse);
  });

  group('installations existantes', () {
    test('l\'appareil de Raphaël ne repasse pas par la bienvenue', () async {
      final controller = await buildController(initialPrefs: {
        'favorite_ids': ['faim', 'parc'],
      });

      expect(controller.needsSetup, isFalse);
      expect(controller.settings.childName, 'Raphaël');
    });

    test('une configuration v2 antérieure non plus', () async {
      SharedPreferences.setMockInitialValues({
        'parlemoi_settings_v2': jsonEncode({
          'actives': ['faim', 'soif'],
          'urgences': ['mal'],
          'favoris': ['faim'],
          'cartesPerso': <Map<String, dynamic>>[],
          'pin': '9999',
          // Pas de cle 'configInitiale' : reglages anterieurs a ce reglage.
        }),
      });

      final catalogue = await loadCatalogue();
      final settings = await StorageService().load(catalogue);

      expect(settings.setupCompleted, isTrue);
      expect(settings.pin, '9999');
    });
  });

  test('réinitialiser ne réouvre pas la bienvenue et garde le code', () async {
    final controller = await buildController();
    await controller.completeSetup(childName: 'Louise', pin: '4071');

    await controller.resetToDefaults();

    // Sinon un parent qui remet les cartes à zéro rouvrirait sans le savoir
    // son espace parents avec le code fourni par défaut.
    expect(controller.needsSetup, isFalse);
    expect(controller.checkPin('4071'), isTrue);
    expect(controller.settings.childName, 'Louise');
    expect(controller.settings.enabledIds,
        containsAll(controller.catalogue.defaultEnabledIds));
  });
}
