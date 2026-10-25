import 'package:flutter/material.dart';

import '../countdown/countdown_controller.dart';
import '../countdown/preset_loader.dart';
import 'session_page.dart';

/// Mở thẳng đồng hồ. Nút thoát loại SessionPage khỏi cây widget để dispose.
class DemoHost extends StatefulWidget {
  const DemoHost({
    required this.loadPresets,
    required this.createController,
    super.key,
  });

  final LoadPresets loadPresets;
  final CountdownController Function(int seconds) createController;

  @override
  State<DemoHost> createState() => _DemoHostState();
}

class _DemoHostState extends State<DemoHost> {
  bool _showDemo = true;

  @override
  Widget build(BuildContext context) {
    if (_showDemo) {
      return SessionPage(
        loadPresets: widget.loadPresets,
        createController: widget.createController,
        onExit: () => setState(() => _showDemo = false),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Demo đếm ngược')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Đã thoát màn hình đếm ngược.'),
            const SizedBox(height: 16),
            FilledButton(
              key: const ValueKey('reopen-demo'),
              onPressed: () => setState(() => _showDemo = true),
              child: const Text('Mở lại demo'),
            ),
          ],
        ),
      ),
    );
  }
}
