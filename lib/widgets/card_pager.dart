import 'package:flutter/material.dart';

import '../models/communication_card.dart';
import 'communication_tile.dart';

/// Une carte par ecran, on glisse verticalement pour passer a la suivante.
///
/// C'est le geste des Reels, que Raphael maitrise deja. Une seule carte a la
/// fois signifie aussi une seule chose a regarder et une cible tactile qui
/// occupe tout l'ecran : impossible de la manquer.
class CardPager extends StatefulWidget {
  const CardPager({
    required this.cards,
    required this.showLabels,
    required this.speakingCardId,
    required this.favoriteIds,
    required this.onTap,
    super.key,
  });

  final List<CommunicationCard> cards;
  final bool showLabels;
  final String? speakingCardId;
  final Set<String> favoriteIds;
  final ValueChanged<CommunicationCard> onTap;

  @override
  State<CardPager> createState() => _CardPagerState();
}

class _CardPagerState extends State<CardPager> {
  final _controller = PageController();
  int _index = 0;

  /// Position au moment ou le doigt s'est pose, qui borne tout le geste.
  double _dragStart = 0;

  /// Part de la hauteur d'une carte au-dela de laquelle on considere que
  /// Raphael a voulu changer de carte, meme sans elan.
  static const _seuilDeplacement = 0.22;
  static const _seuilVitesse = 260.0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ScrollPosition? get _position =>
      _controller.hasClients ? _controller.position : null;

  void _onDragStart(DragStartDetails details) {
    _dragStart = _position?.pixels ?? 0;
  }

  /// La carte suit le doigt, mais ne peut pas s'eloigner de plus d'une carte
  /// du point de depart.
  void _onDragUpdate(DragUpdateDetails details) {
    final position = _position;
    final delta = details.primaryDelta;
    if (position == null || delta == null) return;

    final hauteurCarte = position.viewportDimension;
    final cible = (position.pixels - delta)
        .clamp(_dragStart - hauteurCarte, _dragStart + hauteurCarte)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    position.jumpTo(cible);
  }

  /// Un geste, une carte. Une impulsion enthousiaste ne doit pas emporter
  /// Raphael plusieurs cartes plus loin : il perdrait ce qu'il voulait dire.
  void _onDragEnd(DragEndDetails details) {
    final position = _position;
    if (position == null) return;

    final hauteurCarte = position.viewportDimension;
    final parcouru = position.pixels - _dragStart;
    final vitesse = details.primaryVelocity ?? 0;

    var direction = 0;
    if (parcouru.abs() > hauteurCarte * _seuilDeplacement) {
      direction = parcouru > 0 ? 1 : -1;
    } else if (vitesse.abs() > _seuilVitesse) {
      // Vitesse negative = doigt vers le haut = carte suivante.
      direction = vitesse < 0 ? 1 : -1;
    }

    final depart = (_dragStart / hauteurCarte).round();
    final cible = (depart + direction).clamp(0, widget.cards.length - 1);

    _controller.animateToPage(
      cible,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Le defilement est pilote a la main plutot que laisse a l'inertie :
        // c'est le seul moyen de garantir qu'un geste ne fasse jamais defiler
        // plus d'une carte, quelle que soit sa vigueur.
        GestureDetector(
          onVerticalDragStart: _onDragStart,
          onVerticalDragUpdate: _onDragUpdate,
          onVerticalDragEnd: _onDragEnd,
          child: PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.cards.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final card = widget.cards[index];
              return _FullScreenCard(
                card: card,
                isFavorite: widget.favoriteIds.contains(card.id),
                isSpeaking: card.id == widget.speakingCardId,
                showLabel: widget.showLabels,
                isFirst: index == 0,
                isLast: index == widget.cards.length - 1,
                onTap: () => widget.onTap(card),
              );
            },
          ),
        ),
        // Repere de progression, utile a l'adulte qui accompagne Raphael.
        Positioned(
          top: 12,
          right: 16,
          child: _PositionBadge(
            position: _index + 1,
            total: widget.cards.length,
          ),
        ),
      ],
    );
  }
}

class _FullScreenCard extends StatelessWidget {
  const _FullScreenCard({
    required this.card,
    required this.isFavorite,
    required this.isSpeaking,
    required this.showLabel,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final CommunicationCard card;
  final bool isFavorite;
  final bool isSpeaking;
  final bool showLabel;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      // La marge basse laisse le bouton Urgence flotter sans recouvrir le
      // pictogramme ni le chevron : il doit rester visible en permanence.
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 84),
      child: AnimatedScale(
        scale: isSpeaking ? 1.02 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Material(
          color: card.backgroundColor,
          borderRadius: BorderRadius.circular(28),
          elevation: isSpeaking ? 10 : 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            // Toute la surface parle : viser n'est plus necessaire.
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.fromBorderSide(
                  isSpeaking
                      ? BorderSide(color: primary, width: 8)
                      : BorderSide.none,
                ),
              ),
              child: Semantics(
                button: true,
                label: card.label,
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                      child: Column(
                        children: [
                          Expanded(child: CardPictogram(card: card)),
                          if (showLabel) ...[
                            const SizedBox(height: 16),
                            Text(
                              card.label,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 30,
                                height: 1.1,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF202020),
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Icon(
                            isSpeaking
                                ? Icons.graphic_eq_rounded
                                : Icons.volume_up_rounded,
                            size: 40,
                            color: isSpeaking ? primary : const Color(0xFF505050),
                          ),
                        ],
                      ),
                    ),
                    if (isFavorite)
                      const Positioned(
                        top: 16,
                        left: 16,
                        child: Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFB300),
                          size: 34,
                        ),
                      ),
                    if (!isFirst)
                      const Align(
                        alignment: Alignment.topCenter,
                        child: _SwipeHint(icon: Icons.keyboard_arrow_up_rounded),
                      ),
                    if (!isLast)
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child:
                            _SwipeHint(icon: Icons.keyboard_arrow_down_rounded),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chevron discret indiquant qu'une autre carte attend dans cette direction.
class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Icon(icon, size: 30, color: const Color(0x4D202020)),
    );
  }
}

class _PositionBadge extends StatelessWidget {
  const _PositionBadge({required this.position, required this.total});

  final int position;
  final int total;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0x14000000),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          '$position / $total',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF404040),
          ),
        ),
      ),
    );
  }
}
