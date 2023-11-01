import 'dart:io';

import 'package:importer/importer_impl.dart';
import 'package:supabase/supabase.dart';
import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart';

/// Getter method to obtain an instance of the ImporterImpl class,
/// configured with Supabase credentials from .evn file
ImporterImpl get importer {
  var env = DotEnv()..load();
  return Importer(SupabaseClient(
    env['SUPABASE_URL']!,
    env['SUPABASE_KEY']!,
  ));
}

/// Main method that processes command-line arguments and initiates the appropriate import operation.
///
/// [arguments] - The list of command-line arguments passed to the application.
Future<void> main(List<String> arguments) async {
  exitCode = 0;
  final parser = ArgParser();

  // Add a flag for 'help' and description.
  parser.addFlag('help', abbr: 'h', help: 'Prints usage information.');

  // Add a list of available actions and their descriptions.
  final availableActions = {
    'a': 'Import Activities',
    'c': 'Import Centers',
    'e': 'Import Events',
  };

  // Add options for each available action with custom descriptions.
  for (final action in availableActions.keys) {
    parser.addFlag(
      action,
      abbr: action,
      help: availableActions[action],
    );
  }

  final ArgResults argResults;
  try {
    argResults = parser.parse(arguments);
  } on FormatException catch (e) {
    print(e.message);
    print(parser.usage);
    return;
  }

  // Check if the 'help' flag is present.
  if (argResults['help']) {
    print(parser.usage);
    return;
  }

  // Get the action selected by the user.
  String? action;
  for (final key in availableActions.keys) {
    if (argResults[key] == true) {
      action = key;
      break;
    }
  }

  if (action == null) {
    print("Action not supported.");
    print(parser.usage);
    return;
  }

  // Perform the selected action.
  if (action == 'a') {
    await importer.importActivities();
  } else if (action == 'c') {
    await importer.importCenters();
  } else if (action == 'e') {
    await importer.importEvents();
  }

  print("Finished.");
  exit(0);
}
