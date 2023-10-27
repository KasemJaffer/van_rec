import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:van_rec/data/ds/data_source.dart';
import 'package:van_rec/router.dart';
import 'package:van_rec/shared/extensions.dart';
import 'package:van_rec/shared/providers/providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:van_rec/shared/logs/logger.dart';
import 'package:van_rec/ui/vm/home_screen_vm.dart';
import 'data/ds/supabase_data_source.dart';
import 'data/repo/event_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  initializeLogger();

  // Initialize Supabase
  await supa.Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_KEY']!,
  );
  if (kIsWeb) {
    usePathUrlStrategy();
  }

  // TODO: Remove this line if you don't need it.
  //  Only used for google analytics. You can generate [DefaultFirebaseOptions]
  //  by running `flutterfire configure`
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MyApp(
    prefs: prefs,
    dataSource: SupbaseDataSource(supa.Supabase.instance.client),
  ));
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  final DataSource dataSource;

  const MyApp({required this.prefs, required this.dataSource, super.key});

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Holds the current app theme
  late final _settings = ValueNotifier(
    ThemeSettings(
      sourceColor: Colors.green,
      themeMode: ThemeMode.dark,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(
          create: (_) => AppState(widget.prefs),
          lazy: false,
        ),
        Provider.value(value: widget.dataSource),
        Provider<EventRepository>(
          create: (context) => EventRepository(context.read<DataSource>()),
        ),
        ChangeNotifierProvider<HomeScreenVM>(
          create: (context) => HomeScreenVM(context.read<EventRepository>()),
        ),
        Provider<AppRouter>(
          create: (context) => AppRouter(context.read<AppState>()),
        ),
      ],
      child: DynamicColorBuilder(
        builder: (lightDynamic, darkDynamic) => ThemeProvider(
          lightDynamic: lightDynamic,
          darkDynamic: darkDynamic,
          settings: _settings,
          child: NotificationListener<ThemeSettingChange>(
            onNotification: (notification) {
              _settings.value = notification.settings;
              return true;
            },
            child: ValueListenableBuilder<ThemeSettings>(
              valueListenable: _settings,
              builder: (context, value, _) {
                final goRouter = context.read<AppRouter>().router;
                final theme = ThemeProvider.of(context);
                final textTheme = context.textTheme;
                final light =
                    theme.light(_settings.value.sourceColor, textTheme);
                final dark = theme.dark(_settings.value.sourceColor, textTheme);
                final current =
                    theme.themeMode() == ThemeMode.dark ? dark : light;
                return MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  title: 'VanRec',
                  theme: light,
                  darkTheme: dark,
                  themeMode: theme.themeMode(),
                  routeInformationProvider: goRouter.routeInformationProvider,
                  routeInformationParser: goRouter.routeInformationParser,
                  routerDelegate: goRouter.routerDelegate,
                  color: current.colorScheme.surface,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
