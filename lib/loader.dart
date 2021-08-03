import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/riverpod.dart';
import 'package:serilog_droid/filter.dart';

import 'package:serilog_droid/log.dart';
import 'package:rxdart/rxdart.dart';

class FileSelecter extends StateNotifier<String?> {
  FileSelecter([String? state]) : super(state);
  void setLogFilePath(String path) => state = path;
}

final fileSelecterProvider = StateProvider((ref) => FileSelecter());

class LoadState {
  factory LoadState.loading(double progress) => LoadStateLoading(progress: progress);
  factory LoadState.loaded(List<Map<String, dynamic>> logs, Map<String, Set<dynamic>> availableFilters) =>
      LoadStateLoaded(logs: logs, availableFilters: availableFilters);
  factory LoadState.noFile() => LoadStateNoFile();
}

class LoadStateLoading implements LoadState {
  double progress;
  LoadStateLoading({
    required this.progress,
  });
}

class LoadStateLoaded implements LoadState {
  List<Map<String, dynamic>> logs;
  Map<String, Set<dynamic>> availableFilters;
  LoadStateLoaded({
    required this.logs,
    required this.availableFilters,
  });
}

class LoadStateNoFile implements LoadState {}

class Loader extends StateNotifier<LoadState> {
  final String? filePath;
  Map<String, Set<dynamic>> availableFilters = {};
  late final File? file;

  Isolate? myIsolateInstance;

  Loader(this.filePath) : super(LoadStateNoFile()) {
    _loadFile();
  }

  @override
  void dispose() {
    print("disposing loader");
    myIsolateInstance?.kill();
    super.dispose();
    print("disposed loader");
  }

  Future<void> _loadFile() async {
    print("loading file");

    if (!mounted) return;
    final completer = Completer<SendPort>();
    final endcommunication = Completer<void>();
    ReceivePort isolateToMainStream = ReceivePort();
    List<Map<String, dynamic>> list = [];
    var listen = isolateToMainStream.listen((dynamic data) {
      if (data is SendPort) {
        SendPort mainToIsolateStream = data;
        completer.complete(mainToIsolateStream);
      } else if (data is List<Map<String, dynamic>>) {
        data.forEach((element) {
          element["@rendered"] = renderMessage(element);
          // element["@level"] = getlevel(element["@l"]);
          // element["@time"] = element["@datetime"].toString().split(' ')[1].split('.')[0];
        });
        list.addAll(data);
      } else if (data is double) {
        // print('[isolateToMainStream] $data');
        state = LoadState.loading(data);
      } else if (data is Map<String, Set<dynamic>>) {
        availableFilters = data;
        state = LoadState.loaded(list, availableFilters);
      } else if (data == "end") {
        endcommunication.complete();
      } else {
        print('[isolateToMainStream] ${data.runtimeType}');
        // print('[isolateToMainStream] $data');
      }
    });

    myIsolateInstance = await Isolate.spawn(myIsolate, isolateToMainStream.sendPort, debugName: "loaderIsolate");

    state = LoadState.noFile();
    var sendPort = await completer.future;
    sendPort.send(filePath ?? "");
    await endcommunication.future;
    myIsolateInstance?.kill();
    myIsolateInstance = null;
  }
}

Future<void> myIsolate(SendPort isolateToMainStream) async {
  ReceivePort mainToIsolateStream = ReceivePort();
  isolateToMainStream.send(mainToIsolateStream.sendPort);
  final filePathcompleter = Completer<String>();
  mainToIsolateStream.listen((dynamic message) {
    if (message is String && filePathcompleter.isCompleted == false) {
      filePathcompleter.complete(message);
    }
  });
  var filepath = await filePathcompleter.future;
  var file = File.fromUri(Uri.file(filepath));
  if (file.existsSync()) {
    Map<String, Set<dynamic>> availableFilters = {};
    final filseSize = file.lengthSync();
    print("file size $filseSize");
    var fileOffset = 0.0;
    var list = file
        .openRead()
        .map((event) {
          fileOffset += event.length;
          isolateToMainStream.send(fileOffset / filseSize);
          return event;
        })
        .map((v) => utf8.decode(v, allowMalformed: true))
        .transform(LineSplitter())
        .map<Map<String, dynamic>?>((event) {
          try {
            var decode = jsonDecode(event) as Map<String, dynamic>;
            if (decode.containsKey("MessageContent")) {
              decode["MessageContent"] = jsonDecode(decode["MessageContent"].toString());
            }
            if (decode.containsKey("@l") == false) decode["@l"] = "Information";

            for (var item in decode.entries.where((element) => element.key != "@t" && element.value != null)) {
              Set<dynamic>? set = availableFilters[item.key];
              if (set != null) {
                set.add(item.value);
              } else {
                set = availableFilters[item.key] = <dynamic>{item.value};
              }
            }
            return decode;
          } catch (_) {}
        })
        .where((event) => event != null)
        .map((event) => event!)
        .bufferCount(10)
        .listen((event) {
          isolateToMainStream.send(event);
        });
    await list.asFuture<dynamic>();

    isolateToMainStream.send(availableFilters);
  } else {
    isolateToMainStream.send(true);
  }
  isolateToMainStream.send("end");
}

String renderMessage(Map<String, dynamic> parameters) {
  String msg = parameters['@mt'].toString();
  for (var param in parameters.entries) {
    msg = msg.replaceAll("{${param.key}}", param.value.toString());
    msg = msg.replaceAll("{@${param.key}}", param.value.toString());
  }
  return msg;
}

Level getlevel(dynamic v) {
  switch (v) {
    case "Severe":
      return Level.severe;
    case "Error":
      return Level.error;
    case "Warning":
      return Level.warning;
    case "Information":
      return Level.information;
    case "Debug":
      return Level.debug;
    case "Verbose":
      return Level.verbose;
    case null:
      return Level.debug;
    default:
      return Level.information;
  }
}

final loaderProvider = StateNotifierProvider<Loader, LoadState>((ref) {
  var filepath = ref.watch(filepathProvider).state;
  return Loader(filepath);
});

final filepathProvider = StateProvider<String?>((ref) => null);
