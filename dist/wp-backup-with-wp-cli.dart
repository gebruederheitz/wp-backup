import '../src/index.dart';
import '../src/wp-cli/wp-cli-packaged.dart';

void main(List<String> args) {
  WpBackup.run(args, WpCli());
}
