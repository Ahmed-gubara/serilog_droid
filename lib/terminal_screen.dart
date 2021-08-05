import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dartssh/client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:xterm/flutter.dart';
import 'package:xterm/frontend/input_behavior_default.dart';
import 'package:xterm/frontend/input_behavior_desktop.dart';
import 'package:xterm/terminal/terminal.dart';
import 'package:xterm/terminal/terminal_backend.dart';
// import 'package:xterm/terminal/platform.dart';

class TerminalScreen extends HookWidget {
  const TerminalScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final terminal = useMemoized(() => Terminal(
          maxLines: 100,
          backend: SSHTerminalBackend("http://vps.shalomsudan.com:1993", "dev", "reboot-shortcut-specks"),
        ));
    terminal.write(DateTime.now().toIso8601String());
    return Scaffold(
      appBar: AppBar(),
      body: TerminalView(
        terminal: terminal,
        inputBehavior: InputBehaviorDesktop(),
      ),
    );
  }
}

class FakeTerminalBackend extends TerminalBackend {
  late Completer<int> _exitCodeCompleter;
  // ignore: close_sinks
  late StreamController<String> _outStream;

  FakeTerminalBackend();

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  void init() {
    _exitCodeCompleter = Completer<int>();
    _outStream = StreamController<String>();
    _outStream.sink.add('xterm.dart demo');
    _outStream.sink.add('\r\n');
    _outStream.sink.add('\$ ');
  }

  @override
  Stream<String> get out => _outStream.stream;

  @override
  void resize(int width, int height, int pixelWidth, int pixelHeight) {
    // NOOP
  }

  @override
  void write(String input) {
    if (input.length <= 0) {
      return;
    }
    // in a "real" terminal emulation you would connect onInput to the backend
    // (like a pty or ssh connection) that then handles the changes in the
    // terminal.
    // As we don't have a connected backend here we simulate the changes by
    // directly writing to the terminal.
    if (input == '\r') {
      _outStream.sink.add('\r\n');
      _outStream.sink.add('\$ ');
    } else if (input.codeUnitAt(0) == 127) {
      // Backspace handling
      _outStream.sink.add('\b \b');
    } else {
      _outStream.sink.add(input);
    }
  }

  @override
  void terminate() {
    //NOOP
  }

  @override
  void ackProcessed() {
    //NOOP
  }
}

class SSHTerminalBackend extends TerminalBackend {
  late SSHClient? client;

  final String _host;
  final String _username;
  final String _password;

  late Completer<int> _exitCodeCompleter;
  late StreamController<String> _outStream;

  SSHTerminalBackend(this._host, this._username, this._password);

  void onWrite(String data) {
    _outStream.sink.add(data);
  }

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  void init() {
    _exitCodeCompleter = Completer<int>();
    _outStream = StreamController<String>();

    onWrite('connecting $_host...');
    client = SSHClient(
      hostport: Uri.parse(_host),
      login: _username,
      print: print,
      termWidth: 80,
      termHeight: 25,
      termvar: 'xterm-256color',
      getPassword: () => Uint8List.fromList(utf8.encode(_password)),
      response: (transport, data) {
        onWrite(utf8.decode(data));
      },
      success: () {
        onWrite('connected.\n');
      },
      disconnected: () {
        onWrite('disconnected.');
        _outStream.close();
      },
    );
  }

  @override
  Stream<String> get out => _outStream.stream;

  @override
  void resize(int width, int height, int pixelWidth, int pixelHeight) {
    client?.setTerminalWindowSize(width, height);
  }

  @override
  void write(String input) {
    client?.sendChannelData(encode(input));
  }

  @override
  void terminate() {
    client?.disconnect('terminate');
  }

  @override
  void ackProcessed() {
    // NOOP
  }
}

Uint8List encode(String str) => Uint8List.fromList(utf8.encode(str));
