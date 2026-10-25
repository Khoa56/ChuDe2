import 'dart:convert';
import 'dart:io';

// Trình mở nhanh riêng, không sửa mã nguồn ứng dụng Flutter.
Future<void> main(List<String> arguments) async {
  final checkOnly = arguments.contains('--check');
  try {
    final project = findProject();
    if (project == null) {
      fail(
        'Chua tim thay thu muc chu_de_02_demo.\n'
        'Hay dat file EXE canh tep pubspec.yaml trong thu muc ma nguon,\n'
        'hoac canh thu muc chu_de_02_demo da giai nen.',
        wait: !checkOnly,
      );
      return;
    }
    final flutter = await findFlutter(project, interactive: !checkOnly);
    if (flutter == null) {
      fail(
        'Chua tim thay Flutter.\n'
        'Hay chon thu muc Flutter SDK (noi co bin\\flutter.bat) khi duoc hoi,\n'
        'hoac them Flutter vao PATH roi mo lai file nay.',
        wait: !checkOnly,
      );
      return;
    }
    final git = await findGit(flutter);
    if (git == null) {
      fail(
        'Flutter can Git nhung chua tim thay Git tren may nay.\n'
        'Hay cai Git for Windows tu https://git-scm.com/download/win,\n'
        'sau do mo lai file nay. Khong can sua code demo.',
        wait: !checkOnly,
      );
      return;
    }
    final environment = childEnvironment(flutter: flutter, git: git);
    stdout.writeln('DEMO DONG HO DEM NGUOC - FUTURE & STREAM');
    stdout.writeln('Ma nguon: ${project.path}');
    stdout.writeln('Flutter: $flutter');
    stdout.writeln('Git: $git');
    if (checkOnly) return;
    rememberFlutter(flutter);
    stdout.writeln();
    stdout.writeln('Dang chay Flutter va mo Google Chrome...');
    stdout.writeln('Lan dau co the mat vai phut de tai thu vien va bien dich.');
    stdout.writeln(
      'Giu cua so nay mo khi demo. Trong cua so nay, nhan q de dung.',
    );
    stdout.writeln();
    final child = await Process.start(
      flutter,
      ['run', '-d', 'chrome'],
      workingDirectory: project.path,
      environment: environment,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    final result = await child.exitCode;
    if (result != 0) {
      fail('Flutter dung voi ma loi $result. Xem thong bao o phia tren.');
    }
  } on ProcessException catch (error) {
    fail('Khong khoi dong duoc Flutter: ${error.message}', wait: !checkOnly);
  } on FileSystemException catch (error) {
    fail('Khong doc duoc thu muc: ${error.message}', wait: !checkOnly);
  }
}

Directory? findProject() {
  final launcher = File(Platform.resolvedExecutable).parent;
  final candidates = [
    launcher,
    Directory('${launcher.path}/chu_de_02_demo'),
    Directory('${launcher.path}/chu_de_02_demo_don_gian'),
    Directory.current,
    Directory('${Directory.current.path}/chu_de_02_demo'),
  ];
  for (final candidate in candidates) {
    if (File('${candidate.path}/pubspec.yaml').existsSync() &&
        File('${candidate.path}/lib/main.dart').existsSync()) {
      return candidate.absolute;
    }
  }
  return null;
}

Future<String?> findFlutter(
  Directory project, {
  bool interactive = false,
}) async {
  // Ưu tiên Flutter trên PATH của máy người dùng.
  final onPath = await findOnPath('flutter');
  if (onPath != null) return onPath;
  for (final key in ['FLUTTER_ROOT', 'FLUTTER_HOME']) {
    final location = Platform.environment[key];
    final found = location == null ? null : flutterAt(location);
    if (found != null) return found;
  }
  final settings = settingsFile();
  if (settings != null) {
    try {
      if (settings.existsSync()) {
        final cached = flutterAt(settings.readAsStringSync());
        if (cached != null) return cached;
      }
    } on FileSystemException {
      // Không có quyền đọc cấu hình cũ thì tiếp tục tìm, không dừng demo.
    }
  }
  // Hỗ trợ SDK sẵn có trong workspace tạo demo, không cố định đường dẫn máy.
  var parent = project;
  for (var depth = 0; depth < 5; depth++) {
    final bundled = File('${parent.path}/work/flutter-sdk/bin/flutter.bat');
    if (bundled.existsSync()) return bundled.absolute.path;
    if (parent.parent.path == parent.path) break;
    parent = parent.parent;
  }
  final environment = Platform.environment;
  final home = environment['USERPROFILE'];
  final local = environment['LOCALAPPDATA'];
  final candidates = <String>[
    if (home != null) ...[
      '$home/flutter',
      '$home/development/flutter',
      '$home/develop/flutter',
      '$home/src/flutter',
      '$home/sdks/flutter',
      '$home/scoop/apps/flutter/current',
    ],
    if (local != null) ...['$local/flutter', '$local/Programs/flutter'],
    for (final drive in ['C:', 'D:', 'E:']) ...[
      '$drive/flutter',
      '$drive/src/flutter',
      '$drive/development/flutter',
      '$drive/sdk/flutter',
      '$drive/sdks/flutter',
      '$drive/App/flutter',
    ],
  ];
  for (final candidate in candidates) {
    final found = flutterAt(candidate);
    if (found != null) return found;
  }
  // SDK có thể đã được chuẩn bị trong workspace Codex trước đó.
  // Chỉ xem cấu trúc thư mục ngày/chat đã biết, không quét cả ổ đĩa.
  if (home != null) {
    final codex = Directory('$home/Documents/Codex');
    try {
      if (codex.existsSync()) {
        final dates =
            codex
                .listSync(followLinks: false)
                .whereType<Directory>()
                .where(
                  (directory) =>
                      RegExp(r'\d{4}-\d{2}-\d{2}$').hasMatch(directory.path),
                )
                .toList()
              ..sort((a, b) => b.path.compareTo(a.path));
        for (final date in dates.take(30)) {
          final chats = date
              .listSync(followLinks: false)
              .whereType<Directory>();
          for (final chat in chats.take(40)) {
            final found = flutterAt('${chat.path}/work/flutter-sdk');
            if (found != null) return found;
          }
        }
      }
    } on FileSystemException {
      // Một thư mục không đọc được không có nghĩa Flutter chưa được cài.
    }
  }
  return interactive ? await chooseFlutter() : null;
}

/// Chấp nhận thư mục SDK, thư mục bin hoặc đường dẫn tới flutter.bat.
String? flutterAt(String location) {
  final path = location.trim().replaceAll(RegExp(r'^"|"$'), '');
  if (path.isEmpty) return null;
  final candidates = [path, '$path/bin/flutter.bat', '$path/flutter.bat'];
  for (final candidate in candidates) {
    final file = File(candidate);
    if (candidate
            .toLowerCase()
            .replaceAll('\\', '/')
            .endsWith('/flutter.bat') &&
        file.existsSync()) {
      return file.absolute.path;
    }
  }
  return null;
}

File? settingsFile() {
  final local = Platform.environment['LOCALAPPDATA'];
  if (local == null || local.isEmpty) return null;
  return File('$local/NhipThoiGianLauncher/flutter-sdk.txt');
}

void rememberFlutter(String flutter) {
  final settings = settingsFile();
  if (settings == null) return;
  try {
    settings.parent.createSync(recursive: true);
    settings.writeAsStringSync(flutter);
  } on FileSystemException {
    stderr.writeln(
      'Khong luu duoc vi tri Flutter, nhung demo van co the chay.',
    );
  }
}

Future<String?> chooseFlutter() async {
  stdout.writeln('Chua tu tim thay Flutter SDK.');
  stdout.writeln('Chon thu muc Flutter da cai, vi du D:\\flutter.');
  stdout.writeln('Chi can chon mot lan; cac lan sau chuong trinh se nho.');
  final windows = Platform.environment['SystemRoot'];
  final powershell = windows == null
      ? null
      : File('$windows/System32/WindowsPowerShell/v1.0/powershell.exe');
  if (powershell != null && powershell.existsSync()) {
    try {
      // Hộp chọn thư mục chuẩn của Windows; không tải hay cài phần mềm.
      final result = await Process.run(
        powershell.path,
        [
          '-NoProfile',
          '-STA',
          '-Command',
          r'''[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
Add-Type -AssemblyName System.Windows.Forms
$picker = New-Object System.Windows.Forms.FolderBrowserDialog
$picker.Description = 'Chon thu muc Flutter SDK (co bin\flutter.bat)'
$picker.ShowNewFolderButton = $false
try {
  if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    [Console]::WriteLine($picker.SelectedPath)
  }
} finally { $picker.Dispose() }''',
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      if (result.exitCode == 0) {
        final selection = (result.stdout as String).trim();
        if (selection.isEmpty) return null;
        final found = flutterAt(selection);
        if (found != null) return found;
        stderr.writeln('Thu muc vua chon khong co bin\\flutter.bat.');
      }
    } on ProcessException {
      // Nếu không mở được hộp chọn, cho nhập đường dẫn ngay trong cửa sổ.
    }
  }
  if (!stdin.hasTerminal) return null;
  stdout.writeln('Dan duong dan thu muc Flutter SDK vao day roi nhan Enter:');
  final selection = stdin.readLineSync();
  return selection == null ? null : flutterAt(selection);
}

Future<String?> findOnPath(String name) async {
  final windows = Platform.environment['SystemRoot'];
  final where = windows == null ? 'where.exe' : '$windows/System32/where.exe';
  final lookup = await Process.run(where, [name]);
  if (lookup.exitCode == 0) {
    final files = (lookup.stdout as String)
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((path) => path.isNotEmpty && File(path).existsSync())
        .toList();
    // SDK cũng có script "flutter" dành cho Bash; trên Windows dùng .bat.
    if (name == 'flutter') {
      for (final file in files) {
        if (file.toLowerCase().endsWith('.bat')) return file;
      }
    }
    for (final file in files) {
      if (RegExp(
        r'\.(exe|bat|cmd|com)$',
        caseSensitive: false,
      ).hasMatch(file)) {
        return file;
      }
    }
  }
  return null;
}

Future<String?> findGit(String flutter) async {
  final onPath = await findOnPath('git');
  if (onPath != null) return onPath;
  final sdk = File(flutter).parent.parent;
  final environment = Platform.environment;
  final candidates = <String>[
    for (final name in ['ProgramW6432', 'ProgramFiles', 'ProgramFiles(x86)'])
      if (environment[name] != null) '${environment[name]}/Git/cmd/git.exe',
    if (environment['LOCALAPPDATA'] != null)
      '${environment['LOCALAPPDATA']}/Programs/Git/cmd/git.exe',
    if (environment['USERPROFILE'] != null) ...[
      '${environment['USERPROFILE']}/scoop/apps/git/current/cmd/git.exe',
      // Git đi kèm runtime Codex, nếu máy này đã có; không tải hay cài gì.
      '${environment['USERPROFILE']}/.cache/codex-runtimes/'
          'codex-primary-runtime/dependencies/native/git/cmd/git.exe',
    ],
    '${sdk.path}/bin/mingit/cmd/git.exe',
    '${sdk.parent.path}/mingit/cmd/git.exe',
    '${sdk.parent.path}/Git/cmd/git.exe',
  ];
  for (final path in candidates) {
    if (File(path).existsSync()) return File(path).absolute.path;
  }
  return null;
}

Map<String, String> childEnvironment({
  required String flutter,
  required String git,
}) {
  // Windows không phân biệt hoa/thường trong tên biến môi trường.
  // Chuẩn hóa để tránh tạo đồng thời Path và PATH rồi ghi đè nhầm nhau.
  final result = <String, String>{
    for (final entry in Platform.environment.entries)
      entry.key.toUpperCase(): entry.value,
  };
  result['PATH'] = [
    File(git).parent.path,
    File(flutter).parent.path,
    if (result['PATH']?.isNotEmpty ?? false) result['PATH']!,
  ].join(';');
  final sdk = File(flutter).parent.parent;
  final bundledCache = Directory('${sdk.parent.path}/pub-cache');
  if ((result['PUB_CACHE']?.isEmpty ?? true) && bundledCache.existsSync()) {
    result['PUB_CACHE'] = bundledCache.absolute.path;
  }
  // Chỉ áp dụng cho tiến trình Flutter được mở, không sửa PATH của Windows.
  return result;
}

void fail(String message, {bool wait = true}) {
  stderr.writeln('\n$message');
  stderr.writeln('\nNhan Enter de dong cua so.');
  if (wait && stdin.hasTerminal) stdin.readLineSync();
  exitCode = 1;
}
