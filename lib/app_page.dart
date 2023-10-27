enum AppPage {
  home('/'),
  event('/event');

  final String path;

  String get name => path.split('/').last;

  const AppPage(this.path);
}
