import 'package:finale/services/generic.dart';
import 'package:finale/services/lastfm/album.dart';
import 'package:finale/services/lastfm/lastfm.dart';
import 'package:finale/widgets/base/app_bar.dart';
import 'package:finale/widgets/base/error_view.dart';
import 'package:finale/widgets/base/loading_view.dart';
import 'package:finale/widgets/base/two_up.dart';
import 'package:finale/widgets/entity/entity_display.dart';
import 'package:finale/widgets/entity/entity_image.dart';
import 'package:finale/widgets/entity/lastfm/artist_view.dart';
import 'package:finale/widgets/entity/lastfm/scoreboard.dart';
import 'package:finale/widgets/entity/lastfm/tag_chips.dart';
import 'package:finale/widgets/entity/lastfm/track_view.dart';
import 'package:finale/widgets/entity/lastfm/wiki_tile.dart';
import 'package:finale/widgets/scrobble/scrobble_button.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class AlbumView extends StatelessWidget {
  final BasicAlbum album;

  const AlbumView({required this.album});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LAlbum>(
      future: album is LAlbum
          ? Future.value(album as LAlbum)
          : Lastfm.getAlbum(album),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorView(
            error: snapshot.error!,
            stackTrace: snapshot.stackTrace!,
            entity: this.album,
          );
        } else if (!snapshot.hasData) {
          return LoadingView();
        }

        final album = snapshot.data!;

        return Scaffold(
          appBar: createAppBar(
            album.name,
            subtitle: album.artist.name,
            actions: [
              IconButton(
                icon: Icon(Icons.adaptive.share),
                onPressed: () {
                  Share.share(album.url);
                },
              ),
              if (album.canScrobble) ScrobbleButton(entity: album),
            ],
          ),
          body: TwoUp(
            image: EntityImage(entity: album),
            listItems: [
              Scoreboard(statistics: {
                'Scrobbles': album.playCount,
                'Listeners': album.listeners,
                'Your scrobbles': album.userPlayCount,
              }),
              if (album.topTags.tags.isNotEmpty) ...[
                const Divider(),
                TagChips(topTags: album.topTags),
              ],
              if (album.wiki != null && album.wiki!.isNotEmpty) ...[
                const Divider(),
                WikiTile(wiki: album.wiki!)
              ],
              const Divider(),
              ListTile(
                  leading: EntityImage(entity: album.artist),
                  title: Text(album.artist.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ArtistView(artist: album.artist)));
                  }),
              if (album.tracks.isNotEmpty) ...[
                const Divider(),
                EntityDisplay<LAlbumTrack>(
                  items: album.tracks,
                  scrollable: false,
                  displayNumbers: true,
                  displayImages: false,
                  detailWidgetBuilder: (track) => TrackView(track: track),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
