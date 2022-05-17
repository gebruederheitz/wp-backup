import 'dart:io';

import 'package:cli_dialog/cli_dialog.dart';
import 'package:dcli/dcli.dart';

class FileSelector {
  static const String key = 'files';
  final CLI_Dialog dialog = CLI_Dialog();
  final String directoryPath;

  FileSelector(
    this.directoryPath, {
    String? filter,
    String label = 'Please select a file:',
  }) {
    List<String> files = [];
    if (filter != null) {
      ('ls -1h $directoryPath' | 'grep "$filter"').forEach((line) {
        files.add(line);
      });
    } else {
      'ls -1h $directoryPath'.forEach((line) {
        files.add(line);
      });
    }

    dialog
        .addQuestion({'question': label, 'options': files}, key, is_list: true);
  }

  File ask() {
    Map answers = dialog.ask();
    String path = answers[key];
    return File(join(directoryPath, path));
  }
}
