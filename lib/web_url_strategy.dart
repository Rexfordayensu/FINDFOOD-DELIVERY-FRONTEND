import 'package:flutter_web_plugins/flutter_web_plugins.dart' as real;

void setUrlStrategy(dynamic strategy) {
  real.setUrlStrategy(strategy);
}

class PathUrlStrategy extends real.PathUrlStrategy {}
