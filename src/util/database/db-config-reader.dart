import '../../model/database-configuration.dart';

abstract class DbConfigReader {
  DatabaseConfiguration? read();
}
