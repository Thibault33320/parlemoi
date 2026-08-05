import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/models/settings.dart';
import 'package:parlemoi/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  group('persistance', () {
    test('les reglages survivent a un redemarrage', () async {
      SharedPreferences.setMockInitialValues({});
      final catalogue = await loadCatalogue();
      final storage = StorageService();

      final settings = await storage.load(catalogue);
      settings.columns = 3;
      settings.speechRate = 0.5;
      settings.favoriteIds = {'faim', 'papa'};
      settings.pin = '1234';
      await storage.save(settings);

      final relu = await storage.load(catalogue);

      expect(relu.columns, 3);
      expect(relu.speechRate, 0.5);
      expect(relu.favoriteIds, {'faim', 'papa'});
      expect(relu.pin, '1234');
    });

    test('les favoris de la version 1 sont repris, pas effaces', () async {
      // Etat reel possible sur l'appareil de Raphael avant la mise a jour.
      SharedPreferences.setMockInitialValues({
        'favorite_ids': ['faim', 'parc', 'maman'],
        'grid_columns': 3,
        'speech_rate': 0.42,
      });

      final catalogue = await loadCatalogue();
      final settings = await StorageService().load(catalogue);

      expect(settings.favoriteIds, {'faim', 'parc', 'maman'});
      expect(settings.columns, 3);
      expect(settings.speechRate, 0.42);
      expect(settings.enabledIds, isNotEmpty);
    });

    test('des reglages illisibles ne bloquent pas le demarrage', () async {
      SharedPreferences.setMockInitialValues({
        'parlemoi_settings_v2': 'ceci n\'est pas du json',
      });

      final catalogue = await loadCatalogue();
      final settings = await StorageService().load(catalogue);

      expect(settings.enabledIds, isNotEmpty);
      expect(settings.pin, Settings.defaultPin);
    });

    test('une configuration vide retombe sur les cartes par defaut', () async {
      SharedPreferences.setMockInitialValues({
        'parlemoi_settings_v2': jsonEncode({
          'actives': <String>[],
          'urgences': <String>[],
          'favoris': <String>[],
          'cartesPerso': <Map<String, dynamic>>[],
        }),
      });

      final catalogue = await loadCatalogue();
      final settings = await StorageService().load(catalogue);

      // Sans ce filet, Raphael se retrouverait devant un ecran vide.
      expect(settings.enabledIds, containsAll(catalogue.defaultEnabledIds));
      expect(settings.emergencyIds, catalogue.defaultEmergencyIds);

      // Une carte d'urgence est toujours activee : sinon elle apparaitrait
      // dans le panneau Urgence sans exister dans aucune categorie.
      expect(settings.enabledIds, containsAll(catalogue.defaultEmergencyIds));
    });

    test('les identifiants inconnus sont ecartes au chargement', () async {
      SharedPreferences.setMockInitialValues({
        'parlemoi_settings_v2': jsonEncode({
          'actives': ['faim', 'carte_qui_nexiste_plus', 'soif'],
          'urgences': ['mal'],
          'favoris': ['faim', 'fantome'],
          'cartesPerso': <Map<String, dynamic>>[],
        }),
      });

      final catalogue = await loadCatalogue();
      final settings = await StorageService().load(catalogue);

      // 'mal' s'ajoute a la fin : il figure dans les urgences, et une carte
      // d'urgence doit rester joignable depuis sa categorie.
      expect(settings.enabledIds, ['faim', 'soif', 'mal']);
      expect(settings.favoriteIds, {'faim'});
    });
  });

  group('sauvegarde exportable', () {
    test('un export se reimporte a l\'identique', () async {
      SharedPreferences.setMockInitialValues({});
      final catalogue = await loadCatalogue();
      final storage = StorageService();

      final settings = await storage.load(catalogue);
      settings.columns = 3;
      settings.pin = '9876';
      settings.favoriteIds = {'faim', 'soif'};

      final restaure = storage.import(storage.export(settings), catalogue);

      expect(restaure, isNotNull);
      expect(restaure!.columns, 3);
      expect(restaure.pin, '9876');
      expect(restaure.favoriteIds, {'faim', 'soif'});
      expect(restaure.enabledIds, settings.enabledIds);
    });

    test('les cartes personnalisees traversent l\'export', () async {
      SharedPreferences.setMockInitialValues({});
      final catalogue = await loadCatalogue();
      final storage = StorageService();
      final controller = await buildController();

      final card = await controller.createCustomCard(
        label: 'MON DOUDOU',
        spokenText: 'Je veux mon doudou',
        emoji: '🧸',
        categoryId: 'besoins',
      );

      final restaure = storage.import(controller.exportBackup(), catalogue);

      expect(restaure, isNotNull);
      expect(restaure!.customCards, hasLength(1));
      expect(restaure.customCards.single.id, card.id);
      expect(restaure.customCards.single.spokenText, 'Je veux mon doudou');
      expect(restaure.customCards.single.emoji, '🧸');
      expect(restaure.enabledIds, contains(card.id));
    });

    test('un texte quelconque est refuse sans rien casser', () async {
      final catalogue = await loadCatalogue();
      final storage = StorageService();

      // Un parent qui colle le mauvais presse-papier ne doit rien perdre.
      expect(storage.import('bonjour', catalogue), isNull);
      expect(storage.import('{}', catalogue), isNull);
      expect(storage.import('{"application":"AUTRE"}', catalogue), isNull);
      expect(storage.import('[1,2,3]', catalogue), isNull);
    });
  });
}
