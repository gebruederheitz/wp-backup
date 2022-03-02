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
import 'wp-cli/wp-cli-interface.dart';

const version = '1.0.0';
const debug = false;
var parser;

class WpBackup {
  static void run(List<String> args, WpCli wpCli) {
    ArgumentParser parser = ArgumentParser();
    var options = parser.parseOptions(args);
    Config config = Config.fromOptions(options, wpCli);


    if (config.wantsHelp()) {
      showHelp(parser);
      exit(ExitCodes.ok);
    }

    if (config.wantsVersion()) {
      showVersion();
      exit(ExitCodes.ok);
    }

    if (config.wantsNoInteraction()) {
      config.setNoInteractionDefaults(wpCli);
    } else {
      Wizard wizard = Wizard(config, wpCli);
      config = wizard.run();
    }

    if (config.verbose || debug) {
      Logger().setVerbose(true);
    }

    Logger l = Logger();
    l.debug('Command: ${config.command}');
    l.debug('Operation: ${config.operation}');
    l.debug('Verbose: ${config.verbose}');
    l.debug('WP-CLI type: ${config.wpBinaryType}');
    l.debug('Custom WP-CLI: ${config.wpBinary}');
    l.debug('Project directory: ${config.projectDirectory}');
    ConsoleHelper(config.backupUser);

    showVersion();
    if (config.command == null || ![Commands.restore, Commands.backup].contains(config.command)) {
      l.error('Invaid command. Try "wp-backup -h" for usage information.');
      exit(ExitCodes.commandNotFound);
    }
    testDirectory(config.projectDirectory);

    if ([OperationType.all, OperationType.database]
        .contains(config.operation)) {
      DatabaseBackup dbb = DatabaseBackup(config, wpCli);
      if (config.command == Commands.backup) {
        dbb.backup();
      } else {
        dbb.restore();
      }
    }

    if ([OperationType.all, OperationType.userdata].contains(config.operation)) {
      UserdataBackup udb = UserdataBackup(config);
      if (config.command == Commands.backup) {
        udb.backup();
      } else {
        udb.restore();
      }
    }
  }

  static void showVersion() {
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
