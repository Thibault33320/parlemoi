import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/main.dart';
import 'package:parlemoi/screens/home_screen.dart';
import 'package:parlemoi/services/storage_service.dart';
import 'package:parlemoi/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  group('titre de l\'ecran enfant', () {
    test('sans prenom, seul PARLEMOI s\'affiche', () async {
      final controller = await buildController();
      await controller.setChildName('');

      expect(controller.childScreenTitle, 'PARLEMOI');
    });

    test('le prenom saisi apparait en majuscules', () async {
      final controller = await buildController();
      await controller.setChildName('Louise');

      expect(controller.childScreenTitle, 'PARLEMOI • LOUISE');
    });

    test('les espaces autour du prenom sont ignores', () async {
      final controller = await buildController();
      await controller.setChildName('  Noé  ');

      expect(controller.settings.childName, 'Noé');
      expect(controller.childScreenTitle, 'PARLEMOI • NOÉ');
    });

    test('la voix de test prononce le prenom configure', () async {
      final controller = await buildController();

      await controller.setChildName('Louise');
      expect(controller.voicePreviewSentence, contains('Louise'));

      await controller.setChildName('');
      expect(controller.voicePreviewSentence, isNot(contains('Louise')));
      expect(controller.voicePreviewSentence, contains('Bonjour'));
    });

    test('le prenom survit a un redemarrage', () async {
      final controller = await buildController();
      await controller.setChildName('Louise');

      final catalogue = await loadCatalogue();
      final relu = await StorageService().load(catalogue);

      expect(relu.childName, 'Louise');
    });
  });

  group('installations existantes', () {
    test('une installation neuve demarre sans prenom', () async {
      final controller = await buildController();

      // L'application doit pouvoir servir a une autre famille sans porter
      // le prenom de Raphael.
      expect(controller.settings.childName, isEmpty);
      expect(controller.childScreenTitle, 'PARLEMOI');
    });

    test('l\'appareil de Raphael garde son prenom', () async {
      // Favoris enregistres par la version 1 : c'est son telephone.
      final controller = await buildController(initialPrefs: {
        'favorite_ids': ['faim', 'parc'],
      });

      expect(controller.settings.childName, 'Raphaël');
      expect(controller.childScreenTitle, 'PARLEMOI • RAPHAËL');
    });

    test('une configuration v2 anterieure garde aussi le prenom', () async {
      SharedPreferences.setMockInitialValues({
        'parlemoi_settings_v2': jsonEncode({
          'actives': ['faim', 'soif'],
          'urgences': ['mal'],
          'favoris': ['faim'],
          'cartesPerso': <Map<String, dynamic>>[],
          // Pas de cle 'prenom' : reglages enregistres avant ce reglage.
        }),
      });

      final catalogue = await loadCatalogue();
      final settings = await StorageService().load(catalogue);

      expect(settings.childName, 'Raphaël');
    });
  });

  testWidgets('le titre affiche a l\'ecran suit le prenom', (tester) async {
    final controller = (await tester.runAsync(buildController))!;
    await controller.setChildName('Louise');

    await tester.pumpWidget(
      MaterialApp(
        theme: ParleMoiApp.theme,
        home: AppScope(notifier: controller, child: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PARLEMOI • LOUISE'), findsOneWidget);

    await controller.setChildName('');
    await tester.pumpAndSettle();

    expect(find.text('PARLEMOI'), findsOneWidget);
  });

  test('le prenom voyage dans la sauvegarde', () async {
    final controller = await buildController();
    await controller.setChildName('Louise');

    final catalogue = await loadCatalogue();
    final restaure =
        StorageService().import(controller.exportBackup(), catalogue);

    expect(restaure?.childName, 'Louise');
  });
}
