import 'package:dcli/dcli.dart';

class Logger {
  final String name;
  bool mute = false;
  bool verbose = false;
  bool lastLogHadNewline = true;

  static final Map<String, Logger> _cache = <String, Logger>{};

  factory Logger([String name = 'main']) {
    return _cache.putIfAbsent(name, () => Logger._internal(name));
  }

  Logger._internal(this.name);

  setVerbose(bool verbose) {
    this.verbose = verbose;
  }

  void log(String msg, [bool forceNewline = true]) {
    if (!mute) {
      print(prefix(forceNewline) + msg);
    }
  }

  void debug(String msg, {bool forceNewline = true, bool newline = true}) {
    if (verbose) {
      if (newline) {
        print(prefix(forceNewline) + grey(msg));
      } else {
        echo(prefix(forceNewline) + grey(msg), newline: false);
      }
    }
  }

  void error(String msg) {
    printerr(red(prefix(true) + msg));
    lastLogHadNewline = true;
  }

  String prefix(bool force) {
    return force && !lastLogHadNewline ? '\n' : '';
  }

  void debugContinuable(msg) {
    return debug(msg, newline: false);
  }

  void debugContinued(msg) {
    return debug(msg, forceNewline: false);
  }
}

