import 'dart:html' as html;

Future<void> replaceBrowserUrl(String path) async {
  final uri = Uri.parse(path);
  html.window.history.replaceState(null, '', uri.path);
}
