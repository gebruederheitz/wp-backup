import '../../model/database-configuration.dart';
import 'db-config-reader.dart';

enum YamlDbSetting { user, pass, database, host, prefix }

class YamlReader implements DbConfigReader {
  late final Map yamlContent;

  YamlReader(this.yamlContent);

  DatabaseConfiguration? read() {
    var rawDbConfig = yamlContent['db'] ?? null;

    if (rawDbConfig == null) {
      return null;
    }

    if (rawDbConfig is String) {
      return new DatabaseConfiguration.fromDbUrl(rawDbConfig);
    }

    if (rawDbConfig is Map) {
      return new DatabaseConfiguration(
          rawDbConfig['user'] ?? '', rawDbConfig['pass'] ?? '',
          database: rawDbConfig['database'] ?? null,
          host: rawDbConfig['host'] ?? null,
          tablePrefix: rawDbConfig['prefix'] ?? null);
    }
  }
}
