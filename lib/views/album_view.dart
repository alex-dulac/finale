import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:simplescrobble/components/display_component.dart';
import 'package:simplescrobble/lastfm.dart';
import 'package:simplescrobble/types/generic.dart';
import 'package:simplescrobble/types/lalbum.dart';

class AlbumView extends StatelessWidget {
  final BasicAlbum album;

  AlbumView({Key key, @required this.album}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LAlbum>(
      future: Lastfm.getAlbum(album),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('${snapshot.error}');
        } else if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final album = snapshot.data;

        return Scaffold(
            appBar: AppBar(
              title: Column(
                children: [
                  Text(album.name),
                  Text(
                    album.artist.name,
                    style: TextStyle(fontSize: 12),
                  )
                ],
              ),
            ),
            body: Center(
              child: Column(
                children: [
                  if (album.images != null)
                    Image.network(album.images.last.url),
                  SizedBox(height: 10),
                  IntrinsicHeight(
                      child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Scrobbles'),
                          Text(formatNumber(album.playCount))
                        ],
                      ),
                      VerticalDivider(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Listeners'),
                          Text(formatNumber(album.listeners))
                        ],
                      ),
                      VerticalDivider(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Your scrobbles'),
                          Text(formatNumber(album.userPlayCount))
                        ],
                      ),
                    ],
                  )),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: album.topTags.tags
                            .map((tag) => Container(
                                margin: EdgeInsets.symmetric(horizontal: 2),
                                child: Chip(label: Text(tag.name))))
                            .toList(),
                      )),
                  if (album.artist != null)
                    ListTile(
                      title: Text(album.artist.name),
                      trailing: Icon(Icons.chevron_right),
                    ),
                  if (album.tracks.isNotEmpty)
                    Expanded(
                        child: DisplayComponent(
                      items: album.tracks,
                      displayNumbers: true,
                    )),
                ],
              ),
            ));
      },
    );
  }
}
