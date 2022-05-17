import 'package:dcli/dcli.dart';

import 'configuration/config.dart';

class Commands {
  static const backup = 'backup';
  static const restore = 'restore';
}

class ArgumentParser {
  ArgParser parser = ArgParser();

  ArgResults parseOptions(Iterable args) {
    OptionParameters.forEach(
        (ConfigurationOption option, OptionParameter config) {
      if (config.separatorBefore is String) {
        parser.addSeparator(config.separatorBefore!);
      }

      bool isBoolean = config.defaultValue is bool;

      if (isBoolean) {
        parser.addFlag(config.long,
            abbr: config.short,
            defaultsTo: config.defaultValue,
            negatable: false,
            help: config.help);
      } else {
        parser.addOption(
          config.long,
          abbr: config.short,
          defaultsTo: config.defaultValue,
          help: config.help,
          valueHelp: config.valueHelp,
        );
      }
    });

    parser.addCommand(Commands.backup);
    parser.addCommand(Commands.restore);

    return parser.parse(args as Iterable<String>);
  }

  printUsage() {
    print(parser.usage);
  }
}
