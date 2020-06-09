import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:share/share.dart';
import 'package:simplescrobble/components/error_component.dart';
import 'package:simplescrobble/components/image_component.dart';
import 'package:simplescrobble/components/loading_component.dart';
import 'package:simplescrobble/components/tags_component.dart';
import 'package:simplescrobble/components/wiki_component.dart';
import 'package:simplescrobble/lastfm.dart';
import 'package:simplescrobble/types/generic.dart';
import 'package:simplescrobble/types/ltrack.dart';
import 'package:simplescrobble/views/album_view.dart';
import 'package:simplescrobble/views/artist_view.dart';
import 'package:simplescrobble/views/scrobble_view.dart';

class TrackView extends StatefulWidget {
  final BasicTrack track;

  TrackView({Key key, @required this.track}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TrackViewState();
}

class _TrackViewState extends State<TrackView> {
  bool loved;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LTrack>(
      future: Lastfm.getTrack(widget.track),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorComponent(error: snapshot.error);
        } else if (!snapshot.hasData) {
          return LoadingComponent();
        }

        final track = snapshot.data;
        loved = track.userLoved;

        return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Column(
                children: [
                  Text(track.name),
                  Text(
                    track.artist.name,
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    Share.share(track.url);
                  },
                ),
                Builder(
                    builder: (context) => IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () async {
                            final result = await showBarModalBottomSheet<bool>(
                                context: context,
                                duration: Duration(milliseconds: 200),
                                builder: (context, controller) => ScrobbleView(
                                      track: track,
                                      isModal: true,
                                    ));

                            if (result != null) {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: Text(result
                                      ? 'Scrobbled successfully!'
                                      : 'An error occurred while scrobbling')));
                            }
                          },
                        ))
              ],
            ),
            body: ListView(
              children: [
                if (track.album != null)
                  ImageComponent(
                      displayable: track.album,
                      quality: ImageQuality.high,
                      fit: BoxFit.cover),
                SizedBox(height: 10),
                IntrinsicHeight(
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Scrobbles'),
                        Text(formatNumber(track.playCount))
                      ],
                    ),
                    VerticalDivider(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Listeners'),
                        Text(formatNumber(track.listeners))
                      ],
                    ),
                    VerticalDivider(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Your scrobbles'),
                        Text(formatNumber(track.userPlayCount))
                      ],
                    ),
                    VerticalDivider(),
                    IconButton(
                      icon:
                          Icon(loved ? Icons.favorite : Icons.favorite_border),
                      onPressed: () async {
                        if (await Lastfm.love(track, !loved)) {
                          setState(() {
                            loved = !loved;
                          });
                        }
                      },
                    ),
                  ],
                )),
                if (track.topTags.tags.isNotEmpty) Divider(),
                if (track.topTags.tags.isNotEmpty)
                  TagsComponent(topTags: track.topTags),
                if (track.wiki != null) Divider(),
                if (track.wiki != null) WikiComponent(wiki: track.wiki),
                if (track.artist != null || track.album != null) Divider(),
                if (track.artist != null)
                  ListTile(
                      leading: ImageComponent(displayable: track.artist),
                      title: Text(track.artist.name),
                      trailing: Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    ArtistView(artist: track.artist)));
                      }),
                if (track.album != null)
                  ListTile(
                    leading: ImageComponent(displayable: track.album),
                    title: Text(track.album.name),
                    subtitle: Text(track.artist.name),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  AlbumView(album: track.album)));
                    },
                  ),
              ],
            ));
      },
    );
  }
}
