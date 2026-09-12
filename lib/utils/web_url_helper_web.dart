// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<void> replaceBrowserUrl(String path) async {
  final uri = Uri.parse(path);
  html.window.history.replaceState(null, '', uri.path);
}
