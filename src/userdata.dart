import 'package:cli_util/cli_logging.dart' as CliUtil;
import 'package:dcli/dcli.dart';

import 'configuration/config.dart';
import 'util/console-helper.dart';
import 'util/logger.dart';

class UserdataBackup {
  Config config;

  UserdataBackup(this.config);

  void backup() {
    Logger logger = Logger();
    CliUtil.Logger progressFactory = CliUtil.Logger.standard();

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
      return;
    }

    var fileSize = ('du -sch $filename' | 'grep -P "^[^\\s]+').toList()[0];
    logger.debug("Done: Created userdata backup at $filename ($fileSize).");
    logger.log(green("Userdata backup created."));
  }

  restore() {
    Logger().log('Userdata restoration not implemented yet.');
  }
}
