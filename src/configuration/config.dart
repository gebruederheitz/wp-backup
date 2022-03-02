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
}

final OptionParameters = const {
  'sep-general': {
    'type': 'separator',
    'content': '--- General help & information --------'
  },
  ConfigurationOption.help: {
    'long': 'help',
    'short': 'h',
    'default': false,
    'help': 'Show this help and exit.'
  },
  ConfigurationOption.version: {
    'long': 'version',
    'short': 'v',
    'default': false,
    'help': 'Display version and exit.'
  },
  'sep-global': {
    'type': 'separator',
    'content': '--- Global settings -------------------'
  },
  ConfigurationOption.projectDirectory: {
    'long': 'directory',
    'short': 'd',
    // 'default': '\$HOME',
    'valueHelp': 'path-to-project',
    'help': '''
The directory to run in. This is the directory that contains backup/, userdata/ 
and public/ directoris. Defaults to the current working directory in 
no-interaction mode.
    ''',
  },
  ConfigurationOption.verbose: {
    'long': 'verbose',
    'short': 'V',
    'default': false,
    'help': 'More output.'
  },
  ConfigurationOption.backupUser: {
    'long': 'user',
    'short': 'u',
    'default': null,
    'help': 'The user under which to operate.',
    'valueHelp': 'blargo'
  },
  ConfigurationOption.noInteraction: {
    'long': 'no-interaction',
    'short': 'n',
    'default': false,
    'help':
    'Skip the wizard, do not ask questions. For scripts and CI applications.'
  },
  'sep-operation': {
    'type': 'separator',
    'content': '--- Operation control -----------------'
  },
  ConfigurationOption.operation: {
    'long': 'operation',
    'short': 'o',
    'help': 'Which backups to perform',
    'valueHelp': 'database|userdata|all'
  },
  ConfigurationOption.operationAll: {
    'long': 'all',
    'short': 'a',
    'default': false,
  },
  ConfigurationOption.operationDb: {
    'long': 'db',
    'short': 'D',
    'default': false,
  },
  ConfigurationOption.operationUserdata: {
    'long': 'userdata',
    'short': 'U',
    'default': false,
  },
  'sep-database': {
    'type': 'separator',
    'content': '--- Database backup settings ----------',
  },
  ConfigurationOption.usePhpWrapper: {
    'long': 'php-wrapper',
    'short': 'P',
    'default': false,
    'help': '''
Instead of using a (custom) PHP binary, use php-wrapper instead (must be on the 
\$PATH).
    ''',
  },
  ConfigurationOption.phpBinary: {'long': 'php', 'short': 'p', 'default': null},
  ConfigurationOption.wpBinaryType: {
    'long': 'wp-cli-type',
    'short': 'w',
    'help': '''
Whether to use a wp-cli binary on the \$PATH, in the script directory or the 
bundled version (depending on version). For a custom path, use --wp--cli-path.
    ''',
    'valueHelp': 'bundled|path|directory',
  },
  ConfigurationOption.wpBinary: {
    'long': 'wp-cli-path',
    'short': 'W',
    'default': null,
    'help': 'A custom wp-cli executable PHAR archive to use for DB exporting.',
    'valueHelp': 'path-to-wp-cli.phar',
  },
};

class Config {
  String command;

  OperationType operation;

  String projectDirectory;

  String backupUser;

  bool verbose = false;

  bool usePhpWrapper = false;

  WpCliType wpBinaryType;

  String wpBinary;

  String phpBinary;

  ArgResults options;

  Config.fromOptions(this.options, WpCli wpCli) {
    parseOperation();

    if (options.command?.name != null) {
      command = options.command.name;
    }
      
    if (getParameterValue(ConfigurationOption.projectDirectory) != null) {
      projectDirectory = getParameterValue(ConfigurationOption.projectDirectory);
    }

    if (getParameterValue(ConfigurationOption.verbose) == true) {
      verbose = true;
    }

    parseWpBinary(wpCli);
    if (getParameterValue(ConfigurationOption.usePhpWrapper)) {
      usePhpWrapper = true;
    }

    backupUser = getParameterValue(ConfigurationOption.backupUser) ?? 'whoami'.firstLine;
  }
  
  parseOperation() {
    var operation = getParameterValue(ConfigurationOption.operation);
    if (operation != null) {
      var op = OperationType.values.firstWhere((element) => element.toString() == operation);
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
      String providedType = getParameterValue(ConfigurationOption.wpBinaryType);
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

  static getParameter(ConfigurationOption option) {
    return OptionParameters[option]['long'];
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
