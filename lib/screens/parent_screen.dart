import 'package:flutter/material.dart';

class ParentScreen extends StatefulWidget {
  const ParentScreen({
    required this.columns,
    required this.speechRate,
    required this.onColumnsChanged,
    required this.onSpeechRateChanged,
    super.key,
  });

  final int columns;
  final double speechRate;
  final ValueChanged<int> onColumnsChanged;
  final ValueChanged<double> onSpeechRateChanged;

  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  late int _columns;
  late double _speechRate;

  @override
  void initState() {
    super.initState();
    _columns = widget.columns;
    _speechRate = widget.speechRate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Espace parents')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Affichage',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 2, label: Text('2 colonnes')),
              ButtonSegment(value: 3, label: Text('3 colonnes')),
            ],
            selected: {_columns},
            onSelectionChanged: (selection) {
              final value = selection.first;
              setState(() => _columns = value);
              widget.onColumnsChanged(value);
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'Vitesse de la voix',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          Slider(
            value: _speechRate,
            min: 0.25,
            max: 0.55,
            divisions: 12,
            label: _speechRate.toStringAsFixed(2),
            onChanged: (value) {
              setState(() => _speechRate = value);
              widget.onSpeechRateChanged(value);
            },
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "Astuce : appui long sur une carte pour l'ajouter ou la retirer des favoris.",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
