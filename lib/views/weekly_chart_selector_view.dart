import 'package:finale/components/loading_component.dart';
import 'package:finale/components/weekly_chart_component.dart';
import 'package:finale/lastfm.dart';
import 'package:finale/types/luser.dart';
import 'package:flutter/material.dart';

class WeeklyChartSelectorView extends StatefulWidget {
  final LUser user;

  WeeklyChartSelectorView({Key key, @required this.user}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WeeklyChartSelectorViewState();
}

class _WeeklyChartSelectorViewState extends State<WeeklyChartSelectorView> {
  var _loaded = false;
  List<LUserWeeklyChart> _charts;
  int _index;

  @override
  void initState() {
    super.initState();

    Lastfm.getWeeklyChartList(widget.user).then((chartList) {
      setState(() {
        _charts = chartList.charts;
        _index = _charts.length - 1;
        _loaded = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) => !_loaded
      ? LoadingComponent()
      : Column(
          children: [
            ColoredBox(
              color: Theme.of(context).primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left),
                    color: Colors.white,
                    onPressed: _index > 0
                        ? () {
                            setState(() {
                              _index--;
                            });
                          }
                        : null,
                  ),
                  Text(
                    _charts[_index].displayTitle,
                    style: TextStyle(color: Colors.white),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right),
                    color: Colors.white,
                    onPressed: _index < _charts.length - 1
                        ? () {
                            setState(() {
                              _index++;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
            Expanded(
              child: WeeklyChartComponent(
                // ObjectKey forces the component to be built from scratch when
                // the chart changes.
                key: ObjectKey(_charts[_index]),
                user: widget.user,
                chart: _charts[_index],
              ),
            ),
          ],
        );
}
