import 'dart:io';

import 'package:dcli/dcli.dart';

import '../../model/database-configuration.dart';
import '../logger.dart';
import 'db-config-reader.dart';

enum DotenvDbSetting { user, pass, database, host, prefix }

const Map<DotenvDbSetting, String> DotenvDbSettingNames = {
  DotenvDbSetting.user: 'USER',
  DotenvDbSetting.pass: 'PASSWORD',
  DotenvDbSetting.database: 'NAME',
  DotenvDbSetting.host: 'HOST',
  DotenvDbSetting.prefix: 'TABLE_PREFIX',
};

class DotenvReader implements DbConfigReader {
  late final String workingDir;

  DotenvReader(this.workingDir);

  DatabaseConfiguration? read() {
    File dotenv = File(join(workingDir, 'configuration', '.env'));
    Logger().debug('Looking for dotenv at ${dotenv.path}');
    if (!dotenv.existsSync()) return null;
    String content = dotenv.readAsStringSync();
    RegExp re = RegExp(r'^DB_(.*?)=(.*)$', multiLine: true);

    if (re.hasMatch(content)) {
      String user = '';
      String pass = '';
      String? database;
      String? host;
      String? prefix;

      Iterable<RegExpMatch> matches = re.allMatches(content);
      matches.toSet().forEach((match) {
        String setting = match.group(1) ?? '';
        if (!DotenvDbSettingNames.values.any((element) => element == setting)) {
          return;
        }

        MapEntry matchedSetting = DotenvDbSettingNames.entries
            .firstWhere((element) => element.value == setting);
        DotenvDbSetting parameter = matchedSetting.key;
        String value = match.group(2) ?? '';

        switch (parameter) {
          case DotenvDbSetting.user:
            user = value;
            break;
          case DotenvDbSetting.pass:
            pass = value;
            break;
          case DotenvDbSetting.database:
            database = value;
            break;
          case DotenvDbSetting.host:
            host = value;
            break;
          case DotenvDbSetting.prefix:
            prefix = value;
            break;
        }
      });

      return new DatabaseConfiguration(user, pass,
          database: database, host: host, tablePrefix: prefix);
    } else {
      return null;
    }
  }
}
