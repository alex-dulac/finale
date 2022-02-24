import 'package:finale/services/strava/activity.dart';
import 'package:finale/services/strava/strava.dart';
import 'package:finale/util/preferences.dart';
import 'package:finale/widgets/base/app_bar.dart';
import 'package:finale/widgets/tools/workout_details.dart';
import 'package:flutter/material.dart';

class WorkoutView extends StatefulWidget {
  const WorkoutView();

  @override
  State<StatefulWidget> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView> {
  List<AthleteActivity>? _activities;

  @override
  void initState() {
    super.initState();
    _fetchActivities();
  }

  Future<void> _authenticate() async {
    await Strava().authenticate();
    await _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    if (!Preferences().hasStravaAuthData) {
      return;
    }

    final activities =
        await const StravaListActivitiesRequest().doRequest(20, 1);
    setState(() {
      _activities = activities;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: createAppBar('Strava Workouts'),
        body: Preferences().hasStravaAuthData
            ? ListView(
                children: [
                  if (_activities != null)
                    for (final activity in _activities!)
                      ListTile(
                        title: Text(activity.name),
                        subtitle: Text(activity.localTimeRangeFormatted),
                        leading: const Icon(Icons.run_circle),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    WorkoutDetails(activity: activity)),
                          );
                        },
                      ),
                ],
              )
            : Center(
                child: TextButton(
                  onPressed: _authenticate,
                  child: const Text('Log in with Strava'),
                ),
              ),
      );
}
