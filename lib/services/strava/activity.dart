import 'package:finale/util/util.dart';
import 'package:json_annotation/json_annotation.dart';

part 'activity.g.dart';

double _metersToMiles(num meters) =>
    double.parse((meters / 1609.344).toStringAsFixed(2));

int _metersToFeet(num meters) => (meters * 3.2808399).round();

double _mpsToMph(num mps) => mps * 2.23693629;

int _numToInt(num value) => value.toInt();

@JsonSerializable()
class StravaException implements Exception {
  final String message;

  const StravaException(this.message);

  factory StravaException.fromJson(Map<String, dynamic> json) =>
      _$StravaExceptionFromJson(json);

  @override
  String toString() => message;
}

@JsonSerializable()
class AthleteActivity {
  final String name;
  final String type;

  @JsonKey(name: 'start_date', fromJson: DateTime.parse)
  final DateTime startDate;

  @JsonKey(name: 'start_date_local', fromJson: DateTime.parse)
  final DateTime startDateLocal;

  /// Elapsed time in seconds.
  @JsonKey(name: 'elapsed_time')
  final int elapsedTime;

  /// Distance in miles, truncated to two decimal places.
  @JsonKey(fromJson: _metersToMiles)
  final double distance;

  /// Total elevation gain in feet.
  @JsonKey(name: 'total_elevation_gain', fromJson: _metersToFeet)
  final int totalElevationGain;

  /// Average speed in mph.
  @JsonKey(name: 'average_speed', fromJson: _mpsToMph)
  final double averageSpeed;

  /// Average heart rate in bpm.
  @JsonKey(name: 'average_heartrate', fromJson: _numToInt)
  final int averageHeartRate;

  const AthleteActivity({
    required this.name,
    required this.type,
    required this.startDate,
    required this.startDateLocal,
    required this.elapsedTime,
    required this.distance,
    required this.totalElevationGain,
    required this.averageSpeed,
    required this.averageHeartRate,
  });

  factory AthleteActivity.fromJson(Map<String, dynamic> json) =>
      _$AthleteActivityFromJson(json);

  DateTime get endDate => startDate.add(Duration(seconds: elapsedTime));

  DateTime get endDateLocal =>
      startDateLocal.add(Duration(seconds: elapsedTime));

  String get localTimeRangeFormatted =>
      dateTimeFormat.format(startDateLocal) +
      ' - ' +
      timeFormat.format(endDateLocal);
}
