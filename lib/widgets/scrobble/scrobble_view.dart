import 'package:finale/env.dart';
import 'package:finale/services/generic.dart';
import 'package:finale/services/lastfm/lastfm.dart';
import 'package:finale/util/util.dart';
import 'package:finale/widgets/base/app_bar.dart';
import 'package:finale/widgets/base/date_time_field.dart';
import 'package:finale/widgets/scrobble/music_recognition_component.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrcloud/flutter_acrcloud.dart';
import 'package:in_app_review/in_app_review.dart';

class ScrobbleView extends StatefulWidget {
  final Track? track;
  final bool isModal;

  const ScrobbleView({this.track, this.isModal = false});

  @override
  State<StatefulWidget> createState() => _ScrobbleViewState();
}

class _ScrobbleViewState extends State<ScrobbleView> {
  final _formKey = GlobalKey<FormState>();

  final _trackController = TextEditingController();
  final _artistController = TextEditingController();
  final _albumController = TextEditingController();

  var _useCustomTimestamp = false;
  DateTime? _customTimestamp;

  @override
  void initState() {
    super.initState();
    _trackController.text = widget.track?.name ?? '';
    _artistController.text = widget.track?.artistName ?? '';
    _albumController.text = widget.track?.albumName ?? '';

    if (!widget.isModal && isMobile) {
      ACRCloud.setUp(const ACRCloudConfig(
          acrCloudAccessKey, acrCloudAccessSecret, acrCloudHost));
    }
  }

  String? _required(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Required';
    }

    return null;
  }

  Future<void> _scrobble(BuildContext context) async {
    final response = await Lastfm.scrobble([
      BasicConcreteTrack(
          _trackController.text, _artistController.text, _albumController.text)
    ], [
      _useCustomTimestamp ? _customTimestamp! : DateTime.now()
    ]);

    if (widget.isModal) {
      Navigator.pop(context, response.ignored == 0);
      return;
    }

    if (response.ignored == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scrobbled successfully!')));
      _trackController.text = '';
      _artistController.text = '';
      _albumController.text = '';

      // Ask for a review
      if (!isWeb && await InAppReview.instance.isAvailable()) {
        InAppReview.instance.requestReview();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while scrobbling')));
    }
  }

  /// This widget is a circle whose size depends on the volume that the
  /// microphone picks up. Unfortunately, it's too laggy and the size doesn't
  /// change that much unless you make a noise very close to the microphone.
  // ignore: unused_element
  Widget _buildAudioIndicator(BuildContext context, ACRCloudSession session) {
    return StreamBuilder<double>(
      stream: session.volumeStream,
      initialData: 0.0,
      builder: (context, snapshot) => SizedBox(
          height: 50,
          child: Center(
              child: ClipOval(
                  child: SizedBox(
                      width: 100 * snapshot.data! + 10,
                      height: 100 * snapshot.data! + 10,
                      child: Container(color: Colors.red))))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createAppBar(
        'Scrobble',
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(scrobbleIcon),
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _scrobble(context);
                }
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(10),
            physics: const ScrollPhysics(),
            children: [
              if (!widget.isModal && isMobile)
                MusicRecognitionComponent(
                  onTrackRecognized: (track) {
                    setState(() {
                      _trackController.text = track.title;
                      _albumController.text = track.album.name;
                      _artistController.text = track.artists.first.name;
                    });
                  },
                ),
              TextFormField(
                controller: _trackController,
                decoration: const InputDecoration(labelText: 'Song *'),
                validator: _required,
              ),
              TextFormField(
                controller: _artistController,
                decoration: const InputDecoration(labelText: 'Artist *'),
                validator: _required,
              ),
              TextFormField(
                controller: _albumController,
                decoration: const InputDecoration(labelText: 'Album'),
              ),
              SwitchListTile(
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.red,
                title: const Text('Custom timestamp'),
                value: _useCustomTimestamp,
                onChanged: (value) {
                  setState(
                    () {
                      _useCustomTimestamp = value;

                      if (_useCustomTimestamp) {
                        _customTimestamp = DateTime.now();
                      }
                    },
                  );
                },
              ),
              Visibility(
                visible: _useCustomTimestamp,
                child: DateTimeField(
                  initialValue: _customTimestamp,
                  onChanged: (dateTime) {
                    setState(() {
                      _customTimestamp = dateTime;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _trackController.dispose();
    _artistController.dispose();
    _albumController.dispose();
  }
}
