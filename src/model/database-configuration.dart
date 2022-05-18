import 'dart:io';

import '../util/exit-codes.dart';
import '../util/logger.dart';

class DatabaseConfiguration {
  late final String host;
  late final String port;
  late final String user;
  late final String password;
  late final String database;
  late final String tablePrefix;

  static const DEFAULT_HOST = '127.0.0.1';
  static const DEFAULT_PORT = '3306';
  static const DEFAULT_TABLE_PREFIX = 'wp_';
  static const DEFAULT_DATABASE = 'wordpress';

  DatabaseConfiguration(this.user, this.password,
      {String? host, String? database, String? port, String? tablePrefix}) {
    this.host = host ?? DEFAULT_HOST;
    this.database = database ?? DEFAULT_DATABASE;
    this.port = port ?? DEFAULT_PORT;
    this.tablePrefix = tablePrefix ?? DEFAULT_TABLE_PREFIX;
  }

  DatabaseConfiguration.fromDbUrl(String dbUrl) {
    RegExp re = RegExp(
        r'^(?:mysql:\/\/)?(?<user>.*?):(?<pass>.*?)@(?<host>.*?)(?::(?<port>\d+))?(?:\/(?<database>.*?))?(?:\/(?<prefix>.*))?$');

    if (re.hasMatch(dbUrl)) {
      var matches = re.firstMatch(dbUrl)!;
      this.user = matches.namedGroup('user')!;
      this.password = matches.namedGroup('password')!;
      this.host = matches.namedGroup('host')!;

      this.database = matches.namedGroup('database') ?? DEFAULT_DATABASE;
      this.port = matches.namedGroup('port') ?? DEFAULT_PORT;
      this.tablePrefix = matches.namedGroup('prefix') ?? DEFAULT_TABLE_PREFIX;
    } else {
      Logger().error(
          'Invalid database URL provided. The string must match the format (mysql://)?user:pass@host(:port)?(/dbname)?(/prefix)?.');
      exit(ExitCodes.usageError);
    }
  }
}
