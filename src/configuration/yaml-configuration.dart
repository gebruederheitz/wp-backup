import 'dart:io';

import 'package:dcli/dcli.dart';
import 'package:yaml/yaml.dart';

import '../util/exit-codes.dart';
import '../util/logger.dart';
import 'config.dart';

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
}
