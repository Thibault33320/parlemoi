import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/communication_card.dart';
import '../models/settings.dart';
import '../services/tts_service.dart';
import '../state/app_controller.dart';
import '../widgets/communication_tile.dart';
import '../widgets/media_editor.dart';

/// Espace parents : choix des cartes, voix, affichage, sauvegarde et code.
class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Espace parents'),
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(icon: Icon(Icons.grid_view_rounded), text: 'Cartes'),
              Tab(icon: Icon(Icons.record_voice_over_rounded), text: 'Voix'),
              Tab(icon: Icon(Icons.tune_rounded), text: 'Affichage'),
              Tab(icon: Icon(Icons.save_rounded), text: 'Sauvegarde'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _CardsTab(),
            _VoiceTab(),
            _DisplayTab(),
            _BackupTab(),
          ],
        ),
      ),
    );
  }
}

// --- Onglet Cartes --------------------------------------------------------

class _CardsTab extends StatefulWidget {
  const _CardsTab();

  @override
  State<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<_CardsTab> {
  String _query = '';
  String? _categoryFilter;
  bool _activeOnly = false;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final needle = _normalize(_query);

    final cards = controller.allCards.where((card) {
      if (_categoryFilter != null && card.categoryId != _categoryFilter) {
        return false;
      }
      if (_activeOnly && !controller.isEnabled(card.id)) return false;
      if (needle.isEmpty) return true;
      return _normalize(card.label).contains(needle) ||
          _normalize(card.spokenText).contains(needle);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Rechercher une carte',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                FilterChip(
                  label: const Text('Actives'),
                  selected: _activeOnly,
                  onSelected: (value) => setState(() => _activeOnly = value),
                ),
                const SizedBox(width: 12),
                const VerticalDivider(width: 1),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Toutes'),
                  selected: _categoryFilter == null,
                  onSelected: (_) => setState(() => _categoryFilter = null),
                ),
                for (final category in controller.catalogue.categories) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text('${category.emoji} ${category.name}'),
                    selected: _categoryFilter == category.id,
                    onSelected: (_) =>
                        setState(() => _categoryFilter = category.id),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${cards.length} carte${cards.length > 1 ? 's' : ''} • '
                    '${controller.settings.enabledIds.length} active'
                    '${controller.settings.enabledIds.length > 1 ? 's' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                if (_categoryFilter != null)
                  TextButton.icon(
                    onPressed: () => _openReorder(context, _categoryFilter!),
                    icon: const Icon(Icons.swap_vert_rounded, size: 20),
                    label: const Text('Ordre'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: cards.isEmpty
                ? const Center(child: Text('Aucune carte ne correspond'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: cards.length,
                    itemBuilder: (context, index) => _CardRow(
                      card: cards[index],
                      controller: controller,
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCustomCardEditor(context, controller),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Carte perso'),
      ),
    );
  }

  void _openReorder(BuildContext context, String categoryId) {
    final controller = AppScope.of(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppScope(
          notifier: controller,
          child: _ReorderScreen(categoryId: categoryId),
        ),
      ),
    );
  }
}

String _normalize(String value) {
  const accents = 'àâäáãçéèêëíìîïñóòôöõúùûüýÿ';
  const plain = 'aaaaaceeeeiiiinooooouuuuyy';
  final buffer = StringBuffer();
  for (final rune in value.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = accents.indexOf(char);
    buffer.write(index == -1 ? char : plain[index]);
  }
  return buffer.toString();
}

class _CardRow extends StatelessWidget {
  const _CardRow({required this.card, required this.controller});

  final CommunicationCard card;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final enabled = controller.isEnabled(card.id);

    return ListTile(
      leading: _Thumbnail(card: card),
      title: Text(
        card.label,
        style: const TextStyle(fontWeight: FontWeight.w800),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        card.spokenText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => controller.speak(card),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Favori',
            visualDensity: VisualDensity.compact,
            onPressed:
                enabled ? () => controller.toggleFavorite(card.id) : null,
            icon: Icon(
              controller.isFavorite(card.id)
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: controller.isFavorite(card.id)
                  ? const Color(0xFFFFB300)
                  : null,
            ),
          ),
          IconButton(
            tooltip: 'Urgence',
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                controller.setEmergency(card.id, !controller.isEmergency(card.id)),
            icon: Icon(
              Icons.sos_rounded,
              color: controller.isEmergency(card.id)
                  ? const Color(0xFFD93434)
                  : null,
            ),
          ),
          IconButton(
            tooltip: 'Photo et voix',
            visualDensity: VisualDensity.compact,
            onPressed: () => _openMediaEditor(context, controller, card),
            icon: Icon(
              Icons.tune_rounded,
              color: card.hasPhoto || card.hasRecordedVoice
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
          ),
          if (card.isCustom)
            IconButton(
              tooltip: 'Modifier',
              visualDensity: VisualDensity.compact,
              onPressed: () =>
                  _openCustomCardEditor(context, controller, existing: card),
              icon: const Icon(Icons.edit_rounded),
            ),
          Switch(
            value: enabled,
            onChanged: (value) => controller.setEnabled(card.id, value),
          ),
        ],
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.card});

  final CommunicationCard card;

  @override
  Widget build(BuildContext context) {
    final photo = card.photoBase64;
    final assetPath = card.assetPath;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: card.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: photo != null
              ? Image.memory(decodePhoto(photo), fit: BoxFit.cover)
              : assetPath != null
                  ? Padding(
                      padding: const EdgeInsets.all(6),
                      child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
                    )
                  : Text(card.emoji, style: const TextStyle(fontSize: 24)),
        ),
        if (card.hasRecordedVoice)
          Positioned(
            bottom: -3,
            right: -3,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF2E7D32),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic_rounded, size: 12, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

/// Photo et voix pour n'importe quelle carte, du catalogue comme personnalisee.
Future<void> _openMediaEditor(
  BuildContext context,
  AppController controller,
  CommunicationCard card,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      builder: (context, scrollController) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final live = controller.cardById(card.id) ?? card;

          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Row(
                children: [
                  _Thumbnail(card: live),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          live.label,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          live.spokenText,
                          style: const TextStyle(color: Color(0xFF606060)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PhotoEditor(
                media: controller.media,
                photoBase64: live.photoBase64,
                fallback: _Thumbnail(card: live),
                onChanged: (photo) => photo == null
                    ? controller.removePhoto(live.id)
                    : controller.savePhoto(live.id, photo),
              ),
              VoiceRecorderEditor(
                media: controller.media,
                audioBase64: live.audioBase64,
                previewText: live.spokenText,
                onPlayFallback: () => controller.tts.speak(live.spokenText),
                onChanged: (audio) => audio == null
                    ? controller.removeRecording(live.id)
                    : controller.saveRecording(live.id, audio),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Terminé'),
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

/// Reordonne les cartes actives d'une categorie.
class _ReorderScreen extends StatelessWidget {
  const _ReorderScreen({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final category = controller.catalogue.categoryById(categoryId);
    final cards = controller.cardsInCategory(categoryId);

    return Scaffold(
      appBar: AppBar(title: Text('Ordre • ${category?.name ?? ''}')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Glissez les cartes pour changer leur ordre. '
              'Une position stable aide Raphaël à retrouver une carte sans la lire.',
              style: TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: cards.length,
              onReorderItem: (oldIndex, newIndex) =>
                  controller.reorderInCategory(categoryId, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final card = cards[index];
                return ListTile(
                  key: ValueKey(card.id),
                  leading: _Thumbnail(card: card),
                  title: Text(
                    card.label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  trailing: const Icon(Icons.drag_handle_rounded),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Creation et modification d'une carte personnalisee.
Future<void> _openCustomCardEditor(
  BuildContext context,
  AppController controller, {
  CommunicationCard? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _CustomCardEditor(controller: controller, existing: existing),
    ),
  );
}

class _CustomCardEditor extends StatefulWidget {
  const _CustomCardEditor({required this.controller, this.existing});

  final AppController controller;
  final CommunicationCard? existing;

  @override
  State<_CustomCardEditor> createState() => _CustomCardEditorState();
}

class _CustomCardEditorState extends State<_CustomCardEditor> {
  static const _suggestions = [
    '😀', '😢', '😡', '😨', '🤕', '🍽️', '🥤', '🛏️', '🚽', '🧸',
    '🎵', '📺', '🚗', '🏫', '🌳', '🐶', '🛁', '👕', '💊', '🤗',
    '👋', '❤️', '✅', '❌', '⏸️', '🆘', '📞', '🧩', '⚽', '🍫',
  ];

  late final TextEditingController _label;
  late final TextEditingController _speech;
  late String _emoji;
  late String _categoryId;

  // Pour une carte qui n'existe pas encore, la photo et la voix sont gardees
  // ici puis rattachees a la carte au moment de l'enregistrement.
  String? _photo;
  String? _audio;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _label = TextEditingController(text: existing?.label ?? '');
    _speech = TextEditingController(text: existing?.spokenText ?? '');
    _emoji = existing?.emoji ?? '😀';
    _categoryId =
        existing?.categoryId ?? widget.controller.catalogue.categories.first.id;
    _photo = existing?.photoBase64;
    _audio = existing?.audioBase64;
  }

  @override
  void dispose() {
    _label.dispose();
    _speech.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _label.text.trim().isNotEmpty && _speech.text.trim().isNotEmpty;

  Future<void> _save() async {
    final controller = widget.controller;
    final existing = widget.existing;

    if (existing != null) {
      await controller.updateCustomCard(
        existing.copyWith(
          label: _label.text.trim(),
          spokenText: _speech.text.trim(),
          emoji: _emoji,
          categoryId: _categoryId,
          backgroundColor: controller.catalogue.categoryById(_categoryId)?.color,
        ),
      );

      final photo = _photo;
      photo == null
          ? await controller.removePhoto(existing.id)
          : await controller.savePhoto(existing.id, photo);

      final audio = _audio;
      audio == null
          ? await controller.removeRecording(existing.id)
          : await controller.saveRecording(existing.id, audio);
    } else {
      await controller.createCustomCard(
        label: _label.text.trim(),
        spokenText: _speech.text.trim(),
        emoji: _emoji,
        categoryId: _categoryId,
        photoBase64: _photo,
        audioBase64: _audio,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer cette carte ?'),
        content: Text('« ${existing.label} » sera définitivement retirée.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD93434)),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await widget.controller.deleteCustomCard(existing.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Nouvelle carte' : 'Modifier la carte',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Texte affiché',
                hintText: 'JE VEUX MON DOUDOU',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _speech,
              decoration: const InputDecoration(
                labelText: 'Phrase prononcée',
                hintText: 'Je veux mon doudou',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category
                          in widget.controller.catalogue.categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text('${category.emoji} ${category.name}'),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _categoryId = value ?? _categoryId),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isValid
                      ? () => widget.controller.tts.speak(_speech.text.trim())
                      : null,
                  child: const Text('Écouter'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Pictogramme',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in _suggestions)
                  InkWell(
                    onTap: () => setState(() => _emoji = emoji),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _emoji == emoji
                              ? Theme.of(context).colorScheme.primary
                              : const Color(0xFFDDDDDD),
                          width: _emoji == emoji ? 3 : 1,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            PhotoEditor(
              media: widget.controller.media,
              photoBase64: _photo,
              fallback: Center(
                child: Text(_emoji, style: const TextStyle(fontSize: 32)),
              ),
              onChanged: (photo) => setState(() => _photo = photo),
            ),
            VoiceRecorderEditor(
              media: widget.controller.media,
              audioBase64: _audio,
              previewText: _speech.text.trim().isEmpty
                  ? 'la phrase de la carte'
                  : _speech.text.trim(),
              onPlayFallback: () =>
                  widget.controller.tts.speak(_speech.text.trim()),
              onChanged: (audio) => setState(() => _audio = audio),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (widget.existing != null)
                  TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFD93434),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _isValid ? _save : null,
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- Onglet Voix ----------------------------------------------------------

class _VoiceTab extends StatefulWidget {
  const _VoiceTab();

  @override
  State<_VoiceTab> createState() => _VoiceTabState();
}

class _VoiceTabState extends State<_VoiceTab> {
  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final settings = controller.settings;
    final voices = controller.tts.frenchVoices;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle('Voix française'),
        if (voices.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Aucune voix française détectée sur cet appareil. "
                "L'application utilisera la voix système par défaut. "
                "Sur Android, vous pouvez en ajouter dans "
                "Paramètres → Langues → Synthèse vocale.",
              ),
            ),
          )
        else
          ...voices.map(
            (voice) => RadioListTile<VoiceOption>(
              value: voice,
              // ignore: deprecated_member_use
              groupValue: settings.voiceName == null
                  ? null
                  : VoiceOption(
                      name: settings.voiceName!,
                      locale: settings.voiceLocale ?? 'fr-FR',
                    ),
              // ignore: deprecated_member_use
              onChanged: (value) async {
                if (value == null) return;
                await controller.setVoice(value);
                await controller.tts.speak('Bonjour Raphaël');
              },
              title: Text(voice.displayName),
              subtitle: Text(voice.locale),
            ),
          ),
        const SizedBox(height: 20),
        _SliderRow(
          label: 'Vitesse',
          value: settings.speechRate,
          min: 0.2,
          max: 0.6,
          divisions: 16,
          onChanged: controller.setSpeechRate,
        ),
        _SliderRow(
          label: 'Hauteur',
          value: settings.pitch,
          min: 0.6,
          max: 1.4,
          divisions: 16,
          onChanged: controller.setPitch,
        ),
        _SliderRow(
          label: 'Volume',
          value: settings.volume,
          min: 0.2,
          max: 1.0,
          divisions: 8,
          onChanged: controller.setVolume,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () =>
              controller.tts.speak('Bonjour, je suis Raphaël. J\'ai soif.'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Tester la voix'),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(2),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// --- Onglet Affichage -----------------------------------------------------

class _DisplayTab extends StatelessWidget {
  const _DisplayTab();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final settings = controller.settings;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle('Présentation des cartes'),
        const SizedBox(height: 8),
        SegmentedButton<DisplayMode>(
          segments: const [
            ButtonSegment(
              value: DisplayMode.swipe,
              icon: Icon(Icons.swipe_vertical_rounded),
              label: Text('Une par écran'),
            ),
            ButtonSegment(
              value: DisplayMode.grid,
              icon: Icon(Icons.grid_view_rounded),
              label: Text('Grille'),
            ),
          ],
          selected: {settings.displayMode},
          onSelectionChanged: (selection) =>
              controller.setDisplayMode(selection.first),
        ),
        const SizedBox(height: 8),
        Text(
          settings.displayMode == DisplayMode.swipe
              ? 'Une carte occupe tout l\'écran. Raphaël glisse vers le haut '
                  'pour passer à la suivante, comme dans les Reels.'
              : 'Plusieurs cartes visibles à la fois. Utile pour proposer un '
                  'choix entre deux ou trois possibilités.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF606060)),
        ),
        if (settings.displayMode == DisplayMode.grid) ...[
          const SizedBox(height: 24),
          const _SectionTitle('Nombre de colonnes'),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 2, label: Text('2 colonnes')),
              ButtonSegment(value: 3, label: Text('3 colonnes')),
            ],
            selected: {settings.columns},
            onSelectionChanged: (selection) =>
                controller.setColumns(selection.first),
          ),
        ],
        const SizedBox(height: 24),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Afficher le texte sous les images',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: const Text(
            "Raphaël ne lit pas seul : masquer le texte agrandit l'image "
            'et réduit ce qui le distrait.',
          ),
          value: settings.showLabels,
          onChanged: controller.setShowLabels,
        ),
        const SizedBox(height: 24),
        const _SectionTitle('Code parents'),
        const SizedBox(height: 8),
        const _PinChanger(),
      ],
    );
  }
}

class _PinChanger extends StatefulWidget {
  const _PinChanger();

  @override
  State<_PinChanger> createState() => _PinChangerState();
}

class _PinChangerState extends State<_PinChanger> {
  final _current = TextEditingController();
  final _fresh = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _fresh.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final controller = AppScope.of(context);

    if (!controller.checkPin(_current.text)) {
      setState(() => _error = 'Code actuel incorrect');
      return;
    }
    if (_fresh.text.length < 4 || int.tryParse(_fresh.text) == null) {
      setState(() => _error = 'Le nouveau code doit faire au moins 4 chiffres');
      return;
    }

    await controller.setPin(_fresh.text);
    if (!mounted) return;

    setState(() => _error = null);
    _current.clear();
    _fresh.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code parents modifié')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = AppScope.of(context).settings.pin == Settings.defaultPin;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isDefault)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Le code est encore 2580, celui fourni par défaut. '
                  'Changez-le pour éviter une modification accidentelle.',
                  style: TextStyle(color: Color(0xFFB25C00)),
                ),
              ),
            TextField(
              controller: _current,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Code actuel',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _fresh,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nouveau code',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFFD93434)),
                ),
              ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _apply,
                child: const Text('Changer le code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Onglet Sauvegarde ----------------------------------------------------

class _BackupTab extends StatelessWidget {
  const _BackupTab();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const _SectionTitle('Sauvegarder'),
        const SizedBox(height: 8),
        const Text(
          'Copie tous vos réglages, favoris et cartes personnalisées. '
          'Collez-les dans un e-mail ou une note pour les retrouver, '
          'ou pour les installer sur un autre appareil.',
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: controller.exportBackup()),
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Sauvegarde copiée')),
            );
          },
          icon: const Icon(Icons.copy_rounded),
          label: const Text('Copier ma sauvegarde'),
        ),
        const SizedBox(height: 32),
        const _SectionTitle('Restaurer'),
        const SizedBox(height: 8),
        const Text('Colle une sauvegarde copiée précédemment.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _restore(context, controller),
          icon: const Icon(Icons.paste_rounded),
          label: const Text('Coller une sauvegarde'),
        ),
        const SizedBox(height: 32),
        const _SectionTitle('Réinitialiser'),
        const SizedBox(height: 8),
        const Text(
          'Remet les cartes, favoris et réglages dans leur état d\'origine. '
          'Les cartes personnalisées seront perdues.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD93434),
          ),
          onPressed: () => _reset(context, controller),
          icon: const Icon(Icons.restart_alt_rounded),
          label: const Text('Tout réinitialiser'),
        ),
        const SizedBox(height: 40),
        Card(
          color: const Color(0xFFF0F4FF),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              controller.catalogue.licence,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _restore(BuildContext context, AppController controller) async {
    final field = TextEditingController();
    final clipboard = await Clipboard.getData(Clipboard.kTextPlain);
    field.text = clipboard?.text ?? '';

    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restaurer une sauvegarde'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: field,
            maxLines: 6,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Collez ici le texte de la sauvegarde',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.importBackup(field.text);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Sauvegarde restaurée'
              : "Ce texte n'est pas une sauvegarde PARLEMOI. Rien n'a été modifié.",
        ),
      ),
    );
  }

  Future<void> _reset(BuildContext context, AppController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tout réinitialiser ?'),
        content: const Text(
          'Les cartes personnalisées, favoris et réglages seront perdus. '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD93434),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await controller.resetToDefaults();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réglages réinitialisés')),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
    );
  }
}
