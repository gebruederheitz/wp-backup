import 'dart:io';

import 'package:dcli/dcli.dart';

import '../util/logger.dart';

enum WpCliType {
  bundled,
  directory,
  path,
  custom,
}

abstract class WpCli {
  final String path = '';

  final bool isBundled = false;

  String customPath;

  String byType(WpCliType type) {
    switch (type) {
      case WpCliType.bundled:
        if (isBundled) {
          return path;
        }
        Logger().error('This version of wp-backup does not contain a bundled wp-cli. Please use another --wp-type.');
        return exit(2);
      case WpCliType.directory:
        return join(File(Platform.script.path).parent.path, getFilename());
      case WpCliType.custom:
        return customPath;
      case WpCliType.path:
      default:
        return getFilename();

    }
  }

  String getFilename() {
    return 'wp';
  }
}
