import 'package:dcli/dcli.dart';

import 'configuration/config.dart';

class Commands {
  static const backup = 'backup';
  static const restore = 'restore';
}

class ArgumentParser {
  ArgParser parser = ArgParser();

  ArgResults parseOptions(Iterable args) {
    var params = Map.from(OptionParameters);

    params.forEach((option, config) {
      if (config['type'] == 'separator') {
        parser.addSeparator(config['content']);
        return;
      }

      var type = config['default'].runtimeType;

      if (type == bool) {
        parser.addFlag(
              config['long'],
              abbr: config['short'],
              defaultsTo: config['default'],
              negatable: false,
              help: config['help']);
      } else if (type == String || config['default'] == null) {
        parser.addOption(
            config['long'],
            abbr: config['short'],
            defaultsTo: config['default'],
            help: config['help'],
            valueHelp: config['valueHelp'],
          );
      }
    });

    parser.addCommand(Commands.backup);
    parser.addCommand(Commands.restore);

    return parser.parse(args);
  }

  printUsage() {
    print(parser.usage);
  }
}
