import 'dart:io';

import 'package:cli_dialog/cli_dialog.dart';

import 'exit-codes.dart';

class Confirmation {
  static const String key = 'confirm';

  static bool confirm(String question) {
    return _ask(question);
  }

  static void confirmOrExit(String question) {
    if (!_ask(question)) {
      exit(ExitCodes.ok);
    }
  }

  static bool _ask(String question) {
    return CLI_Dialog(booleanQuestions: [
      [question, key]
    ]).ask()[key];
  }
}
