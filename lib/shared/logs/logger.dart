import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'output_file/output_file.dart' as otf;

Logger? _logger;
String? _logFile;

final _printer = PrettyPrinter(
  methodCount: 0,
  errorMethodCount: 8,
  lineLength: 120,
  colors: defaultTargetPlatform != TargetPlatform.iOS,
  printEmojis: false,
  printTime: false,
  noBoxingByDefault: true,
);

String? get logFile => _logFile;

Logger get logger {
  if (_logger == null) {
    throw Exception(
        'Logger called before initialization. Initialize it first using the method [initializeLogger]');
  }
  return _logger!;
}

void initializeLogger([String? logFile]) {
  _logFile = logFile;
  final output = MultiOutput([
    ConsoleOutput(),
    if (logFile != null) otf.FileOutput(filePath: logFile, overrideExisting: true),
  ]);
  _logger = Logger(printer: _printer, output: output, filter: _MyFilter());
}

void resetLogger() {
  _logger?.close();
  _logger = null;
  return initializeLogger(_logFile);
}

class _MyFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    return true;
  }
}
