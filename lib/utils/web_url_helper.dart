import 'web_url_helper_stub.dart'
    if (dart.library.html) 'web_url_helper_web.dart' as implementation;

Future<void> replaceBrowserUrl(String path) async {
  await implementation.replaceBrowserUrl(path);
}
