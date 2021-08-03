import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serilog_droid/filter.dart';
import 'package:serilog_droid/loader.dart';
import 'package:serilog_droid/log.dart';

class LogRenderer extends StateNotifier<List<Map<String, dynamic>>> {
  LogRenderer({List<Map<String, dynamic>>? state}) : super(state ?? []);
  static LogRenderer fromList(List<Map<String, dynamic>> list, Map<String, Set<dynamic>> filter) {
    var logRenderer = LogRenderer();
    logRenderer.state = _filter(list, filter);
    // compute(_filterLogs, {"list": list, "filter": filter}).then((value) => logRenderer.state = tologs(value));
    return logRenderer;
  }
}

List<Map<String, dynamic>> _filterLogs(Map<String, dynamic> args) {
  var list = args["list"] as List<Map<String, dynamic>>;
  var filter = args["filter"] as Map<String, Set<dynamic>>;
  return _filter(list, filter);
}

List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> list, Map<String, Set<dynamic>> filter) {
  return list.where((element) {
    for (var f in filter.entries) {
      if (((f.value.isEmpty && element.containsKey(f.key)) || f.value.contains(element[f.key])) == false) return false;
    }
    return true;
  }).toList();
}

final logRenderer = StateNotifierProvider<LogRenderer, List<Map<String, dynamic>>>((ref) {
  var loadState = ref.watch(loaderProvider);
  var filter = ref.watch(logFilter);
  if (loadState is LoadStateLoaded) {
    return LogRenderer.fromList(loadState.logs, filter);
  }
  return LogRenderer();
});
