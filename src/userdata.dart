import 'dart:io';

import 'package:cli_util/cli_logging.dart' as CliUtil;
import 'package:dcli/dcli.dart';

import 'configuration/config.dart';
import 'util/confirmation.dart';
import 'util/console-helper.dart';
import 'util/exit-codes.dart';
import 'util/file-selector.dart';
import 'util/logger.dart';

class UserdataBackup {
  final Config config;
  final Logger logger = Logger();
  final CliUtil.Logger progressFactory = CliUtil.Logger.standard();

  UserdataBackup(this.config);

  /// @return true indicates success.
  bool backup() {
    logger.debug("Backing up userdata directory...");
    CliUtil.Progress progress = progressFactory.progress("Creating ZIP archive of userdata. This might take a while.");

    String filename = "${config.projectDirectory}/backup/userdata-${ConsoleHelper.getDateSlug()}.zip";
    String zipOptions = "-9 -r";

    // Quiet zip output, unless in verbose mode
    if (config.verbose) {
      zipOptions += ' -dc';
    } else {
      // zipOptions += ' -q -dg';
      zipOptions += ' -q';
    }

    try {
      ConsoleHelper().userdo(
          'zip $zipOptions "$filename" "${config.projectDirectory}/userdata'
      );
      progress.finish(showTiming: true);
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
    bool backupBeforeRestore = false;
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
      filter: 'userdata-',
      label: 'Please select a userdata backup to restore:',
    ).ask();

    if (Confirmation.confirm('Are you certain you want to restore the backup "$backupToRestore"? This operation might lead to data loss.')) {
      Logger().debug('Will restore $backupToRestore');
      CliUtil.Progress progress = progressFactory.progress('Extracting archive');

      String tempPath = join(config.projectDirectory!, 'userdata_restore');
      Directory tempDir = Directory(tempPath);
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      'unzip -d $tempPath $backupToRestore';
      progress.finish(showTiming: true);

      progress = progressFactory.progress('Moving files into place');
      String targetPath = join(config.projectDirectory!, 'userdata');
      String conveniencePath = join(config.projectDirectory!, 'userdata-previous');

      ConsoleHelper().userdo('mv $targetPath $conveniencePath && mv $tempDir $targetPath');
      Directory(conveniencePath).deleteSync(recursive: true);
      progress.finish(showTiming: true);

      logger.debug('Done: Restored userdata backup from $backupToRestore.');
      logger.log(green('Userdata backup restored.'));
    }
  }
}
