import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:dcli/dcli.dart';

class Archiver {
  static String gzipFile(String sourcePath) {
    InputFileStream input = InputFileStream(sourcePath);
    OutputFileStream output = OutputFileStream('$sourcePath.gz');
    GZipEncoder().encode(input, level: 9, output: output);
    new File(sourcePath).deleteSync();

    return output.path;
  }

  static File gunzip(File archive) {
    String archivePath = archive.path;
    // We strip off the ".gz" extension, keeping the ".mysql"
    String restoredFileName = basenameWithoutExtension(archivePath);
    String restoredPath = join(dirname(archivePath), restoredFileName);

    final inputStream = InputFileStream(archivePath);
    final outputStream = OutputFileStream(restoredPath);
    GZipDecoder().decodeStream(inputStream, outputStream);
    outputStream.close();

    return File(outputStream.path);
  }
}
