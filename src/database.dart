import 'package:cli_util/cli_logging.dart' as CliUtil;
import 'package:dcli/dcli.dart';

import 'configuration/config.dart';
import 'util/console-helper.dart';
import 'util/logger.dart';
import 'wp-cli/wp-cli-interface.dart';

class DatabaseBackup {
  Config config;

  WpCli wpCli;

  final Logger logger = Logger();

  DatabaseBackup(this.config, this.wpCli);

  backup() {
    logger.debug('Creating database backup...');

    String filename = '${config.projectDirectory}/backup/db-${ConsoleHelper.getDateSlug()}.mysql';
    String phpBinary = 'php';
    String wpBinary = wpCli.byType(config.wpBinaryType)!;

    if (config.usePhpWrapper) {
      phpBinary = 'php-wrapper';
    }

    ConsoleHelper.checkWpBinary(wpBinary);

    String exportCommand = 'db export --path="${config.projectDirectory}/public/wordpress" $filename';
    CliUtil.Logger progressFactory = CliUtil.Logger.standard();
    CliUtil.Progress progress = progressFactory.progress('Exporting');

    try {
      ConsoleHelper().userdo(
          '$phpBinary $wpBinary $exportCommand', config.backupUser);
      progress.finish(showTiming: true);
    } catch (e) {
      progress.finish(showTiming: false);
      logger.error('Database export failed.');
      logger.debug(e.toString());
      return;
    }

    logger.debug('Database exported. Compressing...');
    progress = progressFactory.progress('Compressing');
    ConsoleHelper().userdo('gzip -9 "$filename"');

    progress.finish(showTiming: true);
    logger.debug('Done: Created database backup at $filename.gz.');
    logger.log(green('Database backup created.'));
  }

  restore() {
    Logger().log('Database restoration not implemented yet.');
  }
}
