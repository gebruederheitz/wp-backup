import 'dart:io';

import 'package:cli_util/cli_logging.dart' as CliUtil;
import 'package:dcli/dcli.dart';
import 'package:slugify/slugify.dart';

import 'configuration/config.dart';
import 'util/archiver.dart';
import 'util/confirmation.dart';
import 'util/console-helper.dart';
import 'util/exit-codes.dart';
import 'util/file-selector.dart';
import 'util/logger.dart';
import 'wp-cli/wp-cli-interface.dart';

class DatabaseBackup {
  final CliUtil.Logger progressFactory = CliUtil.Logger.standard();
  final Logger logger = Logger();
  final Config config;
  final WpCli wpCli;

  late String phpBinary;
  late String wpBinary;

  DatabaseBackup(this.config, this.wpCli) {
    wpBinary = wpCli.byType(config.wpBinaryType)!;
    phpBinary = 'php';

    if (config.usePhpWrapper) {
      phpBinary = 'php-wrapper';
    }

    wpBinary = ConsoleHelper.checkWpBinary(wpBinary);
  }

  bool backup() {
    logger.debug('Creating database backup...');

    String base = config.projectDirectory!;
    String slug = ConsoleHelper.getDateSlug();
    String comment =
        config.comment != null ? '--' + slugify(config.comment!) : '';
    String filename = '$base/backup/db-$slug$comment.mysql';

    CliUtil.Progress progress = progressFactory.progress('Exporting');

    try {
      _executeDbOperation('export', filename);
      progress.finish(showTiming: true);
    } catch (e) {
      progress.finish(showTiming: false);
      logger.error('Database export failed.');
      logger.debug(e.toString());
      return false;
    }

    logger.debug('Database exported. Compressing...');
    progress = progressFactory.progress(
        'Compressing. This might take a while and you might not see the progress indicator spinning.');
    String archivePath = Archiver.gzipFile(filename);

    progress.finish(showTiming: true);
    logger.debug('Done: Created database backup at $archivePath.');
    logger.log(green('Database backup created.'));

    return true;
  }

  restore() {
    bool backupBeforeRestore = config.backupBeforeRestore;

    // wizard: create backup before restore?
    if (backupBeforeRestore) {
      config.comment = 'before-restore';
      bool success = backup();
      if (!success) {
        logger.error('Pre-restoration backup failed. Aborting.');
        exit(ExitCodes.error);
      }
    }

    File backupToRestore = FileSelector(
      join(config.projectDirectory!, 'backup'),
      filter: 'db-',
      label: 'Please select a database backup to restore:',
    ).ask();

    if (Confirmation.confirm(
        'Are you certain you want to restore the backup "$backupToRestore"? This operation might lead to data loss.')) {
      Logger().debug('Will restore $backupToRestore');

      CliUtil.Progress progress = progressFactory.progress(
          'Unpacking database backup archive. This might take a while and you might not see the progress indicator spinning.');
      String restoredPath = Archiver.gunzip(backupToRestore);
      progress.finish(showTiming: true);

      progress = progressFactory.progress('Restoring database');

      try {
        _executeDbOperation('import', restoredPath);
        progress.finish(showTiming: true);
      } catch (e) {
        progress.finish(showTiming: false);
        logger.error('Database import failed.');
        logger.debug(e.toString());
        File(restoredPath).deleteSync();
        return;
      }

      File(restoredPath).deleteSync();
      logger.debug('Done: Restored database backup from $backupToRestore.');
      logger.log(green('Database backup restored.'));
    }
  }

  _executeDbOperation(String operation, String filename) {
    ConsoleHelper().userdo(
        '$phpBinary $wpBinary db $operation --path="${config.projectDirectory}/public/wordpress" $filename',
        config.backupUser);
  }
}
