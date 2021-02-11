import 'dart:async';

import 'package:finale/components/display_component.dart';
import 'package:finale/lastfm.dart';
import 'package:finale/types/generic.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PeriodSelectorComponent<T extends Displayable> extends StatefulWidget {
  // This Subject must remain open for the entire lifetime of the app, so no
  // need to close it.
  // ignore: close_sinks
  static final _periodChange = PublishSubject<String>();

  final DisplayType displayType;
  final PagedLastfmRequest<T> request;
  final DetailWidgetProvider<T> detailWidgetProvider;

  PeriodSelectorComponent({
    Key key,
    this.displayType = DisplayType.list,
    this.request,
    this.detailWidgetProvider,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PeriodSelectorComponentState<T>();
}

class _PeriodSelectorComponentState<T extends Displayable>
    extends State<PeriodSelectorComponent<T>> {
  static const _periods = {
    '7 days': '7day',
    '1 month': '1month',
    '3 months': '3month',
    '6 months': '6month',
    '12 months': '12month',
    'Overall': 'overall'
  };

  String _period;

  final _displayComponentKey = GlobalKey<DisplayComponentState>();
  StreamSubscription _periodChangeSubscription;

  @override
  void initState() {
    super.initState();

    _periodChangeSubscription =
        PeriodSelectorComponent._periodChange.listen((value) {
      setState(() {
        _period = value;
        _displayComponentKey.currentState.getInitialItems();
      });
    });

    SharedPreferences.getInstance().then((sharedPrefs) {
      setState(() {
        if (!sharedPrefs.containsKey('period')) {
          sharedPrefs.setString('period', '7day');
          PeriodSelectorComponent._periodChange.add('7day');
        }

        _period = sharedPrefs.getString('period');
      });
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: EdgeInsets.only(right: 10),
            child: DropdownButton<String>(
              value: _period,
              items: _periods.entries
                  .map((e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.key),
                      ))
                  .toList(),
              onChanged: (value) async {
                if (value != _period) {
                  final sharedPrefs = await SharedPreferences.getInstance();
                  await sharedPrefs.setString('period', value);
                  PeriodSelectorComponent._periodChange.add(value);
                }
              },
            ),
          ),
          Expanded(
            child: DisplayComponent<T>(
              key: _displayComponentKey,
              displayType: widget.displayType,
              request: widget.request,
              detailWidgetProvider: widget.detailWidgetProvider,
            ),
          ),
        ],
      );

  @override
  void dispose() {
    super.dispose();
    _periodChangeSubscription.cancel();
  }
}
