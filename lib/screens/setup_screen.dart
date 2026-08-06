import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_controller.dart';

/// Ecran de bienvenue, affiche une seule fois a la premiere ouverture.
///
/// Il demande les deux seules choses que l'application ne peut pas deviner :
/// le prenom de l'enfant et un code parents. Le reste est deja configure —
/// 39 cartes essentielles sont actives — pour que l'application soit
/// utilisable immediatement, sans reglage.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _prenom = TextEditingController();
  final _code = TextEditingController();
  final _confirmation = TextEditingController();
  String? _erreur;
  bool _enCours = false;

  @override
  void dispose() {
    _prenom.dispose();
    _code.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _valider() async {
    final code = _code.text.trim();

    if (code.length < 4) {
      setState(() => _erreur = 'Le code doit faire au moins 4 chiffres.');
      return;
    }
    if (int.tryParse(code) == null) {
      setState(() => _erreur = 'Le code ne doit contenir que des chiffres.');
      return;
    }
    if (code != _confirmation.text.trim()) {
      setState(() => _erreur = 'Les deux codes ne sont pas identiques.');
      return;
    }

    setState(() {
      _erreur = null;
      _enCours = true;
    });

    await AppScope.of(context).completeSetup(
      childName: _prenom.text,
      pin: code,
    );
    // Aucune navigation ici : l'application observe ce reglage et bascule
    // d'elle-meme vers l'ecran de l'enfant.
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.chat_rounded, size: 56, color: primary),
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenue dans ParleMoi',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deux réponses et c\'est prêt. Tout le reste est déjà '
                    'configuré : 39 cartes essentielles sont actives.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF606060)),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    "Prénom de l'enfant",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _prenom,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      hintText: 'Par exemple : Raphaël',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _prenom.text.trim().isEmpty
                        ? "S'affichera en haut de son écran. Facultatif."
                        : 'Son écran affichera : '
                            'PARLEMOI • ${_prenom.text.trim().toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF606060),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Code parents',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _code,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Au moins 4 chiffres',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _confirmation,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      hintText: 'Répéter le code',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _valider(),
                  ),

                  const SizedBox(height: 12),
                  const Card(
                    color: Color(0xFFEFF4FF),
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.all(14),
                      child: Text(
                        "Ce code protège les réglages d'un toucher accidentel "
                        "de l'enfant. Notez-le : il n'existe aucun moyen de le "
                        'récupérer.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ),

                  if (_erreur != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        _erreur!,
                        style: const TextStyle(
                          color: Color(0xFFD93434),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _enCours ? null : _valider,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Commencer',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ces deux réglages restent modifiables dans '
                    "l'espace parents.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF808080)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
