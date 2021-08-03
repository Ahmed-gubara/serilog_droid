import 'package:flutter_riverpod/flutter_riverpod.dart';

final logFilter = StateNotifierProvider<Filter, Map<String, Set<dynamic>>>((ref) => Filter());
const Map<String, Set<dynamic>> emptyFilter = <String, Set<dynamic>>{
  // "@l": <dynamic>{"Debug"}
};

class Filter extends StateNotifier<Map<String, Set<dynamic>>> {
  Filter() : super(emptyFilter);

  void clear() => state = emptyFilter;

  void setFilter(String property, Set<dynamic> set) {
    try {
      updateState((map) {
        map[property] = set;
      });
    } catch (e) {
      print(e);
    }
  }

  void updateState(void Function(Map<String, Set<dynamic>> map) update) {
    var map = Map<String, Set<dynamic>>.from(state);
    update(map);
    state = map;
  }
}
