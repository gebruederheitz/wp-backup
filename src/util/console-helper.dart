import 'dart:io';

import 'package:dcli/dcli.dart';

import 'logger.dart';

class ConsoleHelper {
  final String name;
  static final Map<String, ConsoleHelper> _cache = <String, ConsoleHelper>{};

  String? user;

  factory ConsoleHelper([String? user]) {
    return ConsoleHelper._factoryWithName('console-helper', user);
  }

  factory ConsoleHelper._factoryWithName(String name, [String? user]) {
    var instance =
        _cache.putIfAbsent(name, () => ConsoleHelper._internal(name, user));
    if (user != null) {
      instance.setUser(user);
    }

    return instance;
  }

  ConsoleHelper._internal(this.name, [this.user]);

  setUser(String user) {
    this.user = user;
  }

  void userdo(String command, [String? user]) {
    var username = user != null ? user : this.user;
    if (username != null && username != 'whoami'.firstLine) {
      'sudo -s -u $username $command'.run;
    } else {
      command.run;
    }
  }

  void userdoStart(String command, [String? workingDirectory, String? user]) {
    var username = user != null ? user : this.user;
    if (username != null && username != 'whoami'.firstLine) {
      'sudo -s -u $username $command'.start(workingDirectory: workingDirectory);
    } else {
      command.start(workingDirectory: workingDirectory);
    }
  }

  String? userdoFirstLine(String command, [String? user]) {
    var username = user != null ? user : this.user;

    return 'sudo -s -u $username $command'.firstLine;
  }

  static String getDateSlug() {
    return 'date +%Y-%m-%d-%H-%M'.firstLine ?? '';
  }

  static String checkWpBinary(String wpBinaryPath) {
    Logger l = Logger();
    l.debugContinuable('Testing wp binary at path $wpBinaryPath');

    var file = File(wpBinaryPath);
    bool fileExists = file.existsSync();
    bool whichHasResult = false;
    // bool isExecutable = file.statSync().modeString()[2] == 'x';
    // if (!(fileExists && isExecutable)) {
    if (!(fileExists)) {
      if (which(wpBinaryPath).found) {
        whichHasResult = true;
        wpBinaryPath = which(wpBinaryPath).path!;
      }
    }

    if (!(fileExists || whichHasResult)) {
      l.error('Custom wp-cli file does not exist or is not executable!');
      exit(2);
    }

    l.debugContinued(green(' Ok.'));
    return wpBinaryPath;
  }
}
