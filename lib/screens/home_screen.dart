import 'package:flutter/material.dart';
import '../data/default_cards.dart';
import '../models/communication_card.dart';
import '../services/storage_service.dart';
import '../services/tts_service.dart';
import '../widgets/communication_tile.dart';
import 'parent_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _tts = TtsService();
  final _storage = StorageService();

  Set<String> _favorites = <String>{};
  int _columns = 2;
  double _speechRate = 0.36;
  CardCategory _category = CardCategory.favoris;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favorites = await _storage.loadFavorites();
    final columns = await _storage.loadColumns();
    final rate = await _storage.loadSpeechRate();
    await _tts.initialize(rate: rate);

    if (!mounted) return;
    setState(() {
      _favorites = favorites.isEmpty
          ? {'faim', 'soif', 'pipi', 'popo', 'mal', 'parc'}
          : favorites;
      _columns = columns;
      _speechRate = rate;
      _ready = true;
    });
  }

  List<CommunicationCard> get _visibleCards {
    if (_category == CardCategory.favoris) {
      return defaultCards.where((card) => _favorites.contains(card.id)).toList();
    }
    return defaultCards.where((card) => card.category == _category).toList();
  }

  Future<void> _toggleFavorite(CommunicationCard card) async {
    setState(() {
      if (_favorites.contains(card.id)) {
        _favorites.remove(card.id);
      } else {
        _favorites.add(card.id);
      }
    });
    await _storage.saveFavorites(_favorites);
  }

  Future<void> _openParents() async {
    final controller = TextEditingController();
    final allowed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Code parents'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Code PIN'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text == '2580'),
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );

    if (allowed != true || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParentScreen(
          columns: _columns,
          speechRate: _speechRate,
          onColumnsChanged: (value) async {
            setState(() => _columns = value);
            await _storage.saveColumns(value);
          },
          onSpeechRateChanged: (value) async {
            setState(() => _speechRate = value);
            await _tts.setRate(value);
            await _storage.saveSpeechRate(value);
          },
        ),
      ),
    );
  }

  Future<void> _openEmergency() async {
    final emergency = defaultCards.where((card) => card.isEmergency).toList();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: emergency.length,
                    itemBuilder: (context, index) {
                      final card = emergency[index];
                      return CommunicationTile(
                        card: card,
                        isFavorite: _favorites.contains(card.id),
                        onTap: () => _tts.speak(card.spokenText),
                        onLongPress: () => _toggleFavorite(card),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final cards = _visibleCards;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PARLEMOI • RAPHAËL',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: 'Espace parents',
            onPressed: _openParents,
            icon: const Icon(Icons.lock_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
        child: cards.isEmpty
            ? const Center(
                child: Text(
                  'Aucun favori pour le moment',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              )
            : GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return CommunicationTile(
                    card: card,
                    isFavorite: _favorites.contains(card.id),
                    onTap: () => _tts.speak(card.spokenText),
                    onLongPress: () => _toggleFavorite(card),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openEmergency,
        backgroundColor: const Color(0xFFD93434),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sos_rounded),
        label: const Text(
          'URGENCE',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: CardCategory.values.indexOf(_category),
        onDestinationSelected: (index) {
          setState(() => _category = CardCategory.values[index]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.star_outline_rounded),
            selectedIcon: Icon(Icons.star_rounded),
            label: 'Favoris',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Besoins',
          ),
          NavigationDestination(
            icon: Icon(Icons.healing_outlined),
            selectedIcon: Icon(Icons.healing_rounded),
            label: 'Douleur',
          ),
          NavigationDestination(
            icon: Icon(Icons.sentiment_satisfied_alt_outlined),
            selectedIcon: Icon(Icons.sentiment_satisfied_alt_rounded),
            label: 'Émotions',
          ),
          NavigationDestination(
            icon: Icon(Icons.toys_outlined),
            selectedIcon: Icon(Icons.toys_rounded),
            label: 'Activités',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Personnes',
          ),
        ],
      ),
    );
  }
}
