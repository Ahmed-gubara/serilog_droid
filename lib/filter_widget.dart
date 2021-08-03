import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:getwidget/getwidget.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:search_choices/search_choices.dart';
import 'package:serilog_droid/filter.dart';
import 'package:serilog_droid/loader.dart';

class FilterScreen extends HookWidget {
  const FilterScreen({Key? key}) : super(key: key);
  // static const String addItem = "--Add Filter--";
  @override
  Widget build(BuildContext context) {
    var loadState = useProvider(loaderProvider);
    var filters = useProvider(logFilter);
    var selectedFilter = useState<String?>(null);
    // useEffect(() {
    //   print(selectedFilter.value);
    // });
    var availableProperties = <String>[];
    if (loadState is LoadStateLoaded) {
      var usedFilters = filters.keys.toSet();
      availableProperties = [...loadState.availableFilters.keys.where((element) => usedFilters.contains(element) == false)];
    }

    final filter = filters.entries.toList();
    return Scaffold(
      appBar: GFAppBar(
        centerTitle: true,
        title: Container(
          child: DropdownButton<String>(
            value: null,
            hint: Text("Select Value"),
            onChanged: (value) {
              if (value != null && filters.containsKey(value) == false) {
                context.read(logFilter.notifier).updateState((map) => map[value] = <dynamic>{});
              }
            },
            items: availableProperties.map((e) => DropdownMenuItem<String>(child: Text(e), value: e)).toList(),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: filter.length,
        itemBuilder: (context, index) {
          return FilterItem(property: filter[index].key);
        },
      ),
    );
  }
}

class FilterItem extends HookWidget {
  final String property;

  const FilterItem({Key? key, required this.property}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var filter = useProvider(logFilter)[property] ?? <dynamic>[];
    var loadState = useProvider(loaderProvider);
    if (loadState is LoadStateLoading) {
      return Text("Wait for log to load");
    }
    if (loadState is LoadStateNoFile) {
      return Text("Select a log file first");
    }
    final loaded = loadState as LoadStateLoaded;
    var availableFilter = loadState.availableFilters[property]?.toList() ?? <dynamic>[];
    var selectedIndexes = availableFilter.asMap().entries.where((element) => filter.contains(element.value)).map((e) => e.key).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SearchChoices<dynamic>.multiple(
          hint: "Select filter",
          isExpanded: true,
          label: "Select filter for [$property]",
          onClear: () {},
          onChanged: (List<int> selected) {
            if (selected.isEmpty) {
              context.read(logFilter.notifier).updateState((map) {
                map.remove(property);
              });
              return;
            }
            var indexes = selected.toSet();
            context
                .read(logFilter.notifier)
                .setFilter(property, availableFilter.asMap().entries.where((element) => indexes.contains(element.key)).map<dynamic>((e) => e.value).toSet());
          },
          selectedItems: selectedIndexes,
          items: availableFilter.map((dynamic e) => DropdownMenuItem<dynamic>(child: Text(e.toString()), value: e)).toList(),
        ),
      ),
    );
  }
}
