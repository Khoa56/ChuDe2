import 'dart:convert';

import 'package:flutter/services.dart';

final class DurationPreset {
  const DurationPreset({required this.label, required this.seconds});

  final String label;
  final int seconds;
}

typedef LoadPresets = Future<List<DurationPreset>> Function();

final class PresetLoader {
  const PresetLoader({
    this.loadText,
    this.delay = const Duration(milliseconds: 700),
  });

  final Future<String> Function()? loadText;
  final Duration delay;

  Future<List<DurationPreset>> load() async {
    // Đọc tài nguyên bất đồng bộ. Độ trễ mô phỏng giúp thấy trạng thái chờ.
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    final text =
        await (loadText?.call() ??
            rootBundle.loadString('assets/presets.json'));
    final data = jsonDecode(text);
    if (data is! List || data.isEmpty) {
      throw const FormatException('Danh sách thời lượng không hợp lệ.');
    }
    final presets = <DurationPreset>[];
    final seen = <int>{};
    for (final item in data) {
      if (item is! Map<String, dynamic> ||
          item['label'] is! String ||
          (item['label'] as String).trim().isEmpty ||
          item['seconds'] is! int) {
        throw const FormatException('Mốc thời gian không hợp lệ.');
      }
      final seconds = item['seconds'] as int;
      if (seconds < 1 || seconds > 3600 || !seen.add(seconds)) {
        throw const FormatException(
          'Thời lượng phải khác nhau, từ 1–3600 giây.',
        );
      }
      presets.add(DurationPreset(label: item['label'], seconds: seconds));
    }
    return List.unmodifiable(presets);
  }
}
