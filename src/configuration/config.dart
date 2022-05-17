import 'dart:io';

import 'package:dcli/dcli.dart';

import '../util/logger.dart';
import '../wp-cli/wp-cli-interface.dart';

enum OperationType {
  all,
  database,
  userdata,
}

enum ConfigurationOption {
  help,
  version,
  projectDirectory,
  backupUser,
  verbose,
  usePhpWrapper,
  phpBinary,
  wpBinaryType,
  wpBinary,
  operation,
  operationAll,
  operationDb,
  operationUserdata,
  noInteraction,
  comment,
  backupBeforeRestore,
}

class OptionParameter {
  final String? separatorBefore;
  final String long;
  final String short;
  final defaultValue;
  final String? help;
  final String? valueHelp;

  const OptionParameter(
    this.long,
    this.short, {
    this.defaultValue = null,
    this.help = null,
    this.valueHelp = null,
    this.separatorBefore = null,
  });
}

const Map<ConfigurationOption, OptionParameter> OptionParameters =
    const <ConfigurationOption, OptionParameter>{
  ConfigurationOption.help: OptionParameter('help', 'h',
      separatorBefore: '--- General help & information --------',
      defaultValue: false,
      help: 'Show this help and exit.'),
  ConfigurationOption.version: OptionParameter(
    'version',
    'v',
    defaultValue: false,
    help: 'Display version and exit',
  ),
  ConfigurationOption.projectDirectory: OptionParameter(
    'directory',
    'd',
    valueHelp: '</path/to/project>',
    help: '''
The directory to run in. This is the directory that contains backup/, userdata/ 
and public/ directories. Defaults to the current working directory in 
no-interaction mode.
    ''',
  ),
  ConfigurationOption.verbose: OptionParameter(
    'verbose',
    'V',
    defaultValue: false,
    help: 'More output',
  ),
  ConfigurationOption.backupUser: OptionParameter(
    'user',
    'u',
    defaultValue: null,
    help: 'The user under which to operate.',
    valueHelp: '<username>',
  ),
  ConfigurationOption.noInteraction: OptionParameter(
    'no-interaction',
    'n',
    defaultValue: false,
    help:
        'Skip the wizard, do not ask questions. For scripts and CI applications.',
  ),
  ConfigurationOption.operation: OptionParameter(
    'operation',
    'o',
    help: 'Which backups to perform',
    valueHelp: 'database|userdata|all',
    separatorBefore: '--- Operation control -----------------',
  ),
  ConfigurationOption.operationAll: OptionParameter(
    'all',
    'a',
    defaultValue: false,
  ),
  ConfigurationOption.operationDb:
      OptionParameter('db', 'D', defaultValue: false),
  ConfigurationOption.operationUserdata:
      OptionParameter('userdata', 'U', defaultValue: false),
  ConfigurationOption.usePhpWrapper: OptionParameter(
    'php-wrapper',
    'P',
    separatorBefore: '--- Database backup settings ----------',
    defaultValue: false,
    help: '''
Instead of using a (custom) PHP binary, use php-wrapper instead (must be on the 
\$PATH).
    ''',
  ),
  ConfigurationOption.phpBinary:
      OptionParameter('php', 'p', defaultValue: null),
  ConfigurationOption.wpBinaryType: OptionParameter(
    'wp-cli-type',
    'w',
    valueHelp: 'bundled|path|directory',
    help: '''
Whether to use a wp-cli binary on the \$PATH, in the script directory or the 
bundled version (depending on version). For a custom path, use --wp--cli-path.
  ''',
  ),
  ConfigurationOption.wpBinary: OptionParameter(
    'wp-cli-path',
    'W',
    defaultValue: null,
    help: 'A custom wp-cli executable PHAR archive to use for DB exporting.',
    valueHelp: 'path-to-wp-cli.phar',
  ),
  ConfigurationOption.comment: OptionParameter(
    'comment',
    'c',
    separatorBefore: '--- Backup settings -------------------',
    defaultValue: null,
    help:
        'A comment or tag to append to the backup file (not available in restore mode).',
    valueHelp: '<tag-or-comment>',
  ),
  ConfigurationOption.backupBeforeRestore: OptionParameter(
    'backup-before',
    'b',
    separatorBefore: '--- Restore settings ------------------',
    defaultValue: false,
    help: 'Create a backup before restoring the selected one.',
  ),
};

