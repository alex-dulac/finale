import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrcloud/flutter_acrcloud.dart';
import 'package:intl/intl.dart';
import 'package:simplescrobble/env.dart';
import 'package:simplescrobble/lastfm.dart';
import 'package:simplescrobble/types/generic.dart';
import 'package:url_launcher/url_launcher.dart';

class ScrobbleView extends StatefulWidget {
  final FullTrack track;
  final bool isModal;

  ScrobbleView({Key key, this.track, this.isModal = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _ScrobbleViewState();
}

class _ScrobbleViewState extends State<ScrobbleView> {
  final _trackController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();

  var _scrobbleNow = true;
  DateTime _datetime;

  @override
  void initState() {
    super.initState();
    _trackController.text = widget.track?.name;
    _artistController.text = widget.track?.artist?.name;
    _albumController.text = widget.track?.album?.name;

    if (!widget.isModal) {
      ACRCloud.setUp(ACRCloudConfig(
          acrCloudAccessKey, acrCloudAccessSecret, acrCloudHost));
    }
  }

  Future<void> _scrobble(BuildContext context) async {
    final response = await Lastfm.scrobble([
      BasicConcreteTrack(
          _trackController.text, _artistController.text, _albumController.text)
    ], [
      _scrobbleNow ? DateTime.now() : _datetime
    ]);

    if (widget.isModal) {
      Navigator.pop(context, response.ignored == 0);
    } else if (response.ignored == 0) {
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text('Scrobbled successfully!')));
      _trackController.text = '';
      _artistController.text = '';
      _albumController.text = '';
    } else {
      Scaffold.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while scrobbling')));
    }
  }

  // This widget is a circle whose size depends on the volume that the
  // microphone picks up. Unfortunately, it's too laggy and the size doesn't
  // change that much unless you make a noise very close to the microphone.
  // ignore: unused_element
  Widget _buildAudioIndicator(BuildContext context, ACRCloudSession session) {
    return StreamBuilder(
      stream: session.volume,
      initialData: 0.0,
      builder: (context, snapshot) => Container(
          height: 50,
          child: Center(
              child: ClipOval(
                  child: SizedBox(
                      width: 100 * snapshot.data + 10,
                      height: 100 * snapshot.data + 10,
                      child: Container(color: Colors.red))))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Scrobble'),
          actions: [
            Builder(
                builder: (context) => IconButton(
                    icon: Icon(Icons.add), onPressed: () => _scrobble(context)))
          ],
        ),
        body: Form(
            child: Container(
                margin: EdgeInsets.all(10),
                child: Column(
                  children: [
                    if (!widget.isModal)
                      Builder(
                          builder: (context) => ListTile(
                                contentPadding: EdgeInsets.only(left: 8),
                                title: Text('Tap to recognize'),
                                trailing: FlatButton(
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Powered by ',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .caption),
                                          Image.asset(
                                              'assets/images/acrcloud.png',
                                              height: 20)
                                        ]),
                                    onPressed: () {
                                      launch('https://acrcloud.com');
                                    }),
                                onTap: () async {
                                  final session = ACRCloud.startSession();

                                  showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => AlertDialog(
                                            title: Text('Listening...'),
                                            actions: [
                                              FlatButton(
                                                child: Text('Cancel'),
                                                onPressed: session.cancel,
                                              )
                                            ],
                                          ));

                                  final result = await session.result;
                                  session.dispose();
                                  Navigator.pop(context);

                                  if (result == null) {
                                    // Cancelled
                                    return;
                                  }

                                  if (result.metadata?.music?.isNotEmpty ??
                                      false) {
                                    final track = result.metadata.music.first;

                                    setState(() {
                                      _trackController.text = track.title;
                                      _albumController.text = track.album?.name;
                                      _artistController.text =
                                          track.artists?.first?.name;
                                    });
                                  } else {
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                        content:
                                            Text('Could not recognize track')));
                                  }
                                },
                              )),
                    TextFormField(
                      controller: _trackController,
                      decoration: InputDecoration(labelText: 'Song'),
                    ),
                    TextFormField(
                      controller: _artistController,
                      decoration: InputDecoration(labelText: 'Artist'),
                    ),
                    TextFormField(
                      controller: _albumController,
                      decoration: InputDecoration(labelText: 'Album'),
                    ),
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.red,
                      title: Text('Scrobble now'),
                      value: _scrobbleNow,
                      onChanged: (value) {
                        setState(() {
                          _scrobbleNow = value;

                          if (!_scrobbleNow) {
                            _datetime = DateTime.now();
                          }
                        });
                      },
                    ),
                    Visibility(
                      visible: !_scrobbleNow,
                      child: DateTimeField(
                          decoration: InputDecoration(labelText: 'Timestamp'),
                          format: DateFormat('yyyy-MM-dd HH:mm:ss'),
                          initialValue: _datetime,
                          onShowPicker: (context, currentValue) async {
                            final date = await showDatePicker(
                                context: context,
                                initialDate: currentValue ?? DateTime.now(),
                                firstDate:
                                    DateTime.now().subtract(Duration(days: 14)),
                                lastDate:
                                    DateTime.now().add(Duration(days: 1)));

                            if (date != null) {
                              final time = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                      currentValue ?? DateTime.now()));

                              return DateTimeField.combine(date, time);
                            }

                            return currentValue;
                          },
                          onChanged: (datetime) {
                            setState(() {
                              _datetime = datetime;
                            });
                          }),
                    ),
                  ],
                ))));
  }

  @override
  void dispose() {
    super.dispose();
    _trackController.dispose();
    _artistController.dispose();
    _albumController.dispose();
  }
}
