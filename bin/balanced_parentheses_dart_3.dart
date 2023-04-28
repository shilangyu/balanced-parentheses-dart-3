import 'dart:io';

void main() {
  print(areParenthesesBalanced("()()(())()(()())()(((()()))())((((((()))))))"));
}

bool areParenthesesBalanced(String s) {
  // sanity check if the input is up to assumptions
  if (!RegExp(r'^[\(\)]*$').hasMatch(s)) return false;

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
  final result = Process.runSync('dart', ['analyze', file.path]);

  return result.exitCode == 0;
}
