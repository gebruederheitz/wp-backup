import 'dart:io';

import 'package:cli_util/cli_logging.dart' as CliUtil;
import 'package:dcli/dcli.dart';
import 'package:slugify/slugify.dart';

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

    String base = config.projectDirectory!;
    String slug = ConsoleHelper.getDateSlug();
    String comment = config.comment != null ? '--' + slugify(config.comment!) : '';
    String filename = "$base/backup/userdata-$slug$comment.zip";
    String zipOptions = "-9 -r -p";

    // Quiet zip output, unless in verbose mode
    if (config.verbose) {
      zipOptions += ' -dc';
    } else {
      // zipOptions += ' -q -dg';
      zipOptions += ' -q';
    }

    try {
      ConsoleHelper().userdoStart(
          'zip $zipOptions "$filename" .',
          '${config.projectDirectory}/userdata'
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
      ConsoleHelper().userdo('unzip -q -d $tempPath ${backupToRestore.path}');
      progress.finish(showTiming: true);

      progress = progressFactory.progress('Moving files into place');
      String targetPath = join(config.projectDirectory!, 'userdata');
      String conveniencePath = join(config.projectDirectory!, 'userdata-previous');

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
