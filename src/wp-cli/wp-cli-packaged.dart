import 'dart:io';

import 'package:dcli/dcli.dart';

import '../util/logger.dart';
import 'wp-cli-interface.dart' as WpCliInterface;
import '../../lib/src/dcli/resource/generated/resource_registry.g.dart';

const String resourcePath = 'wp';
const String filename = 'wp-backup-wp-cli';

class WpCli extends WpCliInterface.WpCli {
  final path = join(Directory.systemTemp.path, filename);

  final bool isBundled = true;

  WpCli() {
    _unpack(path);
  }

  static void _unpack(String path) {
    Logger l = Logger();
    final wpCliResource = ResourceRegistry.resources[resourcePath]!;

    if (calculateHash(path).hexEncode() != wpCliResource.checksum) {
      l.debugContinuable('Unpacking bundled wp-cli...');
      wpCliResource.unpack(join(path));
      try {
        'chmod u+x $path'.run;
      } catch (e) {
        l.debug(red('Failed') +
            ' to make wp-cli executable. If the backup fails, this might be the reason.');
        l.debug(e.toString());
        return;
      }

      l.debugContinued(' Ok.');
    } else {
      l.debug(
          'Current version of wp-cli already exists, skipping unpack operation.');
    }
  }
}
