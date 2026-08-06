import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parlemoi/main.dart';
import 'package:parlemoi/screens/parent_screen.dart';
import 'package:parlemoi/state/app_controller.dart';
import 'package:parlemoi/widgets/media_editor.dart';

import 'helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(installFakeTts);
  tearDown(removeFakeTts);

  Future<AppController> pumpParent(
    WidgetTester tester, {
    FakeMediaService? media,
  }) async {
    final controller =
        (await tester.runAsync(() => buildController(media: media)))!;
    await tester.pumpWidget(
      MaterialApp(
        theme: ParleMoiApp.theme,
        home: AppScope(notifier: controller, child: const ParentScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('l\'espace parents annonce la photo et la voix', (tester) async {
    await pumpParent(tester);

    // Sans ce rappel, la fonction se devine seulement en reconnaissant une
    // icone parmi quatre : Thibault ne l'avait pas trouvee.
    expect(find.textContaining('remplacer par une photo'), findsOneWidget);
    expect(find.textContaining('enregistrer votre voix'), findsOneWidget);
  });

  testWidgets('toucher l\'image d\'une carte ouvre photo et voix',
      (tester) async {
    await pumpParent(tester);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded).first);
    await tester.pumpAndSettle();

    expect(find.byType(PhotoEditor), findsOneWidget);
    expect(find.byType(VoiceRecorderEditor), findsOneWidget);
    expect(find.text('Prendre une photo'), findsOneWidget);
    expect(find.text('Enregistrer ma voix'), findsOneWidget);
  });

  testWidgets('prendre une photo remplace le pictogramme de la carte',
      (tester) async {
    final media = FakeMediaService();
    final controller = await pumpParent(tester, media: media);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prendre une photo'));
    await tester.pumpAndSettle();

    expect(media.photoRequests, hasLength(1));
    final modifiees =
        controller.allCards.where((card) => card.hasPhoto).toList();
    expect(modifiees, hasLength(1));
    expect(modifiees.single.photoBase64, media.nextPhoto);
  });

  testWidgets('la voix enregistree est proposee a l\'ecoute et supprimable',
      (tester) async {
    final media = FakeMediaService();
    final controller = await pumpParent(tester, media: media);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enregistrer ma voix'));
    // `pumpAndSettle` ferait defiler l'horloge simulee au-dela des 10 secondes
    // d'arret automatique : l'enregistrement serait deja termine.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Arrêter'), findsOneWidget);

    await tester.tap(find.text('Arrêter'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Votre voix est enregistrée'), findsOneWidget);
    expect(controller.allCards.where((c) => c.hasRecordedVoice), hasLength(1));

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Sans enregistrement, la carte doit reparler avec la synthese.
    expect(controller.allCards.where((c) => c.hasRecordedVoice), isEmpty);
    expect(find.textContaining('Voix de synthèse'), findsOneWidget);
  });

  testWidgets('un micro refuse est explique sans bloquer', (tester) async {
    final media = FakeMediaService()..microphoneAllowed = false;
    await pumpParent(tester, media: media);

    await tester.tap(find.byIcon(Icons.photo_camera_rounded).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer ma voix'));
    await tester.pumpAndSettle();

    expect(find.textContaining("micro n'est pas autorisé"), findsOneWidget);
    expect(find.text('Arrêter'), findsNothing);
  });
}
