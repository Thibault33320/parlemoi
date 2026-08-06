import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/setup_screen.dart';
import 'services/catalogue_service.dart';
import 'services/media_service.dart';
import 'services/storage_service.dart';
import 'services/tts_service.dart';
import 'state/app_controller.dart';
import 'widgets/communication_tile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ParleMoiApp());
}

class ParleMoiApp extends StatelessWidget {
  const ParleMoiApp({super.key});

  static final ThemeData theme = () {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4A90E2),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F7F5),
      // Police embarquee plutot que celle du systeme : sur le web, CanvasKit
      // n'en a aucune et irait la telecharger a chaque ouverture.
      fontFamily: 'Roboto',
    );

    // Repli global : tout texte de l'application peut contenir un emoji, et il
    // doit s'afficher meme sans connexion.
    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: 'Roboto',
        fontFamilyFallback: emojiFontFallback,
      ),
    );
  }();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParleMoi',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const _Bootstrap(),
    );
  }
}

/// Charge le catalogue et les reglages avant d'afficher l'interface enfant.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<AppController> _startup;

  @override
  void initState() {
    super.initState();
    _startup = _start();
  }

  Future<AppController> _start() async {
    final catalogue = await Catalogue.load();
    final storage = StorageService();
    final settings = await storage.load(catalogue);
    final tts = TtsService();

    // La synthese vocale ne doit jamais empecher l'ouverture : mieux vaut une
    // application muette qu'une application qui ne demarre pas.
    try {
      await tts.initialize(settings);
    } catch (_) {
      // Les reglages de voix resteront ceux du systeme.
    }

    return AppController(
      catalogue: catalogue,
      settings: settings,
      storage: storage,
      tts: tts,
      media: PlatformMediaService(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppController>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _StartupError(
            error: snapshot.error!,
            onRetry: () => setState(() => _startup = _start()),
          );
        }

        final controller = snapshot.data;
        if (controller == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return AppScope(
          notifier: controller,
          child: const _Racine(),
        );
      },
    );
  }
}

/// Aiguille vers l'ecran de bienvenue tant que l'application n'a pas ete mise
/// en place, puis vers l'ecran de l'enfant.
///
/// Ce widget lit le controleur, donc il se reconstruit de lui-meme une fois la
/// configuration initiale enregistree.
class _Racine extends StatelessWidget {
  const _Racine();

  @override
  Widget build(BuildContext context) {
    return AppScope.of(context).needsSetup
        ? const SetupScreen()
        : const HomeScreen();
  }
}

/// Ecran de repli. Un ecran blanc laisserait sans aucune piste.
class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 56),
              const SizedBox(height: 16),
              const Text(
                "PARLEMOI n'a pas pu démarrer",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$error',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
