import '../src/index.dart';
import '../src/wp-cli/wp-cli.dart';

void main(List<String> args) {
  WpBackup.run(args, WpCli());
}
