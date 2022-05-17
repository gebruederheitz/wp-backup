import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:archive/archive_io.dart';

import 'logger.dart';

class ZipProgress {
  int current = 0;
  final int total;

  ZipProgress(this.total);

  double get percentage {
    return current / total;
  }
}

class ZipFileEncoderWithProgress extends ZipFileEncoder {
  @override
  void zipDirectory(
    Directory dir, {
    String? filename,
    int? level,
    bool followLinks = true,
    DateTime? modified,
    Function(ZipProgress)? progressCallback,
  }) {
    final dirPath = dir.path;
    final zipPath = filename ?? '$dirPath.zip';
    level ??= ZipFileEncoder.GZIP;

    create(zipPath, level: level, modified: modified);
    addDirectoryWithProgress(
      dir,
      includeDirName: false,
      level: level,
      followLinks: followLinks,
      progressCallback: progressCallback,
    );
    close();
  }

  void addDirectoryWithProgress(
    Directory dir, {
    bool includeDirName = true,
    int? level,
    bool followLinks = true,
    Function(ZipProgress)? progressCallback,
  }) {
    List files = dir
        .listSync(recursive: true, followLinks: followLinks)
        .whereType<File>()
        .toList();

    ZipProgress? progress;
    if (progressCallback != null) {
      progress = ZipProgress(files.length);
    }

    for (var file in files) {
      final f = file;
      final dirName = path.basename(dir.path);
      final relPath = path.relative(f.path, from: dir.path);
      addFile(f, includeDirName ? (dirName + '/' + relPath) : relPath, level);

      if (progressCallback != null && progress != null) {
        progress.current++;
        progressCallback(progress);
      }
    }
  }
}

void extractArchiveToDiskWithProgress(Archive archive, String outputPath,
    {bool asyncWrite = false,
    int? bufferSize,
    Function(ZipProgress)? progressCallback}) {
  final outDir = Directory(outputPath);
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final List files = archive.files.where((element) => element.isFile).toList();
  Logger().debug(files.length.toString());
  Logger().debug(files.toString());

  ZipProgress? progress;
  if (progressCallback != null) {
    progress = ZipProgress(files.length);
  }

  for (final file in archive.files) {
    final filePath = '$outputPath${Platform.pathSeparator}${file.name}';

    if (!isWithinOutputPath(outputPath, filePath)) {
      if (progressCallback != null && progress != null) {
        progress = ZipProgress(progress.total - 1);
      }
      continue;
    }

    if (asyncWrite) {
      final output = File(filePath);
      output.create(recursive: true).then((f) {
        f.open(mode: FileMode.write).then((fp) {
          final bytes = file.content as List<int>;
          fp.writeFrom(bytes).then((fp) {
            file.clear();
            fp.close();
          });
        });
      });
    } else {
      final output = OutputFileStream(filePath, bufferSize: bufferSize);
      try {
        file.writeContent(output);
      } catch (err) {
        //
      }
      output.close();
    }

    if (progressCallback != null && progress != null) {
      progress.current++;
      progressCallback(progress);
    }
  }
}
