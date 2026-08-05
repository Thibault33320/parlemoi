import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/communication_card.dart';

class CommunicationTile extends StatelessWidget {
  const CommunicationTile({
    required this.card,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final CommunicationCard card;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: card.backgroundColor,
      borderRadius: BorderRadius.circular(24),
      elevation: 1.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: SvgPicture.asset(
                      card.assetPath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    card.label,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF202020),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Icon(Icons.volume_up_rounded, size: 24),
                ],
              ),
            ),
            if (isFavorite)
              const Positioned(
                top: 10,
                right: 10,
                child: Icon(
                  Icons.star_rounded,
                  color: Color(0xFFFFB300),
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