class Config {
  String? mode;

  OperationType? operation;

  String? projectDirectory;

  String? backupUser;

  bool verbose = false;

  bool usePhpWrapper = false;

  WpCliType? wpBinaryType;

  String? wpBinary;

  String? phpBinary;

  String? comment;

  bool backupBeforeRestore = false;

  ArgResults options;

  Config.fromOptions(this.options, WpCli wpCli) {
    parseOperation();

    if (options.command?.name != null) {
      mode = options.command!.name;
    }

    if (getParameterValue(ConfigurationOption.projectDirectory) != null) {
      projectDirectory =
          getParameterValue(ConfigurationOption.projectDirectory);
    }

    if (getParameterValue(ConfigurationOption.verbose) == true) {
      verbose = true;
    }

    parseWpBinary(wpCli);
    if (getParameterValue(ConfigurationOption.usePhpWrapper)) {
      usePhpWrapper = true;
    }

    if (getParameterValue(ConfigurationOption.comment) != null) {
      comment = getParameterValue(ConfigurationOption.comment);
    }

    backupUser =
        getParameterValue(ConfigurationOption.backupUser) ?? 'whoami'.firstLine;

    if (getParameterValue(ConfigurationOption.backupBeforeRestore) == true) {
      backupBeforeRestore = true;
    }
  }

  parseOperation() {
    var operation = getParameterValue(ConfigurationOption.operation);
    if (operation != null) {
      var op = OperationType.values
          .firstWhere((element) => element.toString() == operation);
      this.operation = op;
    } else if (getParameterValue(ConfigurationOption.operationDb)) {
      this.operation = OperationType.database;
    } else if (getParameterValue(ConfigurationOption.operationUserdata)) {
      this.operation = OperationType.userdata;
    } else if (getParameterValue(ConfigurationOption.operationAll)) {
      this.operation = OperationType.all;
    }
  }

  parseWpBinary(WpCli wpCli) {
    if (getParameterValue(ConfigurationOption.wpBinaryType) != null) {
      String? providedType =
          getParameterValue(ConfigurationOption.wpBinaryType);
      if (providedType == 'bundled') {
        if (!wpCli.isBundled) {
          Logger().error(
              'This version of wp-backup does not contain a bundled wp-cli. Please use another --wp-type.');
          exit(2);
        }
        wpBinaryType = WpCliType.bundled;
      } else if (providedType == 'path') {
        wpBinaryType = WpCliType.path;
      } else if (providedType == 'directory') {
        wpBinaryType = WpCliType.directory;
      } else {
        Logger().error(
            'Invalid wp-cli type provided. Must be one of [bundled|path|directory].');
        exit(2);
      }
    } else if (getParameterValue(ConfigurationOption.wpBinary) != null) {
      wpBinaryType = WpCliType.custom;
      wpBinary = getParameterValue(ConfigurationOption.wpBinary);
      wpCli.customPath = wpBinary;
    }
  }

  static String getParameter(ConfigurationOption option) {
    return OptionParameters[option]!.long;
  }

  getParameterValue(ConfigurationOption option) {
    return this.options[Config.getParameter(option)];
  }

  hasOperation() {
    return this.operation != null;
  }

  setNoInteractionDefaults(WpCli wpCli) {
    if (projectDirectory == null) {
      projectDirectory = 'realpath .'.firstLine;
    }
    if (wpBinaryType == null) {
      wpBinaryType = wpCli.isBundled ? WpCliType.bundled : WpCliType.path;
    }
  }

  bool wantsHelp() {
    var optionResult = getParameterValue(ConfigurationOption.help);
    return optionResult != null ? optionResult : false;
  }

  bool wantsNoInteraction() {
    var optionResult = getParameterValue(ConfigurationOption.noInteraction);
    return optionResult != null ? optionResult : false;
  }

  bool wantsVersion() {
    var optionResult = getParameterValue(ConfigurationOption.version);
    return optionResult != null ? optionResult : false;
  }
}
