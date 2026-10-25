import 'dart:async';

import 'package:flutter/material.dart';

import '../countdown/countdown_controller.dart';
import '../countdown/countdown_state.dart';
import '../countdown/preset_loader.dart';
import 'countdown_dial.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({
    required this.loadPresets,
    required this.createController,
    required this.onExit,
    super.key,
  });

  final LoadPresets loadPresets;
  final CountdownController Function(int seconds) createController;
  final VoidCallback onExit;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  late Future<List<DurationPreset>> _presetsFuture;
  late final AppLifecycleListener _lifecycle;
  CountdownController? _controller;
  StreamSubscription<CountdownState>? _completionSubscription;

  @override
  void initState() {
    super.initState();
    // Future chỉ tạo khi vào màn hình, không tạo trong build().
    _presetsFuture = _prepareSession();
    _lifecycle = AppLifecycleListener(
      onHide: () => _controller?.pause(),
      onPause: () => _controller?.pause(),
    );
  }

  Future<List<DurationPreset>> _prepareSession() async {
    final presets = await widget.loadPresets();
    // Tác vụ có thể xong sau khi người dùng đã thoát.
    if (!mounted) return presets;
    if (presets.isEmpty) throw const FormatException('Không có thời lượng.');
    final initial = presets.firstWhere(
      (preset) => preset.seconds == 60,
      orElse: () => presets.first,
    );
    final controller = widget.createController(initial.seconds);
    _controller = controller;
    _completionSubscription = controller.stream.listen((state) {
      if (mounted && state.status == CountdownStatus.completed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hoàn thành đếm ngược.')),
        );
      }
    });
    return presets;
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    unawaited(_completionSubscription?.cancel());
    unawaited(_controller?.dispose());
    // StreamBuilder tự hủy subscription do nó tạo.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Đồng hồ đếm ngược'),
      actions: [
        TextButton(
          key: const ValueKey('leave-session'),
          onPressed: widget.onExit,
          child: const Text('Thoát màn hình'),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: FutureBuilder<List<DurationPreset>>(
              future: _presetsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải thời lượng...'),
                      ],
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Column(
                    children: [
                      const Text('Không tải được thời lượng.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        key: const ValueKey('retry-load'),
                        onPressed: () => setState(() {
                          _presetsFuture = _prepareSession();
                        }),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  );
                }
                final controller = _controller!;
                final presets = snapshot.data!;
                return StreamBuilder<CountdownState>(
                  stream: controller.stream,
                  initialData: controller.state,
                  builder: (context, snapshot) => _CountdownControls(
                    state: snapshot.data ?? controller.state,
                    controller: controller,
                    presets: presets,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _CountdownControls extends StatelessWidget {
  const _CountdownControls({
    required this.state,
    required this.controller,
    required this.presets,
  });

  final CountdownState state;
  final CountdownController controller;
  final List<DurationPreset> presets;

  @override
  Widget build(BuildContext context) {
    final running = state.status == CountdownStatus.running;
    final completed = state.status == CountdownStatus.completed;
    final status = switch (state.status) {
      CountdownStatus.ready => 'Sẵn sàng',
      CountdownStatus.running => 'Đang chạy',
      CountdownStatus.paused => 'Đã tạm dừng',
      CountdownStatus.completed => 'Đã hết giờ',
    };
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              key: const ValueKey('duration-select'),
              initialValue: state.totalSeconds,
              decoration: const InputDecoration(
                labelText: 'Thời lượng',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final preset in presets)
                  DropdownMenuItem(
                    value: preset.seconds,
                    child: Text(preset.label),
                  ),
              ],
              onChanged: running
                  ? null
                  : (seconds) {
                      if (seconds != null) controller.reset(seconds: seconds);
                    },
            ),
            const SizedBox(height: 24),
            const Text('Thời gian còn lại'),
            CountdownDisplay(seconds: state.remainingSeconds),
            Text(status, key: const ValueKey('session-status')),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  key: const ValueKey('start-session'),
                  onPressed: running || completed ? null : controller.start,
                  child: Text(
                    state.status == CountdownStatus.paused
                        ? 'Tiếp tục'
                        : 'Bắt đầu',
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('pause-session'),
                  onPressed: running ? controller.pause : null,
                  child: const Text('Tạm dừng'),
                ),
                OutlinedButton(
                  key: const ValueKey('reset-session'),
                  onPressed: () => controller.reset(),
                  child: const Text('Đặt lại'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
