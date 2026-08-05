import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const ParleMoiApp());
}

class ParleMoiApp extends StatelessWidget {
  const ParleMoiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParleMoi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2),
        ),
      ),
      home: const CommunicationScreen(),
    );
  }
}

enum CommunicationCategory {
  essentials,
  health,
  emotions,
  activities,
  people,
}

class CommunicationCardData {
  const CommunicationCardData({
    required this.label,
    required this.spokenText,
    required this.icon,
    required this.backgroundColor,
    required this.category,
    this.isEmergency = false,
  });

  final String label;
  final String spokenText;
  final IconData icon;
  final Color backgroundColor;
  final CommunicationCategory category;
  final bool isEmergency;
}

class CommunicationScreen extends StatefulWidget {
  const CommunicationScreen({super.key});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  final FlutterTts _tts = FlutterTts();
  final PageController _pageController = PageController();

  int _currentIndex = 0;
  bool _isSpeaking = false;

  final List<CommunicationCardData> _cards = const [
    CommunicationCardData(
      label: "J'AI FAIM",
      spokenText: "J'ai faim",
      icon: Icons.restaurant_rounded,
      backgroundColor: Color(0xFFFFF2CC),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: "J'AI SOIF",
      spokenText: "J'ai soif",
      icon: Icons.local_drink_rounded,
      backgroundColor: Color(0xFFDDF3FF),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: 'JE VEUX FAIRE PIPI',
      spokenText: 'Je veux faire pipi',
      icon: Icons.wc_rounded,
      backgroundColor: Color(0xFFE4F6E7),
      category: CommunicationCategory.essentials,
      isEmergency: true,
    ),
    CommunicationCardData(
  label: 'JE VEUX FAIRE POPO',
  spokenText: 'Je veux faire popo',
  icon: Icons.bathroom_rounded,
  backgroundColor: Color(0xFFFFE7D8),
  category: CommunicationCategory.essentials,
  isEmergency: true,
),
    CommunicationCardData(
      label: "J'AI MAL",
      spokenText: "J'ai mal",
      icon: Icons.healing_rounded,
      backgroundColor: Color(0xFFFFDDDD),
      category: CommunicationCategory.health,
      isEmergency: true,
    ),
    CommunicationCardData(
      label: "J'AI MAL AU VENTRE",
      spokenText: "J'ai mal au ventre",
      icon: Icons.sick_rounded,
      backgroundColor: Color(0xFFFFE1E1),
      category: CommunicationCategory.health,
      isEmergency: true,
    ),
    CommunicationCardData(
      label: "J'AI MAL À LA TÊTE",
      spokenText: "J'ai mal à la tête",
      icon: Icons.psychology_alt_rounded,
      backgroundColor: Color(0xFFFFE6E6),
      category: CommunicationCategory.health,
      isEmergency: true,
    ),
    CommunicationCardData(
      label: "J'AI BESOIN D'AIDE",
      spokenText: "J'ai besoin d'aide",
      icon: Icons.sos_rounded,
      backgroundColor: Color(0xFFFFD6D6),
      category: CommunicationCategory.essentials,
      isEmergency: true,
    ),
    CommunicationCardData(
      label: 'JE VEUX DORMIR',
      spokenText: 'Je veux dormir',
      icon: Icons.bedtime_rounded,
      backgroundColor: Color(0xFFE8E2FF),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: 'JE VEUX ALLER AU PARC',
      spokenText: 'Je veux aller au parc',
      icon: Icons.park_rounded,
      backgroundColor: Color(0xFFE3F6D8),
      category: CommunicationCategory.activities,
    ),
    CommunicationCardData(
      label: 'JE VEUX JOUER',
      spokenText: 'Je veux jouer',
      icon: Icons.toys_rounded,
      backgroundColor: Color(0xFFFFF0D9),
      category: CommunicationCategory.activities,
    ),
    CommunicationCardData(
      label: 'JE VEUX LA TABLETTE',
      spokenText: 'Je veux la tablette',
      icon: Icons.tablet_mac_rounded,
      backgroundColor: Color(0xFFE1ECFF),
      category: CommunicationCategory.activities,
    ),
    CommunicationCardData(
      label: 'JE VEUX REGARDER LA TÉLÉ',
      spokenText: 'Je veux regarder la télévision',
      icon: Icons.tv_rounded,
      backgroundColor: Color(0xFFE7E7FF),
      category: CommunicationCategory.activities,
    ),
    CommunicationCardData(
      label: 'JE VEUX SORTIR',
      spokenText: 'Je veux sortir',
      icon: Icons.directions_walk_rounded,
      backgroundColor: Color(0xFFE4F4E8),
      category: CommunicationCategory.activities,
    ),
    CommunicationCardData(
      label: 'JE VEUX RENTRER À LA MAISON',
      spokenText: 'Je veux rentrer à la maison',
      icon: Icons.home_rounded,
      backgroundColor: Color(0xFFFFEAD8),
      category: CommunicationCategory.activities,
    ),
    CommunicationCardData(
      label: 'JE VEUX PAPA',
      spokenText: 'Je veux papa',
      icon: Icons.face_rounded,
      backgroundColor: Color(0xFFDDEBFF),
      category: CommunicationCategory.people,
    ),
    CommunicationCardData(
      label: 'JE VEUX MAMAN',
      spokenText: 'Je veux maman',
      icon: Icons.face_3_rounded,
      backgroundColor: Color(0xFFFFE1F0),
      category: CommunicationCategory.people,
    ),
    CommunicationCardData(
      label: 'JE VEUX UN CÂLIN',
      spokenText: 'Je veux un câlin',
      icon: Icons.favorite_rounded,
      backgroundColor: Color(0xFFFFE2F1),
      category: CommunicationCategory.emotions,
    ),
    CommunicationCardData(
      label: 'JE SUIS CONTENT',
      spokenText: 'Je suis content',
      icon: Icons.sentiment_very_satisfied_rounded,
      backgroundColor: Color(0xFFFFF3C8),
      category: CommunicationCategory.emotions,
    ),
    CommunicationCardData(
      label: 'JE SUIS TRISTE',
      spokenText: 'Je suis triste',
      icon: Icons.sentiment_dissatisfied_rounded,
      backgroundColor: Color(0xFFDDEBFF),
      category: CommunicationCategory.emotions,
    ),
    CommunicationCardData(
      label: 'JE SUIS EN COLÈRE',
      spokenText: 'Je suis en colère',
      icon: Icons.sentiment_very_dissatisfied_rounded,
      backgroundColor: Color(0xFFFFD6D6),
      category: CommunicationCategory.emotions,
    ),
    CommunicationCardData(
      label: "J'AI PEUR",
      spokenText: "J'ai peur",
      icon: Icons.warning_amber_rounded,
      backgroundColor: Color(0xFFFFE7C7),
      category: CommunicationCategory.emotions,
      isEmergency: true,
    ),
    CommunicationCardData(
      label: 'OUI',
      spokenText: 'Oui',
      icon: Icons.check_circle_rounded,
      backgroundColor: Color(0xFFDCF5DF),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: 'NON',
      spokenText: 'Non',
      icon: Icons.cancel_rounded,
      backgroundColor: Color(0xFFFFE0E0),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: 'ENCORE',
      spokenText: 'Encore',
      icon: Icons.add_circle_rounded,
      backgroundColor: Color(0xFFE0EDFF),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: "C'EST FINI",
      spokenText: "C'est fini",
      icon: Icons.stop_circle_rounded,
      backgroundColor: Color(0xFFFFE8D9),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: 'ATTENDS',
      spokenText: 'Attends',
      icon: Icons.hourglass_bottom_rounded,
      backgroundColor: Color(0xFFFFF2D8),
      category: CommunicationCategory.essentials,
    ),
    CommunicationCardData(
      label: 'TROP DE BRUIT',
      spokenText: 'Il y a trop de bruit',
      icon: Icons.volume_off_rounded,
      backgroundColor: Color(0xFFE4E4F5),
      category: CommunicationCategory.health,
      isEmergency: true,
    ),
    CommunicationCardData(
      label: 'JE VEUX ÊTRE SEUL',
      spokenText: 'Je veux être seul',
      icon: Icons.person_outline_rounded,
      backgroundColor: Color(0xFFE9E9E9),
      category: CommunicationCategory.emotions,
    ),
    CommunicationCardData(
      label: 'NE ME TOUCHE PAS',
      spokenText: 'Ne me touche pas',
      icon: Icons.pan_tool_rounded,
      backgroundColor: Color(0xFFFFE0E0),
      category: CommunicationCategory.health,
      isEmergency: true,
    ),
  ];

