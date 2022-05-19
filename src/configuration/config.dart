import 'package:dcli/dcli.dart';

import '../model/database-configuration.dart';
import 'yaml-configuration.dart';

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
  useConfigFile,
  configFilePath,
  operation,
  operationAll,
  operationDb,
  operationUserdata,
  noInteraction,
  databaseUrl,
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
  ConfigurationOption.useConfigFile: OptionParameter(
    'config',
    'c',
    separatorBefore: '--- Basic setup -----------------------',
    help: '''
Whether to use a .wp-backup.yaml configuration file. Will look in the project 
directory unless you provide a custom path using --config-file.
    ''',
    defaultValue: false,
  ),
  ConfigurationOption.configFilePath: OptionParameter(
    'config-file',
    'C',
    // @TODO: Make sure this is accurate
    help:
        'The path to a custom .wp-backup.yaml configuration file. Implies --config.',
    valueHelp: 'path/to/.wp-backup.yaml',
  ),
  ConfigurationOption.projectDirectory: OptionParameter(
    'directory',
    'd',
    valueHelp: '/path/to/project',
    help: '''
The directory to run in. This is the directory that contains backup/, userdata/ 
and public/ directories. Defaults to the current working directory in 
no-interaction mode.
    ''',
  ),
  ConfigurationOption.backupUser: OptionParameter(
    'user',
    'u',
    defaultValue: null,
    help: 'The user under which to operate.',
    valueHelp: 'username',
  ),
  ConfigurationOption.databaseUrl: OptionParameter('database-url', 'x',
      help:
          'Allows you to configure the database connection through a URL-style string.',
      valueHelp: 'mysql://user:pass@localhost/db'),
  ConfigurationOption.verbose: OptionParameter(
    'verbose',
    'V',
    separatorBefore: '--- Output control --------------------',
    defaultValue: false,
    help: 'More output',
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
  ConfigurationOption.comment: OptionParameter(
    'tag',
    't',
    separatorBefore: '--- Backup settings -------------------',
    defaultValue: null,
    help:
        'A tag (or comment) to append to the backup file (not available in restore mode).',
    valueHelp: 'tag-or-comment',
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

  late String projectDirectory;

  String? backupUser;

  bool verbose = false;

  bool useConfigFile = false;

  String? configFilePath = null;

  bool hasProjectDirectoryBeenEdited = false;

  String? comment;

  bool backupBeforeRestore = false;

  ArgResults options;

  YamlConfiguration? configurationFile = null;

  DatabaseConfiguration? dbConfig = null;

  Config.fromOptions(this.options) {
    if (getParameterValue(ConfigurationOption.projectDirectory) != null) {
      projectDirectory =
          getParameterValue(ConfigurationOption.projectDirectory);
      hasProjectDirectoryBeenEdited = true;
    } else {
      projectDirectory = 'realpath .'.firstLine ?? '.';
    }

    String? configFilePath =
        getParameterValue(ConfigurationOption.configFilePath);
    if (configFilePath != null) {
      configurationFile = YamlConfiguration.fromFileName(this, configFilePath);
    } else if (getParameterValue(ConfigurationOption.useConfigFile)) {
      configurationFile = YamlConfiguration.discover(this);
    }

    parseOperation();

    if (options.command?.name != null) {
      mode = options.command!.name;
    }

    if (getParameterValue(ConfigurationOption.verbose) == true) {
      verbose = true;
    }

    if (getParameterValue(ConfigurationOption.comment) != null) {
      comment = getParameterValue(ConfigurationOption.comment);
    }

    if (getParameterValue(ConfigurationOption.databaseUrl) != null) {
      var databaseUrl = getParameterValue(ConfigurationOption.databaseUrl);
      dbConfig = DatabaseConfiguration.fromDbUrl(databaseUrl);
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

  static String getParameter(ConfigurationOption option) {
    return OptionParameters[option]!.long;
  }

  getParameterValue(ConfigurationOption option) {
    return this.options[Config.getParameter(option)];
  }

  hasOperation() {
    return this.operation != null;
  }

  /// Apply any default values that might be missing when running in
  /// no-interaction mode
  setNoInteractionDefaults() {}

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
