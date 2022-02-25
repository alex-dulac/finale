import 'package:finale/services/apple_music/album.dart';
import 'package:finale/services/apple_music/apple_music.dart';
import 'package:finale/services/apple_music/artist.dart';
import 'package:finale/services/apple_music/song.dart';
import 'package:finale/util/constants.dart';
import 'package:finale/widgets/base/app_bar.dart';
import 'package:finale/widgets/base/error_view.dart';
import 'package:finale/widgets/base/loading_view.dart';
import 'package:finale/widgets/base/two_up.dart';
import 'package:finale/widgets/entity/apple_music/apple_music_album_view.dart';
import 'package:finale/widgets/entity/artist_tabs.dart';
import 'package:finale/widgets/entity/entity_display.dart';
import 'package:finale/widgets/entity/entity_image.dart';
import 'package:flutter/material.dart';

class AppleMusicArtistView extends StatelessWidget {
  final String artistId;

  const AppleMusicArtistView({required this.artistId});

  @override
  Widget build(BuildContext context) => FutureBuilder<AMArtist>(
        future: AppleMusic.getArtist(artistId),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              error: snapshot.error!,
              stackTrace: snapshot.stackTrace!,
            );
          } else if (!snapshot.hasData) {
            return LoadingView();
          }

          final artist = snapshot.data!;

          return Scaffold(
            appBar: createAppBar(
              artist.name,
              backgroundColor: appleMusicPink,
            ),
            body: TwoUp(
              image: EntityImage(entity: artist),
              listItems: [
                ArtistTabs(
                  color: appleMusicPink,
                  albumsWidget: EntityDisplay<AMAlbum>(
                    scrollable: false,
                    request: AMSearchAlbumsRequest.forArtist(artist),
                    detailWidgetBuilder: (album) =>
                        AppleMusicAlbumView(album: album),
                  ),
                  tracksWidget: EntityDisplay<AMSong>(
                    scrollable: false,
                    request: AMSearchSongsRequest.forArtist(artist),
                    scrobbleableEntity: (track) async => track,
                  ),
                ),
              ],
            ),
          );
        },
      );
}
