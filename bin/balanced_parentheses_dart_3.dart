import 'dart:io';

void main() {
  print(areParenthesesBalanced("()()(())()(()())()(((()()))())((((((()))))))"));
}

bool areParenthesesBalanced(String s) {
  final valid = RegExp(r'^[\(\)]*$').hasMatch(s);
  if (!valid) return false;

  final program = '''
extension on () {
  () call([()? _]) => _ ?? ();
}

void main() {
  final _ = $s;
}
''';

  final file = File(
    Directory.systemTemp.createTempSync().path +
        Platform.pathSeparator +
        'main.dart',
  )..writeAsStringSync(program);
  final result = Process.runSync('dart', ['run', file.path]);

  return result.exitCode == 0;
}
