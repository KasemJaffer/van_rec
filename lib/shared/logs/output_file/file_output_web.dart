import 'dart:convert';

import 'package:logger/logger.dart';

/// Writes the log output to a file and prints it on the console
class FileOutput extends LogOutput {
  final String filePath;
  final bool overrideExisting;
  final Encoding encoding;

  FileOutput({
    required this.filePath,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  void output(OutputEvent event) {}
}
