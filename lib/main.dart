import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:serilog_droid/filter.dart';
import 'package:serilog_droid/filter_widget.dart';
import 'package:serilog_droid/loader.dart';
import 'package:flutter_hooks/flutter_hooks.dart' as hooks;
import 'package:path_provider/path_provider.dart' as paths;
import 'package:serilog_droid/log.dart';
import 'package:serilog_droid/renderer.dart';
import 'package:search_choices/search_choices.dart';
import 'package:getwidget/getwidget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends hooks.HookWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  Widget build(BuildContext context) {
    final filepath = useProvider(filepathProvider);
    final filter = useProvider(logFilter);
    final log = useProvider(logRenderer);
    var filePickerCallback = hooks.useCallback(() async {
      // var externalStorageDirectory = await paths.getLibraryDirectory();
//
      var applicationDocumentsDirectory = await paths.getApplicationDocumentsDirectory();

      var path = await FilesystemPicker.open(context: context, rootDirectory: applicationDocumentsDirectory.parent);
      if (path != null) {
        filepath.state = path;
      }
    }, ["filepicker"]);

    var loader = useProvider(loaderProvider);

    var items2 = <DropdownMenuItem<dynamic>>[
      DropdownMenuItem<dynamic>(
        child: Text("first"),
        value: "1",
      ),
      DropdownMenuItem<dynamic>(
        child: Text("second"),
        value: "2",
      )
    ];
    return Scaffold(
      appBar: GFAppBar(
        title: Text(title),
        bottom: GFAppBar(title: _builderBottomWidget(loader, filePickerCallback, log.length), actions: [
          IconButton(
              onPressed: () {
                Navigator.of(context).push<void>(MaterialPageRoute(builder: (context) => FilterScreen()));
              },
              icon: Icon(Icons.filter_list))
        ]),
      ),
      body: ListView.builder(
        itemCount: log.length,
        itemBuilder: (context, index) => buildListTile(log[index], context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => filePickerCallback(), // _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.folder_open),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  ListTile buildListTile(Map<String, dynamic> log, BuildContext context) {
    return ListTile(
      title: SelectableText(log.message, maxLines: 1),
      subtitle: SelectableText(log.time),
      trailing: GFButton(
        color: getColor(log.level),
        child: Text(log.l),
        onPressed: () {
          showDialog<dynamic>(
            context: context,
            builder: (context) => AlertDialog(
              scrollable: true,
              content: SelectableText(getPrettyJSONString(log)),
            ),
          );
        },
      ),
    );
  }

  Color getColor(Level level) {
    switch (level) {
      case Level.verbose:
      case Level.debug:
        return Colors.grey;
      case Level.information:
        return Colors.yellow.shade700;
      case Level.warning:
        return Colors.orange.shade600;
      case Level.error:
      case Level.severe:
        return Colors.red;
    }
  }

  String getPrettyJSONString(dynamic jsonObject) {
    var encoder = JsonEncoder.withIndent("  ");
    return encoder.convert(jsonObject).replaceAll("\\\"", "'");
  }

  Widget _builderBottomWidget(LoadState loader, Future<void> Function() filePickerCallback, int length) {
    if (loader is LoadStateLoading) return LinearProgressIndicator(value: loader.progress);
    if (loader is LoadStateNoFile) return TextButton(onPressed: (filePickerCallback), child: Text("load"));
    if (loader is LoadStateLoaded) return Text(loader.logs.length.toString() + " entry loadad, filtered $length");
    return SizedBox();
  }
}

extension LogExt on Map<String, dynamic> {
  //       decode["@rendered"] = renderMessage(decode);
  // decode["@level"] = getlevel(decode["@l"]);
  // decode["@datetime"] = DateTime.parse(decode["@t"].toString());
  DateTime get datetime => DateTime.parse(this["@t"].toString());
  Level get level => getlevel(this["@l"]);
  String get time => datetime.toString().split(' ')[1].split('.')[0];
  String get l => this["@l"] as String;
  String get message => this["@rendered"] as String;
}
