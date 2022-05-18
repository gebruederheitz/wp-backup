import '../../model/database-configuration.dart';
import 'db-config-reader.dart';

enum YamlDbSetting { user, pass, database, host, prefix }

class YamlReader implements DbConfigReader {
  late final Map yamlContent;

  YamlReader(this.yamlContent);

  DatabaseConfiguration? read() {
    Map? rawDbConfig = yamlContent['db'] ?? null;

    if (rawDbConfig == null) {
      return null;
    }

    return new DatabaseConfiguration(
        rawDbConfig['user'] ?? '', rawDbConfig['pass'] ?? '',
        database: rawDbConfig['database'] ?? null,
        host: rawDbConfig['host'] ?? null,
        tablePrefix: rawDbConfig['prefix'] ?? null);
  }
}
