import 'package:finale/services/spotify/playlist.dart';
import 'package:finale/services/spotify/spotify.dart';
import 'package:finale/services/spotify/track.dart';
import 'package:finale/util/util.dart';
import 'package:finale/widgets/base/app_bar.dart';
import 'package:finale/widgets/base/two_up.dart';
import 'package:finale/widgets/entity/entity_display.dart';
import 'package:finale/widgets/entity/entity_image.dart';
import 'package:finale/widgets/scrobble/scrobble_button.dart';
import 'package:flutter/material.dart';

class SpotifyPlaylistView extends StatelessWidget {
  final SPlaylistSimple playlist;

  SpotifyPlaylistView({required this.playlist});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: createAppBar(
          playlist.name,
          backgroundColor: spotifyGreen,
          actions: [
            if (playlist.isNotEmpty)
              ScrobbleButton(
                  entityProvider: () => Spotify.getFullPlaylist(playlist)),
          ],
        ),
        body: TwoUp(
          image: EntityImage(entity: playlist),
          listItems: [
            EntityDisplay<STrack>(
              request: SPlaylistTracksRequest(playlist),
              scrollable: false,
              scrobbleableEntity: (track) => Future.value(track),
            ),
          ],
        ),
      );
}
