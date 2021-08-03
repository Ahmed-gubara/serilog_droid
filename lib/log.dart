enum Level { verbose, debug, information, warning, error, severe }

class Log {
  final int index;
  final DateTime dateTime;
  final String msgTemplete;
  final Map<String, dynamic> parameters;
  final Level level;
  String? _message;
  Log({
    required this.index,
    required this.dateTime,
    required this.msgTemplete,
    required this.parameters,
    required this.level,
  });
  String get message => _message ??= renderMessage();

  String renderMessage() {
    String msg = msgTemplete;
    for (var param in parameters.entries) {
      msg = msg.replaceAll("{${param.key}}", param.value.toString());
      msg = msg.replaceAll("{@${param.key}}", param.value.toString());
    }
    return msg;
  }

  factory Log.fromJson(int index, Map<String, dynamic> line) {
    return Log(
        dateTime: DateTime.parse(line["@t"].toString()), index: index, msgTemplete: line['@mt'].toString(), parameters: line, level: getlevel(line["@l"]))
      ..message;
  }
  static Level getlevel(dynamic v) {
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
}

// Map<String,dynamic> decode(String line){
//   compute()
// }
