import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:cli_util/cli_logging.dart' as CliUtil;
import 'package:dcli/dcli.dart';
import 'package:slugify/slugify.dart';
import 'package:progress_bar/progress_bar.dart';

import 'configuration/config.dart';
import 'util/confirmation.dart';
import 'util/console-helper.dart';
import 'util/exit-codes.dart';
import 'util/file-selector.dart';
import 'util/logger.dart';
import 'util/zip-with-progress.dart';

class UserdataBackup {
  final Config config;
  final Logger logger = Logger();
  final CliUtil.Logger progressFactory = CliUtil.Logger.standard();

  UserdataBackup(this.config);

  /// @return true indicates success.
  bool backup() {
    logger.debug("Backing up userdata directory...");
    logger.log('Creating ZIP archive of userdata. This might take a while.');

    final String base = config.projectDirectory;
    final String slug = ConsoleHelper.getDateSlug();
    final String comment =
        config.comment != null ? '--' + slugify(config.comment!) : '';
    final String filename = "$base/backup/userdata-$slug$comment.zip";
    final Directory dir =
        new Directory(join(config.projectDirectory, 'userdata'));
    final ProgressBar progress =
        new ProgressBar('[:bar] :percent (ETA :etas)', total: 100, width: 50);

    try {
      ZipFileEncoderWithProgress().zipDirectory(dir,
          filename: filename, level: Deflate.BEST_COMPRESSION,
          progressCallback: (ZipProgress zipProgress) {
        progress.update(zipProgress.percentage);
      });
      logger.log(green('Done.'), false);
    } catch (e) {
      logger.error('Userdata backup failed!');
      logger.debug(e.toString());
      return false;
    }

    var fileSize = ('du -sch $filename' | 'grep -P "^[^\\s]+').toList()[0];
    logger.debug("Done: Created userdata backup at $filename ($fileSize).");
    logger.log(green("Userdata backup created."));
    return true;
  }

  restore() {
    bool backupBeforeRestore = config.backupBeforeRestore;

    if (backupBeforeRestore) {
      config.comment = 'before-restore';
      bool success = backup();
      if (!success) {
        logger.error('Pre-restoration backup failed. Aborting.');
        exit(ExitCodes.error);
      }
    }

    File backupToRestore = FileSelector(
      join(config.projectDirectory, 'backup'),
      filter: 'userdata-',
      label: 'Please select a userdata backup to restore:',
    ).ask();

    if (Confirmation.confirm(
        'Are you certain you want to restore the backup "$backupToRestore"? This operation might lead to data loss.')) {
      logger.debug('Will restore $backupToRestore');
      logger.log('Extracting archive');
      ProgressBar progressBar = new ProgressBar(
          '[:bar] :percent ETA :etas (:elapseds)',
          total: 100,
          width: 50);

      String tempPath = join(config.projectDirectory, 'userdata_restore');
      Directory tempDir = Directory(tempPath);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      final inputStream = InputFileStream(backupToRestore.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);
      extractArchiveToDiskWithProgress(archive, tempPath,
          progressCallback: (zipProgress) {
        progressBar.update(zipProgress.percentage);
      });

      final progress = progressFactory.progress('Moving files into place');
      String targetPath = join(config.projectDirectory, 'userdata');
      String conveniencePath =
          join(config.projectDirectory, 'userdata-previous');

      /* @FIXME: atomic "&&" operation seems impossible with dcli */
      ConsoleHelper().userdo('mv $targetPath $conveniencePath');
      ConsoleHelper().userdo('mv $tempPath $targetPath');
      Directory(conveniencePath).deleteSync(recursive: true);
      progress.finish(showTiming: true);

      logger.debug('Done: Restored userdata backup from $backupToRestore.');
      logger.log(green('Userdata backup restored.'));
    }
  }
}
