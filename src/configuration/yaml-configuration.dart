import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:yaml/yaml.dart';

import '../util/exit-codes.dart';
import '../util/logger.dart';
import 'config.dart';

enum Key {
  projectDir,
  operation,
  verbose,
  backupUser,
  runWizard,
  backupBeforeRestore,
  wantsTags,
}

const Map<Key, String> Keys = {
  Key.projectDir: 'projectDir',
  Key.operation: 'operation',
  Key.verbose: 'verbose',
  Key.backupUser: 'backupUser',
  Key.runWizard: 'wizard',
  Key.backupBeforeRestore: 'backupBeforeRestore',
  Key.wantsTags: 'askForTag',
};

class YamlConfiguration {
  final Config config;
  final Map yaml;

  YamlConfiguration._constructor(this.config, this.yaml);

  factory YamlConfiguration.discover(Config config) {
    final String pwdPath = config.projectDirectory;
    final File inPwd = File(join(pwdPath, '.wp-backup.yaml'));
    File yamlFile;

    if (inPwd.existsSync()) {
      yamlFile = inPwd;
    } else {
      String? filename = 'find $pwdPath -name .wp-backup.yaml'.firstLine;
      if (filename == null || filename.trim() == '') {
        Logger().error('No configuration file found in path.');
        exit(ExitCodes.usageError);
      }
      yamlFile = File(filename);
    }
    Map parsedYaml = _readYamlFile(yamlFile);

    return YamlConfiguration._constructor(config, parsedYaml);
  }

  factory YamlConfiguration.fromFileName(Config config, String filename) {
    return YamlConfiguration._constructor(
        config, _readYamlFile(File(filename)));
  }

  parse() {
    // Only set the project directory if it hasn't already been set through
    // a command line option
    if (_hasValueForKey(Key.projectDir) &&
        !config.hasProjectDirectoryBeenEdited) {
      final projectDirectory = _getValueByKey(Key.projectDir);
      if (projectDirectory is String) {
        config.projectDirectory = projectDirectory;
        config.hasProjectDirectoryBeenEdited = true;
      }
    }

    if (_hasValueForKey(Key.operation)) {
      final operation = _getValueByKey(Key.operation);

      if (operation is String &&
          OperationType.values.any(
              (element) => element.toString() == "OperationType.$operation")) {
        final OperationType optype = OperationType.values.firstWhere(
            (element) => element.toString() == "OperationType.$operation");
        config.operation = optype;
      }
    }

    if (_hasValueForKey(Key.verbose)) {
      final isVerbose = _getValueByKey(Key.verbose);
      if (isVerbose is bool) {
        config.verbose = isVerbose;
      }
    }

    if (_hasValueForKey(Key.backupUser)) {
      final user = _getValueByKey(Key.backupUser);
      if (user is String) {
        config.backupUser = user;
      }
    }

    if (_hasValueForKey(Key.runWizard)) {
      final isRunWizard = _getValueByKey(Key.runWizard);
      if (isRunWizard is bool) {
        config.noInteraction = !isRunWizard;
      }
    }

    if (_hasValueForKey(Key.backupBeforeRestore)) {
      final wantsBackupBeforeRestore = _getValueByKey(Key.backupBeforeRestore);
      if (wantsBackupBeforeRestore is bool) {
        config.backupBeforeRestore = wantsBackupBeforeRestore;
      }
    }

    if (!config.noInteraction && _hasValueForKey(Key.wantsTags)) {
      final wantsTags = _getValueByKey(Key.wantsTags);
      if (wantsTags is bool) {
        config.neverAskForComment = !wantsTags;
      }
    }
  }

  static Map _readYamlFile(File file) {
    final String fileContent = file.readAsStringSync();
    try {
      final Map parsedYaml = loadYaml(fileContent);
      return parsedYaml;
    } catch (e) {
      Logger().error('Invalid YAML, failed to parse file.');
      exit(ExitCodes.error);
    }
  }

  dynamic _getValueByKey(Key key) {
    return yaml[Keys[key]];
  }

  bool _hasValueForKey(Key key) {
    return yaml.containsKey(Keys[key]);
  }
}