  List<CommunicationCardData> get _emergencyCards =>
      _cards.where((card) => card.isEmergency).toList();

  @override
  void initState() {
    super.initState();
    _configureSpeech();
  }

  Future<void> _configureSpeech() async {
    await _tts.setLanguage('fr-FR');
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> _openEmergencyPanel() async {
    await _tts.stop();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.88,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'BESOINS URGENTS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: _emergencyCards.length,
                      itemBuilder: (context, index) {
                        final card = _emergencyCards[index];
                        return _EmergencyTile(
                          card: card,
                          onTap: () => _speak(card.spokenText),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _cards.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isSpeaking = false;
              });
              _tts.stop();
            },
            itemBuilder: (context, index) {
              final card = _cards[index];
              return CommunicationCard(
                data: card,
                index: index,
                total: _cards.length,
                isSpeaking: _isSpeaking && index == _currentIndex,
                onTap: () => _speak(card.spokenText),
              );
            },
          ),
          Positioned(
            right: 18,
            bottom: 24,
            child: SafeArea(
              child: FloatingActionButton.extended(
                onPressed: _openEmergencyPanel,
                backgroundColor: const Color(0xFFD93434),
                foregroundColor: Colors.white,
                icon: const Icon(Icons.sos_rounded),
                label: const Text(
                  'URGENCE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunicationCard extends StatefulWidget {
  const CommunicationCard({
    required this.data,
    required this.index,
    required this.total,
    required this.isSpeaking,
    required this.onTap,
    super.key,
  });

  final CommunicationCardData data;
  final int index;
  final int total;
  final bool isSpeaking;
  final VoidCallback onTap;

  @override
  State<CommunicationCard> createState() => _CommunicationCardState();
}

class _CommunicationCardState extends State<CommunicationCard> {
  bool _pressed = false;

  void _handleTap() {
    setState(() => _pressed = true);
    widget.onTap();

    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) setState(() => _pressed = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final iconSize = width < 500 ? 145.0 : 195.0;
    final labelSize = width < 500 ? 34.0 : 48.0;

    return Material(
      color: widget.data.backgroundColor,
      child: InkWell(
        onTap: _handleTap,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 18,
                left: 22,
                child: Text(
                  'PARLEMOI • RAPHAËL',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withAlpha(140),
                  ),
                ),
              ),
              Positioned(
                top: 18,
                right: 22,
                child: Text(
                  '${widget.index + 1}/${widget.total}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black.withAlpha(140),
                  ),
                ),
              ),
              Center(
                child: AnimatedScale(
                  scale: _pressed ? 1.06 : 1.0,
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 70, 28, 110),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.data.icon,
                          size: iconSize,
                          color: const Color(0xFF303030),
                        ),
                        const SizedBox(height: 38),
                        Text(
                          widget.data.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: labelSize,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF202020),
                          ),
                        ),
                        const SizedBox(height: 34),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: widget.isSpeaking
                              ? const _SpeakingIndicator(
                                  key: ValueKey('speaking'),
                                )
                              : const _TapToSpeak(
                                  key: ValueKey('idle'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 24,
                left: 20,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 38,
                      color: Colors.black.withAlpha(110),
                    ),
                    Text(
                      'GLISSE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withAlpha(110),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyTile extends StatelessWidget {
  const _EmergencyTile({
    required this.card,
    required this.onTap,
  });

  final CommunicationCardData card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card.backgroundColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                card.icon,
                size: 70,
                color: const Color(0xFF303030),
              ),
              const SizedBox(height: 14),
              Text(
                card.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapToSpeak extends StatelessWidget {
  const _TapToSpeak({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(
          Icons.volume_up_rounded,
          size: 52,
          color: Color(0xFF303030),
        ),
        SizedBox(height: 8),
        Text(
          'TOUCHE POUR PARLER',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF404040),
          ),
        ),
      ],
    );
  }
}

class _SpeakingIndicator extends StatelessWidget {
  const _SpeakingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(
          width: 42,
          height: 42,
          child: CircularProgressIndicator(
            strokeWidth: 5,
            color: Color(0xFF303030),
          ),
        ),
        SizedBox(height: 12),
        Text(
          'JE PARLE...',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF303030),
          ),
        ),
      ],
    );
  }
}
