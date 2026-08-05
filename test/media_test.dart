import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/services/media_service.dart';
import 'package:parlemoi/services/storage_service.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  group('photo du parent', () {
    test('une photo peut remplacer le pictogramme d\'une carte du catalogue',
        () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);

      expect(controller.cardById('faim')!.hasPhoto, isFalse);

      final photo = await media.pickPhoto(PhotoSource.camera);
      await controller.savePhoto('faim', photo!);

      final card = controller.cardById('faim')!;
      expect(card.hasPhoto, isTrue);
      expect(card.photoBase64, photo);
      // Le dessin d'origine reste disponible en cas de retrait de la photo.
      expect(card.assetPath, isNotNull);
    });

    test('retirer la photo redonne le pictogramme d\'origine', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);

      await controller.savePhoto('faim', media.nextPhoto!);
      await controller.removePhoto('faim');

      expect(controller.cardById('faim')!.hasPhoto, isFalse);
      expect(controller.settings.cardMedia.containsKey('faim'), isFalse,
          reason: 'un media vide alourdirait chaque sauvegarde');
    });

    test('la photo survit a un redemarrage', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);
      await controller.savePhoto('soif', media.nextPhoto!);

      final catalogue = await loadCatalogue();
      final relu = await StorageService().load(catalogue);

      expect(relu.cardMedia['soif']?.photoBase64, media.nextPhoto);
    });
  });

  group('voix enregistree du parent', () {
    test('la voix enregistree remplace la synthese', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);

      await controller.saveRecording('faim', media.nextRecording!);
      await controller.speak(controller.cardById('faim')!);

      expect(media.playedRecordings, [media.nextRecording]);
      expect(spokenPhrases, isEmpty,
          reason: 'la synthese ne doit pas doubler la voix du parent');
    });

    test('sans enregistrement, la synthese parle comme avant', () async {
      final controller = await buildController();

      await controller.speak(controller.cardById('faim')!);

      expect(spokenPhrases, ["J'ai faim"]);
    });

    test('un enregistrement illisible retombe sur la synthese', () async {
      final controller = await buildController(media: _BrokenPlayback());

      await controller.saveRecording('faim', 'audio-casse');
      await controller.speak(controller.cardById('faim')!);

      // Une carte muette serait pire qu'une voix de synthese.
      expect(spokenPhrases, ["J'ai faim"]);
      expect(controller.speakingCardId, isNull);
    });

    test('supprimer l\'enregistrement rend la main a la synthese', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);

      await controller.saveRecording('faim', media.nextRecording!);
      await controller.removeRecording('faim');
      await controller.speak(controller.cardById('faim')!);

      expect(media.playedRecordings, isEmpty);
      expect(spokenPhrases, ["J'ai faim"]);
    });

    test('le micro refuse est signale sans bloquer', () async {
      final media = FakeMediaService()..microphoneAllowed = false;

      expect(await media.startRecording(), isFalse);
      expect(media.recording, isFalse);
    });
  });

  group('portabilite', () {
    test('photos et voix voyagent dans la sauvegarde exportee', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);
      final catalogue = await loadCatalogue();

      await controller.savePhoto('faim', media.nextPhoto!);
      await controller.saveRecording('faim', media.nextRecording!);

      final restaure =
          StorageService().import(controller.exportBackup(), catalogue);

      expect(restaure, isNotNull);
      expect(restaure!.cardMedia['faim']?.photoBase64, media.nextPhoto);
      expect(restaure.cardMedia['faim']?.audioBase64, media.nextRecording);
    });

    test('une carte perso nait avec sa photo et sa voix', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);

      final card = await controller.createCustomCard(
        label: 'MON DOUDOU',
        spokenText: 'Je veux mon doudou',
        emoji: '🧸',
        categoryId: 'besoins',
        photoBase64: media.nextPhoto,
        audioBase64: media.nextRecording,
      );

      final relu = controller.cardById(card.id)!;
      expect(relu.hasPhoto, isTrue);
      expect(relu.hasRecordedVoice, isTrue);

      await controller.speak(relu);
      expect(media.playedRecordings, [media.nextRecording]);
    });

    test('supprimer une carte perso emporte sa photo et sa voix', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);

      final card = await controller.createCustomCard(
        label: 'DOUDOU',
        spokenText: 'Doudou',
        emoji: '🧸',
        categoryId: 'besoins',
        photoBase64: media.nextPhoto,
        audioBase64: media.nextRecording,
      );

      await controller.deleteCustomCard(card.id);

      expect(controller.settings.cardMedia.containsKey(card.id), isFalse);
    });

    test('les medias orphelins sont nettoyes au chargement', () async {
      final media = FakeMediaService();
      final controller = await buildController(media: media);

      await controller.savePhoto('faim', media.nextPhoto!);
      controller.settings.cardMedia['carte_disparue'] =
          controller.settings.cardMedia['faim']!;
      await controller.setColumns(3);

      final catalogue = await loadCatalogue();
      final relu = await StorageService().load(catalogue);

      expect(relu.cardMedia.keys, ['faim']);
    });
  });
}

/// Simule un enregistrement corrompu au moment de la lecture.
class _BrokenPlayback extends FakeMediaService {
  @override
  Future<void> playRecording(String base64Audio) async =>
      throw const FormatException('audio illisible');
}
