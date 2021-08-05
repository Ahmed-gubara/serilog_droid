import 'dart:io';

import 'package:file_picker_desktop/file_picker_desktop.dart' as desktop;
import 'package:file_picker/file_picker.dart' as mobile;

class FilePicker {}

Future<String?> openLogFile() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return _mobileOpenLogFile();
  }
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    return _desktopOpenLogFile();
  }
  print("unsupported operating system");
  return null;
}

const allowedExtensions = ['json', 'log', 'txt'];
Future<String?> _desktopOpenLogFile() async {
  try {
    final result = await desktop.pickFiles(
      allowMultiple: false,
      type: desktop.FileType.custom,
      allowedExtensions: allowedExtensions,
    );
    if (result != null) {
      return result.files.single.path;
    } else {
      return null;
    }
  } catch (e) {
    print(e);
    return null;
  }
}

Future<String?> _mobileOpenLogFile() async {
  try {
    var result = await mobile.FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: mobile.FileType.custom,
      allowedExtensions: allowedExtensions,
    );

    if (result != null) {
      return result.files.single.path;
    } else {
      return null;
    }
  } catch (e) {
    print(e);
    return null;
  }
}
