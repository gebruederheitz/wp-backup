import 'dart:io';

import 'package:dcli/dcli.dart';

import 'logger.dart';

void testDirectory(String path) {
  Directory dir = Directory('realpath $path'.firstLine);
  Logger().debugContinuable('Testing directory ${dir.path} for validity...');

  if (!dir.existsSync()) {
    Logger().error('Invalid directory! Please check the parameter passed via the "-f" option or through the wizard!');
    exit(2);
  }

  Function hasChild = getHasChildDirectory(dir);

  if (!(hasChild('userdata') && hasChild('backup') && hasChild('public'))) {
    Logger().error('Not a project directory – make sure the target directory is a \"staggered release\" Wordpress installation containing \"userdata\", \"backup\" and \"release\" subdirectories.');
    exit(2);
  }

  Logger().debugContinued(green(' Ok.'));
}

Function getHasChildDirectory(Directory dir) {
  return <bool> (String child) => Directory(dir.path + '/$child').existsSync();
}
