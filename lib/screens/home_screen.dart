import 'package:flutter/material.dart';

import '../models/communication_card.dart';
import '../models/settings.dart';
import '../state/app_controller.dart';
import '../widgets/card_pager.dart';
import '../widgets/communication_tile.dart';
import 'parent_screen.dart';

/// L'interface de Raphael. Pas de texte indispensable, de grandes cibles,
/// et l'urgence toujours a portee.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _tabId = favoritesTabId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final tabs = <_Tab>[
      const _Tab(id: favoritesTabId, name: 'Favoris', emoji: '⭐'),
      for (final category in controller.visibleCategories)
        _Tab(id: category.id, name: category.name, emoji: category.emoji),
    ];

    // La categorie selectionnee peut disparaitre si le parent vient de
    // desactiver ses dernieres cartes.
    if (!tabs.any((tab) => tab.id == _tabId)) {
      _tabId = favoritesTabId;
    }

    final cards = controller.cardsInCategory(_tabId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PARLEMOI • RAPHAËL',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          _ParentButton(onUnlocked: () => _openParents(controller)),
        ],
      ),
      body: Column(
        children: [
          _CategoryStrip(
            tabs: tabs,
            selectedId: _tabId,
            onSelected: (id) => setState(() => _tabId = id),
          ),
          Expanded(
            child: cards.isEmpty
                ? const _EmptyCategory()
                : _CardsView(
                    // Repartir de la premiere carte quand la categorie change,
                    // plutot que de rester a une position qui n'a plus de sens.
                    key: ValueKey(_tabId),
                    cards: cards,
                    settings: controller.settings,
                    speakingCardId: controller.speakingCardId,
                    onTap: controller.speak,
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEmergency(controller),
        backgroundColor: const Color(0xFFD93434),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sos_rounded, size: 28),
        label: const Text(
          'URGENCE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
    );
  }

  /// Urgence : un toucher pour ouvrir, un toucher pour parler. Jamais plus.
  Future<void> _openEmergency(AppController controller) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFF5F5),
      builder: (sheetContext) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.9,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'BESOINS URGENTS',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ),
                    IconButton(
                      iconSize: 32,
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListenableBuilder(
                    listenable: controller,
                    builder: (context, _) => _CardGrid(
                      cards: controller.emergencyCards,
                      columns: controller.settings.columns,
                      showLabels: controller.settings.showLabels,
                      speakingCardId: controller.speakingCardId,
                      favoriteIds: const {},
                      onTap: controller.speak,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openParents(AppController controller) async {
    final controllerText = TextEditingController();
    final allowed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Code parents'),
        content: TextField(
          controller: controllerText,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Code PIN'),
          onSubmitted: (value) =>
              Navigator.pop(dialogContext, controller.checkPin(value)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              controller.checkPin(controllerText.text),
            ),
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (allowed != true) {
      if (allowed == false && controllerText.text.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code incorrect')),
        );
      }
      return;
    }

    await controller.stopSpeaking();
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppScope(
          notifier: controller,
          child: const ParentScreen(),
        ),
      ),
    );
  }
}

class _Tab {
  const _Tab({required this.id, required this.name, required this.emoji});

  final String id;
  final String name;
  final String emoji;
}

/// Bande de categories. Un appui long est exige pour l'espace parents afin
/// qu'un toucher accidentel de Raphael n'ouvre pas la demande de code.
class _ParentButton extends StatelessWidget {
  const _ParentButton({required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Espace parents : appui long',
      child: InkWell(
        onLongPress: onUnlocked,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 2),
            content: Text('Appui long pour ouvrir l\'espace parents'),
          ),
        ),
        borderRadius: BorderRadius.circular(24),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.lock_rounded),
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.tabs,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_Tab> tabs;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab.id == selectedId;

          return Material(
            color: selected ? primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            elevation: selected ? 3 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => onSelected(tab.id),
              child: Container(
                constraints: const BoxConstraints(minWidth: 84),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                // Sans reduction, une police systeme agrandie par un reglage
                // d'accessibilite ferait deborder la pastille.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab.emoji,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamilyFallback: emojiFontFallback,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tab.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color:
                              selected ? Colors.white : const Color(0xFF303030),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Aiguille vers le mode choisi par le parent.
class _CardsView extends StatelessWidget {
  const _CardsView({
    required this.cards,
    required this.settings,
    required this.speakingCardId,
    required this.onTap,
    super.key,
  });

  final List<CommunicationCard> cards;
  final Settings settings;
  final String? speakingCardId;
  final ValueChanged<CommunicationCard> onTap;

  @override
  Widget build(BuildContext context) {
    if (settings.displayMode == DisplayMode.swipe) {
      return CardPager(
        cards: cards,
        showLabels: settings.showLabels,
        speakingCardId: speakingCardId,
        favoriteIds: settings.favoriteIds,
        onTap: onTap,
      );
    }

    return _CardGrid(
      cards: cards,
      columns: settings.columns,
      showLabels: settings.showLabels,
      speakingCardId: speakingCardId,
      favoriteIds: settings.favoriteIds,
      onTap: onTap,
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.columns,
    required this.showLabels,
    required this.speakingCardId,
    required this.favoriteIds,
    required this.onTap,
  });

  final List<CommunicationCard> cards;
  final int columns;
  final bool showLabels;
  final String? speakingCardId;
  final Set<String> favoriteIds;
  final ValueChanged<CommunicationCard> onTap;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: landscape ? 1.25 : 0.88,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return CommunicationTile(
          card: card,
          isFavorite: favoriteIds.contains(card.id),
          isSpeaking: card.id == speakingCardId,
          showLabel: showLabels,
          onTap: () => onTap(card),
        );
      },
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('⭐', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text(
              'Aucune carte ici pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
