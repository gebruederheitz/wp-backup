import 'dart:convert';
import 'dart:io';
import 'package:dcli/dcli.dart';

import 'argument-parser.dart';
import 'configuration/config.dart';
import 'configuration/wizard.dart';
import 'database.dart';
import 'userdata.dart';
import 'util/console-helper.dart';
import 'util/exit-codes.dart';
import 'util/logger.dart';
import 'util/test-directory.dart';
import '../lib/src/dcli/resource/generated/resource_registry.g.dart';

const debug = false;
var parser;

class WpBackup {
  static void run(List<String> args) {
    ArgumentParser parser = ArgumentParser();
    var options = parser.parseOptions(args);
    Config config = Config.fromOptions(options);

    if (config.wantsHelp()) {
      showHelp(parser);
      exit(ExitCodes.ok);
    }

    showVersion();
    if (config.wantsVersion()) {
      exit(ExitCodes.ok);
    }

    if (config.noInteraction) {
      config.setNoInteractionDefaults();
    } else {
      Wizard wizard = Wizard(config);
      config = wizard.run();
    }

    if (config.verbose || debug) {
      Logger().setVerbose(true);
    }

    Logger l = Logger();
    l.debug('Command: ${config.mode}');
    l.debug('Operation: ${config.operation}');
    l.debug('Verbose: ${config.verbose}');
    l.debug('Project directory: ${config.projectDirectory}');
    ConsoleHelper(config.backupUser);

    if (config.mode == null ||
        ![Commands.restore, Commands.backup].contains(config.mode)) {
      // if no mode is set or the mode is invalid, exit with an error,
      // _unless_ the -c or -C flags are set
      if (config.useConfigFile) {
        config.mode = Commands.backup;
      } else {
        l.error('Invalid command. Try "wp-backup -h" for usage information.');
        exit(ExitCodes.commandNotFound);
      }
    }
    testDirectory(config.projectDirectory);

    if ([OperationType.all, OperationType.database]
        .contains(config.operation)) {
      DatabaseBackup dbb = DatabaseBackup(config);
      if (config.mode == Commands.backup) {
        dbb.backup();
      } else {
        dbb.restore();
      }
    }

    if ([OperationType.all, OperationType.userdata]
        .contains(config.operation)) {
      UserdataBackup udb = UserdataBackup(config);
      if (config.mode == Commands.backup) {
        udb.backup();
      } else {
        udb.restore();
      }
    }
  }

  static void showVersion() {
    final String resourcePath = 'appinfo.json';
    final path = join(Directory.systemTemp.path, resourcePath);
    final appinfoResource = ResourceRegistry.resources[resourcePath]!;
    appinfoResource.unpack(join(path));

    final File appInfoFile = new File(path);
    final String contents = appInfoFile.readAsStringSync();
    final Map parsedContent = jsonDecode(contents);
    final String version = parsedContent['version'];

    print(blue('wp-backup by /gebrüderheitz') + ' v$version');
    print('');
  }

  static void showHelp(ArgumentParser parser) {
    showVersion();
    print('''
Wordpress deployments backup utility: Create backups for the database and
userdata (plugins, languages, uploads) of a Wordpress instance.

Usage:
  wp-backup
  wp-backup [backup|restore] [-a|D|U] [-n] [-V] [-P] [-p php_binary] 
            [-d directory] [-u user]
            [-w bundled|path|directory | -W wp_cli_path]
  wp-backup [backup|restore] [-o operation] [-n] [-V] [-P] [-p php_binary] 
            [-d directory] [-u user]  
            [-w bundled|path|directory | -W wp_cli_path]     
  wp-backup [-h|v]
  
    ''');
    parser.printUsage();
    print('''
      
Backups will target \$DIR/userdata and the WP instance at \$DIR/public. They 
will be zipped and written to \$DIR/backup/.
The program requires GNU coreutils (realpath etc.), zip, gzip, mysqldump to exist
on the system.

    ''');
  }
}
