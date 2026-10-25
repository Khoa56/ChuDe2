import 'package:flutter/material.dart';

import '../countdown/countdown_state.dart';

class CountdownDisplay extends StatelessWidget {
  const CountdownDisplay({required this.seconds, super.key});
  final int seconds;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Còn lại $seconds giây',
    child: ExcludeSemantics(
      child: Text(
        formatTime(seconds),
        key: const ValueKey('countdown-value'),
        style: const TextStyle(
          fontSize: 64,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}
