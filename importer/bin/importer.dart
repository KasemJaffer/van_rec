import 'dart:io';

import 'package:importer/importer.dart';
import 'package:supabase/supabase.dart';
import 'package:args/args.dart';
import 'package:dotenv/dotenv.dart';

Importer get importer {
  var env = DotEnv()..load();
  return Importer(SupabaseClient(
    env['SUPABASE_URL']!,
    env['SUPABASE_KEY']!,
  ));
}

void main(List<String> arguments) async {
  exitCode = 0;
  final parser = ArgParser();
  final argResults = parser.parse(arguments);
  final action = argResults.rest.first;

  if (action == 'a') {
    await importer.importActivities();
  } else if (action == 'c') {
    await importer.importCenters();
  } else if (action == 'e') {
    await importer.importEvents();
  } else {
    print("Action not supported.");
  }

  print("Finished.");
  exit(0);
}
