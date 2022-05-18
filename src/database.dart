import 'dart:io';

import 'package:cli_util/cli_logging.dart' as CliUtil;
import 'package:dcli/dcli.dart';
import 'package:slugify/slugify.dart';

import 'configuration/config.dart';
import 'configuration/yaml-configuration.dart';
import 'model/database-configuration.dart';
import 'util/archiver.dart';
import 'util/confirmation.dart';
import 'util/console-helper.dart';
import 'util/database/dotenv-reader.dart';
import 'util/database/yaml-reader.dart';
import 'util/exit-codes.dart';
import 'util/file-selector.dart';
import 'util/logger.dart';

class DatabaseBackup {
  final CliUtil.Logger progressFactory = CliUtil.Logger.standard();
  final Logger logger = Logger();
  final Config config;
  late final DatabaseConfiguration dbConfig;
  late String mysqldump;
  late String mysql;

  DatabaseBackup(this.config) {
    DatabaseConfiguration? dbConfig = null;
    if (this.config.configurationFile is YamlConfiguration) {
      Logger().debug('Checking YAML configuration for database config...');
      dbConfig = YamlReader(this.config.configurationFile!.yaml).read();
    }

    if (dbConfig == null) {
      Logger().debug('Trying to find Dotenv file...');
      dbConfig = DotenvReader(this.config.projectDirectory).read();
    }

    if (dbConfig == null) {
      Logger().error('No database configuration found.');
      exit(ExitCodes.error);
    }

    logger.debugContinuable('Checking for mysql binaries...');
    _checkMysqlBinaries();
    logger.debugContinued(' Done.');

    this.dbConfig = dbConfig;
  }

  bool backup() {
    logger.log('Starting database backup.');

    final String filename = _getFileName();
    final bool success = _dumpDatabase(filename);
    if (!success) return false;

    logger.debug('Database exported. Compressing...');
    final String archivePath = _compressDbDump(filename);

    logger.debug('Done: Created database backup at $archivePath.');
    logger.log(green('Database backup created.'));

    return true;
  }

  restore() {
    logger.log('Starting database backup restoration.');
    _backupBeforeRestore();

    File backupToRestore = FileSelector(
      join(config.projectDirectory, 'backup'),
      filter: 'db-',
      label: 'Please select a database backup to restore:',
    ).ask();

    if (Confirmation.confirm(
        'Are you certain you want to restore the backup "$backupToRestore"? This operation might lead to data loss.')) {
      Logger().debug('Will restore $backupToRestore');

      CliUtil.Progress progress;
      File restoredBackup;
      bool isTempFile = false;

      if (backupToRestore.path.endsWith('.gz')) {
        progress = progressFactory.progress(
            'Unpacking database backup archive. This might take a while and you might not see the progress indicator spinning.');
        restoredBackup = Archiver.gunzip(backupToRestore);
        isTempFile = true;
        progress.finish(showTiming: true);
      } else {
        restoredBackup = backupToRestore;
      }

      progress = progressFactory.progress('Restoring database');

      try {
        _restoreDatabase(restoredBackup);
        progress.finish(showTiming: true);
      } catch (e) {
        progress.finish(showTiming: false);
        logger.error('Database import failed.');
        logger.debug(e.toString());
        restoredBackup.deleteSync();
        return;
      }

      if (isTempFile) {
        restoredBackup.deleteSync();
      }
      logger.debug('Done: Restored database backup from $backupToRestore.');
      logger.log(green('Database backup restored.'));
    }
  }

  _backupBeforeRestore() {
    if (config.backupBeforeRestore) {
      config.comment = 'before-restore';
      bool success = backup();
      if (!success) {
        logger.error('Pre-restoration backup failed. Aborting.');
        exit(ExitCodes.error);
      }
    }
  }

  _checkMysqlBinaries() {
    final m = which('mysql');
    final md = which('mysqldump');
    if (m.notfound || md.notfound) {
      logger.error(
          'No mysql or mysqldump binary found. Make sure it is installed on the system you\'re creating backups from.');
      exit(ExitCodes.error);
    }

    mysqldump = md.path!;
    mysql = m.path!;
  }

  String _compressDbDump(String filename) {
    final CliUtil.Progress progress = progressFactory.progress(
        'Compressing. This might take a while and you might not see the progress indicator spinning.');
    String archivePath = Archiver.gzipFile(filename);
    progress.finish(showTiming: true);

    return archivePath;
  }

  bool _dumpDatabase(String filename) {
    final CliUtil.Progress progress = progressFactory.progress('Exporting');

    try {
      ConsoleHelper().userdoStart(
          '$mysqldump -h ${dbConfig.host} -u ${dbConfig.user} --password=${dbConfig.password} -P ${dbConfig.port} --result-file=$filename ${dbConfig.database}',
          user: config.backupUser);
      progress.finish(showTiming: true);
      return true;
    } catch (e) {
      progress.finish(showTiming: false);
      logger.error('Database export failed.');
      logger.debug(e.toString());
      return false;
    }
  }

  String _getFileName() {
    String base = config.projectDirectory;
    String slug = ConsoleHelper.getDateSlug();
    String comment =
        config.comment != null ? '--' + slugify(config.comment!) : '';
    return '$base/backup/db-$slug$comment.mysql';
  }

  _restoreDatabase(File backup) {
    ConsoleHelper().userdo(
        '$mysql -h ${dbConfig.host} -u ${dbConfig.user} --password=${dbConfig.password} -P ${dbConfig.port} -e "source ${backup.path}" ${dbConfig.database}',
        config.backupUser);
  }
}
