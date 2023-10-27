import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';

/// Writes the log output to a file and prints it on the console
class FileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;
  IOSink? _sink;

  // Regular Expression pattern for all possible types of ANSI escape
  // sequences in a [String].
  static final _ansiPattern = RegExp([
    '[\\u001B\\u009B][[\\]()#;?]*(?:(?:(?:[a-zA-Z\\d]*(?:;[-a-zA-Z\\d\\/#&.:=?%@~_]*)*)?\\u0007)',
    '(?:(?:\\d{1,4}(?:;\\d{0,4})*)?[\\dA-PR-TZcf-ntqry=><~]))'
  ].join('|'));

  FileOutput({
    required String filePath,
    this.overrideExisting = false,
    this.encoding = utf8,
  }) : file = File(filePath);

  @override
  Future<void> init() async {
    _sink = file.openWrite(
      mode: overrideExisting ? FileMode.writeOnly : FileMode.writeOnlyAppend,
      encoding: encoding,
    );
  }

  @override
  void output(OutputEvent event) {
    // Remove all ANSI sequences from logs file.
    final lines = event.lines.join('\n').replaceAll(_ansiPattern, '');
    _sink?.write(lines);
    _sink?.writeln();
  }

  @override
  Future<void> destroy() async {
    await _sink?.flush();
    await _sink?.close();
  }
}
